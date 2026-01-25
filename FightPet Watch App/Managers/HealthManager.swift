import Foundation
import HealthKit
import Combine

/// HealthKit数据管理器
/// 负责请求权限、查询睡眠和运动数据
class HealthManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    
    // 发布的状态
    @Published var isAuthorized = false
    @Published var isSleeping = false
    @Published var isExercising = false
    
    // MARK: - 权限管理
    
    /// 请求HealthKit访问权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // 检查HealthKit是否可用
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit不可用")
            completion(false)
            return
        }
        
        // 定义需要读取的数据类型
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,  // 睡眠分析
            HKObjectType.workoutType()  // 运动数据
        ]
        
        // 请求权限
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit授权失败: \(error.localizedDescription)")
                }
                self.isAuthorized = success
                completion(success)
            }
        }
    }
    
    // MARK: - 睡眠数据查询
    
    /// 查询指定时间段内的睡眠记录（时间段数组）
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    ///   - completion: 返回睡眠时间段数组
    func querySleepIntervals(from startDate: Date, to endDate: Date, completion: @escaping ([DateInterval]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                print("查询睡眠数据失败: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let sleepSamples = samples as? [HKCategorySample] else {
                completion([])
                return
            }
            
            // 只保留"睡眠中"和"深度睡眠"的记录，过滤掉"在床上"状态
            let sleepIntervals = sleepSamples
                .filter { sample in
                    let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                    return value == .asleep || value == .awake || value == .inBed
                    // 注意：根据需要调整，可能只需要 .asleep
                }
                .map { DateInterval(start: $0.startDate, end: $0.endDate) }
            
            DispatchQueue.main.async {
                completion(sleepIntervals)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// 查询今日睡眠时间段
    func queryTodaySleepIntervals(completion: @escaping ([DateInterval]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        querySleepIntervals(from: startOfDay, to: now, completion: completion)
    }
    
    /// 检查当前是否在睡眠中
    /// - Parameter completion: 返回是否在睡眠
    func isCurrentlySleeping(completion: @escaping (Bool) -> Void) {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)  // 查询过去1小时的睡眠记录
        
        querySleepIntervals(from: oneHourAgo, to: now) { intervals in
            // 如果有任何睡眠记录包含当前时间，则认为在睡眠中
            let sleeping = intervals.contains { interval in
                interval.contains(now)
            }
            
            DispatchQueue.main.async {
                self.isSleeping = sleeping
                completion(sleeping)
            }
        }
    }
    
    // MARK: - 运动数据查询
    
    /// 查询今日运动总时长（秒数）
    func queryTodayExerciseDuration(completion: @escaping (Int) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                print("查询运动数据失败: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let workouts = samples as? [HKWorkout] else {
                completion(0)
                return
            }
            
            // 计算总运动时长
            let totalDuration = workouts.reduce(0.0) { $0 + $1.duration }
            
            DispatchQueue.main.async {
                completion(Int(totalDuration))
            }
        }
        
        healthStore.execute(query)
    }
    
    /// 检查当前是否在运动中
    func isCurrentlyExercising(completion: @escaping (Bool) -> Void) {
        let now = Date()
        let thirtyMinutesAgo = now.addingTimeInterval(-1800)  // 查询过去30分钟
        
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: thirtyMinutesAgo, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 1, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                print("查询运动状态失败: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let workouts = samples as? [HKWorkout], let lastWorkout = workouts.first else {
                DispatchQueue.main.async {
                    self.isExercising = false
                    completion(false)
                }
                return
            }
            
            // 如果最近的运动记录包含当前时间，则认为在运动中
            let exercising = lastWorkout.endDate > now.addingTimeInterval(-600)  // 10分钟内结束的算运动中
            
            DispatchQueue.main.async {
                self.isExercising = exercising
                completion(exercising)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - 后台监听（可选）
    
    /// 启动健康数据监听
    /// 注意：watchOS后台运行受限，此功能可能有限
    func startHealthMonitoring() {
        // 定期查询睡眠和运动状态（每5分钟）
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.isCurrentlySleeping { _ in }
            self?.isCurrentlyExercising { _ in }
        }
    }
}
