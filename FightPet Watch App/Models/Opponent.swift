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
