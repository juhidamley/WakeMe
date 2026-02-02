import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Control Center")
                .font(.largeTitle)
                .bold()
            
            // This is just a UI placeholder for now
            List {
                Section(header: Text("Settings")) {
                    Toggle("Deep Sleep Mode", isOn: .constant(true))
                    Button("Test Alarm") {
                        // We will hook this up to the Watch later
                    }
                }
            }
        }
    }
}
