import SwiftUI

/// 战斗界面
struct BattleView: View {
    let opponent: Opponent
    @ObservedObject var gameState: GameStateManager
    @Environment(\.dismiss) private var dismiss
    
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
        ZStack {
            Constants.Colors.darkBackground
                .ignoresSafeArea()
            
            switch battlePhase {
            case .preparing:
                preparingView
            case .fighting:
                fightingView
            case .result:
                resultView
            }
            
            // 全局震动效果
            Color.clear
                .offset(x: shakeOffset)
        }
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
    
    // MARK: - 准备阶段
    private var preparingView: some View {
        VStack(spacing: 12) {
            Text("⚔️ 战斗准备")
                .padding(.top, 20)
                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                .foregroundColor(.yellow)
            
            // VS 展示
            HStack(spacing: 12) {
                // 玩家
                VStack(spacing: 4) {
                    Text(gameState.player.currentPet.emoji)
                        .font(.system(size: 32))
                    Text(gameState.player.currentPet.name)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                
                Text("VS")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.red)
                
                // 对手
                VStack(spacing: 4) {
                    Text(opponent.emoji)
                        .font(.system(size: 32))
                    Text(opponent.name)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            // 属性对比
            VStack(spacing: 4) {
                statCompareRow(label: "HP", playerVal: "\(gameState.player.currentPet.hp)", opponentVal: "\(opponent.hp)")
                statCompareRow(label: "ATK", playerVal: "\(gameState.player.currentPet.attack)", opponentVal: "\(opponent.attack)")
                statCompareRow(label: "PWR", playerVal: "\(gameState.player.currentPet.power)", opponentVal: "\(opponent.power)")
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 开战按钮
            Button(action: startBattle) {
                Text("⚔️ 开始战斗")
                    .font(.system(size: Constants.FontSize.medium, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.red)
                    .cornerRadius(18)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text("撤退")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
    }
    
    // MARK: - 战斗阶段
    private var fightingView: some View {
        VStack(spacing: 10) {
            // 战斗场景
            VStack(spacing: 15) {
                // 对手侧 (上方)
                VStack(spacing: 4) {
                    HStack {
                        Text(opponent.name)
                            .font(.system(size: 10))
                        Spacer()
                        Text("\(opponentHP) HP")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .padding(.horizontal, 20)
                    
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 140 * hpRatio(current: opponentHP, max: opponentMaxHP))
                    }
                    .frame(width: 140, height: 6)
                    .cornerRadius(3)
                    
                    Text(opponent.emoji)
                        .font(.system(size: 44))
                        .offset(y: opponentOffset)
                        .opacity(opponentFlash ? 0.3 : 1.0)
                }
                
                // 中间交叉剑图标
                Image(systemName: "swords")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
                
                // 玩家侧 (下方)
                VStack(spacing: 4) {
                    Text(gameState.player.currentPet.emoji)
                        .font(.system(size: 44))
                        .offset(y: playerOffset)
                        .opacity(playerFlash ? 0.3 : 1.0)
                    
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 140 * hpRatio(current: playerHP, max: playerMaxHP))
                    }
                    .frame(width: 140, height: 6)
                    .cornerRadius(3)
                    
                    HStack {
                        Text("你")
                            .font(.system(size: 10))
                        Spacer()
                        Text("\(playerHP) HP")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // 伤害飘字
            if showDamageText {
                Text(damageText)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(damageText.contains("暴击") ? .orange : .white)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                    .zIndex(1)
            }
            
            Spacer()
            
            Button(action: skipToResult) {
                Text("跳过")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .padding(.top, 10)
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
            Button(action: { dismiss() }) {
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
    
    private func statCompareRow(label: String, playerVal: String, opponentVal: String) -> some View {
        HStack {
            Text(playerVal)
                .font(.system(size: Constants.FontSize.small, weight: .bold))
                .foregroundColor(.cyan)
                .frame(width: 50, alignment: .trailing)
            
            Spacer()
            
            Text(label)
                .font(.system(size: Constants.FontSize.small))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(opponentVal)
                .font(.system(size: Constants.FontSize.small, weight: .bold))
                .foregroundColor(.red)
                .frame(width: 50, alignment: .leading)
        }
        .padding(.horizontal, 20)
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
        
        // 1. 攻击位移动画
        withAnimation(.easeIn(duration: 0.2)) {
            if isPlayerAttacking {
                playerOffset = -20
            } else {
                opponentOffset = 20
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
