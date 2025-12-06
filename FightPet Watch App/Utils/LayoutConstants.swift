import SwiftUI

/// 布局常量 - 基于标准 Apple Watch 尺寸（44mm）的设计规格
/// 设计基准：Figma 设计图对应的 Apple Watch 尺寸
struct LayoutConstants {
    
    // MARK: - 基准尺寸
    /// 基准屏幕宽度（Figma 设计图对应的 Watch 宽度）
    static let baseScreenWidth: CGFloat = 184  // 44mm Apple Watch
    
    /// 基准屏幕高度（Figma 设计图对应的 Watch 高度）
    static let baseScreenHeight: CGFloat = 224  // 44mm Apple Watch
    
    // MARK: - 固定顶部区域
    /// 固定顶部区域高度比例（相对于整个Watch屏幕，根据Figma设计图精确测量）
    static let fixedSectionHeightRatio: CGFloat = 0.38
    
    // MARK: - 固定区域内部高度分配（相对于固定区域总高度的比例）
    struct FixedSectionLayout {
        /// 顶部外边距（占固定区域的比例）
        static let topMargin: CGFloat = 0.02
        /// 顶部信息栏高度（占固定区域的比例）
        static let topBarHeight: CGFloat = 0.16
        /// 顶部信息栏到宠物卡片间距
        static let topBarToCardSpacing: CGFloat = 0.02
        /// 宠物状态卡片高度（占固定区域的比例）
        static let petCardHeight: CGFloat = 0.54
        /// 宠物卡片到功能按钮间距
        static let cardToButtonSpacing: CGFloat = 0.02
        /// 功能按钮高度（占固定区域的比例）
        static let actionButtonHeight: CGFloat = 0.22
        /// 底部外边距
        static let bottomMargin: CGFloat = 0.02
    }
    
    // MARK: - 顶部信息栏（TopBar）
    struct TopBar {
        /// 水平内边距
        static let horizontalPadding: CGFloat = 8
        /// 垂直内边距
        static let verticalPadding: CGFloat = 4
        /// 卡片圆角
        static let cornerRadius: CGFloat = 14
        /// 图标大小
        static let iconSize: CGFloat = 13
        /// 字体大小
        static let fontSize: CGFloat = 12
        /// 加号按钮大小
        static let plusButtonSize: CGFloat = 16
        /// 元素间距
        static let spacing: CGFloat = 4
        /// 顶部外边距
        static let topMargin: CGFloat = 0
        /// 底部外边距
        static let bottomMargin: CGFloat = 16
    }
    
    // MARK: - 宠物状态卡片（PetCard）
    struct PetCard {
        /// 水平内边距
        static let horizontalPadding: CGFloat = 8
        /// 垂直内边距
        static let verticalPadding: CGFloat = 1
        /// 卡片圆角
        static let cornerRadius: CGFloat = 8
        /// 元素间距
        static let spacing: CGFloat = 4
        /// 等级图标大小
        static let levelIconSize: CGFloat = 14
        /// 等级字体大小
        static let levelFontSize: CGFloat = 20
        /// 经验值字体大小
        static let expFontSize: CGFloat = 11
        /// 进度条高度
        static let progressBarHeight: CGFloat = 6
        /// 重生按钮水平内边距
        static let rebirthButtonHPadding: CGFloat = 9
        /// 重生按钮垂直内边距
        static let rebirthButtonVPadding: CGFloat = 4
        /// 重生按钮字体大小
        static let rebirthButtonFontSize: CGFloat = 10
        /// 重生按钮图标大小
        static let rebirthButtonIconSize: CGFloat = 10
        /// 重生按钮圆角
        static let rebirthButtonCornerRadius: CGFloat = 14
        /// 统计图标大小
        static let statIconSize: CGFloat = 12
        /// 统计字体大小
        static let statFontSize: CGFloat = 10
        /// 统计元素间距
        static let statSpacing: CGFloat = 3
        
        // MARK: 行高比例（相对于卡片区域高度）
        /// 第一行（等级+经验）高度比例
        static let firstRowHeightRatio: CGFloat = 0.6
        /// 第二行（统计信息）高度比例
        static let secondRowHeightRatio: CGFloat = 0.6
        /// 行间距比例
        static let rowSpacingRatio: CGFloat = 0.02
    }
    
    // MARK: - 功能按钮（GradientButton）
    struct ActionButton {
        /// 按钮高度
        static let height: CGFloat = 36
        /// 按钮圆角
        static let cornerRadius: CGFloat = 20
        /// 图标大小
        static let iconSize: CGFloat = 16
        /// 字体大小
        static let fontSize: CGFloat = 12
        /// 图标和文字间距
        static let iconTextSpacing: CGFloat = 4
        /// 按钮之间的间距
        static let buttonSpacing: CGFloat = 8
        /// 水平内边距
        static let horizontalPadding: CGFloat = 10
        /// 底部外边距
        static let bottomMargin: CGFloat = 2
    }
    
    // MARK: - 宠物展示区（PetDisplayView）
    struct PetDisplay {
        /// 宠物头像大小
        static let petEmojiSize: CGFloat = 80
        /// 元素间距
        static let spacing: CGFloat = 16
        /// 名称字体大小
        static let nameFontSize: CGFloat = 18
        /// 名称水平内边距
        static let nameHPadding: CGFloat = 20
        /// 名称垂直内边距
        static let nameVPadding: CGFloat = 8
        /// 名称圆角
        static let nameCornerRadius: CGFloat = 20
        /// 编辑图标大小
        static let editIconSize: CGFloat = 12
        /// 属性图标大小
        static let attributeIconSize: CGFloat = 14
        /// 属性字体大小
        static let attributeFontSize: CGFloat = 12
        /// 属性间距
        static let attributeSpacing: CGFloat = 20
    }
    
    // MARK: - 小窝升级（UpgradeOptionsView）
    struct UpgradeSection {
        /// 水平内边距
        static let horizontalPadding: CGFloat = 16
        /// 垂直内边距
        static let verticalPadding: CGFloat = 16
        /// 卡片圆角
        static let cornerRadius: CGFloat = 16
        /// 标题字体大小
        static let titleFontSize: CGFloat = 14
        /// 元素间距
        static let spacing: CGFloat = 12
        /// 分隔线高度
        static let dividerHeight: CGFloat = 1
        /// 物品卡片宽度
        static let itemCardWidth: CGFloat = 80
        /// 物品卡片高度
        static let itemCardHeight: CGFloat = 80
        /// 物品卡片间距
        static let itemCardSpacing: CGFloat = 12
    }
    
    // MARK: - 辅助函数：根据基准尺寸计算当前尺寸
    /// 根据屏幕宽度缩放
    static func scaledWidth(_ value: CGFloat, screenWidth: CGFloat) -> CGFloat {
        return value * (screenWidth / baseScreenWidth)
    }
    
    /// 根据屏幕高度缩放
    static func scaledHeight(_ value: CGFloat, screenHeight: CGFloat) -> CGFloat {
        return value * (screenHeight / baseScreenHeight)
    }
    
    /// 根据屏幕宽度和高度缩放（取平均值）
    static func scaled(_ value: CGFloat, screenWidth: CGFloat, screenHeight: CGFloat) -> CGFloat {
        let widthScale = screenWidth / baseScreenWidth
        let heightScale = screenHeight / baseScreenHeight
        return value * ((widthScale + heightScale) / 2)
    }
}

