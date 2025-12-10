import SwiftUI

/// 顶部信息栏
struct TopBar: View {
    let diamonds: Int
    let power: Int
    let onAddDiamonds: () -> Void
    let screenWidth: CGFloat
    let allocatedHeight: CGFloat  // 分配给TopBar的高度
    
    var body: some View {
        // 基于 allocatedHeight 计算所有内部尺寸
        let topPadding = allocatedHeight * LayoutConstants.FixedSectionLayout.TopBar.topPaddingRatio
        let contentHeight = allocatedHeight * LayoutConstants.FixedSectionLayout.TopBar.contentHeightRatio
        let bottomPadding = allocatedHeight * LayoutConstants.FixedSectionLayout.TopBar.bottomPaddingRatio
        let buttonSize = contentHeight * LayoutConstants.FixedSectionLayout.TopBar.buttonSizeRatio
        let fontSize: CGFloat = buttonSize * 0.7
        let iconSize: CGFloat = buttonSize * 0.9
        let spacing: CGFloat = screenWidth * 0.02
        
        HStack(alignment: .center, spacing: 8) {
            // 钻石（无背景）
            HStack(alignment: .center, spacing: spacing) {
                Text("💎")
                    .font(.system(size: iconSize))
                Text("\(diamonds)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: true, vertical: false)
                
                // 加号按钮
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: buttonSize))
                    .foregroundColor(.cyan)
                    .frame(width: buttonSize + 4, height: buttonSize + 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAddDiamonds()
                    }
                    .zIndex(999)
            }
            .fixedSize()
            
            Spacer()
        }
        .frame(height: contentHeight)       // 限制内容区高度
        .padding(.top, topPadding)           // 加上顶部padding
        .padding(.bottom, bottomPadding)     // 加上底部padding
        .frame(height: allocatedHeight)      // 最外层严格限制总高度
        .zIndex(100)
    }
}

#Preview {
    TopBar(
        diamonds: 1521,
        power: 44,
        onAddDiamonds: {},
        screenWidth: 184,
        allocatedHeight: 224 * 0.4 * 0.32
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
