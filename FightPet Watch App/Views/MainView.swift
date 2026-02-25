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
            let topSafeMargin = fullScreenHeight * LayoutConstants.fixedTopMarginRatio
            let bottomSafeMargin = fullScreenHeight * LayoutConstants.fixedBottomMarginRatio
            // 基础固定区域高度（用于计算各组件的分配高度）
            let baseFixedSectionHeight = fullScreenHeight * LayoutConstants.fixedSectionHeightRatio
            // 实际固定区域高度（增加了 topSafeMargin）
            let fixedSectionHeight = baseFixedSectionHeight + topSafeMargin + bottomSafeMargin
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
                            // 添加 Spacer 填充增加的空间（在顶部）
                            Spacer(minLength: topSafeMargin)
                            
                            // TopBar: 25% of baseFixedSectionHeight
                            TopBar(
                                diamonds: gameState.player.diamonds,
                                power: gameState.player.currentPet.power,
                                onAddDiamonds: { showStore = true },
                                screenWidth: screenWidth,
                                allocatedHeight: baseFixedSectionHeight * LayoutConstants.FixedSectionLayout.topBarHeightRatio
                            )
                            .padding(.horizontal, screenWidth * 0.04)
                            
                            // PetCard: 60% of baseFixedSectionHeight
                            PetCard(
                                pet: gameState.player.currentPet,
                                gameState: gameState,
                                onRebirth: { showRebirth = true },
                                screenWidth: screenWidth,
                                allocatedHeight: baseFixedSectionHeight * LayoutConstants.FixedSectionLayout.petCardHeightRatio
                            )
                            .padding(.horizontal, screenWidth * 0.02)
                            
                            // ActionButtons: 15% of baseFixedSectionHeight
                            ActionButtonsView(
                                screenWidth: screenWidth,
                                allocatedHeight: baseFixedSectionHeight * LayoutConstants.FixedSectionLayout.actionButtonsHeightRatio,
                                onRanking: { showRanking = true },
                                onActivity: { showActivity = true }
                            )
                            .padding(.horizontal, screenWidth * 0.04)
                        
                            // 添加 Spacer 填充增加的空间（在顶部）
                            Spacer(minLength: bottomSafeMargin)
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
                                .padding(.top, scrollSectionHeight * 0.02)  // 减小顶部间距
                            
                            // 小窝升级部分
                            UpgradeOptionsView(
                                items: gameState.player.upgradeItems,
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
                .environmentObject(gameState)
        }
        .sheet(isPresented: $showStore) {
            StoreView(gameState: gameState)
        }
        .sheet(isPresented: $showRebirth) {
            RebirthView(gameState: gameState)
        }
        .sheet(isPresented: $showActivity) {
            ActivityView(gameState: gameState)
        }
    }
}

#Preview {
    MainView()
}
