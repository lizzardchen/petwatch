import SwiftUI

/// 升级选项视图
struct UpgradeOptionsView: View {
    let items: [UpgradeItem]
    @ObservedObject var gameState: GameStateManager
    let screenWidth: CGFloat
    var onSelectItem: (UpgradeItem) -> Void = { _ in }
    
    var body: some View {
        VStack(spacing: 8) {
            // 标题
            HStack {
                Text("小窝升级")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
            
            // 物品横向列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        UpgradeItemCard(
                            item: item,
                            gameState: gameState,
                            onTap: onSelectItem
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Constants.Colors.darkGray.opacity(0.3))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

/// 升级物品卡片
struct UpgradeItemCard: View {
    let item: UpgradeItem
    @ObservedObject var gameState: GameStateManager
    var onTap: (UpgradeItem) -> Void = { _ in }
    
    // 从 gameState 获取当前物品状态（因为 item 可能已过时）
    private var currentItem: UpgradeItem? {
        gameState.player.upgradeItems.first { $0.id == item.id }
    }
    
    private var displayItem: UpgradeItem {
        currentItem ?? item
    }
    
    // 检查是否满足解锁条件（前置建筑等级要求）
    private var isUnlockedByOrder: Bool {
        gameState.isUpgradeItemUnlocked(displayItem.type)
    }
    
    var body: some View {
        Button(action: {
            onTap(displayItem)
        }) {
            VStack(spacing: 3) {
                // 图标
                if displayItem.isUnlocked {
                    Text(displayItem.type.icon)
                        .font(.system(size: 28))
                } else if isUnlockedByOrder {
                    // 满足前置条件但未购买：显示正常图标
                    Text(displayItem.type.icon)
                        .font(.system(size: 28))
                } else {
                    // 不满足前置条件：显示锁定图标
                    ZStack {
                        Text(displayItem.type.icon)
                            .font(.system(size: 28))
                            .opacity(0.15)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                // 名称
                Text(displayItem.type.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor((displayItem.isUnlocked || isUnlockedByOrder) ? .white : .white.opacity(0.4))
                
                // 等级或锁定提示
                if displayItem.isUnlocked {
                    Text("Lv.\(displayItem.level)")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.7))
                } else if isUnlockedByOrder {
                    // 满足前置条件但未购买：显示可解锁提示
                    Text("可解锁")
                        .font(.system(size: 7))
                        .foregroundColor(.green.opacity(0.9))
                } else {
                    // 不满足前置条件：显示解锁要求
                    Text(displayItem.unlockRequirement())
                        .font(.system(size: 7))
                        .foregroundColor(.orange.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(width: 65, height: 75)
            .padding(.vertical, 4)
            .background(
                (displayItem.isUnlocked || isUnlockedByOrder)
                    ? Constants.Colors.darkGray.opacity(0.8)
                    : Color.black.opacity(0.5)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        (displayItem.isUnlocked || isUnlockedByOrder)
                            ? Color.clear 
                            : Color.white.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UpgradeOptionsView(
        items: [
            UpgradeItem(type: .petBed, level: 1),
            UpgradeItem(type: .foodBowl, level: 0),
            UpgradeItem(type: .toy, level: 0)
        ],
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
