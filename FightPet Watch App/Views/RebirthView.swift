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
    @State private var showHatchAnimation = false
    @State private var hatchAnimPhase: Int = 0
    
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
            
            if showHatchAnimation {
                eggHatchAnimationView
            } else if showResult {
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
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBot = geo.safeAreaInsets.bottom
            let pad: CGFloat = max(6, w * 0.04)
            let scale = min(1.0, max(0.72, h / 210))
            let heroScale = min(1.18, scale * 1.14)
            let cardScale = max(0.7, scale * 0.82)
            let topPadding = max(safeTop, 4) + 2
            let bottomPadding = max(2, safeBot * 0.5) + 2
            let buttonHeight = max(28, 30 * scale)
            let buttonCorner = 10 * scale

            VStack(spacing: 0) {
                // 顶部标题
                ZStack {
                    HStack(spacing: 4 * scale) {
                        Text("🔄")
                            .font(.system(size: 13 * scale))
                        Text("宠物重生")
                            .font(.system(size: 13 * scale, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 22 * scale, alignment: .center)
                .padding(.horizontal, pad)
                .padding(.bottom, 4 * scale)

                // 宠物头像 + 名字 + 品质
                VStack(spacing: 2 * heroScale) {
                    Text(pet.emoji)
                        .font(.system(size: 28 * heroScale))
                    HStack(spacing: 4 * heroScale) {
                        Text(pet.name)
                            .font(.system(size: 12 * heroScale, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(pet.quality.name)
                            .font(.system(size: 9 * heroScale, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5 * heroScale)
                            .padding(.vertical, 1.5 * heroScale)
                            .background(pet.quality.color)
                            .cornerRadius(4 * heroScale)
                    }
                    Text("⚡ PWR: \(pet.power)")
                        .font(.system(size: 10 * heroScale, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 3 * scale)

                // 基础属性卡片
                VStack(spacing: 3 * cardScale) {
                    Text("基础属性")
                        .font(.system(size: 8 * cardScale, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 0) {
                        statBubble(icon: "🧠", value: "\(pet.intelligence)", label: "智力", scale: cardScale)
                        statBubble(icon: "💚", value: "\(pet.stamina)", label: "体力", scale: cardScale)
                        statBubble(icon: "💪", value: "\(pet.strength)", label: "力量", scale: cardScale)
                    }
                }
                .padding(.vertical, 4 * cardScale)
                .padding(.horizontal, pad * 0.85)
                .background(
                    RoundedRectangle(cornerRadius: 9 * cardScale, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .padding(.horizontal, pad)
                .padding(.bottom, 3 * scale)

                // 底部说明
                Text("确认后进入\(rebirthDurationText)孵化")
                    .font(.system(size: 8 * scale))
                    .foregroundColor(.orange.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if !pet.canRebirth() {
                    Text("需达到 Lv.99 才可重生")
                        .font(.system(size: 8 * scale))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.top, 1 * scale)
                }

                Spacer(minLength: 4 * scale)

                // 操作按钮
                HStack(spacing: 6 * scale) {
                    Button(action: closeView) {
                        Text("取消")
                            .font(.system(size: 11 * scale, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight)
                            .background(Constants.Colors.darkGray)
                            .cornerRadius(buttonCorner)
                    }
                    .buttonStyle(.plain)

                    Button(action: startRebirthHatching) {
                        HStack(spacing: 3 * scale) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10 * scale, weight: .bold))
                            Text("确认重生")
                                .font(.system(size: 11 * scale, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: buttonHeight)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(buttonCorner)
                    }
                    .buttonStyle(.plain)
                    .disabled(!pet.canRebirth())
                    .opacity(pet.canRebirth() ? 1 : 0.45)
                }
                .padding(.horizontal, pad)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
        }
        .ignoresSafeArea()
    }

    /// 属性气泡：emoji + 数值 + 标签（三个一排）
    private func statBubble(icon: String, value: String, label: String, scale: CGFloat) -> some View {
        VStack(spacing: 2 * scale) {
            Text(icon)
                .font(.system(size: 12 * scale))
            Text(value)
                .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 7 * scale))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
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
        GeometryReader { geo in
            let w = geo.size.width
            let safeTop = geo.safeAreaInsets.top
            let safeBot = geo.safeAreaInsets.bottom
            let pad: CGFloat = max(6, w * 0.04)

            VStack(spacing: 0) {
                // 标题
                Text("✨ 孵化完成！✨")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.yellow)

                Spacer(minLength: 2)

                // 宠物头像 + 名字 + 品质
                VStack(spacing: 2) {
                    Text(pet.emoji)
                        .font(.system(size: 28))
                    HStack(spacing: 4) {
                        Text(pet.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text(newQuality.name)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(newQuality.color)
                            .cornerRadius(4)
                    }

                    // 品质提升显示
                    if oldQuality != newQuality {
                        HStack(spacing: 4) {
                            Text(oldQuality.name)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(oldQuality.color)
                            Text("→")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                            Text(newQuality.name)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(newQuality.color)
                        }
                        .padding(.top, 1)
                    }

                    Text("⚡ PWR: \(pet.power)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.top, 1)
                }

                Spacer(minLength: 4)

                // 基础属性卡片
                VStack(spacing: 4) {
                    Text("基础属性")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 0) {
                        statBubble(icon: "🧠", value: "\(newIntelligence)", label: "智力", scale: 1)
                        statBubble(icon: "💚", value: "\(newStamina)", label: "体力", scale: 1)
                        statBubble(icon: "💪", value: "\(newStrength)", label: "力量", scale: 1)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, pad)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .padding(.horizontal, pad)

                Spacer(minLength: 4)

                // 钻石奖励
                HStack(spacing: 4) {
                    Text("💎")
                        .font(.system(size: 12))
                    Text("+\(rebirthReward) 钻石")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                }

                Spacer(minLength: 4)

                // 返回按钮
                Button(action: closeView) {
                    Text("返回")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            LinearGradient(
                                colors: [Constants.Colors.purple, Constants.Colors.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, pad)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, max(safeTop, 4))
            .padding(.bottom, max(safeBot, 4) + 4)
        }
        .ignoresSafeArea()
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
        startHatchAnimation()
    }

    private func startHatchAnimation() {
        hatchAnimPhase = 0
        withAnimation(.easeInOut(duration: 0.3)) {
            showHatchAnimation = true
        }
        // Phase 1: 蛋开始抖动 (0.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                hatchAnimPhase = 1
            }
        }
        // Phase 2: 蛋裂开 (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                hatchAnimPhase = 2
            }
        }
        // Phase 3: 光芒爆发 (1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                hatchAnimPhase = 3
            }
        }
        // Phase 4: 新宠物出现 → 跳转结果 (2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showHatchAnimation = false
                showResult = true
            }
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
    
    // MARK: - 蛋破壳动画
    private var eggHatchAnimationView: some View {
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
            let w = geo.size.width
            let eggSize = w * 0.35

            ZStack {
                surfaceGradient.ignoresSafeArea()

                // Phase 3: 光芒爆发
                if hatchAnimPhase >= 3 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.9), .yellow.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.5
                            )
                        )
                        .frame(width: w, height: w)
                        .scaleEffect(hatchAnimPhase >= 3 ? 1.5 : 0.1)
                        .opacity(hatchAnimPhase >= 3 ? 0 : 1)
                        .animation(.easeOut(duration: 0.8), value: hatchAnimPhase)

                    // 星星粒子
                    ForEach(0..<6, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor([Color.yellow, .orange, .white, .pink, .cyan, .yellow][i])
                            .offset(
                                x: cos(Double(i) * .pi / 3) * Double(eggSize * 0.8),
                                y: sin(Double(i) * .pi / 3) * Double(eggSize * 0.8)
                            )
                            .scaleEffect(hatchAnimPhase >= 3 ? 1.2 : 0)
                            .opacity(hatchAnimPhase >= 3 ? 0 : 1)
                            .animation(.easeOut(duration: 0.6).delay(Double(i) * 0.05), value: hatchAnimPhase)
                    }
                }

                VStack(spacing: 8) {
                    ZStack {
                        if hatchAnimPhase < 3 {
                            // 蛋：Phase 1 抖动，Phase 2 裂开
                            ZStack {
                                eggIllustration(size: eggSize * 1.8)
                                    .rotationEffect(.degrees(
                                        hatchAnimPhase == 1
                                        ? (Double.random(in: -5...5))
                                        : 0
                                    ))
                                    .animation(
                                        hatchAnimPhase == 1
                                        ? .easeInOut(duration: 0.08).repeatCount(8, autoreverses: true)
                                        : .default,
                                        value: hatchAnimPhase
                                    )

                                // 裂纹
                                if hatchAnimPhase >= 2 {
                                    crackOverlay(size: eggSize)
                                        .transition(.opacity)
                                }
                            }
                        } else {
                            // Phase 3+: 新宠物 emoji 出现
                            Text(pet.emoji)
                                .font(.system(size: eggSize * 0.7))
                                .scaleEffect(hatchAnimPhase >= 3 ? 1 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: hatchAnimPhase)
                        }
                    }
                    .frame(height: eggSize * 1.4)

                    // 文字
                    Text(hatchAnimPhase < 3 ? "破壳中..." : "🎉 新宠物诞生！")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(hatchAnimPhase < 3 ? .white : .yellow)
                        .animation(.easeInOut(duration: 0.3), value: hatchAnimPhase)
                }
            }
        }
        .ignoresSafeArea()
    }

    /// 裂纹覆盖层
    private func crackOverlay(size: CGFloat) -> some View {
        ZStack {
            // 主裂纹线条
            Path { path in
                path.move(to: CGPoint(x: size * 0.5, y: size * 0.15))
                path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.35))
                path.addLine(to: CGPoint(x: size * 0.55, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.45, y: size * 0.7))
            }
            .stroke(Color.white.opacity(0.9), lineWidth: 2)

            // 分支裂纹
            Path { path in
                path.move(to: CGPoint(x: size * 0.42, y: size * 0.35))
                path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.45))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)

            Path { path in
                path.move(to: CGPoint(x: size * 0.55, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.68, y: size * 0.55))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Helper Views

    private var rebirthDurationText: String {
        formatDuration(Constants.Game.rebirthHatchingDuration)
    }

    private var currentExpText: String {
        pet.level >= Pet.fixedLevel ? "MAX" : "\(pet.exp)/\(pet.expRequiredForNextLevel())"
    }

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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)小时\(minutes)分钟"
        }

        if hours > 0 {
            return "\(hours)小时"
        }

        return "\(max(minutes, 1))分钟"
    }
}

#Preview {
    RebirthView(gameState: GameStateManager())
}
