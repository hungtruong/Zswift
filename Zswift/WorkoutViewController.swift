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
    
    @IBOutlet var workoutView: WorkoutView!
    
    private var workoutStart: Date!
    private var workoutEnd: Date!
    
    private var workoutTimer: Timer!
    
    var workout: Workout! {
        didSet {
            workout.ftp = ftp
            workout.delegate = self
        }
    }
    
    let ftp = UserDefaults.standard.integer(forKey: ftpKey)
    let dateFormatter = DateComponentsFormatter()
    
    let bluetoothService = PM5BluetoothService()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        self.bluetoothService.delegate = self
        startWatch()
        dateFormatter.zeroFormattingBehavior = [.pad]
        dateFormatter.allowedUnits = [.minute, .second]
        
        #if targetEnvironment(simulator)
        let timeInterval = 0.1
        #else
        let timeInterval = 1.0
        #endif
        
        self.workoutTimer = Timer(timeInterval: timeInterval, repeats: true) { _ in
            self.checkService()
        }
        
        self.workoutView.setupWorkout(self.workout)

        RunLoop.current.add(workoutTimer, forMode: .default)
    }
    
    func setupWorkout() {
        workoutStart = Date()
        workout.startTime = workoutStart
        let healthStore = HKHealthStore()
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .cycling
        workoutConfiguration.locationType = .indoor
        
        healthStore.startWatchApp(with: workoutConfiguration) { (success, error) in
            if success {
                print("Success starting workout")
                self.sendWorkoutMetadata()
            }
        }
    }
    
    @IBAction func cancelWorkout() {
        let alert = UIAlertController(title: "Yeah?", message: "Are you totally sure?", preferredStyle: .alert)
        let cancelWorkoutAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
            self?.workoutEnd = Date()
            self?.endWorkout()
        }
        
        let nevermind = UIAlertAction(title: "Nevermind!", style: .cancel, handler: nil)
        alert.addAction(cancelWorkoutAction)
        alert.addAction(nevermind)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func endWorkout() {
        self.workoutEnd = Date()
        sendWorkoutSamples()
        self.workoutTimer.invalidate()

        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func checkService() {
        #if targetEnvironment(simulator)
        let currentWatts = 50
        #else
        let currentWatts = self.bluetoothService.wattValue
        #endif
        
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
            
            guard let currentSegment = workout.currentSegment else {
                return
            }
            
            workout.recalculate(for: workout.timeElapsed)
            workoutView.updateProgress(Float(workout.timeElapsed / workout.totalTime))
            wattValueChanged(currentWatts)
            self.elapsedTimeLabel.text = String(format: "%@ / %@", dateFormatter.string(from: workout.timeElapsed)!,
                                                dateFormatter.string(from: workout.totalTime)!)
            self.segmentTimeLabel.text = String(format: "%@ / %@", dateFormatter.string(from: workout.timeRemainingInSegment)!,
                                                dateFormatter.string(from: currentSegment.duration)!)
            self.segmentLabel.text = String(format: "%@", currentSegment.description(ftp: workout.ftp))
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
    
    func sendWorkoutMetadata() {
        let message: [String : Any] = ["workoutName": self.workout.name]
        
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

extension WorkoutViewController: WorkoutDelegate {
    func currentSegmentChanged(segment: WorkoutSegment) {
        self.saveSegment(segment: segment)
    }
    
    func saveSegment(segment: WorkoutSegment) {
        guard let dateInterval = workout.dateInterval(for: segment) else { return }
        let start = dateInterval.start
        let end = dateInterval.end
        let message: [String : Any] = ["start": start,
                                       "end": end,
                                       "segmentName": segment.description(ftp: ftp)]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print(error.localizedDescription)
        }
    }
}
