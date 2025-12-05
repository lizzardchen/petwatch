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
            return "" // 宠物床是默认解锁的
        case .foodBowl:
            return "需要宠物床 满"
        case .toy:
            return "需要食物碗 满"
        }
    }
    
    /// 当前等级收益（每小时钻石）
    func currentBonus() -> Int {
        return level * 2
    }
    
    /// 下一等级收益
    func nextBonus() -> Int {
        return (level + 1) * 2
    }
    
    /// 升级所需钻石
    func upgradeCost() -> Int {
        if level == 0 {
            return 100 // 解锁费用
        }
        return level * 75
    }
    
    /// 是否可以升级
    func canUpgrade() -> Bool {
        return level < maxLevel
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
