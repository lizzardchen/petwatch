import SwiftUI

/// 宠物卡片组件
struct PetCard: View {
    let pet: Pet
    @ObservedObject var gameState: GameStateManager
    var onRebirth: (() -> Void)? = nil
    let screenWidth: CGFloat
    let allocatedHeight: CGFloat  // 新增：分配给PetCard的高度
    
    var body: some View {
        let isRebirthTestingEnabled = true
        let canOpenRebirth = isRebirthTestingEnabled || pet.level >= 99 || gameState.player.isHatching
        
        // 基于 allocatedHeight 计算所有尺寸
        let vMargin = allocatedHeight * LayoutConstants.FixedSectionLayout.PetCard.verticalMarginRatio
        let contentHeight = allocatedHeight * LayoutConstants.FixedSectionLayout.PetCard.contentHeightRatio
        let hPadding = screenWidth * 0.02
        let vPadding = contentHeight * LayoutConstants.FixedSectionLayout.PetCard.innerPaddingRatio
        let innerContentHeight = contentHeight - (vPadding * 2)
        
        let firstRowHeight = innerContentHeight * LayoutConstants.FixedSectionLayout.PetCard.firstRowHeightRatio
        let secondRowHeight = innerContentHeight * LayoutConstants.FixedSectionLayout.PetCard.secondRowHeightRatio
        let rowSpacing = innerContentHeight * LayoutConstants.FixedSectionLayout.PetCard.rowSpacingRatio
        
        let cornerRadius = screenWidth * 0.04
        
        // 字体大小基于行高计算
        let levelFontSize = firstRowHeight * 0.55
        let expFontSize = firstRowHeight * 0.55
        let statFontSize = secondRowHeight * 0.55
        let iconSize = secondRowHeight * 0.55
        
        // 计算实时经验值（每分钟 = 每秒 × 60）
        let expPerMinute = Int(gameState.totalExpPerSecond() * 60)
        let sleepBonus = Int(gameState.getCurrentSleepBonus())
        
        VStack(alignment: .center, spacing: rowSpacing) {
            // 第1行：等级 + 经验值 + 重生按钮
            HStack(spacing: screenWidth * 0.02) {
                // 等级
                HStack(spacing: screenWidth * 0.01) {
                    Text("⭐Lv.\(pet.level)")
                        .font(.system(size: levelFontSize, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .foregroundColor(.white)
                .layoutPriority(1)
                .fixedSize(horizontal: true, vertical: false)

                // 经验值
                Text("\(pet.exp)/\(pet.expRequiredForNextLevel())")
                    .font(.system(size: expFontSize))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    if canOpenRebirth {
                        onRebirth?()
                    }
                }) {
                    HStack(spacing: screenWidth * 0.015) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: expFontSize * 0.9, weight: .semibold))
                        Text(gameState.player.isHatching ? "孵化" : "重生")
                            .font(.system(size: expFontSize * 0.9, weight: .semibold))
                    }
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(.white)
                    .padding(.horizontal, screenWidth * 0.035)
                    .padding(.vertical, firstRowHeight * 0.15)
                    .background(
                        LinearGradient(
                            colors: canOpenRebirth ? [Color.orange, Color.red] : [Color.gray, Color.gray.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(cornerRadius)
                }
                .buttonStyle(.plain)
                .layoutPriority(2)
                .disabled(!canOpenRebirth)
            }
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .frame(height: firstRowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.Colors.darkGray.opacity(0.7))
            .cornerRadius(cornerRadius)
            
            // 第2行：成长速率和睡眠值
            HStack(spacing: screenWidth * 0.04) {
                HStack(spacing: screenWidth * 0.015) {
                    Text("📈")
                        .font(.system(size: iconSize))
                    Text("+\(expPerMinute)/分钟")
                        .font(.system(size: statFontSize))
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if gameState.player.isExpCardActive {
                    HStack(spacing: screenWidth * 0.015) {
                        Text("⭐×2")
                            .font(.system(size: statFontSize, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundColor(.yellow)
                } else {
                    HStack(spacing: screenWidth * 0.015) {
                        Text("🌙睡眠+\(sleepBonus)")
                            .font(.system(size: statFontSize))
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .frame(height: secondRowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.Colors.darkGray.opacity(0.7))
            .cornerRadius(cornerRadius)
        }
        .frame(height: contentHeight)            // 限制内容区高度
        .padding(.vertical, vMargin)             // 加上上下margin
        .frame(height: allocatedHeight)          // 最外层严格限制总高度
        .background(Constants.Colors.darkGray.opacity(0.3))
        .cornerRadius(cornerRadius)
    }
}

#Preview {
    PetCard(pet: .preview,
            gameState: GameStateManager(),
            screenWidth: 184,  // 典型的 Apple Watch 宽度
            allocatedHeight: 224 * 0.6) // 典型的 Apple Watch 高度的60%
        .padding()
        .background(
            LinearGradient(
                colors: [Constants.Colors.purple, Constants.Colors.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
