import SwiftUI

/// 渐变按钮组件
struct GradientButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    
    init(title: String,
         icon: String? = nil,
         gradient: LinearGradient = Constants.Colors.redGradient,
         action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 16))
                }
                Text(title)
                    .font(.system(size: Constants.FontSize.medium, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(gradient)
            .cornerRadius(Constants.CornerRadius.button)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        GradientButton(title: "排行榜", icon: "🏆") {}
        GradientButton(title: "运动", icon: "🏃", gradient: Constants.Colors.blueGradient) {}
        GradientButton(title: "分享游戏", gradient: Constants.Colors.greenGradient) {}
    }
    .padding()
    .background(Color.black)
}
