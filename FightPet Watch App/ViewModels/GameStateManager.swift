import SwiftUI
import Combine

/// 游戏状态管理器
class GameStateManager: ObservableObject {
    @Published var player: Player
    
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
        
        // 启动游戏定时器
        startGameTimer()
    }
    
    deinit {
        gameTimer?.invalidate()
    }
    
    // MARK: - 定时器管理
    
    /// 启动游戏定时器（每分钟更新一次）
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
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
            
            // 计算经验增加
            let expGainMinutes = Int(elapsed / expUpdateInterval)
            let expPerMinute = totalExpPerMinute()
            let expGain = expGainMinutes * expPerMinute
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
        
        // 每分钟增加经验
        let expToAdd = totalExpPerMinute()
        addExperience(expToAdd)
        
        lastUpdateTime = now
        saveLastUpdateTime()
    }
    
    // MARK: - 经验系统
    
    /// 计算每分钟总经验产出
    /// 1. 基础经验（默认提供）
    /// 2. 升级建筑加成
    func totalExpPerMinute() -> Int {
        let baseExp = player.currentPet.expPerMinute  // 基础经验
        let buildingBonus = player.upgradeItems.reduce(0) { $0 + $1.expBonus() }
        return baseExp + buildingBonus
    }
    
    /// 添加经验并自动升级
    func addExperience(_ amount: Int) {
        player.currentPet.exp += amount
        
        // 自动升级
        while player.currentPet.canLevelUp() {
            player.currentPet.levelUp()
        }
    }
    
    /// 运动中获取额外经验（由健康数据触发）
    func addExerciseExperience(_ steps: Int) {
        // 每1000步获得10点经验
        let bonusExp = (steps / 1000) * 10
        addExperience(bonusExp)
        savePlayer()
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
