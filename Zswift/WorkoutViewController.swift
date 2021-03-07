import Combine
import HealthKit
import UIKit
import WatchConnectivity

class WorkoutViewController: UIViewController {
    private let healthStore = HKHealthStore()
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
    
    private var workoutTimer: Cancellable!
    private var subscriptions = Set<AnyCancellable>()
    
    var workout: Workout! {
        didSet {
            workout.ftp = ftp
            workout.delegate = self
        }
    }
    
    let ftp = UserDefaults.standard.integer(forKey: ftpKey)
    let dateFormatter = DateComponentsFormatter()
    
    #if targetEnvironment(simulator)
    var bluetoothService: ZswiftBluetoothService = MockBluetoothService()
    #else
    var bluetoothService: ZswiftBluetoothService = PM5BluetoothService()
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        startWatch()
        dateFormatter.zeroFormattingBehavior = [.pad]
        dateFormatter.allowedUnits = [.minute, .second]
        
        #if targetEnvironment(simulator)
        let timeInterval = 0.1
        #else
        let timeInterval = 1.0
        #endif
        
        workoutTimer = Timer.publish(every: timeInterval, on: .main, in: .default)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.checkService()
            })

        self.workoutView.setupWorkout(self.workout)
        setupSubscribers()
    }
    
    func setupSubscribers() {
        self.bluetoothService.wattValueSubject
            .receive(on: RunLoop.main)
            .sink { watts in
                self.targetWattsLabel.text =
                    String(format: "%i / %i", watts, self.workout.currentTargetWattage)
            }
            .store(in: &subscriptions)
        
        self.bluetoothService.metersTraveledSubject
            .receive(on: RunLoop.main)
            .sink { meters in
                self.distanceLabel.text = String(format: "%.2f", Double(meters) * 0.00062137)
            }
            .store(in: &subscriptions)
        
        self.bluetoothService.cadenceValueSubject
            .receive(on: RunLoop.main)
            .sink { cadence in
                self.cadenceLabel.text = String(cadence)
            }
            .store(in: &subscriptions)
        
        self.bluetoothService.caloriesBurnedSubject
            .receive(on: RunLoop.main)
            .sink { calories in
                self.caloriesLabel.text = String(calories)
            }
            .store(in: &subscriptions)
    }
    
    func setupWorkout() {
        workoutStart = Date()
        workout.startTime = workoutStart

        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .cycling
        workoutConfiguration.locationType = .indoor
        
        self.healthStore.startWatchApp(with: workoutConfiguration) { (success, error) in
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
        self.workoutTimer.cancel()

        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func checkService() {
        let currentWatts = self.bluetoothService.wattValueSubject.value
        
        if currentWatts < 30 {
            self.targetWattsLabel.text = "0"
            // workout hasn't started or i stopped pedaling
        } else {
            if workout.timeElapsed == 0 {
                setupWorkout()
            }
            
            guard workout.timeElapsed <= workout.totalTime else {
                // end workout
                self.endWorkout()
                return
            }
            
            guard let currentSegment = workout.currentSegment else {
                return
            }
                        
            // tell delegate that segment changed
            if workout.currentSegment != currentSegment {
                currentSegmentChanged(segment: currentSegment)
            }
            
            workoutView.updateProgress(Float(workout.timeElapsed / workout.totalTime))
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
        let message: [String : Any] = ["calories": self.bluetoothService.caloriesBurnedSubject.value,
                                       //TODO convert to miles
                                       "distance": self.bluetoothService.metersTraveledSubject.value,
                                       "start": self.workoutStart!,
                                       "end": self.workoutEnd!]
        
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    func sendWorkoutMetadata() {
        let message: [String : Any] = ["workoutName": self.workout.name]
        
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
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
        print("Session Activated")
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
