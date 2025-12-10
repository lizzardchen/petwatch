import SwiftUI

/// 宠物展示区
struct PetDisplayView: View {
    let pet: Pet
    let screenWidth: CGFloat
    @State private var isEditingName = false
    @State private var editingName = ""
    @EnvironmentObject var gameState: GameStateManager
    
    var body: some View {
        // 基于屏幕宽度计算字体大小，以匹配设计图比例
        let nameFontSize = screenWidth * 0.06  // ~11pt for 184px width
        let pwrFontSize = screenWidth * 0.065   // ~12pt for 184px width
        let statFontSize = screenWidth * 0.06 // ~11pt for 184px width
        let iconSize = screenWidth * 0.075     // ~14pt for 184px width
        
        VStack(spacing: 4) {  // 紧凑间距
            // 宠物头像
            Text(pet.emoji)
                .font(.system(size: 64))
            
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
                    
                    // 确认按钮
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
                    
                    // 取消按钮
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
            
            // 战力和属性（匹配设计图）
            VStack(spacing: 6) {  // 紧凑间距
                // PWR 战力
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.orange)
                    Text("PWR: \(pet.power)")
                        .font(.system(size: pwrFontSize, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                // 快乐值和亲密值
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Text("✨")
                            .font(.system(size: iconSize))
                        Text("\(pet.happiness)")
                            .font(.system(size: statFontSize, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Text("❤️")
                            .font(.system(size: iconSize))
                        Text("\(pet.intimacy)")
                            .font(.system(size: statFontSize, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .cornerRadius(12)
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
