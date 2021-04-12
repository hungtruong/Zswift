//
//  ExtensionDelegate.swift
//  Zswift Watch Extension
//
//  Created by Hung Truong on 4/17/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//

import HealthKit
import WatchKit
class ExtensionDelegate: NSObject, ObservableObject, WKExtensionDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        WorkoutHandler.shared.handle(workoutConfiguration)
    }
}
