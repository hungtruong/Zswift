//
//  WorkoutHandler.swift
//  Zswift Watch Extension
//
//  Created by Hung Truong on 4/17/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//
import HealthKit
import WatchKit
import WatchConnectivity

class WorkoutHandler: NSObject, ObservableObject {
    static let shared = WorkoutHandler()
    let healthStore = HKHealthStore()
    var workoutSession: HKWorkoutSession!
    var workoutBuilder: HKLiveWorkoutBuilder!
    let heartRateQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    
    @Published var heartRate = "-"
    @Published var workoutName = ""
    
    override private init()  {}
    
    @objc func playNotification() {
        WKInterfaceDevice.current().play(.start)
    }
    
    func endWorkout(date: Date) {
        workoutSession.end()
        workoutBuilder.endCollection(withEnd: date) { (success, error) in
            self.workoutBuilder.finishWorkout { (workout, error) in }
        }
    }
    
    func sendHeartRate(_ heartRate: Int) {
        guard WCSession.isSupported() else {
            return
        }
        
        let session = WCSession.default
        let message: [String : Any]  = ["heart_rate": heartRate]
        
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    func updateHeartRate(_ heartRate: Int) {
        DispatchQueue.main.async {
            self.heartRate = String(heartRate)
            self.sendHeartRate(heartRate)
        }
    }
}

extension WorkoutHandler: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session on watch completed")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let _ = message["sendReminder"] {
            [1, 2, 3, 4, 5].forEach { count in
                DispatchQueue.main.asyncAfter(deadline: .now() + count) {
                    self.playNotification()
                }
            }
        }
        
        if let calories = message["calories"] as? Int,
            let distance = message["distance"] as? Int,
            let start = message["start"] as? Date,
            let end = message["end"] as? Date
        {
            let calorieQuantityType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
            let caloriesBurned = HKQuantitySample(type: calorieQuantityType, quantity: calorieQuantity, start: start, end: end)
            
            let distanceQuantityType = HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
            let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: Double(distance))
            let distanceCycled = HKQuantitySample(type: distanceQuantityType, quantity: distanceQuantity, start: start, end: end)
            
            self.workoutBuilder.add([caloriesBurned, distanceCycled]) { (_, _) in
                self.endWorkout(date: end)
            }
        }
        
        if let segment = message["segmentName"] as? String,
            let start = message["start"] as? Date, let end = message["end"] as? Date {
            let dateInterval = DateInterval(start: start, end: end)
            let workoutEvent = HKWorkoutEvent(type: .segment, dateInterval: dateInterval,
                                              metadata: ["Segment Name" : segment])
            self.workoutBuilder.addWorkoutEvents([workoutEvent]) { (success, error) in
                print(success ? "Success saving segment" : error as Any)
            }
            
            //phony calories stuff
            let calorieQuantityType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: 10.0)
            let caloriesBurned = HKQuantitySample(type: calorieQuantityType, quantity: calorieQuantity, start: start, end: end)
            self.workoutBuilder.add([caloriesBurned]) { (success, error) in
                print(success ? "Success saving calories" : error as Any)
            }
            
        }
        
        if let workoutName = message["workoutName"] as? String {
            self.workoutName = workoutName
            let metadata = [HKMetadataKeyWorkoutBrandName: workoutName]
            self.workoutBuilder.addMetadata(metadata) { (success, error) in
                print(success ? "Success saving metadata" : error as Any)
            }
        }
    }
}

extension WorkoutHandler: HKWorkoutSessionDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        let unrelatedWorkoutConfiguration = HKWorkoutConfiguration()
        unrelatedWorkoutConfiguration.activityType = .cycling
        unrelatedWorkoutConfiguration.locationType = .indoor
        if let session = try? HKWorkoutSession(healthStore: healthStore, configuration: unrelatedWorkoutConfiguration) {
            self.workoutSession = session
            self.workoutBuilder = workoutSession.associatedWorkoutBuilder()
            self.workoutBuilder.dataSource =
                HKLiveWorkoutDataSource(healthStore: healthStore,
                                        workoutConfiguration: unrelatedWorkoutConfiguration)
            self.workoutSession.delegate = self
            self.workoutBuilder.delegate = self
            session.startActivity(with: Date())
            self.workoutBuilder.beginCollection(withStart: Date()) { (_, _) in }
            startWorkout(date: Date())
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
    
    func startWorkout(date: Date) {

    }
}

extension WorkoutHandler: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return
            }
            
            switch quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                guard let statistics = workoutBuilder.statistics(for: quantityType),
                    let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                    else {
                    break
                }
                self.updateHeartRate(Int(value))
            default:
                break
            }
        }
    }
}
