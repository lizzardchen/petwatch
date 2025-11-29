import SwiftUI

/// 宠物卡片组件
struct PetCard: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 12) {
            // 头部信息栏
            HStack {
                HStack(spacing: 6) {
                    Text("⭐")
                    Text("Lv.\(pet.level)")
                        .font(.system(size: Constants.FontSize.medium, weight: .bold))
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Text("\(pet.exp)/\(pet.expRequiredForNextLevel())")
                    .font(.system(size: Constants.FontSize.small))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 经验进度条
            CustomProgressBar(current: pet.exp,
                            max: pet.expRequiredForNextLevel(),
                            color: Constants.Colors.purple)
            
            // 成长速率和睡眠值
            HStack {
                HStack(spacing: 4) {
                    Text("📈")
                    Text("+\(pet.expPerMinute)/分钟")
                        .font(.system(size: Constants.FontSize.small))
                }
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("🌙")
                    Text("睡眠+\(pet.sleepBonus)")
                        .font(.system(size: Constants.FontSize.small))
                }
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Constants.Colors.darkGray.opacity(0.6))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

#Preview {
    PetCard(pet: .preview)
        .padding()
        .background(
            LinearGradient(
                colors: [Constants.Colors.purple, Constants.Colors.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
