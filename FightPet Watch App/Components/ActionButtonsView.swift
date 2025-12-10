import SwiftUI

/// 功能按钮区域
struct ActionButtonsView: View {
    let screenWidth: CGFloat
    let allocatedHeight: CGFloat
    let onRanking: () -> Void
    let onActivity: () -> Void
    
    var body: some View {
        let buttonHeight = allocatedHeight * LayoutConstants.FixedSectionLayout.ActionButtons.buttonHeightRatio
        let topMargin = allocatedHeight * LayoutConstants.FixedSectionLayout.ActionButtons.topMarginRatio
        let bottomMargin = allocatedHeight * LayoutConstants.FixedSectionLayout.ActionButtons.bottomMarginRatio
        
        HStack(spacing: screenWidth * 0.04) {
            GradientButton(
                title: "排行榜",
                icon: "🏆",
                gradient: LinearGradient(
                    colors: [Color(red: 0.7, green: 0.4, blue: 0.4),
                            Color(red: 0.6, green: 0.3, blue: 0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                screenWidth: screenWidth,
                height: buttonHeight
            ) {
                onRanking()
            }
            
            GradientButton(
                title: "运动",
                icon: "🏃",
                gradient: Constants.Colors.blueGradient,
                screenWidth: screenWidth,
                height: buttonHeight
            ) {
                onActivity()
            }
        }
        .frame(height: buttonHeight)         // 限制按钮高度
        .padding(.top, topMargin)            // 加上顶部margin
        .padding(.bottom, bottomMargin)      // 加上底部margin
        .frame(height: allocatedHeight)      // 最外层严格限制总高度
    }
}

#Preview {
    ActionButtonsView(
        screenWidth: 184,
        allocatedHeight: 224 * 0.4 * 0.25,
        onRanking: {},
        onActivity: {}
    )
    .padding()
    .background(
        LinearGradient(
            colors: [Constants.Colors.purple, Constants.Colors.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
