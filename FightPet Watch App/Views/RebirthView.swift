import SwiftUI

/// 重生与孵化界面
struct RebirthView: View {
    @ObservedObject var gameState: GameStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showResult = false
    @State private var rebirthReward: Int = 0
    @State private var oldQuality: PetQuality = .rankA
    @State private var newQuality: PetQuality = .rankA
    @State private var newIntelligence: Int = 0
    @State private var newStamina: Int = 0
    @State private var newStrength: Int = 0
    
    private var pet: Pet {
        gameState.player.currentPet
    }
    
    private var isHatching: Bool {
        gameState.player.rebirthSourcePet != nil
    }
    
    var body: some View {
        ZStack {
            Constants.Colors.darkBackground
                .ignoresSafeArea()
            
            if showResult {
                rebirthResultView
            } else if isHatching {
                hatchingView
            } else {
                rebirthConfirmView
            }
        }
    }
    
    // MARK: - 重生确认界面
    private var rebirthConfirmView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("🔄")
                    .font(.system(size: 24))
                Text("宠物重生")
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
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(pet.emoji)
                            .font(.system(size: 50))
                        
                        Text(pet.name)
                            .font(.system(size: Constants.FontSize.large, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text("Lv.\(pet.level)")
                                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            Text(pet.quality.name)
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(pet.quality.color)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Text("重生效果")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let nextQ = pet.quality.nextQuality {
                            rebirthInfoRow(
                                title: "品质提升",
                                oldValue: pet.quality.name,
                                newValue: nextQ.name,
                                oldColor: pet.quality.color,
                                newColor: nextQ.color
                            )
                        } else {
                            rebirthInfoRow(
                                title: "品质",
                                oldValue: pet.quality.name,
                                newValue: pet.quality.name + "(保持)",
                                oldColor: pet.quality.color,
                                newColor: pet.quality.color
                            )
                        }
                        
                        HStack {
                            Text("等级")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("Lv.\(pet.level)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.red)
                                .strikethrough()
                            Text("→")
                                .foregroundColor(.white.opacity(0.5))
                            Text("Lv.1")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("属性分配")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("按新品质总点数随机分配")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("钻石奖励")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("💎 +\(pet.quality.rebirthDiamondReward)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    .padding(.horizontal)
                    
                    HStack(spacing: 6) {
                        Text("⚠️")
                        Text("重生后会进入孵化，孵化完成才生成新宠")
                            .font(.system(size: Constants.FontSize.small))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal)
                }
            }
            
            VStack(spacing: 10) {
                Button(action: startRebirthHatching) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                        Text("确认重生")
                            .font(.system(size: Constants.FontSize.large, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Constants.CornerRadius.large)
                }
                .disabled(!pet.canRebirth())
                
                if !pet.canRebirth() {
                    Text("需达到 Lv.99 才可重生")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.orange)
                }
                
                Button(action: { dismiss() }) {
                    Text("取消")
                        .font(.system(size: Constants.FontSize.large, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Constants.Colors.darkGray)
                        .cornerRadius(Constants.CornerRadius.large)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 孵化界面
    private var hatchingView: some View {
        let remaining = gameState.hatchingRemainingSeconds()
        
        return VStack(spacing: 16) {
            HStack {
                Text("🥚")
                    .font(.system(size: 24))
                Text("孵化中")
                    .font(.system(size: Constants.FontSize.title, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            
            Spacer()
            
            Text("\(pet.emoji)")
                .font(.system(size: 60))
            
            Text("新宠物正在孵化...")
                .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                .foregroundColor(.white)
            
            Text(formatTime(remaining))
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(.yellow)
            
            VStack(spacing: 8) {
                Text("快速孵化：每次消耗 10 钻石减少 10 分钟")
                    .font(.system(size: Constants.FontSize.small))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    _ = gameState.speedUpHatching()
                }) {
                    Text("⚡ 快速孵化")
                        .font(.system(size: Constants.FontSize.medium, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Constants.Colors.purple)
                        .cornerRadius(Constants.CornerRadius.large)
                }
                .disabled(gameState.player.diamonds < 10 || remaining == 0)
            }
            .padding(.horizontal)
            
            Button(action: finishHatchingIfReady) {
                Text(remaining == 0 ? "完成孵化" : "等待孵化完成")
                    .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(remaining == 0 ? Color.green : Color.gray)
                    .cornerRadius(Constants.CornerRadius.large)
            }
            .disabled(remaining != 0)
            .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text("稍后再来")
                    .font(.system(size: Constants.FontSize.small))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
    
    // MARK: - 重生结果界面
    private var rebirthResultView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 20)
                    
                    Text("✨ 孵化完成！✨")
                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text(pet.emoji)
                        .font(.system(size: 60))
                    
                    Text(pet.name)
                        .font(.system(size: Constants.FontSize.large, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if oldQuality != newQuality {
                        HStack(spacing: 8) {
                            Text(oldQuality.name)
                                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(oldQuality.color)
                                .cornerRadius(8)
                            
                            Text("→")
                                .font(.system(size: Constants.FontSize.large))
                                .foregroundColor(.yellow)
                            
                            Text(newQuality.name)
                                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(newQuality.color)
                                .cornerRadius(8)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("新属性")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("🧠")
                                Text("\(newIntelligence)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            VStack(spacing: 4) {
                                Text("💚")
                                Text("\(newStamina)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            VStack(spacing: 4) {
                                Text("💪")
                                Text("\(newStrength)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    .padding(.horizontal)
                    
                    HStack(spacing: 8) {
                        Text("💎")
                        Text("+\(rebirthReward) 钻石")
                            .font(.system(size: Constants.FontSize.large, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                }
            }
            
            Button(action: { dismiss() }) {
                Text("返回")
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
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
    
    // MARK: - Actions
    
    private func startRebirthHatching() {
        oldQuality = pet.quality
        if let reward = gameState.startRebirthHatching() {
            rebirthReward = reward
        }
    }
    
    private func finishHatchingIfReady() {
        guard gameState.completeHatchingIfReady() else { return }
        newQuality = pet.quality
        newIntelligence = pet.intelligence
        newStamina = pet.stamina
        newStrength = pet.strength
        withAnimation(.easeInOut(duration: 0.4)) {
            showResult = true
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    // MARK: - Helper Views
    
    private func rebirthInfoRow(title: String, oldValue: String, newValue: String, oldColor: Color, newColor: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: Constants.FontSize.small))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(oldValue)
                .font(.system(size: Constants.FontSize.small, weight: .bold))
                .foregroundColor(oldColor)
            Text("→")
                .foregroundColor(.white.opacity(0.5))
            Text(newValue)
                .font(.system(size: Constants.FontSize.small, weight: .bold))
                .foregroundColor(newColor)
        }
        .padding(.horizontal)
    }
}

#Preview {
    RebirthView(gameState: GameStateManager())
}
