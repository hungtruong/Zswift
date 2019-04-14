import UIKit

class WorkoutViewController: UIViewController {
    @IBOutlet weak var targetWattsLabel: UILabel!
    @IBOutlet weak var segmentTimeLabel: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var segmentLabel: UILabel!
    @IBOutlet weak var nextSegmentLabel: UILabel!
    
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var cadenceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var workout: Workout! {
        didSet {
            workout.ftp = ftp
        }
    }
    let ftp = 160
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
        let currentWatts = self.bluetoothService.wattValue
//        let currentWatts = 50
        
        self.caloriesLabel.text = String(self.bluetoothService.calories)
        self.cadenceLabel.text = String(self.bluetoothService.cadence)
        self.distanceLabel.text = String(Double(self.bluetoothService.distance) * 0.00062137)
        
        if currentWatts < 30 {
            self.targetWattsLabel.text = "0"
            // workout hasn't started or i stopped pedaling
        } else {
            let previousTimeElapsed = workout.timeElapsed.advanced(by: 1.0)
            workout.recalculate(for: previousTimeElapsed)
            
            self.targetWattsLabel.text = String(format: "%i / %i", currentWatts, workout.currentWattage)
            self.elapsedTimeLabel.text = String(format: "%@ / %@", dateFormatter.string(from: workout.timeElapsed)!,
                                                dateFormatter.string(from: workout.totalTime)!)
            self.segmentTimeLabel.text = String(format: "%@ / %@", dateFormatter.string(from: workout.timeInSegment)!,
                                                dateFormatter.string(from: workout.currentSegment.duration)!)
            self.segmentLabel.text = String(format: "%@", workout.currentSegment.description(ftp: workout.ftp))
            if let nextSegment = workout.nextSegment() {
                self.nextSegmentLabel.text = String(format: "Next: %@", nextSegment.description(ftp: workout.ftp))
            } else {
                self.nextSegmentLabel.text = ""
            }
        }
        
        

    }
}
