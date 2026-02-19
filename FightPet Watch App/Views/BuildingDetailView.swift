import SwiftUI

/// 建筑详情视图
struct BuildingDetailView: View {
    let item: UpgradeItem
    @ObservedObject var gameState: GameStateManager
    @Environment(\.dismiss) private var dismiss
    
    // 从 gameState 获取最新的物品状态
    private var currentItem: UpgradeItem {
        gameState.player.upgradeItems.first { $0.id == item.id } ?? item
    }
    
    var body: some View {
        ZStack {
            // 背景
            Constants.Colors.darkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text(currentItem.type.icon)
                        .font(.system(size: 30))
                    
                    Text(currentItem.type.rawValue)
                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 当前等级信息
                        InfoSection(title: "当前等级", value: "Lv.\(currentItem.level)")
                        
                        // 当前经验加成
                        InfoSection(
                            title: "产出加成",
                            value: String(format: "+%.2f EXP/分钟", currentItem.expBonusPerSecond() * 60),
                            valueColor: .green
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 8)
                        
                        // 升级后等级
                        if currentItem.canUpgrade() {
                            InfoSection(title: "升级至", value: "Lv.\(currentItem.level + 1)")
                            
                            // 升级后经验加成
                            let bonusIncrease = currentItem.nextExpBonusPerSecond() - currentItem.expBonusPerSecond()
                            InfoSection(
                                title: "产出加成",
                                value: String(format: "+ → +%.2f", bonusIncrease * 60),
                                valueColor: .green
                            )
                            
                            // 升级费用
                            InfoSection(
                                title: "升级费用",
                                value: "\(currentItem.upgradeCost())",
                                icon: "💎",
                                valueColor: .red
                            )
                        } else if currentItem.isMaxLevel {
                            Text("已满级")
                                .font(.system(size: Constants.FontSize.large, weight: .bold))
                                .foregroundColor(.yellow)
                                .padding()
                        }
                    }
                    .padding()
                }
                
                // 底部按钮
                VStack(spacing: 12) {
                    if currentItem.canUpgrade() {
                        // 升级按钮
                        Button(action: upgradeBuilding) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 20))
                                Text("升级")
                                    .font(.system(size: Constants.FontSize.large, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canAffordUpgrade ? Constants.Colors.purple : Color.gray)
                            .cornerRadius(Constants.CornerRadius.large)
                        }
                        .disabled(!canAffordUpgrade)
                        
                        // 钻石不足提示
                        if !canAffordUpgrade {
                            Text("钻石不足")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 关闭按钮
                    Button(action: { dismiss() }) {
                        Text("关闭")
                            .font(.system(size: Constants.FontSize.large, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Constants.Colors.darkGray)
                            .cornerRadius(Constants.CornerRadius.large)
                    }
                }
                .padding()
            }
        }
    }
    
    private var canAffordUpgrade: Bool {
        gameState.player.diamonds >= currentItem.upgradeCost()
    }
    
    private func upgradeBuilding() {
        if gameState.spendDiamonds(currentItem.upgradeCost()) {
            if let index = gameState.player.upgradeItems.firstIndex(where: { $0.id == currentItem.id }) {
                gameState.player.upgradeItems[index].level += 1
                gameState.savePlayer()
            }
        }
    }
}

/// 信息行组件
struct InfoSection: View {
    let title: String
    let value: String
    var icon: String? = nil
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: Constants.FontSize.medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon)
                }
                Text(value)
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(valueColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Constants.Colors.darkGray.opacity(0.3))
        .cornerRadius(Constants.CornerRadius.medium)
    }
}

#Preview {
    BuildingDetailView(
        item: UpgradeItem(type: .petBed, level: 3),
        gameState: GameStateManager()
    )
}
