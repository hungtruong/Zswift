import UIKit

class WorkoutViewController: UIViewController {
    @IBOutlet weak var targetWattsLabel: UILabel!
    @IBOutlet var wattLabel: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    var workout: Workout! {
        didSet {
            workout.ftp = ftp
        }
    }
    let ftp = 156
    let dateFormatter = DateComponentsFormatter()
    
    let bluetoothService = PM5BluetoothService()

    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.zeroFormattingBehavior = [.pad]
        dateFormatter.allowedUnits = [.minute, .second]
        // made a timer cause I didn't make the vc the delegate like almost everyone else does
        let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            self.checkService()
        }
        
        RunLoop.current.add(timer, forMode: .default)
    }
    
    func checkService() {
        //let currentWatts = self.bluetoothService.wattValue
        let currentWatts = 50
        if currentWatts < 30 {
            self.wattLabel.text = "0"
            // workout hasn't started or i stopped pedaling
        } else {
            let previousTimeElapsed = workout.timeElapsed.advanced(by: 1.0)
            workout.recalculate(for: previousTimeElapsed)
            
            self.updateWattLabel(String(format: "%i", currentWatts))
            self.targetWattsLabel.text = String(format: "%i", workout.currentWattage)
            self.elapsedTimeLabel.text = dateFormatter.string(from: workout.timeElapsed)
        }
        
        

    }

    func updateWattLabel(_ title: String) {
        self.wattLabel.text = title
    }
}
