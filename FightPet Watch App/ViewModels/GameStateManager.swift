import SwiftUI
import Combine

/// 游戏状态管理器
class GameStateManager: ObservableObject {
    @Published var player: Player
    
    init() {
        // 尝试从UserDefaults加载数据
        if let savedPlayer = UserDefaults.standard.data(forKey: "player"),
           let decodedPlayer = try? JSONDecoder().decode(Player.self, from: savedPlayer) {
            self.player = decodedPlayer
            // 确保升级物品列表存在
            if self.player.upgradeItems.isEmpty {
                self.player.upgradeItems = Player.defaultUpgradeItems()
            }
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
        if spendDiamonds(cost) {
            if let index = player.upgradeItems.firstIndex(where: { $0.id == item.id }) {
                if item.isUnlocked {
                    player.upgradeItems[index].level += 1
                } else {
                    player.upgradeItems[index].level = 1
                }
                savePlayer()
                return true
            }
        }
        return false
    }
    
    /// 获取升级物品
    func getUpgradeItem(type: UpgradeItemType) -> UpgradeItem? {
        return player.upgradeItems.first { $0.type == type }
    }
}
