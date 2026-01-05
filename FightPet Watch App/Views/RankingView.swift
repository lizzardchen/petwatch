import SwiftUI

/// 排行榜界面
struct RankingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameState: GameStateManager
    @State private var showOpponentSelection = false
    @State private var dailyChallenges = 3
    
    // 模拟排行榜数据
    let rankings: [(rank: Int, player: Opponent)] = [
        (1, Opponent(name: "你", emoji: "😍", level: 99, power: 44, wins: 0, winRate: 0.0, diamondReward: 0)),
        (2, Opponent(name: "小明", emoji: "🐱", level: 3, power: 95, wins: 12, winRate: 0.10, diamondReward: 97)),
        (3, Opponent(name: "小红", emoji: "🐱", level: 2, power: 88, wins: 10, winRate: 0.10, diamondReward: 94))
    ]
    
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
                
                Color.clear
                    .frame(width: 30)
            }
            .padding()
            .background(Constants.Colors.darkGray.opacity(0.3))
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(rankings, id: \.rank) { item in
                        RankingCard(
                            rank: item.rank,
                            player: item.player,
                            isCurrentPlayer: item.rank == 1
                        )
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
                                .fill(index < dailyChallenges ? Color.green : Color.gray.opacity(0.3))
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
                    title: gameState.canBattle() ? "随机挑战" : "快乐值不足",
                    icon: "⚔️",
                    gradient: LinearGradient(
                        colors: gameState.canBattle() 
                            ? [Color.red, Color.red.opacity(0.8)]
                            : [Color.gray, Color.gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                ) {
                    if gameState.canBattle() {
                        showOpponentSelection = true
                    }
                }
                .disabled(!gameState.canBattle())
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Constants.Colors.darkBackground)
        .sheet(isPresented: $showOpponentSelection) {
            OpponentSelectionView()
        }
    }
}

/// 排名卡片
struct RankingCard: View {
    let rank: Int
    let player: Opponent
    let isCurrentPlayer: Bool
    
    var rankColor: Color {
        switch rank {
        case 1: return .blue
        case 2: return .gray
        case 3: return .orange
        default: return .clear
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
            Text(player.emoji)
                .font(.system(size: 32))
            
            // 信息
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("⭐")
                        Text("Lv.\(player.level)")
                    }
                    
                    HStack(spacing: 4) {
                        Text("🏆")
                        Text("\(player.wins)胜")
                    }
                }
                .font(.system(size: Constants.FontSize.small))
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // 战力
            VStack(alignment: .trailing, spacing: 2) {
                Text("⚡ \(player.power)")
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
    
    let opponents = Opponent.previewOpponents
    
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
                VStack(spacing: 16) {
                    ForEach(opponents) { opponent in
                        OpponentCard(opponent: opponent)
                    }
                }
                .padding()
                
                // 提示文字
                VStack(spacing: 4) {
                    Text("胜利获得更多钻石")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white.opacity(0.8))
                    Text("失败也有少量钻石奖励")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
            }
        }
        .background(Constants.Colors.darkBackground)
    }
}

/// 对手卡片
struct OpponentCard: View {
    let opponent: Opponent
    
    var body: some View {
        Button(action: {
            // 开始战斗
        }) {
            HStack(spacing: 12) {
                // 头像
                Text(opponent.emoji)
                    .font(.system(size: 40))
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(opponent.name)
                        .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("⚡")
                            Text("\(opponent.power)")
                        }
                        
                        HStack(spacing: 4) {
                            Text("🏆")
                            Text("\(opponent.wins)")
                        }
                    }
                    .font(.system(size: Constants.FontSize.small))
                    .foregroundColor(.orange)
                    
                    Text("胜率 \(Int(opponent.winRate * 100))%")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // 奖励
                VStack(alignment: .trailing, spacing: 2) {
                    Text("💎 +\(opponent.diamondReward)")
                        .font(.system(size: Constants.FontSize.medium, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
            .padding()
        }
        .background(Constants.Colors.darkGray.opacity(0.6))
        .cornerRadius(Constants.CornerRadius.large)
        .buttonStyle(.plain)
    }
}

#Preview {
    RankingView()
        .environmentObject(GameStateManager())
}
