import StoreKit
import SwiftUI
import Combine

/// StoreKit 管理器 - 处理应用内购买
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    
    // 产品 ID 定义
    enum ProductID: String, CaseIterable {
        case smallPack = "com.fightpet.diamonds.small"      // 500钻石 - $6
        case mediumPack = "com.fightpet.diamonds.medium"    // 1200钻石 - $12
        case largePack = "com.fightpet.diamonds.large"      // 3000钻石 - $25
        case superPack = "com.fightpet.diamonds.super"      // 6000钻石 - $45
        case vipMonthly = "com.fightpet.vip.monthly"        // VIP月订阅 - $18/月
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 加载产品
    
    /// 从 App Store 加载产品信息
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let loadedProducts = try await Product.products(for: productIDs)
            
            // 按价格排序
            products = loadedProducts.sorted { $0.price < $1.price }
            
            print("✅ 成功加载 \(products.count) 个产品")
        } catch {
            print("❌ 加载产品失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 购买处理
    
    /// 购买产品
    /// - Parameter product: 要购买的产品
    /// - Returns: 购买结果
    func purchase(_ product: Product) async -> PurchaseResult {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 验证交易
                let transaction = try checkVerified(verification)
                
                // 发放内容
                await deliverContent(for: transaction)
                
                // 完成交易
                await transaction.finish()
                
                return .success
                
            case .userCancelled:
                return .cancelled
                
            case .pending:
                return .pending
                
            @unknown default:
                return .failed(NSError(domain: "StoreKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
            }
        } catch {
            print("❌ 购买失败: \(error.localizedDescription)")
            return .failed(error)
        }
    }
    
    /// 恢复购买
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            print("✅ 购买已恢复")
        } catch {
            print("❌ 恢复购买失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 交易监听
    
    /// 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // 发放内容
                    await self.deliverContent(for: transaction)
                    
                    // 完成交易
                    await transaction.finish()
                } catch {
                    print("❌ 交易验证失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 检查未完成的交易
    func checkPendingTransactions() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                await deliverContent(for: transaction)
            } catch {
                print("❌ 处理未完成交易失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 内容发放
    
    /// 发放购买内容
    private func deliverContent(for transaction: StoreKit.Transaction) async {
        guard let productID = ProductID(rawValue: transaction.productID) else {
            print("❌ 未知产品 ID: \(transaction.productID)")
            return
        }
        
        await MainActor.run {
            switch productID {
            case .smallPack:
                deliverDiamonds(500)
            case .mediumPack:
                deliverDiamonds(1200)
            case .largePack:
                deliverDiamonds(3000)
            case .superPack:
                deliverDiamonds(6000)
            case .vipMonthly:
                deliverVIPSubscription()
            }
            
            purchasedProductIDs.insert(transaction.productID)
        }
    }
    
    /// 发放钻石
    private func deliverDiamonds(_ amount: Int) {
        // 通过通知发送钻石数量
        NotificationCenter.default.post(
            name: .didPurchaseDiamonds,
            object: nil,
            userInfo: ["amount": amount]
        )
        print("💎 发放钻石: \(amount)")
    }
    
    /// 激活 VIP 订阅
    private func deliverVIPSubscription() {
        // 30天的秒数
        let durationSeconds = 30 * 24 * 60 * 60
        
        // 通过通知激活 VIP
        NotificationCenter.default.post(
            name: .didPurchaseVIP,
            object: nil,
            userInfo: ["duration": durationSeconds]
        )
        print("✨ 激活 VIP 订阅: 30天")
    }
    
    // MARK: - 验证
    
    /// 验证交易
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取产品
    func product(for productID: ProductID) -> Product? {
        return products.first { $0.id == productID.rawValue }
    }
    
    /// 检查是否已购买
    func isPurchased(_ productID: ProductID) -> Bool {
        return purchasedProductIDs.contains(productID.rawValue)
    }
}

// MARK: - 购买结果

enum PurchaseResult {
    case success
    case cancelled
    case pending
    case failed(Error)
}

// MARK: - 错误定义

enum StoreError: Error {
    case failedVerification
    
    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "交易验证失败"
        }
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let didPurchaseDiamonds = Notification.Name("didPurchaseDiamonds")
    static let didPurchaseVIP = Notification.Name("didPurchaseVIP")
}
