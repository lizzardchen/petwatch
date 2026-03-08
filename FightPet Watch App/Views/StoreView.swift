import SwiftUI

/// 商店界面
struct StoreView: View {
    @ObservedObject var gameState: GameStateManager
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showPurchaseAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private let packages: [StorePackage] = [
        .init(
            title: "小包",
            amount: 500,
            price: 6,
            colors: [
                Color(red: 0.17, green: 0.39, blue: 1.0),
                Color(red: 0.11, green: 0.30, blue: 0.88)
            ]
        ),
        .init(
            title: "中包",
            amount: 1200,
            price: 12,
            colors: [
                Color(red: 0.79, green: 0.26, blue: 1.0),
                Color(red: 0.64, green: 0.18, blue: 0.93)
            ]
        ),
        .init(
            title: "大包",
            amount: 3000,
            price: 25,
            colors: [
                Color(red: 1.0, green: 0.70, blue: 0.0),
                Color(red: 1.0, green: 0.55, blue: 0.0)
            ],
            badgeText: "最划算"
        ),
        .init(
            title: "超级包",
            amount: 6000,
            price: 45,
            colors: [
                Color(red: 1.0, green: 0.19, blue: 0.54),
                Color(red: 1.0, green: 0.17, blue: 0.28)
            ]
        )
    ]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom

            let horizontalInset = max(6, width * 0.03)
            let topInset = max(2, safeTop * 0.12) + 4
            let bottomInset = max(2, safeBottom * 0.12) + 4
            let panelHeight = height - topInset - bottomInset
            let scale = min(1.0, max(0.88, panelHeight / 204))
            let panelRadius = 28 * scale
            let innerPadding = max(10, width * 0.055)
            let titleFontSize = 17 * scale
            let sectionFontSize = 10 * scale
            let closeButtonSize = 26 * scale
            let packageHeight = 31 * scale
            let packageSpacing = 5 * scale
            let closeButtonHeight = 27 * scale
            let closeButtonCorner = 15 * scale
            let dividerTopPadding = 4 * scale
            let cardHeight = 45 * scale
            let contentSpacing = 7 * scale

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.07, blue: 0.17),
                        Color(red: 0.03, green: 0.10, blue: 0.23)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Color.black.opacity(0.22)
                    .ignoresSafeArea()

                RoundedRectangle(cornerRadius: panelRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.19, blue: 0.28),
                                Color(red: 0.11, green: 0.15, blue: 0.23)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: panelRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .padding(.horizontal, horizontalInset)
                    .padding(.top, topInset)
                    .padding(.bottom, bottomInset)

                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 8 * scale) {
                        Text("商店")
                            .font(.system(size: titleFontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 0)

                        Button(action: closeView) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13 * scale, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: closeButtonSize, height: closeButtonSize)
                                .background(Color.white.opacity(0.14))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: contentSpacing) {
                            VStack(spacing: max(2, 2 * scale)) {
                                Text("💰")
                                    .font(.system(size: 30 * scale))

                                Text("选择套餐")
                                    .font(.system(size: 12 * scale, weight: .medium))
                                    .foregroundColor(.white.opacity(0.62))
                            }
                            .padding(.top, 6 * scale)

                            VIPExperienceCardView(
                                gameState: gameState,
                                height: cardHeight,
                                onTap: purchaseExperienceCard
                            )

                            HStack(spacing: 8 * scale) {
                                Capsule()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 1)

                                Text("钻石套餐")
                                    .font(.system(size: sectionFontSize, weight: .medium))
                                    .foregroundColor(.white.opacity(0.56))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Capsule()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 1)
                            }
                            .padding(.top, dividerTopPadding)

                            VStack(spacing: packageSpacing) {
                                ForEach(packages) { package in
                                    StorePackageRow(
                                        package: package,
                                        height: packageHeight,
                                        onTap: { purchase(package) }
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 8 * scale)
                    }
                    .padding(.top, 6 * scale)

                    Button(action: closeView) {
                        Text("关闭")
                            .font(.system(size: 15 * scale, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: closeButtonHeight)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.28, green: 0.33, blue: 0.42),
                                        Color(red: 0.24, green: 0.28, blue: 0.37)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: closeButtonCorner, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, innerPadding)
                .padding(.top, 8 * scale)
                .padding(.bottom, 8 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, horizontalInset)
                .padding(.top, topInset)
                .padding(.bottom, bottomInset)
            }
        }
        .ignoresSafeArea()
        .alert(alertTitle, isPresented: $showPurchaseAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func purchase(_ package: StorePackage) {
        gameState.addDiamonds(package.amount)
        alertTitle = "购买成功"
        alertMessage = "获得 \(package.amount) 钻石"
        showPurchaseAlert = true
    }

    private func purchaseExperienceCard() {
        let wasActive = gameState.player.isExpCardActive
        let durationSeconds = 30 * 24 * 60 * 60
        let cost = 18

        if gameState.purchaseExpCard(durationSeconds: durationSeconds, cost: cost) {
            alertTitle = wasActive ? "VIP 已续期" : "VIP 已激活"
            alertMessage = wasActive
                ? "双倍经验卡时长已增加 30 天"
                : "经验获取速度提升至 x2，持续 30 天"
        } else {
            alertTitle = "购买失败"
            alertMessage = "激活双倍经验卡需要 \(cost) 钻石"
        }

        showPurchaseAlert = true
    }

    private func closeView() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

private struct StorePackage: Identifiable {
    let id = UUID()
    let title: String
    let amount: Int
    let price: Int
    let colors: [Color]
    var badgeText: String? = nil
}

private struct StorePackageRow: View {
    let package: StorePackage
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: max(8, height * 0.24)) {
                VStack(alignment: .leading, spacing: max(0.5, height * 0.02)) {
                    Text(package.title)
                        .font(.system(size: height * 0.36, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("\(package.amount) 钻石")
                        .font(.system(size: height * 0.26, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                HStack(spacing: max(4, height * 0.14)) {
                    if let badgeText = package.badgeText {
                        Text(badgeText)
                            .font(.system(size: height * 0.24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, max(5, height * 0.16))
                            .padding(.vertical, max(2, height * 0.05))
                            .background(Color(red: 1.0, green: 0.33, blue: 0.18))
                            .clipShape(Capsule())
                    }

                    Text("$\(package.price)")
                        .font(.system(size: height * 0.55, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal, max(10, height * 0.32))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: package.colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: height * 0.5, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.6)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: height * 0.5, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct VIPExperienceCardView: View {
    @ObservedObject var gameState: GameStateManager
    let height: CGFloat
    let onTap: () -> Void

    private var subtitle: String {
        if gameState.player.isExpCardActive {
            return "已生效 · 剩余 \(formatRemaining(gameState.player.expCardRemainingSeconds))"
        }
        return "经验获取速度 ×2"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: max(8, height * 0.18)) {
                VStack(alignment: .leading, spacing: max(1, height * 0.05)) {
                    HStack(spacing: max(4, height * 0.08)) {
                        Text("✧")
                            .font(.system(size: height * 0.34, weight: .bold))
                            .foregroundColor(.white.opacity(0.95))

                        Text("双倍经验")
                            .font(.system(size: height * 0.30, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(subtitle)
                        .font(.system(size: height * 0.21, weight: .medium))
                        .foregroundColor(.white.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: max(2, height * 0.04)) {
                    Text("VIP")
                        .font(.system(size: height * 0.23, weight: .bold))
                        .foregroundColor(Color(red: 0.62, green: 0.34, blue: 0.0))
                        .padding(.horizontal, max(7, height * 0.18))
                        .padding(.vertical, max(3, height * 0.07))
                        .background(Color(red: 1.0, green: 0.80, blue: 0.08))
                        .clipShape(Capsule())

                    Text("$18/月")
                        .font(.system(size: height * 0.50, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .padding(.horizontal, max(10, height * 0.28))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.42, green: 0.16, blue: 0.96),
                        Color(red: 0.64, green: 0.19, blue: 0.98)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: height * 0.5, style: .continuous)
                    .stroke(
                        gameState.player.isExpCardActive ? Color.yellow.opacity(0.45) : Color.white.opacity(0.12),
                        lineWidth: gameState.player.isExpCardActive ? 1 : 0.6
                    )
            }
            .clipShape(
                RoundedRectangle(cornerRadius: height * 0.5, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatRemaining(_ seconds: Int) -> String {
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600

        if days > 0 {
            return "\(days)天\(hours)小时"
        }

        if hours > 0 {
            let minutes = (seconds % 3_600) / 60
            return "\(hours)小时\(minutes)分"
        }

        let minutes = max(1, seconds / 60)
        return "\(minutes)分钟"
    }
}

#Preview {
    StoreView(gameState: GameStateManager())
}
