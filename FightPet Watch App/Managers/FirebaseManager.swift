import Foundation
import FirebaseCore
import FirebaseFirestore

/// 排行榜玩家数据模型（Firestore文档）
struct RankingPlayer: Codable, Identifiable {
    var id: String  // 设备唯一ID
    var name: String
    var emoji: String
    var level: Int
    var power: Int
    var wins: Int
    var quality: String  // A/S/SS
    var rebirthCount: Int
    var lastUpdated: Date
    
    /// 转换为 Opponent（用于战斗）
    func toOpponent(diamondReward: Int) -> Opponent {
        return Opponent(
            name: name,
            emoji: emoji,
            level: level,
            power: power,
            wins: wins,
            winRate: wins > 0 ? min(0.99, Double(wins) / Double(wins + 5)) : 0.0,
            diamondReward: diamondReward
        )
    }
}

/// Firebase 管理器 - 负责排行榜数据的读写
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let db: Firestore
    private let collectionName = "rankings"
    
    /// 设备唯一ID（用于标识玩家）
    private let deviceID: String
    
    /// 排行榜数据
    @Published var rankings: [RankingPlayer] = []
    @Published var isLoading: Bool = false
    
    private init() {
        // 获取或生成设备唯一ID
        if let savedID = UserDefaults.standard.string(forKey: "firebase_device_id") {
            self.deviceID = savedID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "firebase_device_id")
            self.deviceID = newID
        }
        
        self.db = Firestore.firestore()
    }
    
    /// 配置 Firebase（在 App 启动时调用）
    static func configure() {
        FirebaseApp.configure()
    }
    
    // MARK: - 上传玩家数据
    
    /// 同步玩家数据到排行榜
    func syncPlayerData(pet: Pet, wins: Int) {
        let playerData: [String: Any] = [
            "name": pet.name,
            "emoji": pet.emoji,
            "level": pet.level,
            "power": pet.power,
            "wins": wins,
            "quality": pet.quality.name,
            "rebirthCount": pet.rebirthCount,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection(collectionName).document(deviceID).setData(playerData, merge: true) { error in
            if let error = error {
                print("❌ 排行榜数据同步失败: \(error.localizedDescription)")
            } else {
                print("✅ 排行榜数据已同步")
            }
        }
    }
    
    // MARK: - 获取排行榜
    
    /// 获取排行榜数据（按战力降序，最多50人）
    func fetchRankings(completion: (() -> Void)? = nil) {
        isLoading = true
        
        db.collection(collectionName)
            .order(by: "power", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("❌ 获取排行榜失败: \(error.localizedDescription)")
                        completion?()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("⚠️ 排行榜无数据")
                        completion?()
                        return
                    }
                    
                    self.rankings = documents.compactMap { doc in
                        let data = doc.data()
                        return RankingPlayer(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "???",
                            emoji: data["emoji"] as? String ?? "🐾",
                            level: data["level"] as? Int ?? 1,
                            power: data["power"] as? Int ?? 0,
                            wins: data["wins"] as? Int ?? 0,
                            quality: data["quality"] as? String ?? "A",
                            rebirthCount: data["rebirthCount"] as? Int ?? 0,
                            lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    
                    print("📊 排行榜已加载: \(self.rankings.count) 名玩家")
                    completion?()
                }
            }
    }
    
    // MARK: - 获取可挑战对手
    
    /// 获取可挑战的对手（排除自己，按战力接近程度排序）
    func fetchOpponents(playerPower: Int, completion: @escaping ([Opponent]) -> Void) {
        db.collection(collectionName)
            .order(by: "power", descending: true)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 获取对手失败: \(error.localizedDescription)")
                        completion([])
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    
                    let players = documents.compactMap { doc -> RankingPlayer? in
                        // 排除自己
                        guard doc.documentID != self.deviceID else { return nil }
                        
                        let data = doc.data()
                        return RankingPlayer(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "???",
                            emoji: data["emoji"] as? String ?? "🐾",
                            level: data["level"] as? Int ?? 1,
                            power: data["power"] as? Int ?? 0,
                            wins: data["wins"] as? Int ?? 0,
                            quality: data["quality"] as? String ?? "A",
                            rebirthCount: data["rebirthCount"] as? Int ?? 0,
                            lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    
                    // 按与玩家战力差距排序，选最接近的3个
                    let sorted = players.sorted { abs($0.power - playerPower) < abs($1.power - playerPower) }
                    let selected = Array(sorted.prefix(3))
                    
                    let opponents = selected.map { player in
                        let diamondReward = max(10, player.power + Int.random(in: -10...20))
                        return player.toOpponent(diamondReward: diamondReward)
                    }
                    
                    // 按战力从低到高
                    completion(opponents.sorted { $0.power < $1.power })
                }
            }
    }
    
    /// 当前设备ID
    var currentDeviceID: String {
        return deviceID
    }
}
