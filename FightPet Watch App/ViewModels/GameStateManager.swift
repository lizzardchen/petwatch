import SwiftUI

/// 游戏状态管理器
class GameStateManager: ObservableObject {
    @Published var player: Player
    
    init() {
        // 尝试从UserDefaults加载数据
        if let savedPlayer = UserDefaults.standard.data(forKey: "player"),
           let decodedPlayer = try? JSONDecoder().decode(Player.self, from: savedPlayer) {
            self.player = decodedPlayer
        } else {
            // 创建新玩家
            self.player = Player(
                diamonds: Constants.Game.initialDiamonds,
                currentPet: Pet.preview
            )
        }
    }
    
    /// 保存玩家数据
    func savePlayer() {
        if let encoded = try? JSONEncoder().encode(player) {
            UserDefaults.standard.set(encoded, forKey: "player")
        }
    }
    
    /// 添加钻石
    func addDiamonds(_ amount: Int) {
        player.addDiamonds(amount)
        savePlayer()
    }
    
    /// 消费钻石
    func spendDiamonds(_ amount: Int) -> Bool {
        if player.spendDiamonds(amount) {
            savePlayer()
            return true
        }
        return false
    }
    
    /// 升级宠物
    func upgradePet() {
        player.currentPet.levelUp()
        savePlayer()
    }
    
    /// 升级物品
    func upgradeItem(_ item: UpgradeItem) -> Bool {
        let cost = item.upgradeCost()
        return spendDiamonds(cost)
    }
}
