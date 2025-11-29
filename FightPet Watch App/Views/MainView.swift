import SwiftUI

/// 宠物主界面
struct MainView: View {
    @StateObject private var gameState = GameStateManager()
    @State private var showUpgradeOptions = false
    @State private var showRanking = false
    @State private var showActivity = false
    @State private var showStore = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    // 顶部信息栏
                    TopBar(diamonds: gameState.player.diamonds,
                           power: gameState.player.currentPet.power,
                           onAddDiamonds: { showStore = true })
                    .padding(.horizontal)
                    
                    // 宠物状态卡片
                    PetCard(pet: gameState.player.currentPet)
                        .padding(.horizontal)
                    
                    // 功能按钮
                    HStack(spacing: 12) {
                        GradientButton(title: "排行榜",
                                     icon: "🏆",
                                     gradient: LinearGradient(
                                        colors: [Color(red: 0.7, green: 0.4, blue: 0.4),
                                                Color(red: 0.6, green: 0.3, blue: 0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                     )) {
                            showRanking = true
                        }
                        
                        GradientButton(title: "运动",
                                     icon: "🏃",
                                     gradient: Constants.Colors.blueGradient) {
                            showActivity = true
                        }
                    }
                    .padding(.horizontal)
                    
                    // 宠物展示区
                    PetDisplayView(pet: gameState.player.currentPet)
                        .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // 升级选项
                    if showUpgradeOptions {
                        UpgradeOptionsView()
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom))
                    }
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    colors: [Constants.Colors.purple, Constants.Colors.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .sheet(isPresented: $showRanking) {
                RankingView()
            }
            .sheet(isPresented: $showStore) {
                StoreView(gameState: gameState)
            }
        }
    }
}

/// 顶部信息栏
struct TopBar: View {
    let diamonds: Int
    let power: Int
    let onAddDiamonds: () -> Void
    
    var body: some View {
        HStack {
            // 钻石
            HStack(spacing: 6) {
                Text("💎")
                    .font(.system(size: 16))
                Text("\(diamonds)")
                    .font(.system(size: Constants.FontSize.medium, weight: .bold))
                    .foregroundColor(.white)
                
                Button(action: onAddDiamonds) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Constants.Colors.darkGray.opacity(0.6))
            .cornerRadius(20)
            
            Spacer()
            
            // 战力
            HStack(spacing: 6) {
                Text("⚡")
                    .font(.system(size: 16))
                Text("战力 \(power)")
                    .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Constants.Colors.darkGray.opacity(0.6))
            .cornerRadius(20)
        }
    }
}

/// 宠物展示区
struct PetDisplayView: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 16) {
            // 宠物头像
            Text(pet.emoji)
                .font(.system(size: 80))
            
            // 宠物名称
            Text(pet.name)
                .font(.system(size: Constants.FontSize.large, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Constants.Colors.purple.opacity(0.6))
                .cornerRadius(20)
            
            // 快乐和亲密值
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("😊")
                    Text("快乐: \(pet.happiness)")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 4) {
                    Text("❤️")
                    Text("亲密: \(pet.intimacy)")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.white)
                }
            }
            
            // 三维属性
            VStack(spacing: 4) {
                StatDisplay(icon: "🧠", name: "智慧", value: pet.intelligence, color: .purple)
                StatDisplay(icon: "💪", name: "体力", value: pet.stamina, color: .green)
                StatDisplay(icon: "⚡", name: "敏捷", value: pet.agility, color: .blue)
            }
            .background(Constants.Colors.darkGray.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

/// 升级选项视图
struct UpgradeOptionsView: View {
    let items: [UpgradeItem] = [
        UpgradeItem(type: .petBed, level: 2),
        UpgradeItem(type: .foodBowl, level: 1),
        UpgradeItem(type: .toy, level: 1)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("小窝升级")
                .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        UpgradeItemCard(item: item)
                    }
                }
            }
        }
        .padding()
        .background(Constants.Colors.darkGray.opacity(0.3))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

/// 升级物品卡片
struct UpgradeItemCard: View {
    let item: UpgradeItem
    
    var body: some View {
        VStack(spacing: 8) {
            Text(item.type.icon)
                .font(.system(size: 40))
            
            Text(item.type.rawValue)
                .font(.system(size: Constants.FontSize.small, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 80)
        .background(Constants.Colors.darkGray.opacity(0.8))
        .cornerRadius(12)
    }
}

#Preview {
    MainView()
}
