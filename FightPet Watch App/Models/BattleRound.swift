import Foundation

/// 战斗回合记录
struct BattleRound: Identifiable {
    let id = UUID()
    let roundNumber: Int
    let isPlayerAttack: Bool  // true=玩家攻击, false=对手攻击
    let damage: Int
    let isCritical: Bool
    let playerHPAfter: Int
    let opponentHPAfter: Int
}
