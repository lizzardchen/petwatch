import Foundation
import SwiftUI

/// 宠物品质枚举
enum PetQuality: Int, Codable, CaseIterable {
    case common = 1      // 普通
    case rare = 2        // 稀有
    case epic = 3        // 史诗
    case legendary = 4   // 传说
    
    var name: String {
        switch self {
        case .common: return "普通"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    /// 经验需求系数（品质越高，升级所需经验越多）
    var expMultiplier: Double {
        switch self {
        case .common: return 1.0
        case .rare: return 1.2
        case .epic: return 1.5
        case .legendary: return 2.0
        }
    }
    
    /// 三围基础系数（品质越高，三围基础值越高）
    var statsMultiplier: Double {
        switch self {
        case .common: return 1.0
        case .rare: return 1.3
        case .epic: return 1.6
        case .legendary: return 2.0
        }
    }
}

/// 宠物数据模型
struct Pet: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var level: Int
    var exp: Int
    var power: Int
    
    // 品质
    var quality: PetQuality
    
    // 三维属性
    var intelligence: Int  // 智慧 -> 决定暴击率
    var stamina: Int       // 体力 -> 决定HP上限
    var strength: Int      // 力量 -> 决定基础攻击力
    
    // 状态
    var happiness: Int     // 快乐值
    var intimacy: Int      // 亲密值
    var sleepBonus: Int    // 睡眠加成
    
    // 升级相关
    var expPerMinute: Int  // 每分钟经验增长（基础值）
    
    init(id: UUID = UUID(), 
         name: String = "花花",
         emoji: String = "🐼",
         level: Int = 1,
         exp: Int = 0,
         power: Int = 10,
         quality: PetQuality = .common,
         intelligence: Int = 10,
         stamina: Int = 10,
         strength: Int = 10,
         happiness: Int = 60,  // 初始60
         intimacy: Int = 0,
         sleepBonus: Int = 0,
         expPerMinute: Int = 1) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.level = level
        self.exp = exp
        self.quality = quality
        self.intelligence = intelligence
        self.stamina = stamina
        self.strength = strength
        self.happiness = happiness
        self.intimacy = intimacy
        self.sleepBonus = sleepBonus
        self.expPerMinute = expPerMinute
        // 计算初始战力
        self.power = power
        self.calculatePower()
    }
    
    /// 计算战力
    /// 公式：战斗力 = 等级 × 品质 × 系数
    /// 系数由三围计算：(智力 + 体力 + 力量) / 30
    mutating func calculatePower() {
        let coefficient = Double(intelligence + stamina + strength) / 30.0
        power = max(1, Int(Double(level) * Double(quality.rawValue) * coefficient))
    }
    
    /// 升级宠物
    mutating func levelUp() {
        if canLevelUp() {
            level += 1
            exp = 0
            calculatePower()
        }
    }
    
    /// 检查是否可以升级
    func canLevelUp() -> Bool {
        return exp >= expRequiredForNextLevel()
    }
    
    /// 下一级所需经验（根据品质调整）
    func expRequiredForNextLevel() -> Int {
        return Int(Double(level * 100) * quality.expMultiplier)
    }
    
    /// 是否可以参与排行榜战斗（快乐值需要>=30）
    func canBattle() -> Bool {
        return happiness >= 30
    }
    
    /// 减少快乐值
    mutating func decreaseHappiness(_ amount: Int) {
        happiness = max(0, happiness - amount)
    }
    
    /// 增加快乐值
    mutating func increaseHappiness(_ amount: Int) {
        happiness = min(100, happiness + amount)
    }
    
    // MARK: - 战斗属性计算
    // 根据三围计算战斗属性
    
    /// 攻击力 = 力量 × 2
    var attack: Int {
        return strength * 2
    }
    
    /// HP = 体力 × 15
    var hp: Int {
        return stamina * 15
    }
    
    /// 防御力 = 体力 × 0.5
    var defense: Double {
        return Double(stamina) * 0.5
    }
    
    /// 暴击率 = min(30, 智力 × 0.5)，上限30%
    var critRate: Double {
        return min(30.0, Double(intelligence) * 0.5)
    }
    
    /// 速度 = 智力 × 0.2
    var speed: Double {
        return Double(intelligence) * 0.2
    }
    
    /// 计算伤害值
    /// 公式：伤害值 = max(1, (攻击力 - 防御力)) × (1.5 if 暴击 else 1)
    func calculateDamage(targetDefense: Double, isCritical: Bool) -> Int {
        let baseDamage = max(1.0, Double(attack) - targetDefense)
        let critMultiplier = isCritical ? 1.5 : 1.0
        return Int(baseDamage * critMultiplier)
    }
    
    /// 判断是否暴击（基于暴击率）
    func rollCritical() -> Bool {
        return Double.random(in: 0...100) < critRate
    }
}

// MARK: - Preview Data
extension Pet {
    static let preview = Pet(
        name: "[A] 花花",
        emoji: "🐼",
        level: 99,
        exp: 153,
        power: 44,
        quality: .rare,
        intelligence: 11,
        stamina: 11,
        strength: 11,
        happiness: 98,
        intimacy: 0,
        sleepBonus: 0,
        expPerMinute: 11
    )
}
