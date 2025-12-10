import SwiftUI

/// 升级选项视图
struct UpgradeOptionsView: View {
    let items: [UpgradeItem]
    let hourlyIncome: Int
    @ObservedObject var gameState: GameStateManager
    let screenWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题和每小时收益
            HStack {
                Text("小窝升级")
                    .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("💎")
                    Text("+\(hourlyIncome)/时")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.cyan)
                }
            }
            
            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
            
            // 物品横向列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        UpgradeItemCard(item: item, gameState: gameState)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Constants.Colors.darkGray.opacity(0.3))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

/// 升级物品卡片
struct UpgradeItemCard: View {
    let item: UpgradeItem
    @ObservedObject var gameState: GameStateManager
    
    // 从 gameState 获取当前物品状态（因为 item 可能已过时）
    private var currentItem: UpgradeItem? {
        gameState.player.upgradeItems.first { $0.id == item.id }
    }
    
    private var displayItem: UpgradeItem {
        currentItem ?? item
    }
    
    var body: some View {
        Button(action: {
            // 处理物品点击
            let current = displayItem
            
            if !current.isUnlocked {
                // 检查解锁条件
                if canUnlock(current) {
                    unlockItem(current)
                }
            } else if current.canUpgrade() {
                upgradeItem(current)
            }
        }) {
            VStack(spacing: 6) {
                // 图标
                if displayItem.isUnlocked {
                    Text(displayItem.type.icon)
                        .font(.system(size: 40))
                } else {
                    ZStack {
                        Text(displayItem.type.icon)
                            .font(.system(size: 40))
                            .opacity(0.3)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                
                // 名称
                Text(displayItem.type.rawValue)
                    .font(.system(size: Constants.FontSize.small, weight: .semibold))
                    .foregroundColor(.white)
                
                // 等级或锁定提示
                if displayItem.isUnlocked {
                    Text("Lv.\(displayItem.level)")
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text(displayItem.unlockRequirement())
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(width: 90, height: 110)
            .padding(.vertical, 8)
            .background(Constants.Colors.darkGray.opacity(0.8))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(!canInteractWithItem(displayItem))
        .opacity(canInteractWithItem(displayItem) ? 1.0 : 0.6)
    }
    
    /// 检查是否可以解锁物品
    private func canUnlock(_ item: UpgradeItem) -> Bool {
        switch item.type {
        case .petBed:
            return true // 默认解锁
        case .foodBowl:
            // 需要宠物床满级
            if let petBed = gameState.player.upgradeItems.first(where: { $0.type == .petBed }) {
                return petBed.isMaxLevel
            }
            return false
        case .toy:
            // 需要食物碗满级
            if let foodBowl = gameState.player.upgradeItems.first(where: { $0.type == .foodBowl }) {
                return foodBowl.isMaxLevel
            }
            return false
        }
    }
    
    /// 检查是否可以与物品交互
    private func canInteractWithItem(_ item: UpgradeItem) -> Bool {
        if !item.isUnlocked {
            return canUnlock(item)
        }
        return item.canUpgrade() && gameState.player.diamonds >= item.upgradeCost()
    }
    
    /// 解锁物品
    private func unlockItem(_ item: UpgradeItem) {
        if gameState.spendDiamonds(item.upgradeCost()) {
            if let index = gameState.player.upgradeItems.firstIndex(where: { $0.id == item.id }) {
                gameState.player.upgradeItems[index].level = 1
                gameState.savePlayer()
            }
        }
    }
    
    /// 升级物品
    private func upgradeItem(_ item: UpgradeItem) {
        if gameState.spendDiamonds(item.upgradeCost()) {
            if let index = gameState.player.upgradeItems.firstIndex(where: { $0.id == item.id }) {
                gameState.player.upgradeItems[index].level += 1
                gameState.savePlayer()
            }
        }
    }
}

#Preview {
    UpgradeOptionsView(
        items: [
            UpgradeItem(type: .petBed, level: 1),
            UpgradeItem(type: .foodBowl, level: 0),
            UpgradeItem(type: .toy, level: 0)
        ],
        hourlyIncome: 100,
        gameState: GameStateManager(),
        screenWidth: 184
    )
    .padding()
    .background(
        LinearGradient(
            colors: [Constants.Colors.purple, Constants.Colors.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
