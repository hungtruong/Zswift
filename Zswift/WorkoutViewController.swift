import HealthKit
import UIKit
import WatchConnectivity

class WorkoutViewController: UIViewController {
    @IBOutlet weak var targetWattsLabel: UILabel!
    @IBOutlet weak var segmentTimeLabel: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var segmentLabel: UILabel!
    @IBOutlet weak var nextSegmentLabel: UILabel!
    
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var cadenceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet var heartRateLabel: UILabel!
    
    private var workoutStart: Date!
    private var workoutEnd: Date!
    
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
        self.bluetoothService.delegate = self
        startWatch()
        dateFormatter.zeroFormattingBehavior = [.pad]
        dateFormatter.allowedUnits = [.minute, .second]

        let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            self.checkService()
        }
        
        RunLoop.current.add(timer, forMode: .default)
    }
    
    func setupWorkout() {
        workoutStart = Date()
        let healthStore = HKHealthStore()
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .cycling
        workoutConfiguration.locationType = .indoor
        
        healthStore.startWatchApp(with: workoutConfiguration) { (success, error) in
            if success {
                print("Success starting workout")
            }
        }
    }
    
    @IBAction func cancelWorkout() {
        self.workoutEnd = Date()
        self.endWorkout()
    }
    
    func endWorkout() {
        self.workoutEnd = Date()
        sendWorkoutSamples()

        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func checkService() {
        let currentWatts = self.bluetoothService.wattValue
//        let currentWatts = 50
        if currentWatts < 30 {
            self.targetWattsLabel.text = "0"
            // workout hasn't started or i stopped pedaling
        } else {
            if workout.timeElapsed == 0 {
                setupWorkout()
            }
            
            guard workout.timeElapsed < workout.totalTime else {
                // end workout
                self.endWorkout()
                return
            }
            
            workout.recalculate(for: workout.timeElapsed)
            wattValueChanged(currentWatts)
            self.elapsedTimeLabel.text = String(format: "%@ / %@", dateFormatter.string(from: workout.timeElapsed)!,
                                                dateFormatter.string(from: workout.totalTime)!)
            self.segmentTimeLabel.text = String(format: "%@ / %@", dateFormatter.string(from: workout.timeRemainingInSegment)!,
                                                dateFormatter.string(from: workout.currentSegment.duration)!)
            self.segmentLabel.text = String(format: "%@", workout.currentSegment.description(ftp: workout.ftp))
            if let nextSegment = workout.nextSegment() {
                self.nextSegmentLabel.text = String(format: "Next: %@", nextSegment.description(ftp: workout.ftp))
            } else {
                self.nextSegmentLabel.text = ""
            }
            
            if workout.timeRemainingInSegment == 5.0 {
                WCSession.default.sendMessage(["sendReminder": true], replyHandler: nil, errorHandler: nil)
            }
            
            workout.timeElapsed = workout.timeElapsed.advanced(by: 1.0)
        }
    }
    
    func sendWorkoutSamples() {
        let message: [String : Any] = ["calories": self.bluetoothService.calories,
                                       "distance": self.bluetoothService.distance,
                                       "start": self.workoutStart!,
                                       "end": self.workoutEnd!]
        
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}

extension WorkoutViewController: BluetoothServiceDelegate {
    func wattValueChanged(_ watts: Int) {
        self.targetWattsLabel.text = String(format: "%i / %i", watts, workout.currentWattage)
    }
    
    func distanceValueChanged(_ distance: Int) {
        self.distanceLabel.text = String(format: "%.2f", Double(distance) * 0.00062137)
    }
    
    func caloriesChanged(_ calories: Int) {
        self.caloriesLabel.text = String(calories)
    }
    
    func cadenceChanged(_ cadence: Int) {
        self.cadenceLabel.text = String(cadence)
    }
    
    
}

extension WorkoutViewController: WCSessionDelegate {
    func startWatch() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session Completed")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session Inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session Deactivated")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let heartRate =  message["heart_rate"] as? Int {
            DispatchQueue.main.async {
                self.heartRateLabel.text = String(heartRate)
            }
        }
    }
}

