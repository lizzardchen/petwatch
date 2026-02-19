import SwiftUI

/// 商店界面
struct StoreView: View {
    @ObservedObject var gameState: GameStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var showDiamondPurchases = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("商店")
                    .font(.system(size: Constants.FontSize.title, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    if !showDiamondPurchases {
                        // 选择套餐标题
                        VStack(spacing: 12) {
                            Text("💰")
                                .font(.system(size: 50))
                            Text("选择套餐")
                                .font(.system(size: Constants.FontSize.large, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // 双倍经验订阅
                        SubscriptionCard()
                            .padding(.horizontal)
                        
                        // 分隔线
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("钻石充值")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 8)
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        Button(action: { showDiamondPurchases = true }) {
                            Text("查看更多充值选项")
                                .font(.system(size: Constants.FontSize.small))
                                .foregroundColor(.cyan)
                        }
                        .padding(.bottom)
                    } else {
                        // 钻石充值选项
                        DiamondPurchaseView(gameState: gameState)
                            .padding(.horizontal)
                    }
                }
            }
            
            // 关闭按钮
            Button(action: { dismiss() }) {
                Text("关闭")
                    .font(.system(size: Constants.FontSize.large, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Constants.Colors.darkGray)
                    .cornerRadius(Constants.CornerRadius.large)
            }
            .padding()
        }
        .background(Constants.Colors.darkBackground)
    }
}

/// 订阅卡片
struct SubscriptionCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("⭐")
                    Text("双倍经验")
                        .font(.system(size: Constants.FontSize.large, weight: .bold))
                }
                .foregroundColor(.white)
                
                Text("EXP获取速度×2")
                    .font(.system(size: Constants.FontSize.small))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("特权")
                    .font(.system(size: Constants.FontSize.tiny, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(12)
                
                Text("¥18/月")
                    .font(.system(size: Constants.FontSize.large, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple, Color.purple.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(Constants.CornerRadius.large)
    }
}



/// 钻石充值视图
struct DiamondPurchaseView: View {
    @ObservedObject var gameState: GameStateManager
    
    let packages = [
        (amount: 500, price: 6, color: Color.blue, isRecommended: false),
        (amount: 1200, price: 12, color: Color.purple, isRecommended: false),
        (amount: 3000, price: 25, color: Color.orange, isRecommended: true)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                Text("钻石充值")
                    .font(.system(size: Constants.FontSize.medium))
                    .foregroundColor(.white.opacity(0.7))
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.bottom, 8)
            
            ForEach(0..<packages.count, id: \.self) { index in
                DiamondPackageCard(
                    amount: packages[index].amount,
                    price: packages[index].price,
                    color: packages[index].color,
                    isRecommended: packages[index].isRecommended,
                    gameState: gameState
                )
            }
        }
    }
}

/// 钻石套餐卡片
struct DiamondPackageCard: View {
    let amount: Int
    let price: Int
    let color: Color
    let isRecommended: Bool
    @ObservedObject var gameState: GameStateManager
    @State private var showAlert = false
    
    var title: String {
        switch amount {
        case 500: return "小袋钻石"
        case 1200: return "中袋钻石"
        case 3000: return "大袋钻石"
        default: return "钻石礼包"
        }
    }
    
    var body: some View {
        Button(action: {
            gameState.addDiamonds(amount)
            showAlert = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: Constants.FontSize.large, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(amount) 钻石")
                        .font(.system(size: Constants.FontSize.medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isRecommended {
                        Text("推荐")
                            .font(.system(size: Constants.FontSize.tiny, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Text("¥\(price)")
                        .font(.system(size: Constants.FontSize.title, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: isRecommended
                        ? [Color.orange, Color.red]
                        : [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Constants.CornerRadius.large)
        }
        .buttonStyle(.plain)
        .alert("购买成功!", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("获得 \(amount) 钻石!")
        }
    }
}

#Preview {
    StoreView(gameState: GameStateManager())
}
