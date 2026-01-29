import SwiftUI
import Combine

/// 游戏状态管理器
class GameStateManager: ObservableObject {
    @Published var player: Player
    
    // HealthKit管理器
    let healthManager = HealthManager()
    
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
    
    /// 处理离线期间的变化
    private func processOfflineTime() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastUpdateTime)
        
        if elapsed > 60 {
            // 计算快乐值减少
            let happinessDecayCount = Int(elapsed / happinessDecayInterval)
            let happinessLoss = happinessDecayCount * happinessDecayAmount
            player.currentPet.decreaseHappiness(happinessLoss)
            
            // 计算经验增加（基于秒数）
            let elapsedSeconds = Int(elapsed)
            let expPerSecond = totalExpPerSecond()
            let expGain = Int(Double(elapsedSeconds) * expPerSecond)
            addExperience(expGain)
            
            lastUpdateTime = now
            saveLastUpdateTime()
        }
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
        
        // 2. 双倍经验卡加成（暂时未实现，TODO: 添加经验卡系统）
        let expCardMultiplier: Double = 1.0  // 使用经验卡时为2.0
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
        player.currentPet.exp += amount
        
        // 自动升级
        while player.currentPet.canLevelUp() {
            player.currentPet.levelUp()
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
}
