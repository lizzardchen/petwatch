import SwiftUI

/// 排行榜界面
struct RankingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameState: GameStateManager
    @State private var showOpponentSelection = false
    @State private var firebaseRankings: [RankingPlayer] = []
    @State private var isLoading = false
    
    /// 合并 Firebase 数据与玩家自身数据，生成最终排行榜
    private var mergedRankings: [(rank: Int, name: String, emoji: String, level: Int, power: Int, wins: Int, isCurrentPlayer: Bool)] {
        let pet = gameState.player.currentPet
        let deviceID = gameState.firebaseManager.currentDeviceID
        
        var all: [(rank: Int, name: String, emoji: String, level: Int, power: Int, wins: Int, isCurrentPlayer: Bool)] = []
        
        // 添加玩家自己
        all.append((rank: 0, name: pet.name, emoji: pet.emoji, level: pet.level, power: pet.power, wins: gameState.player.wins, isCurrentPlayer: true))
        
        // 添加 Firebase 上的其他玩家（排除自己）
        for p in firebaseRankings where p.id != deviceID {
            all.append((rank: 0, name: p.name, emoji: p.emoji, level: p.level, power: p.power, wins: p.wins, isCurrentPlayer: false))
        }
        
        // 按战力降序排列
        all.sort { $0.power > $1.power }
        
        // 分配排名
        for i in 0..<all.count {
            all[i].rank = i + 1
        }
        
        return all
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("🏆")
                    Text("排行榜")
                        .font(.system(size: Constants.FontSize.large, weight: .bold))
                }
                .foregroundColor(.white)
                
                Spacer()
                
                // 刷新按钮
                Button(action: loadRankings) {
                    Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                }
                .frame(width: 30)
            }
            .padding()
            .background(Constants.Colors.darkGray.opacity(0.3))
            
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading && firebaseRankings.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .padding()
                        Text("加载排行榜...")
                            .font(.system(size: Constants.FontSize.small))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        ForEach(mergedRankings, id: \.rank) { item in
                            RankingCard(
                                rank: item.rank,
                                name: item.name,
                                emoji: item.emoji,
                                level: item.level,
                                power: item.power,
                                wins: item.wins,
                                isCurrentPlayer: item.isCurrentPlayer
                            )
                        }
                        
                        if firebaseRankings.isEmpty {
                            Text("暂无其他玩家数据")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.4))
                                .padding()
                        }
                    }
                }
                .padding()
                
                // 今日剩余挑战次数
                HStack(spacing: 8) {
                    Text("今日剩余挑战次数")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index < gameState.player.dailyChallenges ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding()
                
                // 快乐值不足提示
                if !gameState.canBattle() {
                    HStack(spacing: 6) {
                        Text("⚠️")
                        Text("快乐值低于30，无法参与战斗")
                            .font(.system(size: Constants.FontSize.small))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal)
                }
                
                // 随机挑战按钮
                GradientButton(
                    title: !gameState.hasRemainingChallenges() ? "次数已用完" : (gameState.canBattle() ? "随机挑战" : "快乐值不足"),
                    icon: "⚔️",
                    gradient: LinearGradient(
                        colors: (gameState.canBattle() && gameState.hasRemainingChallenges())
                            ? [Color.red, Color.red.opacity(0.8)]
                            : [Color.gray, Color.gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                ) {
                    if gameState.canBattle() && gameState.hasRemainingChallenges() {
                        showOpponentSelection = true
                    }
                }
                .disabled(!gameState.canBattle() || !gameState.hasRemainingChallenges())
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Constants.Colors.darkBackground)
        .onAppear {
            loadRankings()
            // 上传自己的最新数据
            gameState.syncToFirebase()
        }
        .sheet(isPresented: $showOpponentSelection) {
            OpponentSelectionView(firebaseRankings: firebaseRankings)
                .environmentObject(gameState)
        }
    }
    
    private func loadRankings() {
        isLoading = true
        gameState.firebaseManager.fetchRankings {
            isLoading = false
            firebaseRankings = gameState.firebaseManager.rankings
        }
    }
}

/// 排名卡片
struct RankingCard: View {
    let rank: Int
    let name: String
    let emoji: String
    let level: Int
    let power: Int
    let wins: Int
    let isCurrentPlayer: Bool
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return Constants.Colors.darkGray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 36, height: 36)
                
                Text("\(rank)")
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // 头像
            Text(emoji)
                .font(.system(size: 32))
            
            // 信息
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("⭐")
                        Text("Lv.\(level)")
                    }
                    
                    HStack(spacing: 4) {
                        Text("🏆")
                        Text("\(wins)胜")
                    }
                }
                .font(.system(size: Constants.FontSize.small))
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // 战力
            VStack(alignment: .trailing, spacing: 2) {
                Text("⚡ \(power)")
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            isCurrentPlayer
                ? LinearGradient(
                    colors: [Constants.Colors.blue, Constants.Colors.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                : LinearGradient(
                    colors: [Constants.Colors.darkGray.opacity(0.6), Constants.Colors.darkGray.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
        )
        .cornerRadius(Constants.CornerRadius.large)
    }
}

/// 对手选择界面
struct OpponentSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameState: GameStateManager
    let firebaseRankings: [RankingPlayer]
    @State private var opponents: [Opponent] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("选择对手")
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Color.clear
                    .frame(width: 30)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding()
                        Text("寻找对手...")
                            .font(.system(size: Constants.FontSize.small))
                            .foregroundColor(.white.opacity(0.6))
                    } else if opponents.isEmpty {
                        Text("暂无可挑战玩家")
                            .font(.system(size: Constants.FontSize.small))
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                    } else {
                        ForEach(opponents) { opponent in
                            OpponentCard(opponent: opponent, gameState: gameState)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 提示文字
                VStack(spacing: 4) {
                    Text("胜利获得更多钻石")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 12)
            }
        }
        .background(Constants.Colors.darkBackground)
        .onAppear {
            loadOpponents()
        }
    }
    
    private func loadOpponents() {
        let playerPower = gameState.player.currentPet.power
        let deviceID = gameState.firebaseManager.currentDeviceID
        
        // 过滤掉自己
        let others = firebaseRankings.filter { $0.id != deviceID }
        
        if !others.isEmpty {
            // 需求：根据排行榜里面的选择的宠物去获取数据
            // 我们选出战力最接近的3个作为对手
            let sorted = others.sorted { abs($0.power - playerPower) < abs($1.power - playerPower) }
            let selected = Array(sorted.prefix(3))
            opponents = selected.map { p in
                // 奖励根据对方战力动态计算
                let reward = max(10, Int(Double(p.power) * 0.1) + 10)
                return p.toOpponent(diamondReward: reward)
            }.sorted { $0.power < $1.power }
        } else {
            // 备选：本地生成
            opponents = gameState.generateOpponents()
        }
    }
}

/// 对手卡片
struct OpponentCard: View {
    let opponent: Opponent
    @ObservedObject var gameState: GameStateManager
    @State private var showBattle = false
    
    var body: some View {
        Button(action: {
            showBattle = true
        }) {
            HStack(spacing: 10) {
                // 头像
                Text(opponent.emoji)
                    .font(.system(size: 32))
                
                // 信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(opponent.name)
                        .font(.system(size: Constants.FontSize.small, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text("⚡ \(opponent.power)")
                            .foregroundColor(.orange)
                        Text("胜率: \(Int(opponent.winRate * 100))%")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .font(.system(size: 10))
                }
                
                Spacer()
                
                Text("💎\(opponent.diamondReward)")
                    .font(.system(size: Constants.FontSize.small, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Constants.Colors.darkGray.opacity(0.6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showBattle) {
            BattleView(opponent: opponent, gameState: gameState)
        }
    }
}

#Preview {
    RankingView()
        .environmentObject(GameStateManager())
}
