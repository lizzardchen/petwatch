import SwiftUI

/// 宠物主界面
struct MainView: View {
    @StateObject private var gameState = GameStateManager()
    @State private var showRanking = false
    @State private var showActivity = false
    @State private var showStore = false
    @State private var showRebirth = false
    @State private var showDebugInfo = false  // 临时调试开关
    
    var body: some View {
        GeometryReader { geometry in
            // 使用完整屏幕高度（包含安全区域）
            let fullScreenHeight = geometry.size.height + 
                                  geometry.safeAreaInsets.top + 
                                  geometry.safeAreaInsets.bottom
            let screenWidth = geometry.size.width
            let fixedSectionHeight = fullScreenHeight * LayoutConstants.fixedSectionHeightRatio
            let scrollSectionHeight = fullScreenHeight - fixedSectionHeight
            
            ZStack {
                // 背景渐变（覆盖整个界面）
                LinearGradient(
                    colors: [Constants.Colors.purple, Constants.Colors.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 使用 ZStack 进行绝对定位，而不是 VStack
                ZStack(alignment: .top) {
                    // 固定顶部区域
                    ZStack {
                        // 蓝框：显示固定区域的完整范围（包含安全区域）
                        // Rectangle()
                        //     .stroke(Color.blue, lineWidth: 2)
                        //     .frame(height: fixedSectionHeight)
                        //     .frame(maxWidth: .infinity, alignment: .top)
                        //     .ignoresSafeArea(edges: .top)
                        
                        VStack(spacing: 0) {
                            // TopBar: 25% of fixedSectionHeight
                            TopBar(
                                diamonds: gameState.player.diamonds,
                                power: gameState.player.currentPet.power,
                                onAddDiamonds: { showStore = true },
                                screenWidth: screenWidth,
                                allocatedHeight: fixedSectionHeight * LayoutConstants.FixedSectionLayout.topBarHeightRatio
                            )
                            .padding(.horizontal, screenWidth * 0.04)
                            
                            // PetCard: 60% of fixedSectionHeight
                            PetCard(
                                pet: gameState.player.currentPet,
                                onRebirth: { showRebirth = true },
                                screenWidth: screenWidth,
                                allocatedHeight: fixedSectionHeight * LayoutConstants.FixedSectionLayout.petCardHeightRatio
                            )
                            .padding(.horizontal, screenWidth * 0.02)
                            
                            // ActionButtons: 15% of fixedSectionHeight
                            ActionButtonsView(
                                screenWidth: screenWidth,
                                allocatedHeight: fixedSectionHeight * LayoutConstants.FixedSectionLayout.actionButtonsHeightRatio,
                                onRanking: { showRanking = true },
                                onActivity: { showActivity = true }
                            )
                            .padding(.horizontal, screenWidth * 0.04)
                        }
                        .ignoresSafeArea(edges: .top)
                    }
                    .frame(height: fixedSectionHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)
                    
                    // 可滚动的底部区域 - 定位在固定区域下方
                    ScrollView {
                        VStack(spacing: scrollSectionHeight * 0.08) {
                            PetDisplayView(pet: gameState.player.currentPet,
                                         screenWidth: screenWidth)
                                .padding(.horizontal, screenWidth * 0.04)
                                .padding(.top, scrollSectionHeight * 0.08)
                            
                            // 小窝升级部分
                            UpgradeOptionsView(
                                items: gameState.player.upgradeItems,
                                hourlyIncome: gameState.player.hourlyDiamondIncome(),
                                gameState: gameState,
                                screenWidth: screenWidth)
                            .padding(.horizontal, screenWidth * 0.04)
                            .padding(.bottom, scrollSectionHeight * 0.15)
                        }
                    }
                    .frame(height: scrollSectionHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .offset(y: fixedSectionHeight)
                    .ignoresSafeArea(edges: .top)
                }
                
                // 临时调试信息显示
                if showDebugInfo {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("📐 尺寸调试")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        Divider()
                            .frame(height: 0.5)
                            .background(Color.yellow)
                        
                        Group {
                            Text("Geo: \(Int(screenWidth))×\(Int(geometry.size.height))")
                            Text("Safe: ↑\(Int(geometry.safeAreaInsets.top)) ↓\(Int(geometry.safeAreaInsets.bottom))")
                            
                            Divider()
                                .frame(height: 0.5)
                                .background(Color.yellow.opacity(0.5))
                            
                            Text("完整高度: \(Int(fullScreenHeight))px")
                                .foregroundColor(.white)
                            
                            Divider()
                                .frame(height: 0.5)
                                .background(Color.yellow.opacity(0.5))
                            
                            Text("固定区: \(Int(fixedSectionHeight))px")
                                .foregroundColor(.cyan)
                            Text("  = \(String(format: "%.0f", (fixedSectionHeight/fullScreenHeight)*100))% 全屏")
                                .foregroundColor(.cyan.opacity(0.8))
                            
                            Text("滚动区: \(Int(scrollSectionHeight))px")
                                .foregroundColor(.green)
                            Text("  = \(String(format: "%.0f", (scrollSectionHeight/fullScreenHeight)*100))% 全屏")
                                .foregroundColor(.green.opacity(0.8))
                            
                            Divider()
                                .frame(height: 0.5)
                                .background(Color.yellow.opacity(0.5))
                            
                            let topBarH = fixedSectionHeight * 0.25
                            let petCardH = fixedSectionHeight * 0.60
                            let actionH = fixedSectionHeight * 0.15
                            
                            Text("TB:\(Int(topBarH)) PC:\(Int(petCardH)) AC:\(Int(actionH))")
                            Text("∑=\(Int(topBarH + petCardH + actionH))")
                                .foregroundColor(abs(topBarH + petCardH + actionH - fixedSectionHeight) < 1 ? .green : .red)
                        }
                        .font(.system(size: 6, design: .monospaced))
                        .foregroundColor(.white)
                    }
                    .padding(4)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
                    .allowsHitTesting(false)
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
/// 功能按钮区域
struct ActionButtonsView: View {
    let screenWidth: CGFloat
    let allocatedHeight: CGFloat
    let onRanking: () -> Void
    let onActivity: () -> Void
    
    var body: some View {
        let buttonHeight = allocatedHeight * LayoutConstants.FixedSectionLayout.ActionButtons.buttonHeightRatio
        let topMargin = allocatedHeight * LayoutConstants.FixedSectionLayout.ActionButtons.topMarginRatio
        let bottomMargin = allocatedHeight * LayoutConstants.FixedSectionLayout.ActionButtons.bottomMarginRatio
        
        HStack(spacing: screenWidth * 0.04) {
            GradientButton(
                title: "排行榜",
                icon: "🏆",
                gradient: LinearGradient(
                    colors: [Color(red: 0.7, green: 0.4, blue: 0.4),
                            Color(red: 0.6, green: 0.3, blue: 0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                screenWidth: screenWidth,
                height: buttonHeight
            ) {
                onRanking()
            }
            
            GradientButton(
                title: "运动",
                icon: "🏃",
                gradient: Constants.Colors.blueGradient,
                screenWidth: screenWidth,
                height: buttonHeight
            ) {
                onActivity()
            }
        }
        .frame(height: buttonHeight)         // 限制按钮高度
        .padding(.top, topMargin)            // 加上顶部margin
        .padding(.bottom, bottomMargin)      // 加上底部margin
        .frame(height: allocatedHeight)      // 最外层严格限制总高度
    }
}

/// 顶部信息栏
struct TopBar: View {
    let diamonds: Int
    let power: Int
    let onAddDiamonds: () -> Void
    let screenWidth: CGFloat
    let allocatedHeight: CGFloat  // 新增：分配给TopBar的高度
    
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
