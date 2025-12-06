import SwiftUI

/// 宠物主界面
struct MainView: View {
    @StateObject private var gameState = GameStateManager()
    @State private var showRanking = false
    @State private var showActivity = false
    @State private var showStore = false
    @State private var showRebirth = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            let fixedSectionHeight = screenHeight * LayoutConstants.fixedSectionHeightRatio
            let scrollSectionHeight = screenHeight * (1 - LayoutConstants.fixedSectionHeightRatio)
            
            ZStack {
                // 背景渐变（覆盖整个界面）
                LinearGradient(
                    colors: [Constants.Colors.purple, Constants.Colors.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 固定顶部区域（不滚动）- 占据约35%的高度
                    VStack(spacing: 0) {
                        // 顶部信息栏
                        TopBar(diamonds: gameState.player.diamonds,
                               power: gameState.player.currentPet.power,
                               onAddDiamonds: { showStore = true },
                               screenWidth: screenWidth)
                        .padding(.horizontal, LayoutConstants.scaledWidth(8, screenWidth: screenWidth))
                        .padding(.top, LayoutConstants.scaledHeight(LayoutConstants.TopBar.topMargin, screenHeight: fixedSectionHeight))
                        .padding(.bottom, LayoutConstants.scaledHeight(LayoutConstants.TopBar.bottomMargin, screenHeight: fixedSectionHeight))
                        
                        // 宠物状态卡片
                        PetCard(pet: gameState.player.currentPet,
                               onRebirth: {
                            showRebirth = true
                        },
                        screenWidth: screenWidth,
                        screenHeight: fixedSectionHeight)
                        .padding(.horizontal, LayoutConstants.scaledWidth(4, screenWidth: screenWidth))
                        .padding(.bottom, LayoutConstants.scaledHeight(20, screenHeight: fixedSectionHeight))
                        
                        // 功能按钮
                        HStack(spacing: LayoutConstants.scaledWidth(LayoutConstants.ActionButton.buttonSpacing, screenWidth: screenWidth)) {
                            GradientButton(title: "排行榜",
                                         icon: "🏆",
                                         gradient: LinearGradient(
                                            colors: [Color(red: 0.7, green: 0.4, blue: 0.4),
                                                    Color(red: 0.6, green: 0.3, blue: 0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                         ),
                                         screenWidth: screenWidth) {
                                showRanking = true
                            }
                            
                            GradientButton(title: "运动",
                                         icon: "🏃",
                                         gradient: Constants.Colors.blueGradient,
                                         screenWidth: screenWidth) {
                                showActivity = true
                            }
                        }
                        .padding(.horizontal, LayoutConstants.scaledWidth(8, screenWidth: screenWidth))
                        .padding(.bottom, LayoutConstants.scaledHeight(LayoutConstants.ActionButton.bottomMargin, screenHeight: fixedSectionHeight))
                    }
                    .frame(height: fixedSectionHeight)
                    
                    // 可滚动的底部区域（占据剩余65%）
                    ScrollView {
                        VStack(spacing: scrollSectionHeight * 0.08) {
                            // 宠物展示区
                            PetDisplayView(pet: gameState.player.currentPet,
                                         screenWidth: screenWidth)
                                .padding(.horizontal, screenWidth * 0.04)
                                .padding(.top, scrollSectionHeight * 0.08)
                            
                            // 小窝升级部分
                            UpgradeOptionsView(
                                items: gameState.player.upgradeItems,
                                hourlyIncome: gameState.player.hourlyDiamondIncome(),
                                gameState: gameState,
                                screenWidth: screenWidth
                            )
                            .padding(.horizontal, screenWidth * 0.04)
                            .padding(.bottom, scrollSectionHeight * 0.15)
                        }
                    }
                    .frame(height: scrollSectionHeight)
                } 
            }
        }
        .sheet(isPresented: $showRanking) {
            RankingView()
        }
        .sheet(isPresented: $showStore) {
            StoreView(gameState: gameState)
        }
        .sheet(isPresented: $showRebirth) {
            // TODO: 重生界面（待实现）
            Text("重生界面（待实现）")
        }
    }
}

/// 顶部信息栏
struct TopBar: View {
    let diamonds: Int
    let power: Int
    let onAddDiamonds: () -> Void
    let screenWidth: CGFloat
    
    var body: some View {
        let iconSize: CGFloat = 14
        let fontSize: CGFloat = 13
        let buttonSize: CGFloat = 20
        let spacing: CGFloat = 4
        
        HStack(alignment: .center,spacing: 8) {
            // 钻石（无背景）
            HStack(alignment: .center,spacing: spacing) {
                Text("💎")
                    .font(.system(size: iconSize))
                Text("\(diamonds)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: true, vertical: false)
                
                // 使用 ZStack 确保按钮在最上层
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: buttonSize))
                    .foregroundColor(.cyan)
                    .frame(width: buttonSize + 4, height: buttonSize + 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAddDiamonds()
                    }
                    .zIndex(999)  // 确保在最上层
            }
            //.border(Color.green, width: 2)  // 左侧 HStack 的边界
            .fixedSize()  // 防止 HStack 扩展
            
            Spacer()
            
            // 战力（无背景）
            // HStack(alignment: .center,spacing: spacing) {
            //     Text("⚡")
            //         .font(.system(size: iconSize))
            //     Text("战力 \(power)")
            //         .font(.system(size: fontSize, weight: .semibold))
            //         .foregroundColor(.white)
            // }
            // .border(Color.green, width: 2)  // 左侧 HStack 的边界
        }
        .zIndex(100)  // 确保整个 TopBar 在其他视图之上
    }
}

/// 宠物展示区
struct PetDisplayView: View {
    let pet: Pet
    let screenWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 16) {
            // 宠物头像
            Text(pet.emoji)
                .font(.system(size: 80))
            
            // 宠物名称（带编辑图标）
            HStack(spacing: 4) {
                Text(pet.name)
                    .font(.system(size: Constants.FontSize.large, weight: .semibold))
                    .foregroundColor(.white)
                
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Constants.Colors.purple.opacity(0.6))
            .cornerRadius(20)
            
            // 快乐和亲密值
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("✨")
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
    let items: [UpgradeItem]
    let hourlyIncome: Int
    @ObservedObject var gameState: GameStateManager
    let screenWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题和每小时收益
            HStack {
                Text("小窝升级")
                    .font(.system(size: Constants.FontSize.medium, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("💎")
                    Text("+\(hourlyIncome)/时")
                        .font(.system(size: Constants.FontSize.small))
                        .foregroundColor(.cyan)
                }
            }
            
            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
            
            // 物品横向列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        UpgradeItemCard(item: item, gameState: gameState)
                    }
                }
                .padding(.horizontal, 4)
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
    @ObservedObject var gameState: GameStateManager
    
    // 从 gameState 获取当前物品状态（因为 item 可能已过时）
    private var currentItem: UpgradeItem? {
        gameState.player.upgradeItems.first { $0.id == item.id }
    }
    
    private var displayItem: UpgradeItem {
        currentItem ?? item
    }
    
    var body: some View {
        Button(action: {
            // 处理物品点击
            let current = displayItem
            
            if !current.isUnlocked {
                // 检查解锁条件
                if canUnlock(current) {
                    unlockItem(current)
                }
            } else if current.canUpgrade() {
                upgradeItem(current)
            }
        }) {
            VStack(spacing: 6) {
                // 图标
                if displayItem.isUnlocked {
                    Text(displayItem.type.icon)
                        .font(.system(size: 40))
                } else {
                    ZStack {
                        Text(displayItem.type.icon)
                            .font(.system(size: 40))
                            .opacity(0.3)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                
                // 名称
                Text(displayItem.type.rawValue)
                    .font(.system(size: Constants.FontSize.small, weight: .semibold))
                    .foregroundColor(.white)
                
                // 等级或锁定提示
                if displayItem.isUnlocked {
                    Text("Lv.\(displayItem.level)")
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text(displayItem.unlockRequirement())
                        .font(.system(size: Constants.FontSize.tiny))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(width: 90, height: 110)
            .padding(.vertical, 8)
            .background(Constants.Colors.darkGray.opacity(0.8))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(!canInteractWithItem(displayItem))
        .opacity(canInteractWithItem(displayItem) ? 1.0 : 0.6)
    }
    
    /// 检查是否可以解锁物品
    private func canUnlock(_ item: UpgradeItem) -> Bool {
        switch item.type {
        case .petBed:
            return true // 默认解锁
        case .foodBowl:
            // 需要宠物床满级
            if let petBed = gameState.player.upgradeItems.first(where: { $0.type == .petBed }) {
                return petBed.isMaxLevel
            }
            return false
        case .toy:
            // 需要食物碗满级
            if let foodBowl = gameState.player.upgradeItems.first(where: { $0.type == .foodBowl }) {
                return foodBowl.isMaxLevel
            }
            return false
        }
    }
    
    /// 检查是否可以与物品交互
    private func canInteractWithItem(_ item: UpgradeItem) -> Bool {
        if !item.isUnlocked {
            return canUnlock(item)
        }
        return item.canUpgrade() && gameState.player.diamonds >= item.upgradeCost()
    }
    
    /// 解锁物品
    private func unlockItem(_ item: UpgradeItem) {
        if gameState.spendDiamonds(item.upgradeCost()) {
            if let index = gameState.player.upgradeItems.firstIndex(where: { $0.id == item.id }) {
                gameState.player.upgradeItems[index].level = 1
                gameState.savePlayer()
            }
        }
    }
    
    /// 升级物品
    private func upgradeItem(_ item: UpgradeItem) {
        if gameState.spendDiamonds(item.upgradeCost()) {
            if let index = gameState.player.upgradeItems.firstIndex(where: { $0.id == item.id }) {
                gameState.player.upgradeItems[index].level += 1
                gameState.savePlayer()
            }
        }
    }
}

#Preview {
    MainView()
}
