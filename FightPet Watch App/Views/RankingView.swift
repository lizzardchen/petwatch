import SwiftUI

/// 排行榜界面
struct RankingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameState: GameStateManager
    var onClose: (() -> Void)? = nil
    @State private var showOpponentSelection = false
    @State private var firebaseRankings: [RankingPlayer] = []
    @State private var challengeOpponents: [Opponent] = []
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
            if isLoading && firebaseRankings.isEmpty {
                Spacer(minLength: 8)
                ProgressView()
                    .tint(.white)
                Text("加载排行榜...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
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
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                                .padding(.top, 10)
                        }
                    }
                    .padding(.top, 2)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 2)
                }
            }

            battleSection
        }
        .overlay(alignment: .top) {
            rankingHeader
                .padding(.top, 0)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.03, green: 0.08, blue: 0.19),
                            Color(red: 0.05, green: 0.1, blue: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .top)
                .zIndex(2)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.19),
                    Color(red: 0.06, green: 0.12, blue: 0.22),
                    Color(red: 0.09, green: 0.15, blue: 0.26)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            loadRankings()
            gameState.syncToFirebase()
        }
        .sheet(isPresented: $showOpponentSelection) {
            OpponentSelectionView(opponents: challengeOpponents)
                .environmentObject(gameState)
        }
    }

    private var rankingHeader: some View {
        ZStack {
            HStack {
                Button(action: {
                    if let onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                }) {
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

            HStack(spacing: 4) {
                Image(systemName: "trophy")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.yellow)
                Text("Rank")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var battleSection: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Text("今日剩余挑战次数")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.74))

                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < gameState.player.dailyChallenges ? Color.green : Color.gray.opacity(0.35))
                        .frame(width: 5, height: 5)
                }
            }

            Button(action: {
                if gameState.canBattle() && gameState.hasRemainingChallenges() {
                    loadChallengeOpponentsAndPresent()
                }
            }) {
                HStack(spacing: 4) {
                    if !gameState.canBattle() {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .bold))
                    } else {
                        Image(systemName: "sword")
                            .font(.system(size: 9, weight: .bold))
                    }

                    Text(buttonTitle)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(buttonEnabled ? .white : .white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: buttonEnabled
                            ? [Color(red: 1.0, green: 0.16, blue: 0.53), Color(red: 1.0, green: 0.0, blue: 0.42)]
                            : [Color.gray.opacity(0.7), Color.gray.opacity(0.56)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!buttonEnabled)
        }
        .padding(.horizontal, 8)
        .padding(.top, 1)
        .padding(.bottom, 2)
    }

    private var buttonEnabled: Bool {
        gameState.canBattle() && gameState.hasRemainingChallenges()
    }

    private var buttonTitle: String {
        if !gameState.hasRemainingChallenges() { return "次数已用完" }
        if !gameState.canBattle() { return "快乐值不足" }
        return "Battle"
    }

    private func loadRankings() {
        isLoading = true
        gameState.firebaseManager.fetchRankings {
            isLoading = false
            firebaseRankings = gameState.firebaseManager.rankings
        }
    }

    private func loadChallengeOpponentsAndPresent() {
        gameState.firebaseManager.fetchOpponents(playerPower: gameState.player.currentPet.power) { opponents in
            self.challengeOpponents = opponents.isEmpty ? gameState.generateOpponents() : opponents
            self.showOpponentSelection = true
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

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.82, blue: 0.05)
        case 2: return Color(red: 0.82, green: 0.85, blue: 0.9)
        case 3: return Color(red: 1.0, green: 0.38, blue: 0.0)
        default: return Color(red: 0.25, green: 0.31, blue: 0.42)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(rank)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.black.opacity(rank <= 3 ? 0.9 : 0.78))
                .frame(width: 21, height: 21)
                .background(rankColor)
                .clipShape(Circle())

            Text(emoji)
                .font(.system(size: 19))

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("☆ Lv.\(level)")
                    Text("· 🏆 \(wins)W")
                }
                .font(.system(size: 4.5, weight: .medium))
                .foregroundColor(.white.opacity(0.62))
                .lineLimit(1)
            }

            Spacer(minLength: 2)

            HStack(spacing: 1) {
                Image(systemName: "bolt")
                    .font(.system(size: 7, weight: .bold))
                Text("\(power)")
                    .font(.system(size: 7, weight: .bold))
            }
            .foregroundColor(Color(red: 1.0, green: 0.58, blue: 0.0))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(
            Group {
                if isCurrentPlayer {
                    LinearGradient(
                        colors: [Color(red: 0.31, green: 0.25, blue: 0.95), Color(red: 0.58, green: 0.2, blue: 0.97)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.white.opacity(0.04)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.white.opacity(isCurrentPlayer ? 0.0 : 0.05), lineWidth: 1)
        )
    }
}

/// 对手选择界面
struct OpponentSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameState: GameStateManager
    let opponents: [Opponent]

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
                    if opponents.isEmpty {
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
