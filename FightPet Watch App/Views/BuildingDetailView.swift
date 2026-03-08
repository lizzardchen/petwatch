import SwiftUI

/// 建筑详情视图
struct BuildingDetailView: View {
    let item: UpgradeItem
    @ObservedObject var gameState: GameStateManager
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    private var currentItem: UpgradeItem {
        gameState.player.upgradeItems.first { $0.id == item.id } ?? item
    }

    private var isUnlockedByOrder: Bool {
        gameState.isUpgradeItemUnlocked(currentItem.type)
    }

    private var canAffordUpgrade: Bool {
        gameState.player.diamonds >= currentItem.upgradeCost()
    }

    private var canUpgradeNow: Bool {
        isUnlockedByOrder && currentItem.canUpgrade() && canAffordUpgrade
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let safeTop = geo.safeAreaInsets.top
            let safeBot = geo.safeAreaInsets.bottom
            let pad: CGFloat = max(6, w * 0.04)
            let topRowHeight: CGFloat = max(20, safeTop)
            let headerHeight: CGFloat = max(36, safeTop + 12)
            let headerHorizontalPadding: CGFloat = max(10, w * 0.06)
            let timeReserveWidth: CGFloat = min(max(44, w * 0.26), 54)

            VStack(spacing: 0) {
                // 顶部区域：标题垂直居中
                HStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Text(currentItem.type.icon)
                            .font(.system(size: 16))
                        Text(currentItem.type.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Color.clear
                        .frame(width: timeReserveWidth)
                }
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                .padding(.leading, headerHorizontalPadding)
                .padding(.trailing, max(4, w * 0.02))

                if !isUnlockedByOrder {
                    Spacer()
                    Text("🔒")
                        .font(.system(size: 32))
                    Text(currentItem.unlockRequirement())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 3)
                    Spacer()
                } else if currentItem.isMaxLevel {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Lv.\(currentItem.level)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("已满级 ✨")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(formatExpPerSec(currentItem.expBonusPerSecond()) + " EXP/秒")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    Spacer()
                } else {
                    // 可升级信息区
                    VStack(spacing: 3) {
                        compactRow(label: "当前等级", value: "Lv.\(currentItem.level)", valueColor: .white)
                        compactRow(
                            label: "产出加成",
                            value: "+ \(formatExpPerSec(currentItem.expBonusPerSecond())) EXP/秒",
                            valueColor: .green
                        )

                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 0.5)
                            .padding(.horizontal, pad)
                            .padding(.vertical, 1)

                        compactRow(
                            label: "升级至",
                            value: "Lv.\(currentItem.level + 1)",
                            valueColor: Constants.Colors.purpleLight
                        )

                        let curExp = currentItem.expBonusPerSecond()
                        let nextExp = currentItem.nextExpBonusPerSecond()
                        let diff = nextExp - curExp
                        HStack(spacing: 0) {
                            Text("产出加成")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.55))
                            Spacer(minLength: 2)
                            Text("\(formatExpPerSec(curExp))")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.green.opacity(0.7))
                            Text(" → ")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.35))
                            Text("\(formatExpPerSec(nextExp))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                            Text(" (+\(formatExpPerSec(diff)))")
                                .font(.system(size: 8))
                                .foregroundColor(.green.opacity(0.6))
                        }
                        .padding(.horizontal, pad + 2)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(5)
                        .padding(.horizontal, pad)
                    }
                    .padding(.top, 0)

                    Spacer(minLength: 2)
                }

                // 底部按钮
                VStack(spacing: 4) {
                    if isUnlockedByOrder && currentItem.canUpgrade() {
                        Button(action: { _ = gameState.upgradeItem(currentItem) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 11))
                                Text("升级")
                                    .font(.system(size: 11, weight: .bold))
                                Text("·")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.65))
                                HStack(spacing: 1) {
                                    Text("💎")
                                        .font(.system(size: 10))
                                    Text("\(currentItem.upgradeCost())")
                                        .font(.system(size: 11, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(canUpgradeNow ? Constants.Colors.purple : Color.gray.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canUpgradeNow)

                        if !canAffordUpgrade {
                            Text("钻石不足")
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        }
                    }

                    Button(action: closeView) {
                        Text("关闭")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(Constants.Colors.darkGray)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, pad)
                .padding(.bottom, max(safeBot, 2) + 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Constants.Colors.darkBackground.ignoresSafeArea())
        .ignoresSafeArea()
    }

    private func compactRow(label: String, value: String, valueColor: Color) -> some View {
        let pad: CGFloat = 6
        return HStack {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, pad + 2)
        .padding(.vertical, 2)
        .background(Color.white.opacity(0.04))
        .cornerRadius(5)
        .padding(.horizontal, pad)
    }

    private func formatExpPerSec(_ val: Double) -> String {
        if val == Double(Int(val)) {
            return String(format: "%.1f", val)
        }
        return String(format: "%.2f", val)
    }

    private func closeView() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview {
    BuildingDetailView(
        item: UpgradeItem(type: .petBed, level: 3),
        gameState: GameStateManager()
    )
}
