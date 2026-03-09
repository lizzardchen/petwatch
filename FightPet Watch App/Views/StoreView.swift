import SwiftUI

/// 商店界面
struct StoreView: View {
    @ObservedObject var gameState: GameStateManager
    @StateObject private var storeManager = StoreKitManager.shared
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showPurchaseAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isPurchasing = false

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
            let topInset = max(2, safeTop * 0.05) + 2  // 大幅减小 topInset，让标题靠近顶部
            let bottomInset = max(2, safeBottom * 0.12) + 4
            let panelHeight = height - topInset - bottomInset
            let scale = min(1.0, max(0.88, panelHeight / 204))
            let panelRadius = 28 * scale
            let innerPadding = max(10, width * 0.055)
            let titleFontSize = 15 * scale  // 稍微减小标题字体
            let sectionFontSize = 10 * scale
            let packageHeight = 31 * scale
            let packageSpacing = 3 * scale  // 从 5 改为 3，更紧凑
            let closeButtonHeight = 27 * scale
            let closeButtonCorner = 15 * scale
            let dividerTopPadding = 2 * scale  // 从 4 改为 2，减少分隔线上方间距
            let cardHeight = 45 * scale
            let contentSpacing = 4 * scale  // 从 7 改为 4，减少内容区域间距

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
                    }
                    .padding(.bottom, 2 * scale)

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: contentSpacing) {
                            VStack(spacing: max(2, 2 * scale)) {
                                Text("💰")
                                    .font(.system(size: 30 * scale))

                                Text("选择套餐")
                                    .font(.system(size: 12 * scale, weight: .medium))
                                    .foregroundColor(.white.opacity(0.62))
                            }
                            .padding(.top, 3 * scale)  // 从 6 改为 3，减少顶部间距

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
                        .padding(.bottom, 6 * scale)  // 从 8 改为 6，减少底部间距
                    }
                    .padding(.top, 4 * scale)  // 从 6 改为 4，减少顶部间距

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
                .padding(.top, 4 * scale)  // 从 8 改为 4，减少顶部内边距
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
        .task {
            await storeManager.loadProducts()
            await storeManager.checkPendingTransactions()
        }
        .onAppear {
            setupPurchaseNotifications()
        }
        .onDisappear {
            removePurchaseNotifications()
        }
        .overlay {
            if isPurchasing {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
    }

    private func purchase(_ package: StorePackage) {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            
            // 根据套餐金额匹配产品 ID
            let productID: StoreKitManager.ProductID
            switch package.amount {
            case 500:
                productID = .smallPack
            case 1200:
                productID = .mediumPack
            case 3000:
                productID = .largePack
            case 6000:
                productID = .superPack
            default:
                alertTitle = "错误"
                alertMessage = "未找到对应的产品"
                showPurchaseAlert = true
                return
            }
            
            guard let product = storeManager.product(for: productID) else {
                alertTitle = "错误"
                alertMessage = "产品加载失败，请稍后重试"
                showPurchaseAlert = true
                return
            }
            
            let result = await storeManager.purchase(product)
            
            switch result {
            case .success:
                alertTitle = "购买成功"
                alertMessage = "获得 \(package.amount) 💎"
                showPurchaseAlert = true
                
            case .cancelled:
                // 用户取消，不显示提示
                break
                
            case .pending:
                alertTitle = "等待确认"
                alertMessage = "购买正在处理中，请稍后查看"
                showPurchaseAlert = true
                
            case .failed(let error):
                alertTitle = "购买失败"
                alertMessage = error.localizedDescription
                showPurchaseAlert = true
            }
        }
    }

    private func purchaseExperienceCard() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            
            guard let product = storeManager.product(for: .vipMonthly) else {
                alertTitle = "错误"
                alertMessage = "产品加载失败，请稍后重试"
                showPurchaseAlert = true
                return
            }
            
            let result = await storeManager.purchase(product)
            
            switch result {
            case .success:
                let wasActive = gameState.player.isExpCardActive
                alertTitle = wasActive ? "VIP 已续期" : "VIP 已激活"
                alertMessage = "经验获取速度提升至 ×2，持续 30 天"
                showPurchaseAlert = true
                
            case .cancelled:
                // 用户取消，不显示提示
                break
                
            case .pending:
                alertTitle = "等待确认"
                alertMessage = "订阅正在处理中，请稍后查看"
                showPurchaseAlert = true
                
            case .failed(let error):
                alertTitle = "购买失败"
                alertMessage = error.localizedDescription
                showPurchaseAlert = true
            }
        }
    }

    private func closeView() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
    
    // MARK: - 通知处理
    
    private func setupPurchaseNotifications() {
        NotificationCenter.default.addObserver(
            forName: .didPurchaseDiamonds,
            object: nil,
            queue: .main
        ) { notification in
            if let amount = notification.userInfo?["amount"] as? Int {
                gameState.addDiamonds(amount)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .didPurchaseVIP,
            object: nil,
            queue: .main
        ) { notification in
            if let duration = notification.userInfo?["duration"] as? Int {
                gameState.activateExpCard(durationSeconds: duration)
            }
        }
    }
    
    private func removePurchaseNotifications() {
        NotificationCenter.default.removeObserver(self, name: .didPurchaseDiamonds, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didPurchaseVIP, object: nil)
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
