import Foundation

/// 玩家数据模型
struct Player: Codable {
    var diamonds: Int           // 钻石数量
    var currentPet: Pet         // 当前宠物
    var rank: Int              // 排名
    var wins: Int              // 胜场数
    var dailyChallenges: Int   // 今日剩余挑战次数
    var upgradeItems: [UpgradeItem]  // 升级物品列表
    
    // 健康数据追踪（用于经验加成）
    var todayExerciseSeconds: Int = 0     // 今日运动秒数
    var todaySleepSeconds: Int = 0        // 今日睡眠秒数
    var lastHealthUpdateDate: Date = Date()  // 上次健康数据更新日期
    
    // 每日登录追踪
    var loginStreakDays: Int = 0          // 连续登录天数（最多7天）
    var lastLoginDate: Date?              // 上次登录日期
    var totalLoginDays: Int = 0           // 总登录天数
    var hasClaimedTodayReward: Bool = false  // 今日是否已领取奖励
    
    init(diamonds: Int = 50,
         currentPet: Pet? = nil,
         rank: Int = 999,
         wins: Int = 0,
         dailyChallenges: Int = 3,
         upgradeItems: [UpgradeItem] = []) {
        self.diamonds = diamonds
        // 使用便捷初始化方法创建默认宠物（A级，随机属性）
        self.currentPet = currentPet ?? Pet(name: "花花", emoji: "🐼", quality: .rankA)
        self.rank = rank
        self.wins = wins
        self.dailyChallenges = dailyChallenges
        self.upgradeItems = upgradeItems.isEmpty ? Player.defaultUpgradeItems() : upgradeItems
    }
    
    /// 获取默认升级物品列表
    static func defaultUpgradeItems() -> [UpgradeItem] {
        return [
            UpgradeItem(type: .petBed, level: 1, maxLevel: 10),
            UpgradeItem(type: .foodBowl, level: 0, maxLevel: 10),
            UpgradeItem(type: .toy, level: 0, maxLevel: 10)
        ]
    }
    
    /// 获取每小时钻石收益
    func hourlyDiamondIncome() -> Int {
        return upgradeItems.reduce(0) { $0 + $1.currentBonus() }
    }
    
    /// 添加钻石
    mutating func addDiamonds(_ amount: Int) {
        diamonds += amount
    }
    
    /// 消费钻石
    mutating func spendDiamonds(_ amount: Int) -> Bool {
        if diamonds >= amount {
            diamonds -= amount
            return true
        }
        return false
    }
}

// MARK: - Preview Data
extension Player {
    static let preview = Player(
        diamonds: 1,
        currentPet: .preview,
        rank: 1,
        wins: 0,
        dailyChallenges: 3
    )
}
