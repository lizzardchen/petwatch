import SwiftUI
import Combine

/// 重生与孵化界面
struct RebirthView: View {
    @ObservedObject var gameState: GameStateManager
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var showResult = false
    @State private var rebirthReward: Int = 0
    @State private var oldQuality: PetQuality = .rankA
    @State private var newQuality: PetQuality = .rankA
    @State private var newIntelligence: Int = 0
    @State private var newStamina: Int = 0
    @State private var newStrength: Int = 0
    @State private var currentTime = Date()
    @State private var eggOffset: CGFloat = 0
    
    private var pet: Pet {
        gameState.player.currentPet
    }
    
    private var isHatching: Bool {
        gameState.player.rebirthSourcePet != nil
    }
    
    var body: some View {
        ZStack {
            Constants.Colors.darkBackground
                .ignoresSafeArea()
            
            if showResult {
                rebirthResultView
            } else if isHatching {
                hatchingView
            } else {
                rebirthConfirmView
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            currentTime = date
        }
    }
    
    // MARK: - 蛋的浮动动画
    private func startEggAnimation() {
        eggOffset = 10
        withAnimation(
            Animation.easeInOut(duration: 1.6)
                .repeatForever(autoreverses: true)
        ) {
            eggOffset = -10
        }
    }
    
    // MARK: - 重生确认界面
    private var rebirthConfirmView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("🔄")
                    .font(.system(size: 24))
                Text("宠物重生")
                    .font(.system(size: Constants.FontSize.title, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: closeView) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(pet.emoji)
                            .font(.system(size: 50))
                        
                        Text(pet.name)
                            .font(.system(size: Constants.FontSize.large, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text("Lv.\(pet.level)")
                                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            Text(pet.quality.name)
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(pet.quality.color)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Text("重生效果")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let nextQ = pet.quality.nextQuality {
                            rebirthInfoRow(
                                title: "品质提升",
                                oldValue: pet.quality.name,
                                newValue: nextQ.name,
                                oldColor: pet.quality.color,
                                newColor: nextQ.color
                            )
                        } else {
                            rebirthInfoRow(
                                title: "品质",
                                oldValue: pet.quality.name,
                                newValue: pet.quality.name + "(保持)",
                                oldColor: pet.quality.color,
                                newColor: pet.quality.color
                            )
                        }
                        
                        HStack {
                            Text("等级")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("Lv.\(pet.level)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.red)
                                .strikethrough()
                            Text("→")
                                .foregroundColor(.white.opacity(0.5))
                            Text("Lv.1")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("属性分配")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("按新品质总点数随机分配")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("钻石奖励")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("💎 +\(pet.quality.rebirthDiamondReward)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    .padding(.horizontal)
                    
                    HStack(spacing: 6) {
                        Text("⚠️")
                        Text("重生后会进入孵化，孵化完成才生成新宠")
                            .font(.system(size: Constants.FontSize.small))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal)
                }
            }
            
            VStack(spacing: 10) {
                Button(action: startRebirthHatching) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                        Text("确认重生")
                            .font(.system(size: Constants.FontSize.large, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Constants.CornerRadius.large)
                }
                // .disabled(!pet.canRebirth())  // 测试：始终允许重生
                
                // if !pet.canRebirth() {
                //     Text("需达到 Lv.99 才可重生")
                //         .font(.system(size: Constants.FontSize.small))
                //         .foregroundColor(.orange)
                // }
                
                Button(action: closeView) {
                    Text("取消")
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
    
    // MARK: - 孵化界面
    private var hatchingView: some View {
        let remaining = hatchingRemainingSeconds(at: currentTime)
        let progress = hatchingProgress(remainingSeconds: remaining)
        let isReady = remaining == 0
        let directHatchCost = Constants.Game.rebirthDirectHatchCost
        let surfaceGradient = LinearGradient(
            colors: [
                Color(red: 0.43, green: 0.12, blue: 0.66),
                Color(red: 0.68, green: 0.05, blue: 0.34),
                Color(red: 0.72, green: 0.22, blue: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        return GeometryReader { geo in
            let screenWidth = geo.size.width
            let screenHeight = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let surfaceInset = max(6, screenWidth * 0.035)
            let contentInset = max(8, screenWidth * 0.045)
            let cardCornerRadius: CGFloat = min(40, screenWidth * 0.18)
            let topInset = max(safeTop, 8) + 6
            let bottomInset = max(safeBottom, 8) + 12
            let availableHeight = max(screenHeight - topInset - bottomInset, 200)
            let progressSize = min(screenWidth * 0.47, availableHeight * 0.34)
            let ringLineWidth = max(4, progressSize * 0.048)
            let buttonHeight: CGFloat = 28
            let timeCardMinWidth = min(screenWidth * 0.62, 132)
            let contentScale = min(1, max(0.84, availableHeight / 250))

            ZStack {
                surfaceGradient
                    .ignoresSafeArea()

                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(surfaceGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.03), lineWidth: 1)
                    }
                    .padding(.horizontal, surfaceInset)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 进度环和蛋
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: ringLineWidth)
                            .frame(width: progressSize, height: progressSize)

                        Circle()
                            .trim(from: 0, to: max(progress, isReady ? 1 : 0.02))
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.95), Color.orange.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: progressSize, height: progressSize)

                        eggIllustration(size: progressSize)
                            .offset(y: eggOffset)

                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.orange)
                            .offset(x: progressSize * 0.22, y: -progressSize * 0.32)

                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.pink.opacity(0.9))
                            .offset(x: -progressSize * 0.32, y: -progressSize * 0.05)
                    }

                    // 状态文字
                    Text(isReady ? "✨ 孵化完成！✨" : "正在孵化...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isReady ? .yellow : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.top, 2)

                    if isReady {
                        // 孵化完成状态
                        Text("点击下方按钮领取新宠物")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.76))
                            .padding(.top, 2)

                        Button(action: {
                            finishHatchingIfReady()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 15, weight: .bold))
                                Text("领取宠物！")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "sparkles")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.18, green: 0.80, blue: 0.34),
                                        Color(red: 0.10, green: 0.65, blue: 0.28)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, contentInset)
                        .padding(.top, 10)
                    } else {
                        // 孵化中状态
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.top, 1)

                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Constants.Colors.blue)
                                .frame(width: 26, height: 26)
                                .background(Color(red: 0.21, green: 0.07, blue: 0.30))
                                .clipShape(Circle())
                            
                            VStack(spacing: 0) {
                                Text("剩余时间")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.76))
                                Text(formatCountdown(remaining))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .frame(minWidth: timeCardMinWidth)
                        .background(Color.black.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.top, 6)

                        Button(action: {
                            directFinishHatching()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text("直接孵化 (\(directHatchCost)💎)")
                                    .font(.system(size: 14, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.96, green: 0.67, blue: 0.11),
                                        Color(red: 0.99, green: 0.45, blue: 0.02)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(gameState.player.diamonds < directHatchCost)
                        .opacity(gameState.player.diamonds < directHatchCost ? 0.55 : 1)
                        .padding(.horizontal, contentInset)
                        .padding(.top, 8)

                        Text("新的旅程即将开始...")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.74))
                            .padding(.top, 6)
                            .padding(.bottom, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .padding(.top, topInset)
                .padding(.bottom, bottomInset)
                .scaleEffect(contentScale, anchor: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear(perform: startEggAnimation)
    }
    
    // MARK: - 重生结果界面
    private var rebirthResultView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 20)
                    
                    Text("✨ 孵化完成！✨")
                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text(pet.emoji)
                        .font(.system(size: 60))
                    
                    Text(pet.name)
                        .font(.system(size: Constants.FontSize.large, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if oldQuality != newQuality {
                        HStack(spacing: 8) {
                            Text(oldQuality.name)
                                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(oldQuality.color)
                                .cornerRadius(8)
                            
                            Text("→")
                                .font(.system(size: Constants.FontSize.large))
                                .foregroundColor(.yellow)
                            
                            Text(newQuality.name)
                                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(newQuality.color)
                                .cornerRadius(8)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("新属性")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("🧠")
                                Text("\(newIntelligence)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            VStack(spacing: 4) {
                                Text("💚")
                                Text("\(newStamina)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            VStack(spacing: 4) {
                                Text("💪")
                                Text("\(newStrength)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    .padding(.horizontal)
                    
                    HStack(spacing: 8) {
                        Text("💎")
                        Text("+\(rebirthReward) 钻石")
                            .font(.system(size: Constants.FontSize.large, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                }
            }
            
            Button(action: closeView) {
                Text("返回")
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Constants.Colors.purple, Constants.Colors.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Constants.CornerRadius.large)
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func closeView() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
    
    private func startRebirthHatching() {
        oldQuality = pet.quality
        if let reward = gameState.startRebirthHatching() {
            rebirthReward = reward
        }
    }
    
    private func directFinishHatching() {
        gameState.directCompleteHatching()
    }
    
    private func finishHatchingIfReady() {
        guard gameState.completeHatchingIfReady() else { return }
        newQuality = pet.quality
        newIntelligence = pet.intelligence
        newStamina = pet.stamina
        newStrength = pet.strength
        withAnimation(.easeInOut(duration: 0.4)) {
            showResult = true
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    private func formatCountdown(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        
        return String(format: "%02d:%02d", m, s)
    }
    
    private func hatchingRemainingSeconds(at date: Date) -> Int {
        guard let hatchEndDate = gameState.player.hatchEndDate else { return 0 }
        return max(0, Int(hatchEndDate.timeIntervalSince(date)))
    }
    
    private func hatchingProgress(remainingSeconds: Int) -> CGFloat {
        let total = max(Constants.Game.rebirthHatchingDuration, 1)
        let clampedRemaining = min(TimeInterval(remainingSeconds), total)
        return CGFloat((total - clampedRemaining) / total)
    }
    
    // MARK: - Helper Views
    
    private func eggIllustration(size: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            Color(red: 0.92, green: 0.90, blue: 0.86),
                            Color(red: 0.82, green: 0.80, blue: 0.76)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.46, height: size * 0.64)
                .rotationEffect(.degrees(-8))
                .shadow(color: Color.black.opacity(0.16), radius: 8, x: 5, y: 8)
            
            Circle()
                .fill(Color(red: 0.98, green: 0.37, blue: 0.53))
                .frame(width: size * 0.045, height: size * 0.045)
                .offset(x: size * 0.14, y: -size * 0.16)
        }
    }

    private func rebirthInfoRow(title: String, oldValue: String, newValue: String, oldColor: Color, newColor: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: Constants.FontSize.small))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(oldValue)
                .font(.system(size: Constants.FontSize.small, weight: .bold))
                .foregroundColor(oldColor)
            Text("→")
                .foregroundColor(.white.opacity(0.5))
            Text(newValue)
                .font(.system(size: Constants.FontSize.small, weight: .bold))
                .foregroundColor(newColor)
        }
        .padding(.horizontal)
    }
}

#Preview {
    RebirthView(gameState: GameStateManager())
}
