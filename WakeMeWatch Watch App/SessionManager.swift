import Foundation
import HealthKit
import Combine
import WatchKit
import WatchConnectivity

class SessionManager: NSObject, ObservableObject, HKLiveWorkoutBuilderDelegate, HKWorkoutSessionDelegate, WCSessionDelegate {
    
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
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Receive Command from Phone
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard let action = message["action"] as? String else { return }
            
            if let newThreshold = message["threshold"] as? Double {
                self.thresholdBPM = newThreshold
            }
            
            if action == "START" {
                self.startSession()
            } else if action == "STOP" {
                self.stopSession()
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    // MARK: - HealthKit Setup
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
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    
    // MARK: - Heart Rate Logic
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                let statistics = workoutBuilder.statistics(for: quantityType)
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                
                DispatchQueue.main.async {
                    self.currentHeartRate = value
                    
                    if WCSession.default.isReachable {
                        WCSession.default.sendMessage(["bpm": value, "isActive": true], replyHandler: nil)
                    }
                    
                    // Trigger Logic
                    if value < self.thresholdBPM && value > 0 {
                        self.triggerWakeUpHaptic()
                    }
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    // MARK: - 6-PULSE WAKE UP ENGINE
    func triggerWakeUpHaptic() {
        let now = Date()
        // Throttle to prevent overlap (10 seconds)
        guard now.timeIntervalSince(lastAlertTime) > 10 else { return }
        lastAlertTime = now
        
        print("⚠️ TRIGGERING 6-PULSE ALARM")
        
        // Define the 6 pulses with 0.6s delay between each
        let delays = [0.0, 0.6, 1.2, 1.8, 2.4, 3.0]
        
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // .failure is the longest, strongest vibration type available
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
}
