import Foundation
import WatchConnectivity
import Combine 

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var currentHeartRate: Double = 0
    @Published var isClassActive = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Send Commands to Watch
    func sendActionToWatch(start: Bool, threshold: Double) {
        guard WCSession.default.isReachable else { return }
        
        let message: [String: Any] = [
            "action": start ? "START" : "STOP",
            "threshold": threshold
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Receive Data from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let bpm = message["bpm"] as? Double {
                self.currentHeartRate = bpm
            }
            if let isActive = message["isActive"] as? Bool {
                self.isClassActive = isActive
            }
        }
    }
    
    // MARK: - Boilerplate (Required)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
    
    // MARK: - Boilerplate (Required)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

