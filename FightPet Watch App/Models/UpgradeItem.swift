import Foundation

/// 可升级物品类型
enum UpgradeItemType: String, Codable {
    case petBed = "宠物床"
    case foodBowl = "食物碗"
    case toy = "玩具"
    
    var icon: String {
        switch self {
        case .petBed: return "🛏️"
        case .foodBowl: return "🍜"
        case .toy: return "🧸"
        }
    }
    
    var description: String {
        switch self {
        case .petBed: return "钻石/小时"
        case .foodBowl: return "宠物属性"
        case .toy: return "快乐值"
        }
    }
}

/// 可升级物品数据模型
struct UpgradeItem: Identifiable, Codable {
    let id: UUID
    let type: UpgradeItemType
    var level: Int
    let maxLevel: Int
    
    init(id: UUID = UUID(),
         type: UpgradeItemType,
         level: Int = 0,
         maxLevel: Int = 10) {
        self.id = id
        self.type = type
        self.level = level
        self.maxLevel = maxLevel
    }
    
    /// 是否已解锁（level > 0 表示已解锁）
    var isUnlocked: Bool {
        return level > 0
    }
    
    /// 是否已满级
    var isMaxLevel: Bool {
        return level >= maxLevel
    }
    
    /// 解锁条件描述
    func unlockRequirement() -> String {
        switch type {
        case .petBed:
            return ""
        case .foodBowl:
            return "宠物床 Lv.10 解锁"
        case .toy:
            return "食物碗 Lv.10 解锁"
        }
    }
    
    // MARK: - 建筑经验加成数据表（从Excel导入）
    
    /// 建筑1（宠物床）每秒经验加成
    static let building1ExpBonus: [Int: Double] = [
        1: 0.4, 2: 0.44, 3: 0.484, 4: 0.5324, 5: 0.58564,
        6: 0.644204, 7: 0.708624, 8: 0.779487, 9: 0.857436, 10: 0.943179
    ]
    
    /// 建筑2（食物碗）每秒经验加成
    static let building2ExpBonus: [Int: Double] = [
        1: 0.8, 2: 0.88, 3: 0.968, 4: 1.0648, 5: 1.17128,
        6: 1.288408, 7: 1.417249, 8: 1.558974, 9: 1.714871, 10: 1.886358
    ]
    
    /// 建筑3（玩具）每秒经验加成
    static let building3ExpBonus: [Int: Double] = [
        1: 1.5, 2: 1.65, 3: 1.815, 4: 1.9965, 5: 2.19615,
        6: 2.415765, 7: 2.657342, 8: 2.923076, 9: 3.215383, 10: 3.536922
    ]
    
    /// 建筑1（宠物床）升级消耗钻石
    static let building1UpgradeCost: [Int: Int] = [
        1: 10, 2: 15, 3: 23, 4: 34, 5: 51,
        6: 76, 7: 114, 8: 171, 9: 256, 10: 384
    ]
    
    /// 建筑2（食物碗）升级消耗钻石
    static let building2UpgradeCost: [Int: Int] = [
        1: 384, 2: 768, 3: 1536, 4: 2304, 5: 3456,
        6: 5184, 7: 7776, 8: 11664, 9: 17496, 10: 26244
    ]
    
    /// 建筑3（玩具）升级消耗钻石
    static let building3UpgradeCost: [Int: Int] = [
        1: 26244, 2: 28868, 3: 31755, 4: 34931, 5: 38424,
        6: 42266, 7: 46493, 8: 51142, 9: 56256, 10: 61882
    ]
    
    /// 当前等级每秒经验加成
    func expBonusPerSecond() -> Double {
        guard isUnlocked else { return 0 }
        
        switch type {
        case .petBed:
            return UpgradeItem.building1ExpBonus[level] ?? 0
        case .foodBowl:
            return UpgradeItem.building2ExpBonus[level] ?? 0
        case .toy:
            return UpgradeItem.building3ExpBonus[level] ?? 0
        }
    }
    
    /// 下一等级每秒经验加成
    func nextExpBonusPerSecond() -> Double {
        let nextLevel = level + 1
        guard nextLevel <= maxLevel else { return expBonusPerSecond() }
        
        switch type {
        case .petBed:
            return UpgradeItem.building1ExpBonus[nextLevel] ?? 0
        case .foodBowl:
            return UpgradeItem.building2ExpBonus[nextLevel] ?? 0
        case .toy:
            return UpgradeItem.building3ExpBonus[nextLevel] ?? 0
        }
    }
    
    /// 升级所需钻石（从Excel数据表查询）
    func upgradeCost() -> Int {
        let targetLevel = isUnlocked ? level + 1 : 1
        
        switch type {
        case .petBed:
            return UpgradeItem.building1UpgradeCost[targetLevel] ?? 0
        case .foodBowl:
            return UpgradeItem.building2UpgradeCost[targetLevel] ?? 0
        case .toy:
            return UpgradeItem.building3UpgradeCost[targetLevel] ?? 0
        }
    }
    
    /// 是否可以升级
    func canUpgrade() -> Bool {
        return level < maxLevel
    }
    
    /// 【已废弃】旧的经验加成方法（保留兼容性）
    @available(*, deprecated, message: "使用 expBonusPerSecond() 代替")
    func expBonus() -> Int {
        return Int(expBonusPerSecond() * 60) // 转换为每分钟
    }
    
    /// 【已废弃】当前等级收益（每小时钻石）
    @available(*, deprecated, message: "当前系统不使用小时钻石收益")
    func currentBonus() -> Int {
        return level * 2
    }
    
    /// 【已废弃】下一等级收益
    @available(*, deprecated, message: "当前系统不使用小时钻石收益")
    func nextBonus() -> Int {
        return (level + 1) * 2
    }
}

// MARK: - Preview Data
extension UpgradeItem {
    static let preview = UpgradeItem(
        type: .petBed,
        level: 2,
        maxLevel: 10
    )
}
