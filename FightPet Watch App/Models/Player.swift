import Foundation

/// 玩家数据模型
struct Player: Codable {
    var diamonds: Int           // 钻石数量
    var currentPet: Pet         // 当前宠物
    var rank: Int              // 排名
    var wins: Int              // 胜场数
    var dailyChallenges: Int   // 今日剩余挑战次数
    
    init(diamonds: Int = 1971,
         currentPet: Pet = Pet(),
         rank: Int = 999,
         wins: Int = 0,
         dailyChallenges: Int = 3) {
        self.diamonds = diamonds
        self.currentPet = currentPet
        self.rank = rank
        self.wins = wins
        self.dailyChallenges = dailyChallenges
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
        diamonds: 1971,
        currentPet: .preview,
        rank: 1,
        wins: 0,
        dailyChallenges: 3
    )
}
