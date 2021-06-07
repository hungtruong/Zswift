import SwiftUI
private let defaults = UserDefaults.standard
let ftpKey = "userFTP"
struct SettingsView: View {
    @AppStorage(ftpKey) var ftp: Int = 160
    var body: some View {
        Form {
            Section(header: Text("Settings")) {
                HStack {
                    Stepper("FTP", value: $ftp, in: 100...300, step: 5)
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
