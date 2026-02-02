import Foundation
import HealthKit
import Combine
import WatchKit

class SessionManager: NSObject, ObservableObject, HKLiveWorkoutBuilderDelegate, HKWorkoutSessionDelegate {
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var isRunning = false
    @Published var currentHeartRate: Double = 0
    @Published var healthKitAuthorized = false
    
    var thresholdBPM: Double = 90
    var lastAlertTime: Date = Date.distantPast
    
    override init() {
        super.init()
        checkHealthKitAuthorization()
    }
    
    func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        DispatchQueue.main.async {
            self.healthKitAuthorized = (status == .sharingAuthorized)
        }
    }
    
    func startSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        // Check if already authorized
        if healthKitAuthorized {
            beginWorkout()
            return
        }
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.healthKitAuthorized = success
                if success {
                    self.beginWorkout()
                } else {
                    self.isRunning = false
                    print("HealthKit authorization denied: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }
    
    func beginWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
            session?.delegate = self
            builder?.delegate = self
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            session?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { (success, error) in
                DispatchQueue.main.async {
                    self.isRunning = success
                    print("Collection started: \(success)")
                }
            }
        } catch {
            print("Failed to start workout: \(error.localizedDescription)")
        }
    }
    
    func stopSession() {
        session?.end()
        
        builder?.endCollection(withEnd: Date()) { (success, error) in
            self.builder?.finishWorkout { (workout, error) in
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.currentHeartRate = 0
                    print("Session Ended")
                }
            }
        }
    }
    
    // MARK: - HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout state changed to: \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                let statistics = workoutBuilder.statistics(for: quantityType)
                
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                
                DispatchQueue.main.async {
                    self.currentHeartRate = value
                    print("Heart Rate: \(value) BPM")
                    
                    // Check threshold
                    if value < self.thresholdBPM && value > 0 {
                        self.triggerAlert()
                    }
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }
    
    func triggerAlert() {
        let now = Date()
        // Throttle alerts to once every 10 seconds
        guard now.timeIntervalSince(lastAlertTime) > 10 else { return }
        lastAlertTime = now
        
        WKInterfaceDevice.current().play(.notification)
        print("⚠️ Alert triggered! Heart rate below threshold")
    }
}
