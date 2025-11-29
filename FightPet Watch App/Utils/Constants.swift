import SwiftUI

/// 应用常量
struct Constants {
    
    // MARK: - Colors
    struct Colors {
        // 主色调
        static let purple = Color(red: 0.42, green: 0.27, blue: 0.76)
        static let purpleLight = Color(red: 0.55, green: 0.36, blue: 0.96)
        static let pink = Color(red: 0.93, green: 0.28, blue: 0.60)
        static let red = Color(red: 0.96, green: 0.25, blue: 0.37)
        
        // 功能色
        static let blue = Color(red: 0.23, green: 0.51, blue: 0.96)
        static let orange = Color(red: 0.96, green: 0.62, blue: 0.04)
        static let green = Color(red: 0.13, green: 0.73, blue: 0.45)
        
        // 灰度
        static let darkGray = Color(red: 0.22, green: 0.25, blue: 0.32)
        static let mediumGray = Color(red: 0.37, green: 0.40, blue: 0.48)
        static let lightGray = Color(red: 0.56, green: 0.59, blue: 0.66)
        
        // 背景
        static let darkBackground = Color(red: 0.06, green: 0.09, blue: 0.16)
        
        // 渐变
        static let purpleGradient = LinearGradient(
            colors: [purple, purpleLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let redGradient = LinearGradient(
            colors: [orange, red],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let blueGradient = LinearGradient(
            colors: [blue, Color.blue.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let greenGradient = LinearGradient(
            colors: [green, Color.green.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let button: CGFloat = 25
    }
    
    // MARK: - Font Sizes
    struct FontSize {
        static let tiny: CGFloat = 10
        static let small: CGFloat = 12
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let title: CGFloat = 24
    }
    
    // MARK: - Animation
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
    
    // MARK: - Game Constants
    struct Game {
        static let initialDiamonds = 1971
        static let dailyChallenges = 3
        static let shareReward = 100
        static let hatchingTime: TimeInterval = 60 // 60秒
    }
}
