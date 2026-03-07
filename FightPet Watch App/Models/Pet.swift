import Foundation
import SwiftUI

/// 宠物品质枚举
enum PetQuality: Int, Codable, CaseIterable {
    case rankA = 1       // A级
    case rankS = 2       // S级
    case rankSS = 3      // SS级
    
    var name: String {
        switch self {
        case .rankA: return "A级"
        case .rankS: return "S级"
        case .rankSS: return "SS级"
        }
    }
    
    var color: Color {
        switch self {
        case .rankA: return .gray
        case .rankS: return .blue
        case .rankSS: return .orange
        }
    }
    
    /// 初始属性总点数（智力+力量+体力）
    var totalStatsPoints: Int {
        switch self {
        case .rankA: return 8
        case .rankS: return 15
        case .rankSS: return 24
        }
    }
    
    /// 经验需求系数（品质越高，升级所需经验越多）
    var expMultiplier: Double {
        switch self {
        case .rankA: return 1.0
        case .rankS: return 1.3
        case .rankSS: return 1.6
        }
    }
    
    /// 重生后的下一品质
    var nextQuality: PetQuality? {
        switch self {
        case .rankA: return .rankS
        case .rankS: return .rankSS
        case .rankSS: return nil  // 已是最高品质
        }
    }

    /// 随机获取一个品质（重生时使用）
    static func randomQuality() -> PetQuality {
        return PetQuality.allCases.randomElement()!
    }
    
    /// 重生钻石奖励
    var rebirthDiamondReward: Int {
        switch self {
        case .rankA: return 100
        case .rankS: return 300
        case .rankSS: return 500
        }
    }
    
    /// 随机生成符合品质要求的属性点分配
    /// 规则：三个属性总和必须等于totalStatsPoints，且每个属性至少为1
    func randomStatsAllocation() -> (intelligence: Int, stamina: Int, strength: Int) {
        let total = totalStatsPoints
        var remaining = total - 3  // 先给每个属性分配1点
        
        var intelligence = 1
        var stamina = 1
        var strength = 1
        
        // 随机分配剩余点数
        while remaining > 0 {
            let roll = Int.random(in: 0...2)
            switch roll {
            case 0: intelligence += 1
            case 1: stamina += 1
            case 2: strength += 1
            default: break
            }
            remaining -= 1
        }
        
        return (intelligence, stamina, strength)
    }
}

/// 宠物数据模型
struct Pet: Identifiable, Codable {
    static let fixedLevel = Constants.Game.fixedPetLevel

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
    
    // 重生
    var rebirthCount: Int  // 重生次数
    
    // 升级相关
    var expPerMinute: Int  // 每分钟经验增长（基础值）
    
    // MARK: - 等级经验表（从Excel数值表导入）
    /// 宠物升级所需经验表
    /// Key: 当前等级, Value: 从当前等级升到下一级所需经验
    /// 例如：等级1(key=1)升到等级2需要15经验
    static let levelExperienceTable: [Int: Int] = [
        1: 15,
        2: 30,
        3: 100,
        4: 200,
        5: 400,
        6: 800,
        7: 1200,
        8: 1500,
        9: 2000,
        10: 3000,
        11: 3600,
        12: 4320,
        13: 5184,
        14: 6220,
        15: 7464,
        16: 8957,
        17: 10749,
        18: 12899,
        19: 15479,
        20: 18575,
        21: 22290,
        22: 26748,
        23: 32097,
        24: 38517,
        25: 46221,
        26: 55465,
        27: 66558,
        28: 79869,
        29: 95843,
        30: 115012,
        31: 138015,
        32: 165618,
        33: 198742,
        34: 238490,
        35: 286188,
        36: 343426,
        37: 412111,
        38: 494533,
        39: 593440,
        40: 712128,
        41: 783341,
        42: 861676,
        43: 947843,
        44: 1042627,
        45: 1146890,
        46: 1261579,
        47: 1387737,
        48: 1526511,
        49: 1679162,
        50: 1847079,
        51: 1939433,
        52: 2036404,
        53: 2138224,
        54: 2245136,
        55: 2357392,
        56: 2475262,
        57: 2599025,
        58: 2728977,
        59: 2865425,
        60: 3008697,
        61: 3068871,
        62: 3130248,
        63: 3192853,
        64: 3256710,
        65: 3321844,
        66: 3388281,
        67: 3456047,
        68: 3525168,
        69: 3595671,
        70: 3667585,
        71: 3704260,
        72: 3741303,
        73: 3778716,
        74: 3816503,
        75: 3854668,
        76: 3893215,
        77: 3932147,
        78: 3971469,
        79: 4011183,
        80: 4051295,
        81: 4091808,
        82: 4132726,
        83: 4174053,
        84: 4215794,
        85: 4257952,
        86: 4300531,
        87: 4343537,
        88: 4386972,
        89: 4430842,
        90: 4475150,
        91: 4519902,
        92: 4565101,
        93: 4610752,
        94: 4656859,
        95: 4703428,
        96: 4750462,
        97: 4797967,
        98: 4845947,
        99: 4894406
    ]
    
    // 主初始化方法
    init(id: UUID = UUID(), 
         name: String = "花花",
         emoji: String = "🐼",
         level: Int = 1,
         exp: Int = 0,
         power: Int = 10,
         quality: PetQuality = .rankA,
         intelligence: Int,
         stamina: Int,
         strength: Int,
         happiness: Int = 60,  // 初始60
         intimacy: Int = 0,
         sleepBonus: Int = 0,
         rebirthCount: Int = 0,
         expPerMinute: Int = 1) {
        
        // 验证属性总和和最小值
        let totalStats = intelligence + stamina + strength
        assert(totalStats == quality.totalStatsPoints, 
               "属性总和(\(totalStats))必须等于品质要求(\(quality.totalStatsPoints))")
        assert(intelligence > 0 && stamina > 0 && strength > 0, 
               "所有属性必须大于0")
        
        self.id = id
        self.name = name
        self.emoji = emoji
        self.level = Self.fixedLevel
        self.exp = 0
        self.quality = quality
        self.intelligence = intelligence
        self.stamina = stamina
        self.strength = strength
        self.happiness = happiness
        self.intimacy = intimacy
        self.sleepBonus = sleepBonus
        self.rebirthCount = rebirthCount
        self.expPerMinute = expPerMinute
        self.power = power
    }

    mutating func lockLevelToFixedValue(resetExp: Bool = true) {
        level = Self.fixedLevel
        if resetExp {
            exp = 0
        }
        calculatePower()
    }
    
    /// 便捷初始化方法：根据品质随机生成属性
    init(id: UUID = UUID(),
         name: String = "花花",
         emoji: String = "🐼",
         quality: PetQuality = .rankA,
         level: Int = 1,
         happiness: Int = 60,
         intimacy: Int = 0,
         sleepBonus: Int = 0,
         rebirthCount: Int = 0,
         expPerMinute: Int = 1) {
        
        // 随机分配属性
        let stats = quality.randomStatsAllocation()
        
        self.init(
            id: id,
            name: name,
            emoji: emoji,
            level: level,
            exp: 0,
            power: 0,
            quality: quality,
            intelligence: stats.intelligence,
            stamina: stats.stamina,
            strength: stats.strength,
            happiness: happiness,
            intimacy: intimacy,
            sleepBonus: sleepBonus,
            rebirthCount: rebirthCount,
            expPerMinute: expPerMinute
        )
        
        // 计算初始战力
        var mutableSelf = self
        mutableSelf.calculatePower()
        self = mutableSelf
    }
    
    /// 计算战力
    /// 公式：战斗力 = 等级 × 品质 × 系数
    /// 系数由三围计算：(智力 + 体力 + 力量) / 30
    mutating func calculatePower() {
        let coefficient = Double(intelligence + stamina + strength) / 30.0
        power = max(1, Int(Double(level) * Double(quality.rawValue) * coefficient))
    }
    
    /// 升级宠物（保留溢出经验）
    mutating func levelUp() {
        guard canLevelUp() else { return }
        let required = expRequiredForNextLevel()
        exp -= required  // 扣除升级所需经验，保留溢出部分
        level += 1
        calculatePower()
    }
    
    /// 检查是否可以升级
    func canLevelUp() -> Bool {
        guard level < Self.fixedLevel else { return false }
        return exp >= expRequiredForNextLevel()
    }
    
    /// 下一级所需经验（从经验表查询当前等级）
    /// 表格key是当前等级，value是升到下一级所需经验
    /// 例如：Lv.1(key=1)升到Lv.2需要15经验
    func expRequiredForNextLevel() -> Int {
        // 从经验表中查询当前等级对应的升级经验
        if let requiredExp = Pet.levelExperienceTable[level] {
            return requiredExp
        }
        
        // 如果超出表格范围（等级99+），返回默认值
        return 100000
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
    
    // MARK: - 重生系统
    
    /// 是否可以重生（等级达到99）
    func canRebirth() -> Bool {
        return level >= Self.fixedLevel
    }
    
    /// 重生后的品质（随机）
    func rebirthQuality() -> PetQuality {
        return PetQuality.randomQuality()
    }
    
    /// 执行重生，返回新的Pet
    func rebirth() -> Pet {
        let newQuality = rebirthQuality()
        let newStats = newQuality.randomStatsAllocation()
        
        var newPet = Pet(
            id: self.id,
            name: self.name,
            emoji: self.emoji,
            level: Self.fixedLevel,
            exp: 0,
            power: 0,
            quality: newQuality,
            intelligence: newStats.intelligence,
            stamina: newStats.stamina,
            strength: newStats.strength,
            happiness: 60,
            intimacy: self.intimacy,
            sleepBonus: 0,
            rebirthCount: self.rebirthCount + 1,
            expPerMinute: 1
        )
        newPet.calculatePower()
        return newPet
    }
}

// MARK: - Preview Data
extension Pet {
    static let preview = Pet(
        name: "花花",
        emoji: "🐼",
        level: 5,
        exp: 153,
        power: 44,
        quality: .rankS,
        intelligence: 5,
        stamina: 5,
        strength: 5,
        happiness: 98,
        intimacy: 0,
        sleepBonus: 0,
        rebirthCount: 0,
        expPerMinute: 11
    )
    
    /// A级示例宠物（总属性8点）
    static let previewRankA = Pet(
        name: "小白",
        emoji: "🐱",
        quality: .rankA,
        intelligence: 3,
        stamina: 2,
        strength: 3
    )
    
    /// S级示例宠物（总属性15点）
    static let previewRankS = Pet(
        name: "小黑",
        emoji: "🐶",
        quality: .rankS,
        intelligence: 5,
        stamina: 5,
        strength: 5
    )
    
    /// SS级示例宠物（总属性24点）
    static let previewRankSS = Pet(
        name: "小金",
        emoji: "🦁",
        quality: .rankSS,
        intelligence: 8,
        stamina: 8,
        strength: 8
    )
}
