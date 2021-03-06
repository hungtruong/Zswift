import Foundation
import UIKit
import Combine

class Workout: ObservableObject, Identifiable {
    var subscriptions = Set<AnyCancellable>()
    
    let name: String
    let workoutDescription: String
    let workoutSegments: [WorkoutSegment]
    let uuid = UUID() // for equatable
    let totalTime: TimeInterval

    init(name: String, workoutDescription: String, workoutSegments: [WorkoutSegment], ftp: Int,
         currentSegment: WorkoutSegment? = nil) {
        self.name = name
        self.workoutDescription = workoutDescription
        let workoutSegmentsArrays = workoutSegments.compactMap({ segment -> [WorkoutSegment] in
            return segment.expandedWorkoutSegments()
        })
        
        self.workoutSegments =  Array(workoutSegmentsArrays.joined())
        self.totalTime = self.workoutSegments.reduce(0.0, { (total, segment) -> TimeInterval in
            return total + segment.duration
        })
        

    }
}

enum WorkoutSegment: Equatable, Hashable {    
    static var dateFormatter = DateComponentsFormatter() {
        didSet {
            dateFormatter.zeroFormattingBehavior = [.pad]
            dateFormatter.allowedUnits = [.minute, .second]
        }
    }

    case warmup(duration: TimeInterval, powerLow: Double, powerHigh: Double)
    case intervals(reps: Int, onDuration: TimeInterval, offDuration: TimeInterval, onPower: Double,
        offPower: Double)
    case steady(duration: TimeInterval, power: Double)
    case cooldown(duration: TimeInterval, powerLow: Double, powerHigh: Double)
    
    var duration: TimeInterval {
        switch self {
        case .warmup(duration: let duration, powerLow: _, powerHigh: _):
            return duration.rounded()
        case .steady(duration: let duration, power: _):
            return duration.rounded()
        case .intervals(reps: _, onDuration: _, offDuration: _, onPower: _, offPower: _):
            return 0
        case .cooldown(duration: let duration, powerLow: _, powerHigh: _):
            return duration.rounded()
        }
    }
    
    func wattage(for ftp: Int, interval: TimeInterval) -> Int {
        func roundToFive(_ number: Int) -> Int {
            return (number + 4) / 5 * 5;
        }
        
        switch self {
        case .warmup(duration: let duration, powerLow: let powerLow, powerHigh: let powerHigh),
             .cooldown(duration: let duration, powerLow: let powerLow, powerHigh: let powerHigh):
            return roundToFive(Int((((interval / duration) * (powerHigh - powerLow)) + powerLow) * Double(ftp)))
        case .steady(duration: _, power: let power):
            return roundToFive(Int(power * Double(ftp)))
        case .intervals(reps: _, onDuration: _, offDuration: _, onPower: _, offPower: _):
            return 0
        }
    }
    
    /// Returns an array of segments, just the segment itself if it's not an interval and
    /// the expanded set of intervals if it is an interval segment
    func expandedWorkoutSegments() -> [WorkoutSegment] {
        switch self {
        case .warmup, .steady, .cooldown:
            return [self]
        case .intervals(reps: let reps, onDuration: let onDuration, offDuration: let offDuration,
                        onPower: let onPower, offPower: let offPower):
            var segments: [WorkoutSegment] = []
            for _ in stride(from: 0, to: reps, by: 1) {
                segments.append(.steady(duration: onDuration, power: onPower))
                segments.append(.steady(duration: offDuration, power: offPower))
            }
            return segments
        }
    }
    
    func description(ftp: Int?) -> String {
        var wattageString = ""
        if let ftp = ftp {
            let wattage = self.wattage(for: ftp, interval: 0)
            wattageString = String(wattage)
        }
        
        switch self {
        case .warmup(duration: _, powerLow: _, powerHigh: _):
            return "Warmup"
        case .steady(duration: _, power: _):
            return "Steady" + String(format: " %@w %@m", wattageString, WorkoutSegment.dateFormatter.string(from: self.duration)!)
        case .intervals(reps: _, onDuration: _, offDuration: _, onPower: _, offPower: _):
            return ""
        case .cooldown(duration: _, powerLow: _, powerHigh: _):
            return "Cooldown"
        }
    }
    
    func highPower() -> Double {
        switch self {
        case .warmup(duration: _, powerLow: let powerLow, powerHigh: _):
            return powerLow
        case .steady(duration: _, power: let power):
            return power
        case .intervals(reps: _, onDuration: _, offDuration: _, onPower: _, offPower: _):
            return 0.0
        case .cooldown(duration: _, powerLow: _, powerHigh: let powerHigh):
            return powerHigh
        }
    }
    
    func startPower() -> Double {
        switch self {
        case let .warmup(_, powerLow, _):
            return powerLow
        case let .steady(_, power):
            return power
        case .intervals:
            return 0.0
        case let .cooldown(_, powerLow, _):
            return powerLow
        }
    }
    
    func endPower() -> Double {
        switch self {
        case let .warmup(_, _, powerHigh):
            return powerHigh
        case let .steady(_, power):
            return power
        case .intervals:
            return 0.0
        case let .cooldown(_, _, powerHigh):
            return powerHigh
        }
    }
    
    func color() -> UIColor {
        switch self.highPower() {
        case let p where p <= 0.6 :
            return UIColor(named: "Gray") ?? .black
        case let p where p < 0.76:
            return UIColor(named: "Blue") ?? .black
        case let p where p < 0.90:
            return UIColor(named: "Green") ?? .black
        case let p where p < 1.05:
            return UIColor(named: "Yellow") ?? .black
        case let p where p < 1.19:
            return UIColor(named: "Orange") ?? .black
        default:
            return UIColor(named: "Red") ?? .black
        }
    }
}

extension Workout {
    func maximumPower() -> Double {
        return workoutSegments.map{ $0.highPower() }.max()!
    }
}

extension Workout: Hashable, Equatable {
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

extension Workout {
    static func mockWorkout() -> Workout {
        let workoutSegments: [WorkoutSegment] = [
            WorkoutSegment.warmup(duration: 420, powerLow: 0.25, powerHigh: 0.77),
            WorkoutSegment.steady(duration: 120, power: 0.95),
            WorkoutSegment.steady(duration: 60, power: 0.5),
            WorkoutSegment.steady(duration: 120, power: 0.95),
            WorkoutSegment.steady(duration: 120, power: 0.5),
            WorkoutSegment.steady(duration: 540, power: 0.80),
            WorkoutSegment.steady(duration: 120, power: 0.5),
            WorkoutSegment.cooldown(duration: 300, powerLow: 0.75, powerHigh: 0.25)
        ]
        
        return Workout(name: "Fake workout", workoutDescription: "This workout is just a test", workoutSegments: workoutSegments, ftp: 160)
    }
}
