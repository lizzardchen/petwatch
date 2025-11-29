import Foundation

/// 宠物数据模型
struct Pet: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var level: Int
    var exp: Int
    var power: Int
    
    // 三维属性
    var intelligence: Int  // 智慧
    var stamina: Int       // 体力
    var agility: Int       // 敏捷
    
    // 状态
    var happiness: Int     // 快乐值
    var intimacy: Int      // 亲密值
    var sleepBonus: Int    // 睡眠加成
    
    // 升级相关
    var expPerMinute: Int  // 每分钟经验增长
    
    init(id: UUID = UUID(), 
         name: String = "花花",
         emoji: String = "🐼",
         level: Int = 1,
         exp: Int = 0,
         power: Int = 10,
         intelligence: Int = 10,
         stamina: Int = 10,
         agility: Int = 10,
         happiness: Int = 50,
         intimacy: Int = 0,
         sleepBonus: Int = 0,
         expPerMinute: Int = 1) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.level = level
        self.exp = exp
        self.power = power
        self.intelligence = intelligence
        self.stamina = stamina
        self.agility = agility
        self.happiness = happiness
        self.intimacy = intimacy
        self.sleepBonus = sleepBonus
        self.expPerMinute = expPerMinute
    }
    
    /// 计算战力
    mutating func calculatePower() {
        power = (intelligence + stamina + agility) / 3 + level * 2
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
    
    /// 下一级所需经验
    func expRequiredForNextLevel() -> Int {
        return level * 100
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
        intelligence: 11,
        stamina: 11,
        agility: 11,
        happiness: 98,
        intimacy: 0,
        sleepBonus: 0,
        expPerMinute: 11
    )
}
