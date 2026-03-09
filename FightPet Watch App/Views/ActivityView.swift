import SwiftUI

/// 运动追踪页
struct ActivityView: View {
    @ObservedObject var gameState: GameStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var todayExerciseSeconds: Int = 0
    @State private var todaySleepSeconds: Int = 0
    @State private var isLoadingHealth = false
    @State private var hasClaimedSleepReward = false
    @State private var hasClaimedExerciseReward = false
    
    // 每日上限（秒）
    private let sleepDailyLimitSeconds = 7200      // 120分钟
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
        return min(todaySleepSeconds, sleepDailyLimitSeconds) / 60
    }
    
    // 计算可领取的力量值（每分钟1点）
    private var claimableStrength: Int {
        return min(todayExerciseSeconds, exerciseDailyLimitSeconds) / 60
    }
    
    var body: some View {
        ZStack {
            Constants.Colors.darkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("运动追踪")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 睡眠奖励卡片
                        sleepRewardCard()
                        
                        // 运动奖励卡片
                        exerciseRewardCard()
                        
                        // 关闭按钮
                        Button(action: { dismiss() }) {
                            Text("关闭")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            loadHealthData()
        }
    }
    
    // MARK: - 睡眠奖励卡片
    
    private func sleepRewardCard() -> some View {
        VStack(spacing: 0) {
            // 顶部质量评级
            HStack {
                Text("差")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                
                Spacer()
                
                Text("优")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // 经验值显示
            Text("+\(claimableExp) EXP/分钟")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.green)
                .padding(.bottom, 12)
            
            // 领取按钮
            Button(action: claimSleepReward) {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 16))
                    Text("领取")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: hasClaimedSleepReward ? [Color.gray, Color.gray.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(hasClaimedSleepReward || claimableExp == 0)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // 运动时长信息
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                Text("运动时长")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("\(todayExerciseSeconds / 60)分钟")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // 今日力量增长
            HStack {
                Text("今日力量增长")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(claimableStrength)/\(exerciseDailyLimitSeconds / 60)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                        .frame(
                            width: geo.size.width * min(1.0, Double(todayExerciseSeconds) / Double(exerciseDailyLimitSeconds)),
                            height: 12
                        )
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // 时长统计
            HStack {
                Text("\(todaySleepSeconds / 60)分钟")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("\(sleepDailyLimitSeconds / 60)分钟")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    // MARK: - 运动奖励卡片
    
    private func exerciseRewardCard() -> some View {
        VStack(spacing: 12) {
            // 力量值显示
            Text("+\(claimableStrength) 力量")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.blue)
            
            // 领取按钮
            Button(action: claimExerciseReward) {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 16))
                    Text("领取")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: hasClaimedExerciseReward ? [Color.gray, Color.gray.opacity(0.8)] : [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(hasClaimedExerciseReward || claimableStrength == 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    // MARK: - Actions
    
    private func claimSleepReward() {
        guard !hasClaimedSleepReward && claimableExp > 0 else { return }
        
        // 添加经验值
        gameState.addExperience(claimableExp)
        hasClaimedSleepReward = true
        
        // 触觉反馈
        WKInterfaceDevice.current().play(.success)
    }
    
    private func claimExerciseReward() {
        guard !hasClaimedExerciseReward && claimableStrength > 0 else { return }
        
        // 添加力量属性
        gameState.player.currentPet.strength += claimableStrength
        gameState.savePlayer()
        hasClaimedExerciseReward = true
        
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
}


#Preview {
    ActivityView(gameState: GameStateManager())
}
