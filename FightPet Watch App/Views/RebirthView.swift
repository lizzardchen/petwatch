import SwiftUI

/// 重生界面
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
    
    var body: some View {
        ZStack {
            // 背景
            Constants.Colors.darkBackground
                .ignoresSafeArea()
            
            if showResult {
                rebirthResultView
            } else {
                rebirthConfirmView
            }
        }
    }
    
    // MARK: - 重生确认界面
    private var rebirthConfirmView: some View {
        VStack(spacing: 0) {
            // 标题栏
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
                    // 当前宠物信息
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
                        
                        if pet.rebirthCount > 0 {
                            Text("已重生 \(pet.rebirthCount) 次")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    
                    // 分隔线
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal)
                    
                    // 重生效果预览
                    VStack(spacing: 12) {
                        Text("重生效果")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // 品质变化
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
                        
                        // 等级重置
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
                        
                        // 属性重新分配
                        let newTotal = pet.rebirthQuality().totalStatsPoints
                        HStack {
                            Text("属性总点数")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(pet.intelligence + pet.stamina + pet.strength)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(.white)
                            Text("→")
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(newTotal)")
                                .font(.system(size: Constants.FontSize.small, weight: .bold))
                                .foregroundColor(newTotal > pet.intelligence + pet.stamina + pet.strength ? .green : .white)
                        }
                        .padding(.horizontal)
                        
                        // 钻石奖励
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
                    
                    // 警告提示
                    HStack(spacing: 6) {
                        Text("⚠️")
                        Text("重生后等级归1，属性随机重新分配")
                            .font(.system(size: Constants.FontSize.small))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal)
                }
            }
            
            // 底部按钮
            VStack(spacing: 10) {
                // 重生按钮
                Button(action: performRebirth) {
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
                
                // 取消按钮
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
    
    // MARK: - 重生结果界面
    private var rebirthResultView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 20)
                    
                    // 成功标题
                    Text("✨ 重生成功！✨")
                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    // 宠物头像
                    Text(pet.emoji)
                        .font(.system(size: 60))
                    
                    Text(pet.name)
                        .font(.system(size: Constants.FontSize.large, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // 品质变化
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
                    
                    // 新属性
                    VStack(spacing: 8) {
                        Text("新属性分配")
                            .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("🧠")
                                    .font(.system(size: 20))
                                Text("\(newIntelligence)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.purple)
                                Text("智力")
                                    .font(.system(size: Constants.FontSize.small))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            VStack(spacing: 4) {
                                Text("💚")
                                    .font(.system(size: 20))
                                Text("\(newStamina)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.green)
                                Text("体力")
                                    .font(.system(size: Constants.FontSize.small))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            VStack(spacing: 4) {
                                Text("💪")
                                    .font(.system(size: 20))
                                Text("\(newStrength)")
                                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                                    .foregroundColor(.red)
                                Text("力量")
                                    .font(.system(size: Constants.FontSize.small))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    .padding(.horizontal)
                    
                    // 钻石奖励
                    HStack(spacing: 8) {
                        Text("💎")
                            .font(.system(size: 24))
                        Text("+\(rebirthReward) 钻石")
                            .font(.system(size: Constants.FontSize.large, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .background(Constants.Colors.darkGray.opacity(0.3))
                    .cornerRadius(Constants.CornerRadius.large)
                    
                    // 重生次数
                    Text("第 \(pet.rebirthCount) 次重生")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // 确定按钮
            Button(action: { dismiss() }) {
                Text("太好了！")
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
    
    // MARK: - Actions
    
    private func performRebirth() {
        oldQuality = pet.quality
        
        if let reward = gameState.rebirthPet() {
            rebirthReward = reward
            newQuality = pet.quality
            newIntelligence = pet.intelligence
            newStamina = pet.stamina
            newStrength = pet.strength
            
            withAnimation(.easeInOut(duration: 0.5)) {
                showResult = true
            }
        }
    }
}

#Preview {
    RebirthView(gameState: GameStateManager())
}
