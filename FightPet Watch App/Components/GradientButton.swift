import SwiftUI

/// 渐变按钮组件
struct GradientButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    let screenWidth: CGFloat
    let height: CGFloat  // 新增：明确的高度参数
    
    init(title: String,
         icon: String? = nil,
         gradient: LinearGradient = Constants.Colors.redGradient,
         screenWidth: CGFloat = 200,
         height: CGFloat? = nil,  // 可选参数，兼容旧代码
         action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.screenWidth = screenWidth
        // 如果没有传入height，使用旧的计算方式作为默认值
        self.height = height ?? LayoutConstants.scaledWidth(LayoutConstants.ActionButton.height, screenWidth: screenWidth)
        self.action = action
    }
    
    var body: some View {
        let iconSize = height * 0.5
        let fontSize = height * 0.45
        let cornerRadius = screenWidth * 0.04
        
        Button(action: action) {
            HStack(spacing: screenWidth * 0.02) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: iconSize))
                }
                Text(title)
                    .font(.system(size: fontSize, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(gradient)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        GradientButton(title: "排行榜", icon: "🏆", screenWidth: 184) {}
        GradientButton(title: "运动", icon: "🏃", gradient: Constants.Colors.blueGradient, screenWidth: 184) {}
        GradientButton(title: "分享游戏", gradient: Constants.Colors.greenGradient, screenWidth: 184) {}
    }
    .padding()
    .background(Color.black)
}
