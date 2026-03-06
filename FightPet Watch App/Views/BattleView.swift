import SwiftUI

/// 战斗界面
struct BattleView: View {
    let opponent: Opponent
    @ObservedObject var gameState: GameStateManager
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    private let preparingHeaderMinHeight: CGFloat = 34
    
    // 战斗状态
    @State private var battlePhase: BattlePhase = .preparing
    @State private var rounds: [BattleRound] = []
    @State private var currentRoundIndex: Int = 0
    @State private var playerWon: Bool = false
    @State private var diamondReward: Int = 0
    
    // 动画状态
    @State private var playerHP: Int = 0
    @State private var opponentHP: Int = 0
    @State private var playerMaxHP: Int = 0
    @State private var opponentMaxHP: Int = 0
    @State private var showDamageText: Bool = false
    @State private var damageText: String = ""
    @State private var damageIsPlayer: Bool = false
    @State private var roundTimer: Timer? = nil
    
    // 新增动画偏移
    @State private var playerOffset: CGFloat = 0
    @State private var opponentOffset: CGFloat = 0
    @State private var playerFlash: Bool = false
    @State private var opponentFlash: Bool = false
    @State private var shakeOffset: CGFloat = 0
    
    enum BattlePhase {
        case preparing
        case fighting
        case result
    }
    
    var body: some View {
        GeometryReader { rootGeo in
            let headerHeight = max(rootGeo.safeAreaInsets.top, preparingHeaderMinHeight)

            ZStack {
                Constants.Colors.darkBackground
                    .ignoresSafeArea()
                
                switch battlePhase {
                case .preparing:
                    preparingView(headerHeight: headerHeight)
                case .fighting:
                    fightingView
                case .result:
                    resultView
                }
                
                // 全局震动效果
                Color.clear
                    .offset(x: shakeOffset)
            }
            .overlay(alignment: .top) {
                if battlePhase == .preparing {
                    preparingHeader(headerHeight: headerHeight)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if battlePhase == .preparing {
                    preparingBottomBar
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                playerMaxHP = gameState.player.currentPet.hp
                opponentMaxHP = opponent.hp
                playerHP = playerMaxHP
                opponentHP = opponentMaxHP
            }
            .onDisappear {
                roundTimer?.invalidate()
            }
        }
    }
    
    // MARK: - 准备阶段
    private func preparingView(headerHeight: CGFloat) -> some View {
        GeometryReader { geo in
            let availableHeight = max(1, geo.size.height - headerHeight)
            let availableWidth = geo.size.width
            let avatarSize = min(48, max(30, availableHeight * 0.23))
            let nameFontSize = min(12, max(8, availableHeight * 0.065))
            let versusFontSize = min(30, max(16, availableHeight * 0.15))
            let valueFontSize = min(18, max(11, availableHeight * 0.095))
            let labelFontSize = min(12, max(8, availableHeight * 0.06))
            let statRowSpacing = min(6, max(1, availableHeight * 0.018))
            let valueWidth = min(56, max(40, availableWidth * 0.18))
            let avatarBlockEstimate = avatarSize + nameFontSize + 12
            let statsBlockEstimate = (valueFontSize * 3) + (statRowSpacing * 2) + 10
            let freeHeight = max(0, availableHeight - avatarBlockEstimate - statsBlockEstimate)
            let topPadding = min(10, freeHeight * 0.25)
            let sectionSpacing = max(4, min(16, freeHeight * 0.45))

            VStack(spacing: 0) {
                // VS 展示
                HStack(spacing: 12) {
                    // 玩家
                    VStack(spacing: 4) {
                        Text(gameState.player.currentPet.emoji)
                            .font(.system(size: avatarSize))
                        Text(gameState.player.currentPet.name)
                            .font(.system(size: nameFontSize, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)

                    Text("VS")
                        .font(.system(size: versusFontSize, weight: .black))
                        .foregroundColor(.red)

                    // 对手
                    VStack(spacing: 4) {
                        Text(opponent.emoji)
                            .font(.system(size: avatarSize))
                        Text(opponent.name)
                            .font(.system(size: nameFontSize, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.top, topPadding)

                Spacer(minLength: sectionSpacing)

                // 属性对比
                VStack(spacing: statRowSpacing) {
                    statCompareRow(
                        label: "HP",
                        playerVal: "\(gameState.player.currentPet.hp)",
                        opponentVal: "\(opponent.hp)",
                        valueFontSize: valueFontSize,
                        labelFontSize: labelFontSize,
                        valueWidth: valueWidth,
                        horizontalPadding: 10
                    )
                    statCompareRow(
                        label: "ATK",
                        playerVal: "\(gameState.player.currentPet.attack)",
                        opponentVal: "\(opponent.attack)",
                        valueFontSize: valueFontSize,
                        labelFontSize: labelFontSize,
                        valueWidth: valueWidth,
                        horizontalPadding: 10
                    )
                    statCompareRow(
                        label: "PWR",
                        playerVal: "\(gameState.player.currentPet.power)",
                        opponentVal: "\(opponent.power)",
                        valueFontSize: valueFontSize,
                        labelFontSize: labelFontSize,
                        valueWidth: valueWidth,
                        horizontalPadding: 10
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: availableHeight, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var preparingBottomBar: some View {
        let buttonHeight: CGFloat = 34
        return VStack(spacing: 0) {
            Button(action: startBattle) {
                Text("⚔️ 开始战斗")
                    .font(.system(size: Constants.FontSize.medium, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(Color.red)
                    .cornerRadius(buttonHeight / 2)
            }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
        }
    }

    private func preparingHeader(headerHeight: CGFloat) -> some View {
        return ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.19),
                    Color(red: 0.05, green: 0.10, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack {
                Button(action: closeBattle) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            Text("战斗准备")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
        }
        .frame(height: headerHeight)
        .padding(.horizontal, 8)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - 战斗阶段
    private var fightingView: some View {
        GeometryReader { geo in
            let barPadding: CGFloat = 20
            let barWidth = geo.size.width - barPadding * 2
            
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.40, green: 0.03, blue: 0.03),
                                Color(red: 0.12, green: 0.01, blue: 0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(2)
                
                VStack(spacing: 0) {
                    // 玩家侧 (上方)
                    VStack(spacing: 3) {
                        Text(gameState.player.currentPet.emoji)
                            .font(.system(size: 40))
                            .offset(y: playerOffset)
                            .opacity(playerFlash ? 0.3 : 1.0)
                        
                        Text("You")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.2))
                            Rectangle().fill(Color.green)
                                .frame(width: max(0, barWidth * hpRatio(current: playerHP, max: playerMaxHP)))
                        }
                        .frame(height: 7)
                        .cornerRadius(3.5)
                        .padding(.horizontal, barPadding)
                        
                        Text("\(playerHP) HP")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, geo.safeAreaInsets.top * 0.5)
                    
                    Spacer()
                    
                    VStack(spacing: 6) {
                        Image(systemName: "swords")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.35))
                        
                        if showDamageText {
                            Text(damageText)
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(damageText.contains("💥") ? .orange : .white)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                                .zIndex(1)
                        }
                    }
                    
                    Spacer()
                    
                    // 对手侧 (下方)
                    VStack(spacing: 3) {
                        Text(opponent.emoji)
                            .font(.system(size: 40))
                            .offset(y: opponentOffset)
                            .opacity(opponentFlash ? 0.3 : 1.0)
                        
                        Text(opponent.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(opponentHP) HP")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                        
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.2))
                            Rectangle().fill(Color.red)
                                .frame(width: max(0, barWidth * hpRatio(current: opponentHP, max: opponentMaxHP)))
                        }
                        .frame(height: 7)
                        .cornerRadius(3.5)
                        .padding(.horizontal, barPadding)
                    }
                    
                    Button(action: skipToResult) {
                        Text("跳过")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - 结果阶段
    private var resultView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 16)
                    
                    // 胜负标题
                    if playerWon {
                        Text("🎉 胜利！🎉")
                            .font(.system(size: Constants.FontSize.title, weight: .bold))
                            .foregroundColor(.yellow)
                    } else {
                        Text("💔 失败")
                            .font(.system(size: Constants.FontSize.title, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    // 战斗双方最终状态
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text(gameState.player.currentPet.emoji)
                                .font(.system(size: 36))
                            Text(gameState.player.currentPet.name)
                                .font(.system(size: Constants.FontSize.small, weight: .semibold))
                                .foregroundColor(.white)
                            Text("HP: \(playerHP)/\(playerMaxHP)")
                                .font(.system(size: Constants.FontSize.tiny))
                                .foregroundColor(playerHP > 0 ? .green : .red)
                        }
                        
                        Text(playerWon ? "WIN" : "LOSE")
                            .font(.system(size: Constants.FontSize.large, weight: .black))
                            .foregroundColor(playerWon ? .yellow : .red)
                        
                        VStack(spacing: 4) {
                            Text(opponent.emoji)
                                .font(.system(size: 36))
                            Text(opponent.name)
                                .font(.system(size: Constants.FontSize.small, weight: .semibold))
                                .foregroundColor(.white)
                            Text("HP: \(opponentHP)/\(opponentMaxHP)")
                                .font(.system(size: Constants.FontSize.tiny))
                                .foregroundColor(opponentHP > 0 ? .green : .red)
                        }
                    }
                    
                    // 战斗统计
                    VStack(spacing: 8) {
                        Text("战斗统计")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Text("总回合数")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(rounds.last?.roundNumber ?? 0)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        let playerDmgTotal = rounds.filter { $0.isPlayerAttack }.reduce(0) { $0 + $1.damage }
                        HStack {
                            Text("总伤害输出")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(playerDmgTotal)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        let playerCrits = rounds.filter { $0.isPlayerAttack && $0.isCritical }.count
                        HStack {
                            Text("暴击次数")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(playerCrits)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    .padding(.horizontal)
                    
                    // 奖励
                    VStack(spacing: 8) {
                        Text("战斗奖励")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Text("💎")
                                .font(.system(size: 20))
                            Text("+\(diamondReward) 钻石")
                                .font(.system(size: Constants.FontSize.large, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        
                        Text("快乐值 -10")
                            .font(.system(size: Constants.FontSize.small))
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    .padding(.horizontal)
                }
            }
            
            // 返回按钮
            Button(action: closeBattle) {
                Text("返回")
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
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
    
    // MARK: - Helper Views
    
    private func statCompareRow(
        label: String,
        playerVal: String,
        opponentVal: String,
        valueFontSize: CGFloat = Constants.FontSize.small,
        labelFontSize: CGFloat = Constants.FontSize.small,
        valueWidth: CGFloat = 50,
        horizontalPadding: CGFloat = 20
    ) -> some View {
        HStack {
            Text(playerVal)
                .font(.system(size: valueFontSize, weight: .bold))
                .foregroundColor(.cyan)
                .frame(width: valueWidth, alignment: .trailing)
            
            Spacer()
            
            Text(label)
                .font(.system(size: labelFontSize))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(opponentVal)
                .font(.system(size: valueFontSize, weight: .bold))
                .foregroundColor(.red)
                .frame(width: valueWidth, alignment: .leading)
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    private func battleLogRow(round: BattleRound) -> some View {
        HStack(spacing: 4) {
            if round.isPlayerAttack {
                Text(gameState.player.currentPet.emoji)
                    .font(.system(size: 10))
                Text("→")
                    .font(.system(size: 8))
                    .foregroundColor(.yellow)
                Text(opponent.emoji)
                    .font(.system(size: 10))
            } else {
                Text(opponent.emoji)
                    .font(.system(size: 10))
                Text("→")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
                Text(gameState.player.currentPet.emoji)
                    .font(.system(size: 10))
            }
            
            Text("-\(round.damage)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(round.isPlayerAttack ? .cyan : .red)
            
            if round.isCritical {
                Text("暴击!")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentDisplayRound: Int {
        if currentRoundIndex < rounds.count {
            return rounds[currentRoundIndex].roundNumber
        }
        return rounds.last?.roundNumber ?? 1
    }
    
    private var displayedRounds: [BattleRound] {
        Array(rounds.prefix(currentRoundIndex + 1))
    }
    
    // MARK: - Helper Functions
    
    private func hpRatio(current: Int, max: Int) -> CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(current) / CGFloat(max)
    }
    
    private func hpColor(current: Int, max: Int) -> Color {
        let ratio = hpRatio(current: current, max: max)
        if ratio > 0.5 { return .green }
        if ratio > 0.2 { return .yellow }
        return .red
    }
    
    // MARK: - Actions
    private func closeBattle() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func startBattle() {
        let result = gameState.executeBattle(against: opponent)
        self.rounds = result.rounds
        self.playerWon = result.playerWon
        self.diamondReward = result.diamondReward
        self.currentRoundIndex = 0
        
        withAnimation {
            battlePhase = .fighting
        }
        
        // 逐步播放回合
        playNextRound()
    }
    
    private func playNextRound() {
        guard currentRoundIndex < rounds.count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    battlePhase = .result
                }
            }
            return
        }
        
        let round = rounds[currentRoundIndex]
        let isPlayerAttacking = round.isPlayerAttack
        
        // 1. 攻击位移动画（玩家在上方向下攻击，对手在下方向上攻击）
        withAnimation(.easeIn(duration: 0.2)) {
            if isPlayerAttacking {
                playerOffset = 20
            } else {
                opponentOffset = -20
            }
        }
        
        // 2. 命中效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 震动
            withAnimation(.default.repeatCount(3, autoreverses: true)) {
                shakeOffset = 5
            }
            
            // 受击闪烁
            withAnimation(.easeInOut(duration: 0.1).repeatCount(2, autoreverses: true)) {
                if isPlayerAttacking {
                    opponentFlash = true
                } else {
                    playerFlash = true
                }
            }
            
            // 显示伤害
            withAnimation(.spring()) {
                showDamageText = true
                damageText = round.isCritical ? "💥 \(round.damage)" : "-\(round.damage)"
            }
            
            // 更新HP
            withAnimation(.easeInOut(duration: 0.3)) {
                playerHP = round.playerHPAfter
                opponentHP = round.opponentHPAfter
            }
            
            // 重置位移
            withAnimation(.easeOut(duration: 0.2)) {
                playerOffset = 0
                opponentOffset = 0
                shakeOffset = 0
            }
            
            // 3. 准备下一回合
            roundTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
                withAnimation {
                    showDamageText = false
                    playerFlash = false
                    opponentFlash = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentRoundIndex += 1
                    playNextRound()
                }
            }
        }
    }
    
    private func skipToResult() {
        roundTimer?.invalidate()
        if let lastRound = rounds.last {
            playerHP = lastRound.playerHPAfter
            opponentHP = lastRound.opponentHPAfter
        }
        currentRoundIndex = rounds.count - 1
        withAnimation {
            battlePhase = .result
        }
    }
}

#Preview {
    BattleView(
        opponent: Opponent.previewOpponents[0],
        gameState: GameStateManager()
    )
}
