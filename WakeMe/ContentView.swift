import SwiftUI

struct ContentView: View {
    @State private var threshold = 60.0
    @State private var isSilentMode = true
    @State private var isClassActive = false
    @State private var currentHeartRate: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Status") {
                    HStack {
                        Text("Heart Rate")
                        Spacer()
                        Text("\(Int(currentHeartRate)) BPM")
                            .foregroundColor(isClassActive ? .green : .gray)
                            .fontWeight(.bold)
                    }
                    
                    Button(action: {
                        isClassActive.toggle()
                        // TODO: Connect to watch session
                    }) {
                        HStack {
                            Image(systemName: isClassActive ? "pause.fill" : "play.fill")
                            Text(isClassActive ? "End Class" : "Start Class")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isClassActive ? .red : .blue)
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
}
