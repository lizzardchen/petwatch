import SwiftUI
import Combine
import HealthKit

/// 游戏状态管理器
class GameStateManager: ObservableObject {
    @Published var player: Player
    
    // HealthKit管理器
    let healthManager = HealthManager()
    
    // Firebase管理器
    let firebaseManager = FirebaseManager.shared
    
    // 快乐值和经验定时器
    private var gameTimer: Timer?
    private var lastUpdateTime: Date
    
    // 常量
    private let happinessDecayInterval: TimeInterval = 600  // 10分钟
    private let happinessDecayAmount: Int = 2
    private let expUpdateInterval: TimeInterval = 60  // 1分钟
    
    init() {
        // 初始化时间
        self.lastUpdateTime = UserDefaults.standard.object(forKey: "lastUpdateTime") as? Date ?? Date()
        
        // 尝试从UserDefaults加载数据
        if let savedPlayer = UserDefaults.standard.data(forKey: "player"),
           let decodedPlayer = try? JSONDecoder().decode(Player.self, from: savedPlayer) {
            self.player = decodedPlayer
            // 确保升级物品列表存在
            if self.player.upgradeItems.isEmpty {
                self.player.upgradeItems = Player.defaultUpgradeItems()
            }
        } else {
            // 创建新玩家
            self.player = Player(
                diamonds: Constants.Game.initialDiamonds,
                currentPet: Pet()  // 使用默认Pet，不是preview
            )
        }
        
        // 计算离线期间的变化
        processOfflineTime()
        
        // 检查并发放每日登录奖励
        checkDailyLoginReward()
        
        // 请求He althKit权限
        healthManager.requestAuthorization { granted in
            if granted {
                print("HealthKit授权成功")
                // 启动健康数据监听
                self.healthManager.startHealthMonitoring()
            } else {
                print("HealthKit授权失败，睡眠和运动加成将不可用")
            }
        }
        
        // 启动游戏定时器
        startGameTimer()
    }
    
    deinit {
        gameTimer?.invalidate()
    }
    
    // MARK: - 定时器管理
    
    /// 启动游戏定时器（每10秒更新一次）
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.onTimerTick()
        }
    }
    
    /// 定时器触发
    private func onTimerTick() {
        updateHappinessAndExp()
        savePlayer()
    }
    
    /// 处理离线期间的变化（包含健康数据补偿）
    private func processOfflineTime() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastUpdateTime)
        
        if elapsed > 60 {
            // 计算快乐值减少
            let happinessDecayCount = Int(elapsed / happinessDecayInterval)
            let happinessLoss = happinessDecayCount * happinessDecayAmount
            player.currentPet.decreaseHappiness(happinessLoss)
            
            // 计算基础经验（不含睡眠和运动加成）
            let elapsedSeconds = Int(elapsed)
            let baseExpPerSecond = 1.0  // 基础挂机
            let buildingBonus = player.upgradeItems.reduce(0.0) { $0 + $1.expBonusPerSecond() }
            let baseExpGain = Int((baseExpPerSecond + buildingBonus) * Double(elapsedSeconds))
            
            // 查询离线期间的健康数据并补发经验
            queryOfflineHealthBonus(from: lastUpdateTime, to: now) { [weak self] healthBonus in
                guard let self = self else { return }
                
                let totalExp = baseExpGain + healthBonus
                self.addExperience(totalExp)
                
                print("📊 离线补发: 基础\(baseExpGain) + 健康\(healthBonus) = 总计\(totalExp)经验")
                
                self.lastUpdateTime = now
                self.saveLastUpdateTime()
                self.savePlayer()
            }
        }
    }
    
    /// 查询离线期间的健康数据加成
    /// - Parameters:
    ///   - startDate: 离线开始时间
    ///   - endDate: 离线结束时间（当前时间）
    ///   - completion: 返回健康加成经验值
    private func queryOfflineHealthBonus(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        let group = DispatchGroup()
        var sleepBonus = 0
        var exerciseBonus = 0
        
        // 1. 查询睡眠时间段
        group.enter()
        healthManager.querySleepIntervals(from: startDate, to: endDate) { intervals in
            // 计算总睡眠时长（秒）
            let totalSleepSeconds = intervals.reduce(0.0) { total, interval in
                return total + interval.duration
            }
            
            // 睡眠加成：2经验/秒，每天最多4小时=14400秒
            let dailyLimit = 14400.0  // 4小时
            let effectiveSleepSeconds = min(totalSleepSeconds, dailyLimit)
            sleepBonus = Int(effectiveSleepSeconds * 2.0)
            
            group.leave()
        }
        
        // 2. 查询运动时长
        group.enter()
        queryExerciseDuration(from: startDate, to: endDate) { duration in
            // 运动加成：3经验/秒，每天最多2小时=7200秒
            let dailyLimit = 7200  // 2小时
            let effectiveDuration = min(duration, dailyLimit)
            exerciseBonus = effectiveDuration * 3
            
            group.leave()
        }
        
        // 等待所有查询完成
        group.notify(queue: .main) {
            let totalBonus = sleepBonus + exerciseBonus
            completion(totalBonus)
        }
    }
    
    /// 查询指定时间段的运动总时长
    private func queryExerciseDuration(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                print("查询运动数据失败: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let workouts = samples as? [HKWorkout] else {
                completion(0)
                return
            }
            
            let totalDuration = workouts.reduce(0.0) { $0 + $1.duration }
            
            DispatchQueue.main.async {
                completion(Int(totalDuration))
            }
        }
        
        healthManager.healthStore.execute(query)
    }
    
    /// 更新快乐值和经验
    private func updateHappinessAndExp() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastUpdateTime)
        
        // 每10分钟减少2点快乐值
        if elapsed >= happinessDecayInterval {
            let decayCount = Int(elapsed / happinessDecayInterval)
            player.currentPet.decreaseHappiness(decayCount * happinessDecayAmount)
        }
        
        // 每秒增加经验
        let expPerSecond = totalExpPerSecond()
        let expToAdd = Int(expPerSecond * elapsed)
        addExperience(expToAdd)
        
        lastUpdateTime = now
        saveLastUpdateTime()
    }
    
    // MARK: - 经验系统
    
    /// 计算每秒总经验产出
    /// 公式: 总经验/秒 = [基础挂机(1) × 双倍经验卡倍数] + 建筑1 + 建筑2 + 建筑3 + 睡眠 + 运动
    func totalExpPerSecond() -> Double {
        // 1. 基础挂机经验（1经验/秒）
        let baseExp: Double = 1.0
        
        // 2. 双倍经验卡加成
        let expCardMultiplier: Double = player.isExpCardActive ? 2.0 : 1.0
        let baseWithCard = baseExp * expCardMultiplier
        
        // 3. 建筑加成（从升级物品获取）
        let buildingBonus = player.upgradeItems.reduce(0.0) { $0 + $1.expBonusPerSecond() }
        
        // 4. 睡眠加成（从Player获取，最多2经验/秒，每天限4小时=14400秒）
        let sleepBonus = calculateSleepBonus()
        
        // 5. 运动加成（从Player获取，最多3经验/秒，每天限2小时=7200秒）
        let exerciseBonus = calculateExerciseBonus()
        
        return baseWithCard + buildingBonus + sleepBonus + exerciseBonus
    }
    
    /// 计算睡眠经验加成（即时制）
    /// 只在当前睡眠时提供2经验/秒
    private func calculateSleepBonus() -> Double {
        // 同步获取睡眠状态（使用published property）
        return healthManager.isSleeping ? 2 : 0.0
    }
    
    /// 计算运动经验加成（即时制）
    /// 只在当前运动时提供3经验/秒
    private func calculateExerciseBonus() -> Double {
        // 同步获取运动状态（使用published property）
        return healthManager.isExercising ? 3 : 0.0
    }
    
    /// 检查并重置每日健康数据
    private func checkAndResetDailyHealth() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(player.lastHealthUpdateDate) {
            // 新的一天，重置数据
            player.todayExerciseSeconds = 0
            player.todaySleepSeconds = 0
            player.lastHealthUpdateDate = Date()
            savePlayer()
        }
    }
    
    /// 【已废弃】旧的每分钟经验计算（保留兼容性）
    @available(*, deprecated, message: "使用 totalExpPerSecond() 代替")
    func totalExpPerMinute() -> Int {
        return Int(totalExpPerSecond() * 60)
    }
    
    /// 添加经验并自动升级
    func addExperience(_ amount: Int) {
        let oldLevel = player.currentPet.level
        player.currentPet.exp += amount
        
        // 自动升级
        while player.currentPet.canLevelUp() {
            player.currentPet.levelUp()
        }
        
        // 升级后同步排行榜
        if player.currentPet.level != oldLevel {
            syncToFirebase()
        }
    }
    
    // MARK: - 健康数据更新
    
    /// 更新运动秒数（从HealthKit调用）
    /// - Parameter seconds: 今日累计运动秒数
    func updateExerciseData(seconds: Int) {
        checkAndResetDailyHealth()
        player.todayExerciseSeconds = seconds
        savePlayer()
    }
    
    /// 更新睡眠秒数（从HealthKit调用）
    /// - Parameter seconds: 今日累计睡眠秒数
    func updateSleepData(seconds: Int) {
        checkAndResetDailyHealth()
        player.todaySleepSeconds = seconds
        savePlayer()
    }
    
    /// 获取当前运动经验加成（用于UI显示）
    func getCurrentExerciseBonus() -> Double {
        return calculateExerciseBonus()
    }
    
    /// 获取当前睡眠经验加成（用于UI显示）
    func getCurrentSleepBonus() -> Double {
        return calculateSleepBonus()
    }
    
    // MARK: - 快乐值系统
    
    /// 用户交互增加快乐值
    func interactWithPet() {
        player.currentPet.increaseHappiness(5)
        savePlayer()
    }
    
    /// 检查是否可以战斗
    func canBattle() -> Bool {
        return player.currentPet.canBattle()
    }
    
    // MARK: - 数据持久化
    
    /// 保存玩家数据
    func savePlayer() {
        if let encoded = try? JSONEncoder().encode(player) {
            UserDefaults.standard.set(encoded, forKey: "player")
        }
    }
    
    /// 保存最后更新时间
    private func saveLastUpdateTime() {
        UserDefaults.standard.set(lastUpdateTime, forKey: "lastUpdateTime")
    }
    
    
    // MARK: - 每日登录奖励
    
    /// 检查并发放每日登录奖励
    /// 新用户前7天每日登录获得20钻石，断签则重置连续天数
    private func checkDailyLoginReward() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 检查上次登录日期
        if let lastLogin = player.lastLoginDate {
            let lastLoginDay = calendar.startOfDay(for: lastLogin)
            
            // 如果今天已经登录过，直接返回
            if calendar.isDate(today, inSameDayAs: lastLoginDay) {
                return
            }
            
            // 计算距离上次登录的天数
            let daysSinceLastLogin = calendar.dateComponents([.day], from: lastLoginDay, to: today).day ?? 0
            
            if daysSinceLastLogin == 1 {
                // 连续登录
                player.loginStreakDays += 1
            } else {
                // 断签，重置连续天数
                player.loginStreakDays = 1
            }
        } else {
            // 首次登录
            player.loginStreakDays = 1
        }
        
        // 前7天才发放每日奖励
        if player.loginStreakDays <= 7 {
            player.addDiamonds(20)
            print("✨ 每日登录奖励：+20钻石 (连续\(player.loginStreakDays)天)")
        }
        
        // 重置每日挑战次数
        player.dailyChallenges = Constants.Game.dailyChallenges
        print("⚔️ 每日挑战次数已重置为 \(Constants.Game.dailyChallenges)")
        
        // 更新登录数据
        player.lastLoginDate = today
        player.totalLoginDays += 1
        player.hasClaimedTodayReward = true
        
        savePlayer()
    }
    
    // MARK: - 钻石管理
    
    /// 添加钻石
    func addDiamonds(_ amount: Int) {
        player.addDiamonds(amount)
        savePlayer()
    }
    
    /// 消费钻石
    func spendDiamonds(_ amount: Int) -> Bool {
        if player.spendDiamonds(amount) {
            savePlayer()
            return true
        }
        return false
    }
    
    // MARK: - 宠物管理
    
    /// 升级宠物
    func upgradePet() {
        player.currentPet.levelUp()
        savePlayer()
    }
    
    /// 升级物品
    func upgradeItem(_ item: UpgradeItem) -> Bool {
        let cost = item.upgradeCost()
        if spendDiamonds(cost) {
            if let index = player.upgradeItems.firstIndex(where: { $0.id == item.id }) {
                if item.isUnlocked {
                    player.upgradeItems[index].level += 1
                } else {
                    player.upgradeItems[index].level = 1
                }
                savePlayer()
                return true
            }
        }
        return false
    }
    
    /// 获取升级物品
    func getUpgradeItem(type: UpgradeItemType) -> UpgradeItem? {
        return player.upgradeItems.first { $0.type == type }
    }
    
    /// 更新宠物名称
    func updatePetName(_ newName: String) {
        player.currentPet.name = newName
        savePlayer()
    }
    
    // MARK: - 双倍经验卡
    
    /// 激活双倍经验卡
    /// - Parameter durationSeconds: 持续时长（秒）
    func activateExpCard(durationSeconds: Int) {
        player.activateExpCard(durationSeconds: durationSeconds)
        savePlayer()
    }
    
    /// 用钻石购买双倍经验卡
    /// - Parameters:
    ///   - durationSeconds: 持续时长（秒）
    ///   - cost: 钻石费用
    /// - Returns: 是否购买成功
    func purchaseExpCard(durationSeconds: Int, cost: Int) -> Bool {
        guard spendDiamonds(cost) else { return false }
        activateExpCard(durationSeconds: durationSeconds)
        return true
    }
    
    /// 本地生成对手（Firebase无数据时的备选）
    func generateOpponents() -> [Opponent] {
        let pet = player.currentPet
        let npcNames = ["小明", "小红", "小刚", "阿花", "大壮"]
        let npcEmojis = ["🐱", "😺", "🐶", "🐰", "🦊"]
        var opponents: [Opponent] = []
        for i in 0..<3 {
            let levelVariance = max(1, Int(Double(pet.level) * 0.3))
            let opponentLevel = max(1, min(99, pet.level + Int.random(in: -levelVariance...levelVariance)))
            let opponentPower = max(1, Int(Double(opponentLevel) * Double.random(in: 0.8...1.5)))
            let winRate = Double.random(in: 0.05...0.30)
            let diamondReward = max(10, opponentPower + Int.random(in: -10...20))
            opponents.append(Opponent(
                name: npcNames[i], emoji: npcEmojis[i],
                level: opponentLevel, power: opponentPower,
                wins: Int.random(in: 0...20), winRate: winRate,
                diamondReward: diamondReward
            ))
        }
        return opponents.sorted { $0.power < $1.power }
    }
    
    // MARK: - Firebase 数据同步
    
    /// 同步玩家数据到 Firebase 排行榜
    func syncToFirebase() {
        firebaseManager.syncPlayerData(pet: player.currentPet, wins: player.wins)
    }
    
    // MARK: - 战斗系统
    
    /// 检查是否还有剩余挑战次数
    func hasRemainingChallenges() -> Bool {
        return player.dailyChallenges > 0
    }
    
    /// 执行战斗并返回战斗日志
    /// - Parameter opponent: 对手
    /// - Returns: (胜负结果, 战斗回合日志, 钻石奖励)
    func executeBattle(against opponent: Opponent) -> (playerWon: Bool, rounds: [BattleRound], diamondReward: Int) {
        var playerHP = player.currentPet.hp
        var opponentHP = opponent.hp
        var rounds: [BattleRound] = []
        
        let maxRounds = 20
        var roundNumber = 0
        
        // 根据速度决定先手
        let playerFirst = player.currentPet.speed >= opponent.speed
        
        while playerHP > 0 && opponentHP > 0 && roundNumber < maxRounds {
            roundNumber += 1
            
            if playerFirst {
                // 玩家先攻
                let playerCrit = player.currentPet.rollCritical()
                let playerDmg = player.currentPet.calculateDamage(targetDefense: opponent.defense, isCritical: playerCrit)
                opponentHP = max(0, opponentHP - playerDmg)
                
                rounds.append(BattleRound(
                    roundNumber: roundNumber,
                    isPlayerAttack: true,
                    damage: playerDmg,
                    isCritical: playerCrit,
                    playerHPAfter: playerHP,
                    opponentHPAfter: opponentHP
                ))
                
                if opponentHP <= 0 { break }
                
                // 对手反击
                let opponentCrit = opponent.rollCritical()
                let opponentDmg = opponent.calculateDamage(targetDefense: player.currentPet.defense, isCritical: opponentCrit)
                playerHP = max(0, playerHP - opponentDmg)
                
                rounds.append(BattleRound(
                    roundNumber: roundNumber,
                    isPlayerAttack: false,
                    damage: opponentDmg,
                    isCritical: opponentCrit,
                    playerHPAfter: playerHP,
                    opponentHPAfter: opponentHP
                ))
            } else {
                // 对手先攻
                let opponentCrit = opponent.rollCritical()
                let opponentDmg = opponent.calculateDamage(targetDefense: player.currentPet.defense, isCritical: opponentCrit)
                playerHP = max(0, playerHP - opponentDmg)
                
                rounds.append(BattleRound(
                    roundNumber: roundNumber,
                    isPlayerAttack: false,
                    damage: opponentDmg,
                    isCritical: opponentCrit,
                    playerHPAfter: playerHP,
                    opponentHPAfter: opponentHP
                ))
                
                if playerHP <= 0 { break }
                
                // 玩家反击
                let playerCrit = player.currentPet.rollCritical()
                let playerDmg = player.currentPet.calculateDamage(targetDefense: opponent.defense, isCritical: playerCrit)
                opponentHP = max(0, opponentHP - playerDmg)
                
                rounds.append(BattleRound(
                    roundNumber: roundNumber,
                    isPlayerAttack: true,
                    damage: playerDmg,
                    isCritical: playerCrit,
                    playerHPAfter: playerHP,
                    opponentHPAfter: opponentHP
                ))
            }
        }
        
        let playerWon = opponentHP <= 0 || (playerHP > 0 && opponentHP > 0 && playerHP >= opponentHP)
        
        // 计算奖励
        let diamondReward: Int
        if playerWon {
            diamondReward = opponent.diamondReward
            player.wins += 1
        } else {
            diamondReward = max(5, opponent.diamondReward / 5)
        }
        
        // 扣减挑战次数
        player.dailyChallenges = max(0, player.dailyChallenges - 1)
        
        // 消耗快乐值
        player.currentPet.decreaseHappiness(10)
        
        // 发放钻石
        player.addDiamonds(diamondReward)
        
        savePlayer()
        syncToFirebase()
        
        return (playerWon, rounds, diamondReward)
    }
    
    // MARK: - 重生系统
    
    /// 执行宠物重生
    /// - Returns: 重生获得的钻石奖励数量，nil表示重生失败
    func rebirthPet() -> Int? {
        guard player.currentPet.canRebirth() else { return nil }
        
        let reward = player.currentPet.quality.rebirthDiamondReward
        player.currentPet = player.currentPet.rebirth()
        player.addDiamonds(reward)
        savePlayer()
        syncToFirebase()
        
        return reward
    }
}
