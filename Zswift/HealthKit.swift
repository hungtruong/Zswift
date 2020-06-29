import Foundation
import HealthKit

func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
    guard HKHealthStore.isHealthDataAvailable() else {
        completion(false, nil)
        return
    }
    
    guard
        let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
        let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
        let cyclingDistance = HKObjectType.quantityType(forIdentifier: .distanceCycling) else {
            completion(false, nil)
            return
    }
    
    let healthKitTypesToWrite: Set<HKSampleType> = [heartRate,
                                                    activeEnergy,
                                                    HKObjectType.workoutType(),
                                                    cyclingDistance
    ]
    
    let healthKitTypesToRead: Set<HKObjectType> = [heartRate,
                                                   activeEnergy,
                                                   HKObjectType.workoutType(),
                                                   cyclingDistance
    ]
    
    HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                         read: healthKitTypesToRead) { (success, error) in
                                            completion(success, error)
    }
}
