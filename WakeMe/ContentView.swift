import SwiftUI

struct ContentView: View {
    // 1. Inject the Connector
    @StateObject private var connector = WatchConnector()
    @State private var threshold = 60.0
    @State private var isSilentMode = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Status") {
                    HStack {
                        Text("Heart Rate")
                        Spacer()
                        // 2. Read from Connector
                        Text("\(Int(connector.currentHeartRate)) BPM")
                            .foregroundColor(connector.isClassActive ? .green : .gray)
                            .fontWeight(.bold)
                    }
                    
                    Button(action: {
                        toggleSession()
                    }) {
                        HStack {
                            // 3. Bind to Connector State
                            Image(systemName: connector.isClassActive ? "pause.fill" : "play.fill")
                            Text(connector.isClassActive ? "End Class" : "Start Class")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(connector.isClassActive ? .red : .blue)
                }
                
                Section("Settings") {
                    HStack {
                        Text("Wake Threshold")
                        Spacer()
                        Text("\(Int(threshold)) BPM")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $threshold, in: 40...100, step: 5)
                    Toggle("Silent Mode", isOn: $isSilentMode)
                }
            }
            .navigationTitle("WakeMe")
        }
    }
    
    // 4. Send Command
    func toggleSession() {
        let newState = !connector.isClassActive
        connector.isClassActive = newState
        connector.sendActionToWatch(start: newState, threshold: threshold)
    }
}
