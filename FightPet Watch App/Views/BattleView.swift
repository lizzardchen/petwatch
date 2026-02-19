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
        VStack(spacing: 16) {
            Text("⚔️ 战斗准备 ⚔️")
                .font(.system(size: Constants.FontSize.title, weight: .bold))
                .foregroundColor(.yellow)
            
            // VS 展示
            HStack(spacing: 16) {
                // 玩家
                VStack(spacing: 6) {
                    Text(gameState.player.currentPet.emoji)
                        .font(.system(size: 40))
                    Text(gameState.player.currentPet.name)
                        .font(.system(size: Constants.FontSize.small, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Lv.\(gameState.player.currentPet.level)")
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.cyan)
                    Text("⚡\(gameState.player.currentPet.power)")
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.orange)
                }
                
                Text("VS")
                    .font(.system(size: Constants.FontSize.title, weight: .black))
                    .foregroundColor(.red)
                
                // 对手
                VStack(spacing: 6) {
                    Text(opponent.emoji)
                        .font(.system(size: 40))
                    Text(opponent.name)
                        .font(.system(size: Constants.FontSize.small, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Lv.\(opponent.level)")
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.cyan)
                    Text("⚡\(opponent.power)")
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.orange)
                }
            }
            .padding()
            
            // 属性对比
            VStack(spacing: 6) {
                statCompareRow(label: "HP", playerVal: "\(gameState.player.currentPet.hp)", opponentVal: "\(opponent.hp)")
                statCompareRow(label: "ATK", playerVal: "\(gameState.player.currentPet.attack)", opponentVal: "\(opponent.attack)")
                statCompareRow(label: "DEF", playerVal: String(format: "%.1f", gameState.player.currentPet.defense), opponentVal: String(format: "%.1f", opponent.defense))
                statCompareRow(label: "暴击", playerVal: String(format: "%.0f%%", gameState.player.currentPet.critRate), opponentVal: String(format: "%.0f%%", opponent.critRate))
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 开战按钮
            Button(action: startBattle) {
                HStack {
                    Text("⚔️")
                    Text("开战！")
                        .font(.system(size: Constants.FontSize.large, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Constants.CornerRadius.large)
            }
            .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text("取消")
                    .font(.system(size: Constants.FontSize.medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 16)
    }
    
    // MARK: - 战斗阶段
    private var fightingView: some View {
        VStack(spacing: 8) {
            // 回合数
            Text("第 \(currentDisplayRound) 回合")
                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                .foregroundColor(.yellow)
            
            // 战斗场景
            HStack(spacing: 12) {
                // 玩家侧
                VStack(spacing: 4) {
                    Text(gameState.player.currentPet.emoji)
                        .font(.system(size: 36))
                    
                    // HP条
                    VStack(spacing: 2) {
                        Text("\(playerHP)/\(playerMaxHP)")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 6)
                                    .cornerRadius(3)
                                
                                Rectangle()
                                    .fill(hpColor(current: playerHP, max: playerMaxHP))
                                    .frame(width: geo.size.width * hpRatio(current: playerHP, max: playerMaxHP), height: 6)
                                    .cornerRadius(3)
                                    .animation(.easeInOut(duration: 0.3), value: playerHP)
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(width: 60)
                }
                
                // 中间战斗效果
                ZStack {
                    if showDamageText {
                        VStack(spacing: 2) {
                            Text(damageIsPlayer ? "→" : "←")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                            Text(damageText)
                                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                                .foregroundColor(damageText.contains("暴击") ? .orange : .white)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 60, height: 40)
                
                // 对手侧
                VStack(spacing: 4) {
                    Text(opponent.emoji)
                        .font(.system(size: 36))
                    
                    // HP条
                    VStack(spacing: 2) {
                        Text("\(opponentHP)/\(opponentMaxHP)")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 6)
                                    .cornerRadius(3)
                                
                                Rectangle()
                                    .fill(hpColor(current: opponentHP, max: opponentMaxHP))
                                    .frame(width: geo.size.width * hpRatio(current: opponentHP, max: opponentMaxHP), height: 6)
                                    .cornerRadius(3)
                                    .animation(.easeInOut(duration: 0.3), value: opponentHP)
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(width: 60)
                }
            }
            .padding(.horizontal)
            
            // 战斗日志
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(displayedRounds.enumerated()), id: \.offset) { index, round in
                            battleLogRow(round: round)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 100)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: displayedRounds.count) { _ in
                    if let lastIndex = displayedRounds.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 跳过按钮
            Button(action: skipToResult) {
                Text("跳过动画")
                    .font(.system(size: Constants.FontSize.small))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
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
            // 战斗结束
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    battlePhase = .result
                }
            }
            return
        }
        
        let round = rounds[currentRoundIndex]
        
        // 显示伤害文字
        withAnimation(.easeInOut(duration: 0.2)) {
            showDamageText = true
            damageIsPlayer = round.isPlayerAttack
            damageText = round.isCritical ? "暴击! -\(round.damage)" : "-\(round.damage)"
        }
        
        // 更新HP
        withAnimation(.easeInOut(duration: 0.3)) {
            playerHP = round.playerHPAfter
            opponentHP = round.opponentHPAfter
        }
        
        // 隐藏伤害文字并播放下一回合
        roundTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
            withAnimation {
                showDamageText = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentRoundIndex += 1
                playNextRound()
            }
        }
    }
    
    private func skipToResult() {
        roundTimer?.invalidate()
        
        // 直接跳到最终状态
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
