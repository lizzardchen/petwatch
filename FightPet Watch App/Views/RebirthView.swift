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
        GeometryReader { geo in
            let pad: CGFloat = max(8, geo.size.width * 0.04)

            ScrollView {
                VStack(spacing: 0) {
                    // 顶部栏
                    HStack {
                        Text("🔄")
                            .font(.system(size: 18))
                        Text("宠物重生")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: closeView) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, pad)
                    .padding(.top, 2)
                    .padding(.bottom, 6)

                    // 宠物身份
                    VStack(spacing: 4) {
                        Text(pet.emoji)
                            .font(.system(size: 36))
                        Text(pet.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Text("Lv.\(pet.level)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.yellow)
                            Text(pet.quality.name)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(pet.quality.color)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.bottom, 8)

                    // 基础信息
                    compactSection(title: "基础信息", rows: [
                        ("⚔️", "战力", "\(pet.power)"),
                        ("✨", "经验", currentExpText),
                        ("⏱", "经验/分", "+\(pet.expPerMinute)"),
                        ("🔄", "重生次数", "\(pet.rebirthCount)")
                    ], pad: pad)

                    // 核心属性
                    compactSection(title: "核心属性", rows: [
                        ("🧠", "智慧", "\(pet.intelligence)"),
                        ("💚", "体力", "\(pet.stamina)"),
                        ("💪", "力量", "\(pet.strength)"),
                        ("😊", "快乐值", "\(pet.happiness)")
                    ], pad: pad)

                    // 状态信息
                    compactSection(title: "状态信息", rows: [
                        ("❤️", "亲密值", "\(pet.intimacy)"),
                        ("😴", "睡眠加成", "\(pet.sleepBonus)"),
                        ("🗡", "攻击", "\(pet.attack)"),
                        ("❤️‍🔥", "生命", "\(pet.hp)")
                    ], pad: pad)

                    // 战斗属性
                    compactSection(title: "战斗属性", rows: [
                        ("🛡", "防御", String(format: "%.1f", pet.defense)),
                        ("💥", "暴击率", String(format: "%.1f%%", pet.critRate)),
                        ("💨", "速度", String(format: "%.1f", pet.speed)),
                        ("🥚", "孵化时长", rebirthDurationText)
                    ], pad: pad)

                    // 底部说明
                    Text("确认后获得宠物蛋，进入\(rebirthDurationText)孵化流程")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, pad)
                        .padding(.top, 6)

                    // 条件提示
                    if !pet.canRebirth() {
                        Text("需达到 Lv.99 才可重生")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    // 底部操作按钮
                    HStack(spacing: 8) {
                        Button(action: closeView) {
                            Text("取消")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Constants.Colors.darkGray)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        Button(action: startRebirthHatching) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .bold))
                                Text("确认重生")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .disabled(!pet.canRebirth())
                        .opacity(pet.canRebirth() ? 1 : 0.45)
                    }
                    .padding(.horizontal, pad)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .ignoresSafeArea()
    }

    /// 紧凑属性行（两列网格）
    private func compactSection(title: String, rows: [(String, String, String)], pad: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, pad + 4)
                .padding(.bottom, 3)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ], spacing: 4) {
                ForEach(rows, id: \.1) { icon, label, value in
                    HStack(spacing: 4) {
                        Text(icon)
                            .font(.system(size: 10))
                        Text(label)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(value)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, pad)
            .padding(.bottom, 6)
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
