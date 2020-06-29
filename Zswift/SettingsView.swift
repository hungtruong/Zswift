import SwiftUI
private let defaults = UserDefaults.standard
let ftpKey = "userFTP"
struct SettingsView: View {
    @State private var ftp: Int =
        defaults.integer(forKey: ftpKey)
    var body: some View {
        Form {
            Section(header: Text("Settings")) {
                HStack {
                    Stepper(onIncrement: {
                        self.ftp += 5
                        defaults.set(self.ftp, forKey: ftpKey)
                    }, onDecrement: {
                        self.ftp -= 5
                        defaults.set(self.ftp, forKey: ftpKey)
                    }) {
                        Text("FTP")
                    }
                    Spacer(minLength: 20)
                    Text("\(ftp)")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
