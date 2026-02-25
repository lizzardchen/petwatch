import SwiftUI

/// 运动详情页
struct ActivityView: View {
    @ObservedObject var gameState: GameStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var todayExerciseSeconds: Int = 0
    @State private var todaySleepSeconds: Int = 0
    @State private var isLoadingHealth = false
    
    // 经验加成上限
    private let exerciseDailyLimitSeconds = 7200   // 2小时
    private let sleepDailyLimitSeconds = 14400     // 4小时
    
    // 当前状态
    private var isSleeping: Bool { gameState.healthManager.isSleeping }
    private var isExercising: Bool { gameState.healthManager.isExercising }
    
    // 经验加成
    private var sleepExpBonus: Double { isSleeping ? 2.0 : 0.0 }
    private var exerciseExpBonus: Double { isExercising ? 3.0 : 0.0 }
    
    var body: some View {
        ZStack {
            Constants.Colors.darkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("🏃 运动健康")
                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 14) {
                        
                        // 当前状态卡片
                        VStack(spacing: 10) {
                            Text("当前状态")
                                .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 16) {
                                // 睡眠状态
                                statusBadge(
                                    icon: "🌙",
                                    label: "睡眠",
                                    isActive: isSleeping,
                                    activeText: "睡眠中",
                                    inactiveText: "未睡眠",
                                    activeColor: .blue
                                )
                                
                                // 运动状态
                                statusBadge(
                                    icon: "🏃",
                                    label: "运动",
                                    isActive: isExercising,
                                    activeText: "运动中",
                                    inactiveText: "未运动",
                                    activeColor: .green
                                )
                            }
                        }
                        .padding()
                        .background(Constants.Colors.darkGray.opacity(0.3))
                        .cornerRadius(Constants.CornerRadius.large)
                        .padding(.horizontal)
                        
                        // 今日数据
                        VStack(spacing: 10) {
                            Text("今日数据")
                                .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            // 运动时长
                            healthDataRow(
                                icon: "🏃",
                                label: "运动时长",
                                value: formatDuration(todayExerciseSeconds),
                                limit: formatDuration(exerciseDailyLimitSeconds),
                                progress: Double(min(todayExerciseSeconds, exerciseDailyLimitSeconds)) / Double(exerciseDailyLimitSeconds),
                                color: .green
                            )
                            
                            // 睡眠时长
                            healthDataRow(
                                icon: "🌙",
                                label: "睡眠时长",
                                value: formatDuration(todaySleepSeconds),
                                limit: formatDuration(sleepDailyLimitSeconds),
                                progress: Double(min(todaySleepSeconds, sleepDailyLimitSeconds)) / Double(sleepDailyLimitSeconds),
                                color: .blue
                            )
                        }
                        .padding()
                        .background(Constants.Colors.darkGray.opacity(0.3))
                        .cornerRadius(Constants.CornerRadius.large)
                        .padding(.horizontal)
                        
                        // 经验加成说明
                        VStack(spacing: 10) {
                            Text("经验加成")
                                .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            expBonusRow(
                                icon: "🏃",
                                label: "运动加成",
                                bonus: "+3 exp/秒",
                                condition: "运动中激活",
                                isActive: isExercising,
                                dailyLimit: "每日上限2小时"
                            )
                            
                            expBonusRow(
                                icon: "🌙",
                                label: "睡眠加成",
                                bonus: "+2 exp/秒",
                                condition: "睡眠中激活",
                                isActive: isSleeping,
                                dailyLimit: "每日上限4小时"
                            )
                            
                            // 当前总加成
                            let currentBonus = sleepExpBonus + exerciseExpBonus
                            if currentBonus > 0 {
                                HStack {
                                    Text("✨ 当前健康加成")
                                        .font(.system(size: Constants.FontSize.small))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("+\(String(format: "%.0f", currentBonus)) exp/秒")
                                        .font(.system(size: Constants.FontSize.small, weight: .bold))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal)
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Constants.Colors.darkGray.opacity(0.3))
                        .cornerRadius(Constants.CornerRadius.large)
                        .padding(.horizontal)
                        
                        // 总经验产出
                        VStack(spacing: 8) {
                            Text("当前总经验产出")
                                .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            let totalPerSec = gameState.totalExpPerSecond()
                            let totalPerMin = Int(totalPerSec * 60)
                            
                            HStack(spacing: 20) {
                                VStack(spacing: 2) {
                                    Text("\(String(format: "%.1f", totalPerSec))")
                                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                                        .foregroundColor(.cyan)
                                    Text("exp/秒")
                                        .font(.system(size: Constants.FontSize.small))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Text("=")
                                    .font(.system(size: Constants.FontSize.large))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                VStack(spacing: 2) {
                                    Text("\(totalPerMin)")
                                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                                        .foregroundColor(.cyan)
                                    Text("exp/分钟")
                                        .font(.system(size: Constants.FontSize.small))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding()
                        .background(Constants.Colors.darkGray.opacity(0.3))
                        .cornerRadius(Constants.CornerRadius.large)
                        .padding(.horizontal)
                        
                        // HealthKit 授权状态
                        if !gameState.healthManager.isAuthorized {
                            HStack(spacing: 8) {
                                Text("⚠️")
                                Text("HealthKit未授权，睡眠和运动加成不可用")
                                    .font(.system(size: Constants.FontSize.small))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                            .frame(height: 16)
                    }
                }
            }
        }
        .onAppear {
            loadHealthData()
        }
    }
    
    // MARK: - Helper Views
    
    private func statusBadge(icon: String, label: String, isActive: Bool, activeText: String, inactiveText: String, activeColor: Color) -> some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 28))
            
            Text(isActive ? activeText : inactiveText)
                .font(.system(size: Constants.FontSize.small, weight: .bold))
                .foregroundColor(isActive ? activeColor : .white.opacity(0.4))
            
            Circle()
                .fill(isActive ? activeColor : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActive ? activeColor.opacity(0.15) : Color.clear)
        .cornerRadius(10)
    }
    
    private func healthDataRow(icon: String, label: String, value: String, limit: String, progress: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(icon)
                Text(label)
                    .font(.system(size: Constants.FontSize.small))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(value)
                    .font(.system(size: Constants.FontSize.small, weight: .bold))
                    .foregroundColor(.white)
                Text("/ \(limit)")
                    .font(.system(size: Constants.FontSize.tiny))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 5)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * min(1.0, progress), height: 5)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal)
    }
    
    private func expBonusRow(icon: String, label: String, bonus: String, condition: String, isActive: Bool, dailyLimit: String) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: Constants.FontSize.small, weight: .semibold))
                    .foregroundColor(.white)
                Text(dailyLimit)
                    .font(.system(size: Constants.FontSize.tiny))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(bonus)
                    .font(.system(size: Constants.FontSize.small, weight: .bold))
                    .foregroundColor(isActive ? .green : .white.opacity(0.4))
                Text(isActive ? "✅ 生效中" : condition)
                    .font(.system(size: Constants.FontSize.tiny))
                    .foregroundColor(isActive ? .green : .white.opacity(0.4))
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
    
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
