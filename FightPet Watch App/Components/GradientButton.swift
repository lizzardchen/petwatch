import SwiftUI

/// 渐变按钮组件
struct GradientButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    let screenWidth: CGFloat
    
    init(title: String,
         icon: String? = nil,
         gradient: LinearGradient = Constants.Colors.redGradient,
         screenWidth: CGFloat = 200,
         action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.screenWidth = screenWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutConstants.scaledWidth(LayoutConstants.ActionButton.iconTextSpacing, screenWidth: screenWidth)) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.ActionButton.iconSize, screenWidth: screenWidth)))
                }
                Text(title)
                    .font(.system(size: LayoutConstants.scaledWidth(LayoutConstants.ActionButton.fontSize, screenWidth: screenWidth), weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.scaledWidth(LayoutConstants.ActionButton.height, screenWidth: screenWidth))
            .background(gradient)
            .cornerRadius(LayoutConstants.scaledWidth(LayoutConstants.ActionButton.cornerRadius, screenWidth: screenWidth))
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
