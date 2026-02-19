import Foundation

/// 对手数据模型
struct Opponent: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let level: Int
    let power: Int
    let wins: Int
    let winRate: Double
    let diamondReward: Int
    
    // 战斗属性（基于等级和战力派生）
    let intelligence: Int
    let stamina: Int
    let strength: Int
    
    init(id: UUID = UUID(),
         name: String,
         emoji: String,
         level: Int,
         power: Int,
         wins: Int,
         winRate: Double,
         diamondReward: Int) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.level = level
        self.power = power
        self.wins = wins
        self.winRate = winRate
        self.diamondReward = diamondReward
        
        // 根据战力和等级派生三围（模拟对手属性）
        let totalStats = max(3, power / max(1, level))
        let base = totalStats / 3
        let remainder = totalStats % 3
        self.intelligence = base + (remainder > 0 ? 1 : 0)
        self.stamina = base + (remainder > 1 ? 1 : 0)
        self.strength = base
    }
    
    // MARK: - 战斗属性计算（与 Pet 保持一致）
    
    /// 攻击力 = 力量 × 2
    var attack: Int { return strength * 2 }
    
    /// HP = 体力 × 15
    var hp: Int { return stamina * 15 }
    
    /// 防御力 = 体力 × 0.5
    var defense: Double { return Double(stamina) * 0.5 }
    
    /// 暴击率 = min(30, 智力 × 0.5)
    var critRate: Double { return min(30.0, Double(intelligence) * 0.5) }
    
    /// 速度 = 智力 × 0.2
    var speed: Double { return Double(intelligence) * 0.2 }
    
    /// 计算伤害值
    func calculateDamage(targetDefense: Double, isCritical: Bool) -> Int {
        let baseDamage = max(1.0, Double(attack) - targetDefense)
        let critMultiplier = isCritical ? 1.5 : 1.0
        return Int(baseDamage * critMultiplier)
    }
    
    /// 判断是否暴击
    func rollCritical() -> Bool {
        return Double.random(in: 0...100) < critRate
    }
}

// MARK: - Preview Data
extension Opponent {
    static let previewOpponents: [Opponent] = [
        Opponent(name: "小明", emoji: "🐱", level: 3, power: 95, wins: 12, winRate: 0.10, diamondReward: 97),
        Opponent(name: "小红", emoji: "🐱", level: 2, power: 88, wins: 10, winRate: 0.10, diamondReward: 94),
        Opponent(name: "小刚", emoji: "😺", level: 2, power: 82, wins: 8, winRate: 0.12, diamondReward: 91)
    ]
}
