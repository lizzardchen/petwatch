import SwiftUI

/// 宠物卡片组件
struct PetCard: View {
    let pet: Pet
    var onRebirth: (() -> Void)? = nil
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    
    var body: some View {
        // 使用精确的布局常量，并根据屏幕尺寸缩放
        let hPadding = LayoutConstants.scaledWidth(LayoutConstants.PetCard.horizontalPadding, screenWidth: screenWidth)
        let vPadding = LayoutConstants.scaledWidth(LayoutConstants.PetCard.verticalPadding, screenWidth: screenWidth)
        let spacing = LayoutConstants.scaledWidth(LayoutConstants.PetCard.spacing, screenWidth: screenWidth)
        let cornerRadius = LayoutConstants.scaledWidth(LayoutConstants.PetCard.cornerRadius, screenWidth: screenWidth)
        
        // 计算卡片内容区域高度（去掉padding后的高度）
        let contentHeight = screenHeight - (vPadding * 2)
        
        // 根据比例计算每行的固定高度
        let firstRowHeight = contentHeight * LayoutConstants.PetCard.firstRowHeightRatio
        let secondRowHeight = contentHeight * LayoutConstants.PetCard.secondRowHeightRatio
        let rowSpacing = contentHeight * LayoutConstants.PetCard.rowSpacingRatio
        
        VStack(spacing: rowSpacing) {
            // 第1行：等级 + 进度条 + 经验值 + 重生按钮（全部在一行）
            HStack(spacing: LayoutConstants.scaledWidth(4, screenWidth: screenWidth)) {
                // 等级
                HStack(spacing: LayoutConstants.scaledWidth(3, screenWidth: screenWidth)) {
                    Text("⭐")
                        .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.levelIconSize, screenWidth: screenWidth)))
                    Text("Lv.\(pet.level)")
                        .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.levelFontSize, screenWidth: screenWidth), weight: .bold))
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.white)

                // // 进度条
                // CustomProgressBar(current: pet.exp,
                //                 max: pet.expRequiredForNextLevel(),
                //                 color: Constants.Colors.purple,
                //                 height: LayoutConstants.scaledHeight(LayoutConstants.PetCard.progressBarHeight, screenHeight: screenHeight))
                //     .frame(maxWidth: .infinity)
                
                // 经验值
                Text("\(pet.exp)/\(pet.expRequiredForNextLevel())")
                    .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.expFontSize, screenWidth: screenWidth)))
                    .foregroundColor(.white.opacity(0.7))
                    .minimumScaleFactor(0.3)
                    .fixedSize(horizontal: true, vertical: false)
                
                // 重生按钮（当达到99级时显示）
                if pet.level >= 99 {
                    Button(action: {
                        onRebirth?()
                    }) {
                        HStack(spacing: LayoutConstants.scaledWidth(3, screenWidth: screenWidth)) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.rebirthButtonIconSize, screenWidth: screenWidth), weight: .semibold))
                            Text("重生")
                                .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.rebirthButtonFontSize, screenWidth: screenWidth), weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, LayoutConstants.scaledWidth(LayoutConstants.PetCard.rebirthButtonHPadding, screenWidth: screenWidth))
                        .padding(.vertical, LayoutConstants.scaledWidth(LayoutConstants.PetCard.rebirthButtonVPadding, screenWidth: screenWidth))
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(LayoutConstants.scaledWidth(LayoutConstants.PetCard.rebirthButtonCornerRadius, screenWidth: screenWidth))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: firstRowHeight)
            
            // 第2行：成长速率和睡眠值
            HStack(spacing: LayoutConstants.scaledWidth(LayoutConstants.PetCard.statSpacing * 2, screenWidth: screenWidth)) {
                HStack(spacing: LayoutConstants.scaledWidth(LayoutConstants.PetCard.statSpacing, screenWidth: screenWidth)) {
                    Text("📈")
                        .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.statIconSize, screenWidth: screenWidth)))
                    Text("+\(pet.expPerMinute)/分钟")
                        .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.statFontSize, screenWidth: screenWidth)))
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: LayoutConstants.scaledWidth(LayoutConstants.PetCard.statSpacing, screenWidth: screenWidth)) {
                    Text("🌙")
                        .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.statIconSize, screenWidth: screenWidth)))
                    Text("睡眠+\(pet.sleepBonus)")
                        .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.PetCard.statFontSize, screenWidth: screenWidth)))
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.white.opacity(0.8))
            }
            .frame(height: secondRowHeight)
        }
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .background(Constants.Colors.darkGray.opacity(0.6))
        .cornerRadius(cornerRadius)
    }
}

#Preview {
    PetCard(pet: .preview, 
            screenWidth: 184,  // 典型的 Apple Watch 宽度
            screenHeight: 224) // 典型的 Apple Watch 高度
        .padding()
        .background(
            LinearGradient(
                colors: [Constants.Colors.purple, Constants.Colors.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
