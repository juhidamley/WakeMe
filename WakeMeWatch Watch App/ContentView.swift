import SwiftUI

struct ContentView: View {
    @StateObject var sessionManager = SessionManager()
    
    var body: some View {
        ZStack {
            Circle()
                .fill(sessionManager.isRunning ? Color.green.opacity(0.15) : Color.clear)
                .scaleEffect(sessionManager.isRunning ? 1.3 : 0.8)
            
            VStack(spacing: 16) {
                if sessionManager.isRunning {
                    VStack(spacing: 8) {
                        Text("\(Int(sessionManager.currentHeartRate))")
                            .font(.system(size: 60, weight: .bold))
                        Text("BPM")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if !sessionManager.healthKitAuthorized {
                    VStack(spacing: 12) {
                        Text("Health Permission Required")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text("Enable HealthKit access to track heart rate")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            sessionManager.startSession()
                        }) {
                            Text("Enable HealthKit")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding()
                } else {
                    Button(action: {
                        if sessionManager.isRunning {
                            sessionManager.stopSession()
                        } else {
                            sessionManager.startSession()
                        }
                    }) {
                        HStack {
                            Image(systemName: sessionManager.isRunning ? "pause.fill" : "play.fill")
                            Text(sessionManager.isRunning ? "End Class" : "Start Class")
                        }
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(sessionManager.isRunning ? .red : .blue)
                }
            }
        }
    }
}
