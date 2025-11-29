import SwiftUI

/// 进度条组件
struct CustomProgressBar: View {
    let current: Int
    let max: Int
    let color: Color
    let height: CGFloat
    
    init(current: Int,
         max: Int,
         color: Color = .green,
         height: CGFloat = 8) {
        self.current = current
        self.max = max
        self.color = color
        self.height = height
    }
    
    private var progress: Double {
        guard max > 0 else { return 0 }
        return Double(current) / Double(max)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                
                // 前景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * progress),
                           height: height)
                    .animation(Constants.Animation.spring, value: current)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        VStack(alignment: .leading) {
            Text("经验: 153/18069385668231789000")
                .font(.caption)
                .foregroundColor(.white)
            CustomProgressBar(current: 153, max: 1806, color: .purple)
        }
        
        VStack(alignment: .leading) {
            Text("睡眠质量: 5/10")
                .font(.caption)
                .foregroundColor(.white)
            CustomProgressBar(current: 5, max: 10, color: .blue)
        }
        
        VStack(alignment: .leading) {
            Text("血量: 75/100")
                .font(.caption)
                .foregroundColor(.white)
            CustomProgressBar(current: 75, max: 100, color: .green, height: 12)
        }
    }
    .padding()
    .background(Color.black)
}
