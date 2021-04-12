//
//  WorkoutManager.swift
//  Zswift
//
//  Created by Hung Truong on 4/10/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//
import Combine
import HealthKit
import SwiftUI
import WatchConnectivity

class WorkoutManager: NSObject, ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    private let healthStore = HKHealthStore()
    private var workoutStart = Date()
    private var workoutEnd = Date()
    #if targetEnvironment(simulator)
//    let timeInterval = 1.0
    let timeInterval = 0.05
    private let bluetoothService: ZswiftBluetoothService = MockBluetoothService()
    #else
    let timeInterval = 1.0
    private let bluetoothService: ZswiftBluetoothService = PM5BluetoothService()
    #endif
    private let dateFormatter = DateComponentsFormatter()

    
    private var workoutTimer: AnyPublisher<Date, Never>!
    private var workoutProgresser: Cancellable?
    
    var currentSegmentPublisher: AnyPublisher<(WorkoutSegment, Int)?, Never>!
    var timeInCurrentSegmentPublisher: AnyPublisher<TimeInterval, Never>!
    var timeRemainingInCurrentSegmentPublisher: AnyPublisher<TimeInterval, Never>!

    @AppStorage(ftpKey) var ftp: Int = 160
    @Published var workout: Workout
    @Published var timeElapsed: TimeInterval = 0
    @Published var workoutProgress: Double = 0.0
    @Published var segmentProgress: Double = 0.0
    @Published var currentSegmentDescription: String = ""
    @Published var nextSegmentDescription: String? = nil
    @Published var currentWattage = ""
    @Published var targetWattage = ""
    @Published var timeElapsedString = "00:00"
    @Published var currentSegmentTimeElapsedString = "00:00"
    @Published var currentSegmentTimeString = "00:00"
    @Published var caloriesString = "0"
    @Published var cadenceString = "0"
    @Published var milesString = "0"
    @Published var heartRateString = "-"
    @Published var workoutIsOver = false
    @Published var currentSegmentColor: Color = .blue

    var totalWorkoutTimeString: String = "00:00"
    
    init(workout: Workout) {
        self.workout = workout
        super.init()
        
        dateFormatter.zeroFormattingBehavior = [.pad]
        dateFormatter.allowedUnits = [.minute, .second]
        startWorkout()
        setupObservables()
    }
    
    func setupObservables() {
        bluetoothService.wattValueSubject
            .map { String($0) }
            .assign(to: \.currentWattage, on: self)
            .store(in: &subscriptions)

        bluetoothService.caloriesBurnedSubject
            .map { String($0) }
            .assign(to: \.caloriesString, on: self)
            .store(in: &subscriptions)

        bluetoothService.cadenceValueSubject
            .map { String($0) }
            .assign(to: \.cadenceString, on: self)
            .store(in: &subscriptions)

        bluetoothService.metersTraveledSubject
            .map { String(format: "%.2f", Double($0) * 0.00062137) }
            .assign(to: \.milesString, on: self)
            .store(in: &subscriptions)
        
        self.currentSegmentPublisher =
            $timeElapsed
            .map { [unowned self] timeElapsed in
                var tempElapsedTime = timeElapsed
                for (index, segment) in self.workout.workoutSegments.enumerated() {
                    if tempElapsedTime - segment.duration > 0 {
                        tempElapsedTime = tempElapsedTime - segment.duration
                    } else {
                        return (segment, index)
                    }
                }
                return nil
            }
            .eraseToAnyPublisher()
  
        self.currentSegmentPublisher
            .compactMap { $0?.0 }
            .removeDuplicates()
            .map { $0.description(ftp: self.ftp) }
            .assign(to: \.currentSegmentDescription, on: self)
            .store(in: &subscriptions)
        
        self.currentSegmentPublisher
            .compactMap { $0?.0 }
            .removeDuplicates()
            .compactMap { self.dateFormatter.string(from: $0.duration) }
            .assign(to: \.currentSegmentTimeString, on: self)
            .store(in: &subscriptions)
        
        self.currentSegmentPublisher
            .compactMap { $0?.1 }
            .map { index -> String? in
                if index < self.workout.workoutSegments.count - 1 {
                    let segment = self.workout.workoutSegments[index+1]
                    return segment.description(ftp: self.ftp)
                } else {
                    return nil
                }
            }
            .assign(to: \.nextSegmentDescription, on: self)
            .store(in: &subscriptions)
        
        self.currentSegmentPublisher
            .compactMap { $0?.0 }
            .map { $0.color() }
            .map { Color($0) }
            .assign(to: \.currentSegmentColor, on: self)
            .store(in: &subscriptions)
                    
        self.timeInCurrentSegmentPublisher =
            $timeElapsed
            .compactMap { [unowned self] timeElapsed in
                var tempElapsedTime = timeElapsed
                for (_, segment) in self.workout.workoutSegments.enumerated() {
                    if tempElapsedTime - segment.duration > 0 {
                        tempElapsedTime = tempElapsedTime - segment.duration
                    } else {
                        break
                    }
                }
                return tempElapsedTime
            }
            .eraseToAnyPublisher()
        
        timeInCurrentSegmentPublisher
            .combineLatest(currentSegmentPublisher)
            .map { [unowned self] timeInSegment, currentSegment in
                return currentSegment?.0.wattage(for: self.ftp, interval: timeInSegment) ?? 0
            }
            .map { String($0) }
            .assign(to: \.targetWattage, on: self)
            .store(in: &subscriptions)
        
        timeInCurrentSegmentPublisher
            .combineLatest(currentSegmentPublisher)
            .map { timeInSegment, currentSegment in
                return timeInSegment / TimeInterval(currentSegment?.0.duration ?? 1)
            }
            .map { min(max($0, 0.0), 1.0) }
            .assign(to: \.segmentProgress, on: self)
            .store(in: &subscriptions)
   
        timeRemainingInCurrentSegmentPublisher =
            timeInCurrentSegmentPublisher
            .combineLatest(currentSegmentPublisher)
            .map { timeInSegment, currentSegment in
                return (currentSegment?.0.duration ?? 0) - timeInSegment
            }
            .eraseToAnyPublisher()
        
        timeRemainingInCurrentSegmentPublisher
            .compactMap { self.dateFormatter.string(from: $0) }
            .assign(to: \.currentSegmentTimeElapsedString, on: self)
            .store(in: &subscriptions)
        
        timeRemainingInCurrentSegmentPublisher
            .filter { $0 == 5 }
            .sink { _ in self.sendSegmentEndNotifier() }
            .store(in: &subscriptions)
        
        $timeElapsed
            .compactMap { Double($0 / self.workout.totalTime) }
            .map { min(max($0, 0.0), 1.0) }
            .assign(to: \.workoutProgress, on: self)
            .store(in: &subscriptions)
        
        $timeElapsed
            .map { $0 > self.workout.totalTime }
            .first { $0 }
            .assign(to: \.workoutIsOver, on: self)
            .store(in: &subscriptions)
        
        $workoutIsOver
            .sink { if $0 { self.workoutProgresser?.cancel() } }
            .store(in: &subscriptions)
    }
    
    func startWorkout() {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .cycling
        workoutConfiguration.locationType = .indoor
        
        self.healthStore.startWatchApp(with: workoutConfiguration) { [unowned self] (success, error) in
            if success {
                print("Success starting workout")
                self.startWatch()
                self.sendWorkoutMetadata()
            }
        }
        
        self.totalWorkoutTimeString = dateFormatter.string(from: workout.totalTime) ?? ""
        workoutTimer = Timer.publish(every: timeInterval, on: .main, in: .default)
            .autoconnect()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
  
        workoutProgresser =
            workoutTimer
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                if self.bluetoothService.wattValueSubject.value > 30 {
                    self.timeElapsed = self.timeElapsed.advanced(by: 1.0)
                    self.timeElapsedString = self.dateFormatter.string(from: self.timeElapsed)!
                }
            }
    }
    
    func endWorkout() {
        workoutProgresser?.cancel()
        self.workoutEnd = Date()
        sendWorkoutSamples()
        subscriptions.removeAll()
    }
}

extension WorkoutManager: WCSessionDelegate {
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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.heartRateString = String(heartRate)
            }
        }
    }
    
    func sendWorkoutSamples() {
        let message: [String : Any] = ["calories": self.bluetoothService.caloriesBurnedSubject.value,
                                       //TODO convert to miles
                                       "distance": self.bluetoothService.metersTraveledSubject.value,
                                       "start": self.workoutStart,
                                       "end": self.workoutEnd]
        
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    func sendWorkoutMetadata() {
        let message: [String : Any] = ["workoutName": self.workout.name]
        
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    func sendSegmentEndNotifier() {
        let message: [String: Any] = ["sendReminder": "foo"]
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}
