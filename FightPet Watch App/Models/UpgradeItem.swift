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
         level: Int = 1,
         maxLevel: Int = 10) {
        self.id = id
        self.type = type
        self.level = level
        self.maxLevel = maxLevel
    }
    
    /// 当前等级收益
    func currentBonus() -> Int {
        return level * 2
    }
    
    /// 下一等级收益
    func nextBonus() -> Int {
        return (level + 1) * 2
    }
    
    /// 升级所需钻石
    func upgradeCost() -> Int {
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
