import Foundation

struct Workout {
    let name: String
    let workoutDescription: String
    let workoutSegments: [WorkoutSegment]
    var ftp: Int
    
    var currentSegment: WorkoutSegment
    var currentWattage: Int = 0
    var totalTime: TimeInterval = 0
    var timeElapsed: TimeInterval = 0
    var timeRemaining: TimeInterval = 0
    var timeInSegment: TimeInterval = 0
    var timeLeftInSegment: TimeInterval = 0
    var timeRemainingInSegment: TimeInterval = 0
    

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
}

extension Workout {
    mutating func recalculate(for interval: TimeInterval) {
        var tempElapsedTime = interval
        timeElapsed = tempElapsedTime
        timeRemaining = totalTime - tempElapsedTime
        for segment in workoutSegments {
            if tempElapsedTime - segment.duration > 0 {
                tempElapsedTime = tempElapsedTime - segment.duration
            } else {
                // at this point, tempElapsedTime is the time offset into the segment
                timeInSegment = tempElapsedTime
                currentSegment = segment
                timeRemainingInSegment = segment.duration - timeInSegment
                currentWattage = segment.wattage(for: ftp, interval: timeInSegment)
                break
            }
        }
    }
    
    func nextSegment() -> WorkoutSegment? {
        let index = self.workoutSegments.firstIndex(of: self.currentSegment)! + 1
        return index < workoutSegments.count ? workoutSegments[index] : nil
    }
}
