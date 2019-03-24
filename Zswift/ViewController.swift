import UIKit

class ViewController: UIViewController {
    @IBOutlet var wattLabel: UILabel!
    
    let bluetoothService = PM5BluetoothService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // made a timer cause I didn't make the vc the delegate like almost everyone else does
        let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            self.checkService()
        }
        RunLoop.current.add(timer, forMode: .default)
    }
    
    func checkService() {
        self.updateWattLabel(String(format: "%i", self.bluetoothService.wattValue))
    }

    func updateWattLabel(_ title: String) {
        self.wattLabel.text = title
    }
}
