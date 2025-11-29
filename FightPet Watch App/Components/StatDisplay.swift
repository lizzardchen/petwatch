import SwiftUI

/// 属性显示组件
struct StatDisplay: View {
    let icon: String
    let name: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 14))
            
            Text(name)
                .font(.system(size: Constants.FontSize.small))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text("\(value)")
                .font(.system(size: Constants.FontSize.medium, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 4) {
        StatDisplay(icon: "🧠", name: "智慧", value: 11, color: .purple)
        StatDisplay(icon: "💪", name: "体力", value: 11, color: .green)
        StatDisplay(icon: "⚡", name: "敏捷", value: 11, color: .blue)
    }
    .background(Constants.Colors.darkGray.opacity(0.5))
    .cornerRadius(12)
    .padding()
    .background(Color.black)
}
