import Foundation
import UIKit

protocol WorkoutDelegate {
    func currentSegmentChanged(segment: WorkoutSegment)
}

struct Workout {
    var delegate: WorkoutDelegate?
    
    let name: String
    let workoutDescription: String
    let workoutSegments: [WorkoutSegment]
    var ftp: Int
    let uuid = UUID() // for equatable
    
    var currentSegment: WorkoutSegment? = nil {
        didSet {
            if oldValue != currentSegment {
                delegate?.currentSegmentChanged(segment: currentSegment!)
            }
        }
    }
    
    private var currentSegmentIndex = 0
    
    var currentWattage: Int = 0
    var totalTime: TimeInterval = 0
    var timeElapsed: TimeInterval = 0
    var timeRemaining: TimeInterval = 0
    var timeInSegment: TimeInterval = 0
    var timeLeftInSegment: TimeInterval = 0
    var timeRemainingInSegment: TimeInterval = 0
    var startTime: Date?

    init(name: String, workoutDescription: String, workoutSegments: [WorkoutSegment], ftp: Int,
         currentSegment: WorkoutSegment? = nil) {
        self.name = name
        self.workoutDescription = workoutDescription
        let workoutSegmentsArrays = workoutSegments.compactMap({ segment -> [WorkoutSegment] in
            return segment.expandedWorkoutSegments()
        })
        
        self.workoutSegments =  Array(workoutSegmentsArrays.joined())
        self.ftp = ftp
        self.currentSegment = workoutSegments.first!
        self.currentWattage = 0
        self.totalTime = self.workoutSegments.reduce(0.0, { (total, segment) -> TimeInterval in
            return total + segment.duration
        })
    }
}

enum WorkoutSegment: Equatable {
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
            return "Steady" + String(format: " @%@w %@m", wattageString, WorkoutSegment.dateFormatter.string(from: self.duration)!)
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
        }    }
    
    func color() -> UIColor {
        switch self.highPower() {
        case let p where p <= 0.6 :
            return .gray
        case let p where p < 0.76:
            return .blue
        case let p where p < 0.90:
            return .green
        case let p where p < 1.05:
            return .yellow
        case let p where p < 1.19:
            return .orange
        default:
            return .red
        }
    }
}

extension Workout {
    mutating func recalculate(for interval: TimeInterval) {
        var tempElapsedTime = interval
        timeElapsed = tempElapsedTime
        timeRemaining = totalTime - tempElapsedTime
        for (index, segment) in workoutSegments.enumerated() {
            if tempElapsedTime - segment.duration > 0 {
                tempElapsedTime = tempElapsedTime - segment.duration
            } else {
                // at this point, tempElapsedTime is the time offset into the segment
                timeInSegment = tempElapsedTime
                currentSegment = segment
                currentSegmentIndex = index
                timeRemainingInSegment = segment.duration - timeInSegment
                currentWattage = segment.wattage(for: ftp, interval: timeInSegment)
                break
            }
        }
    }
    
    func nextSegment() -> WorkoutSegment? {
        let index = currentSegmentIndex + 1
        return index < workoutSegments.count ? workoutSegments[index] : nil
    }
    
    func maximumPower() -> Double {
        return workoutSegments.map{ $0.highPower() }.max()!
    }
    
    func dateInterval(for segment: WorkoutSegment) -> DateInterval? {
        guard var startTime = startTime else { return nil }
        for workoutSegment in workoutSegments {
            if segment == workoutSegment {
                return DateInterval(start: startTime, duration: segment.duration)
            } else {
                // add segment time to start time
                startTime.addTimeInterval(workoutSegment.duration)
            }
        }
        return nil
    }
}

/*
0-60% is zone 1
61-75 is zone 2
76-89 is zone 3
 89-104 zone 4
 105-118 zone 5
 119+ zone 6
*/
