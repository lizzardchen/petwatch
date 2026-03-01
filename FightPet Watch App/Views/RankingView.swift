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
        .overlay {
            if showOpponentSelection {
                OpponentSelectionView(
                    opponents: challengeOpponents,
                    onClose: { showOpponentSelection = false }
                )
                .environmentObject(gameState)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .center)),
                        removal: .opacity
                    )
                )
                .zIndex(20)
            }
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
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            HStack(spacing: 4) {
                Image(systemName: "trophy")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.yellow)
                Text("Rank")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 8)
        .padding(.top, 5)
        .padding(.bottom, 1)
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
                if buttonEnabled {
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
        gameState.hasRemainingChallenges() && (gameState.canBattle() || allowBattleTestBypass)
    }

    private var buttonTitle: String {
        if !gameState.hasRemainingChallenges() { return "次数已用完" }
        if !gameState.canBattle() && allowBattleTestBypass { return "测试战斗" }
        if !gameState.canBattle() { return "快乐值不足" }
        return "Battle"
    }

    private var allowBattleTestBypass: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
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
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.black.opacity(rank <= 3 ? 0.9 : 0.78))
                .frame(width: 21, height: 21)
                .background(rankColor)
                .clipShape(Circle())

            Text(emoji)
                .font(.system(size: 19))

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("☆ Lv.\(level)")
                    Text("· 🏆 \(wins)W")
                }
                .font(.system(size: 5.5, weight: .medium))
                .foregroundColor(.white.opacity(0.62))
                .lineLimit(1)
            }

            Spacer(minLength: 2)

            HStack(spacing: 1) {
                Image(systemName: "bolt")
                    .font(.system(size: 8, weight: .bold))
                Text("\(power)")
                    .font(.system(size: 8, weight: .bold))
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
    @EnvironmentObject var gameState: GameStateManager
    let opponents: [Opponent]
    var onClose: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    if opponents.isEmpty {
                        Text("暂无可挑战玩家")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)
                    } else {
                        ForEach(opponents) { opponent in
                            OpponentCard(opponent: opponent, gameState: gameState)
                        }
                    }

                    Text("Battle to earn rewards!")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                }
                .padding(.horizontal, 8)
                .padding(.top, 2)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .overlay(alignment: .top) {
            ZStack {
                HStack {
                    Button(action: {
                        if let onClose {
                            onClose()
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

                Text("Battle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .offset(y: 2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 0)
            .padding(.bottom, 4)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.08, blue: 0.19),
                        Color(red: 0.05, green: 0.10, blue: 0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
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
            HStack(spacing: 8) {
                Text(opponent.emoji)
                    .font(.system(size: 23))

                VStack(alignment: .leading, spacing: 1) {
                    Text(opponent.name)
                        .font(.system(size: 6, weight: .medium))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "bolt")
                            Text("\(opponent.power)")
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.58, blue: 0.0))

                        Text("Win: \(Int(opponent.winRate * 100))%")
                            .foregroundColor(.white.opacity(0.62))
                    }
                    .font(.system(size: 4.5, weight: .medium))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.15, green: 0.21, blue: 0.30).opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
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
