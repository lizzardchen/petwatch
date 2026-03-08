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
            let pad: CGFloat = max(8, w * 0.05)
            let topTrailingReservedWidth: CGFloat = max(42, w * 0.22)

            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Spacer(minLength: 0)
                    HStack(spacing: 6) {
                        Text(currentItem.type.icon)
                            .font(.system(size: 22))
                        Text(currentItem.type.rawValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, pad)
                .padding(.trailing, topTrailingReservedWidth)
                .padding(.top, 4)

                if !isUnlockedByOrder {
                    // 未解锁状态
                    Spacer()
                    Text("🔒")
                        .font(.system(size: 36))
                    Text(currentItem.unlockRequirement())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                    Spacer()
                } else if currentItem.isMaxLevel {
                    // 满级状态
                    Spacer()
                    VStack(spacing: 6) {
                        Text("Lv.\(currentItem.level)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("已满级 ✨")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(formatExpPerSec(currentItem.expBonusPerSecond()) + " EXP/秒")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                    Spacer()
                } else {
                    // 可升级状态
                    ScrollView {
                        VStack(spacing: 5) {
                            // 当前等级
                            infoRow(label: "当前等级", value: "Lv.\(currentItem.level)", valueColor: .white)

                            // 产出加成
                            infoRow(
                                label: "产出加成",
                                value: "+ " + formatExpPerSec(currentItem.expBonusPerSecond()) + " EXP/秒",
                                valueColor: .green
                            )

                            // 分割线
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                                .padding(.horizontal, pad)
                                .padding(.vertical, 2)

                            // 升级至
                            infoRow(
                                label: "升级至",
                                value: "Lv.\(currentItem.level + 1)",
                                valueColor: Constants.Colors.purpleLight
                            )

                            // 升级后产出（当前 → 下一级 + 增量）
                            let curExp = currentItem.expBonusPerSecond()
                            let nextExp = currentItem.nextExpBonusPerSecond()
                            let diff = nextExp - curExp
                            HStack(spacing: 0) {
                                Text("产出加成")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer(minLength: 4)
                                Text("+ ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                                Text("→ ")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("+" + formatExpPerSec(diff))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, pad)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(7)
                            .padding(.horizontal, pad)

                        }
                        .padding(.top, 5)
                    }
                }

                // 底部按钮
                VStack(spacing: 5) {
                    if isUnlockedByOrder && currentItem.canUpgrade() {
                        Button(action: { _ = gameState.upgradeItem(currentItem) }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 13))
                                Text("升级")
                                    .font(.system(size: 12, weight: .bold))
                                Text("·")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.65))
                                HStack(spacing: 2) {
                                    Text("💎")
                                        .font(.system(size: 11))
                                    Text("\(currentItem.upgradeCost())")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 30)
                            .background(canUpgradeNow ? Constants.Colors.purple : Color.gray.opacity(0.5))
                            .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canUpgradeNow)

                        if !canAffordUpgrade {
                            Text("钻石不足")
                                .font(.system(size: 9))
                                .foregroundColor(.red)
                        }
                    }

                    Button(action: closeView) {
                        Text("关闭")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 30)
                            .background(Constants.Colors.darkGray)
                            .cornerRadius(9)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, pad)
                .padding(.bottom, max(safeBot, 4) + 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, max(safeTop, 4))
        }
        .background(Constants.Colors.darkBackground.ignoresSafeArea())
        .ignoresSafeArea()
    }

    private func infoRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, max(8, 12))
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.04))
        .cornerRadius(7)
        .padding(.horizontal, max(8, 12))
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
