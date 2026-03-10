import SwiftUI

/// 运动追踪页
struct ActivityView: View {
    @ObservedObject var gameState: GameStateManager
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    private let headerOverlayHeight: CGFloat = 24
    @State private var todayExerciseSeconds: Int = 0
    @State private var todaySleepSeconds: Int = 0
    @State private var isLoadingHealth = false
    @State private var hasClaimedSleepReward = false
    @State private var hasClaimedExerciseReward = false
    
    // 每日上限（秒）
    private let sleepDailyLimitSeconds = 30000     // 500分钟
    private let exerciseDailyLimitSeconds = 3000   // 50分钟
    
    // 当前状态
    private var isSleeping: Bool { gameState.healthManager.isSleeping }
    private var isExercising: Bool { gameState.healthManager.isExercising }
    
    // 睡眠质量评级
    private var sleepQuality: String {
        let progress = Double(min(todaySleepSeconds, sleepDailyLimitSeconds)) / Double(sleepDailyLimitSeconds)
        if progress >= 0.8 { return "优" }
        if progress >= 0.5 { return "良" }
        if progress >= 0.3 { return "中" }
        return "差"
    }
    
    // 计算可领取的经验值（每分钟1 EXP）
    private var claimableExp: Int {
        min(todaySleepSeconds, sleepDailyLimitSeconds) / 60
    }
    
    // 计算可领取的力量值（每分钟1点）
    private var claimableStrength: Int {
        min(todayExerciseSeconds, exerciseDailyLimitSeconds) / 60
    }
    
    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let topInset = safeTop * 0.03
            let contentTopInset = max(16, headerOverlayHeight + topInset - 2)

            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        sleepSection
                            .padding(.top, contentTopInset)
                            .padding(.bottom, 12)

                        exerciseSection
                            .padding(.bottom, 12)

                        Text("41mm Apple Watch")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .contentShape(Rectangle())
                }

                headerView(topInset: topInset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(red: 0.15, green: 0.18, blue: 0.28))
            .ignoresSafeArea(edges: [.top, .bottom])
        }
        .onAppear {
            loadHealthData()
        }
    }

    private func headerView(topInset: CGFloat) -> some View {
        HStack(spacing: 8) {
            Button(action: closeView) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)

            Text("运动追踪")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, topInset)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.15, green: 0.18, blue: 0.28).opacity(0.96))
    }

    private var sleepSection: some View {
        VStack(spacing: 4) {
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.purple.opacity(0.8))
                    
                    Text("睡眠质量")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(todaySleepSeconds / 60)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                
                HStack {
                    Text("已经验加成")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text("\(claimableExp)/\(sleepDailyLimitSeconds / 60)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.top, 2)
                
                VStack(spacing: 2) {
                    HStack {
                        Text("差")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Text("优")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    
                    GeometryReader { sliderGeo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 28)
                            
                            let progress = Double(min(todaySleepSeconds, sleepDailyLimitSeconds)) / Double(sleepDailyLimitSeconds)
                            let indicatorX = max(16, min((sliderGeo.size.width - 32) * CGFloat(progress) + 16, sliderGeo.size.width - 16))
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.blue.opacity(0.5), radius: 4, x: 0, y: 2)
                                .offset(x: indicatorX - 16)
                        }
                    }
                    .frame(height: 32)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                
                Text("+\(claimableExp) EXP/分钟")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
            }
            .allowsHitTesting(false)
            
            Button(action: claimSleepReward) {
                HStack(spacing: 4) {
                    Image(systemName: hasClaimedSleepReward ? "checkmark.circle.fill" : "gift.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(hasClaimedSleepReward ? "已领取" : "领取")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white.opacity(hasClaimedSleepReward || claimableExp == 0 ? 0.5 : 1.0))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
            .disabled(hasClaimedSleepReward || claimableExp == 0)
            .padding(.horizontal, 12)
            .padding(.top, 6)
        }
    }

    private var exerciseSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.orange)
                
                Text("运动时长")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(todayExerciseSeconds / 60)分钟")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            
            HStack {
                Text("今日敏捷增长")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(claimableStrength)/\(exerciseDailyLimitSeconds / 60)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 12)
            .padding(.top, 2)
            
            GeometryReader { progressGeo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 12)
                    
                    let progress = min(1.0, Double(todayExerciseSeconds) / Double(exerciseDailyLimitSeconds))
                    let progressWidth = progressGeo.size.width * CGFloat(progress)
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth, height: 12)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                        .shadow(color: Color.blue.opacity(0.5), radius: 3, x: 0, y: 1)
                        .offset(x: max(0, min(progressWidth - 10, progressGeo.size.width - 20)))
                }
            }
            .frame(height: 20)
            .padding(.horizontal, 12)
            .padding(.top, 6)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Actions
    
    func claimSleepReward() {
        guard !hasClaimedSleepReward && claimableExp > 0 else { return }
        
        // 添加经验值
        gameState.addExperience(claimableExp)
        hasClaimedSleepReward = true
        
        // 触觉反馈
        WKInterfaceDevice.current().play(.success)
    }
    
    // MARK: - Helpers
    
    private func loadHealthData() {
        isLoadingHealth = true
        
        // 查询今日运动时长
        gameState.healthManager.queryTodayExerciseDuration { seconds in
            todayExerciseSeconds = seconds
        }
        
        // 查询今日睡眠时长
        gameState.healthManager.queryTodaySleepIntervals { intervals in
            let total = intervals.reduce(0.0) { $0 + $1.duration }
            todaySleepSeconds = Int(total)
            isLoadingHealth = false
        }
        
        // 刷新当前状态
        gameState.healthManager.isCurrentlySleeping { _ in }
        gameState.healthManager.isCurrentlyExercising { _ in }
    }

    private func closeView() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview {
    ActivityView(gameState: GameStateManager())
}
