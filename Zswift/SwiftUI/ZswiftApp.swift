import SwiftUI
@main
struct ZswiftApp: App {
    init() {
        // Register default FTP for Hung
        UserDefaults.standard.register(defaults: [ftpKey : 160])
        authorizeHealthKit { (success, error) in
            success ? print("Success") : print("Error")
        }
    }
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WorkoutSelectionView()
                    .navigationTitle("Zswift")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            NavigationLink(
                                destination: SettingsView(),
                                label: {
                                    Image(systemName: "gear")
                                })
                        }
                    }

            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutSelectionView()
                .navigationTitle("ZSwift")
        }
    }
}
