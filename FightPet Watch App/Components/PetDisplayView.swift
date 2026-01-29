import SwiftUI

/// 宠物展示区
struct PetDisplayView: View {
    let pet: Pet
    let screenWidth: CGFloat
    @State private var isEditingName = false
    @State private var editingName = ""
    @EnvironmentObject var gameState: GameStateManager
    
    var body: some View {
        // 基于屏幕宽度计算字体大小
        let nameFontSize = screenWidth * 0.06
        let pwrFontSize = screenWidth * 0.065
        let statFontSize = screenWidth * 0.055
        let smallFontSize = screenWidth * 0.045
        let iconSize = screenWidth * 0.07
        
        VStack(spacing: 4) {
            // 宠物头像 + 品质徽章
            ZStack(alignment: .topTrailing) {
                Text(pet.emoji)
                    .font(.system(size: 64))
                
                // 品质徽章
                Text(pet.quality.name)
                    .font(.system(size: smallFontSize, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(pet.quality.color)
                    .cornerRadius(8)
                    .offset(x: 10, y: -5)
            }
            
            // 宠物名称（带编辑功能）
            if isEditingName {
                // 编辑模式
                HStack(spacing: 8) {
                    TextField("", text: $editingName)
                        .font(.system(size: nameFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Constants.Colors.purple.opacity(0.8))
                        .cornerRadius(20)
                    
                    Button(action: {
                        if !editingName.isEmpty {
                            gameState.updatePetName(editingName)
                        }
                        isEditingName = false
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        editingName = pet.name
                        isEditingName = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
            } else {
                // 显示模式
                HStack(spacing: 4) {
                    Text(pet.name)
                        .font(.system(size: nameFontSize, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        editingName = pet.name
                        isEditingName = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Constants.Colors.purple.opacity(0.6))
                .cornerRadius(20)
            }
            
            // 战力显示
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(.orange)
                Text("PWR: \(pet.power)")
                    .font(.system(size: pwrFontSize, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            // 基础属性（三围）
            VStack(spacing: 4) {
                Text("基础属性")
                    .font(.system(size: smallFontSize, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    // 智力
                    VStack(spacing: 2) {
                        Text("🧠")
                            .font(.system(size: iconSize))
                        Text("\(pet.intelligence)")
                            .font(.system(size: statFontSize, weight: .bold))
                            .foregroundColor(.purple)
                        Text("智力")
                            .font(.system(size: smallFontSize))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // 体力
                    VStack(spacing: 2) {
                        Text("💚")
                            .font(.system(size: iconSize))
                        Text("\(pet.stamina)")
                            .font(.system(size: statFontSize, weight: .bold))
                            .foregroundColor(.green)
                        Text("体力")
                            .font(.system(size: smallFontSize))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // 力量
                    VStack(spacing: 2) {
                        Text("💪")
                            .font(.system(size: iconSize))
                        Text("\(pet.strength)")
                            .font(.system(size: statFontSize, weight: .bold))
                            .foregroundColor(.red)
                        Text("力量")
                            .font(.system(size: smallFontSize))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)
        }
    }
}

#Preview {
    PetDisplayView(pet: .preview, screenWidth: 184)
        .environmentObject(GameStateManager())
        .padding()
        .background(
            LinearGradient(
                colors: [Constants.Colors.purple, Constants.Colors.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}

