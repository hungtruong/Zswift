import Foundation

struct Workout {
    let name: String
    let workoutDescription: String
    let workoutSegments: [WorkoutSegment]
    let ftp: Int
    
    var currentSegment: WorkoutSegment
    var currentWattage: Int
    var totalTime: TimeInterval
    var timeRemaining: TimeInterval
    var timeInSegment: TimeInterval
    var timeRemainingInSegment: TimeInterval
    
    init(name: String, workoutDescription: String, workoutSegments: [WorkoutSegment], ftp: Int,
         currentSegment: WorkoutSegment? = nil, currentWattage: Int? = 0, totalTime: TimeInterval? = 0.0,
         timeRemaining: TimeInterval? = 0.0, timeInSegment: TimeInterval? = 0.0, timeRemainingInSegment: TimeInterval? = 0.0) {
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
        
        self.timeRemaining = 0.0
        self.timeInSegment = 0.0
        self.timeRemainingInSegment = 0.0
    }
}

enum WorkoutSegment {
    case warmup(duration: TimeInterval, powerLow: Double, powerHigh: Double)
    case intervals(reps: Int, onDuration: TimeInterval, offDuration: TimeInterval, onPower: Double,
        offPower: Double)
    case steady(duration: TimeInterval, power: Double)
    case cooldown(duration: TimeInterval, powerLow: Double, powerHigh: Double)
    
    var duration: TimeInterval {
        switch self {
        case .warmup(duration: let duration, powerLow: _, powerHigh: _):
            return duration
        case .steady(duration: let duration, power: _):
            return duration
        case .intervals(reps: _, onDuration: _, offDuration: _, onPower: _, offPower: _):
            return 0
        case .cooldown(duration: let duration, powerLow: _, powerHigh: _):
            return duration
        }
    }
    
    func wattage(for ftp: Int, interval: TimeInterval) -> Int {
        switch self {
        case .warmup(duration: let duration, powerLow: let powerLow, powerHigh: let powerHigh):
            return Int((((interval / duration) * (powerHigh - powerLow)) + powerLow) * Double(ftp))
        case .steady(duration: _, power: let power):
            return Int(power * Double(ftp))
        case .intervals(reps: _, onDuration: _, offDuration: _, onPower: _, offPower: _):
            return 0
        case .cooldown(duration: let duration, powerLow: let powerLow, powerHigh: let powerHigh):
            return Int(((((duration - interval) / duration) * (powerHigh - powerLow)) + powerLow) * Double(ftp))
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
                segments.append(.steady(duration: offDuration, power: offPower))
                segments.append(.steady(duration: onDuration, power: onPower))
            }
            return segments
        }
    }
}

extension Workout {
    mutating func recalculate(for interval: inout TimeInterval) {
        timeRemaining = totalTime - interval
        for segment in workoutSegments {
            if interval - segment.duration > 0 {
                interval = interval - segment.duration
            } else {
                currentSegment = segment
                timeRemainingInSegment = segment.duration - interval
                currentWattage = segment.wattage(for: ftp, interval: interval)
                timeInSegment = interval
                break
            }
        }
    }
}



let segments: [WorkoutSegment] = [.warmup(duration: 60, powerLow: 0.5, powerHigh: 1.0),
                                  .intervals(reps: 2, onDuration: 30, offDuration: 30, onPower: 0.5, offPower: 0.25),
                                  .steady(duration: 60, power: 1),
                                  .cooldown(duration: 60, powerLow: 0.5, powerHigh: 1.0)]

var workout = Workout(name: "hung", workoutDescription: "hung", workoutSegments: segments,
                      ftp: 100, currentSegment: nil, currentWattage: nil, totalTime: nil, timeRemaining: nil, timeInSegment: nil, timeRemainingInSegment: nil)

var timeInterval = TimeInterval(130.0)
workout.recalculate(for: &timeInterval)

class ZWOParser: NSObject, XMLParserDelegate {
    private var workoutName: String?
    private var workoutDescription: String?
    private var workoutSegments: [WorkoutSegment] = []
    private var characters: String? = nil
    
    func workout() -> Workout? {
        guard let workoutName = self.workoutName, let workoutDescription = self.workoutDescription else {
            return nil
        }
        
        return Workout(name: workoutName, workoutDescription: workoutDescription, workoutSegments: workoutSegments, ftp: 0)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "Warmup":
            guard let durationString = attributeDict["Duration"], let duration = Double(durationString),
            let powerLowString = attributeDict["PowerLow"], let powerLow = Double(powerLowString),
            let powerHighString = attributeDict["PowerHigh"], let powerHigh = Double(powerHighString)  else {
                return
            }
            self.workoutSegments.append(.warmup(duration: TimeInterval(duration), powerLow: powerLow,
                                                powerHigh: powerHigh))
        case "IntervalsT":
            guard let repeatString = attributeDict["Repeat"], let repeatCount = Int(repeatString),
            let onDurationString = attributeDict["OnDuration"], let onDuration = Double(onDurationString),
            let offDurationString = attributeDict["OffDuration"], let offDuration = Double(offDurationString),
            let onPowerString = attributeDict["OnPower"], let onPower = Double(onPowerString),
            let offPowerString = attributeDict["OffPower"], let offPower = Double(offPowerString) else {
                return
            }
            self.workoutSegments.append(.intervals(reps: repeatCount, onDuration: onDuration, offDuration: offDuration, onPower: onPower, offPower: offPower))
        case "SteadyState":
            guard let durationString = attributeDict["Duration"], let duration = Double(durationString),
                let powerString = attributeDict["Power"], let power = Double(powerString) else {
                    return
            }
            self.workoutSegments.append(.steady(duration: duration, power: power))
        case "Cooldown":
            guard let durationString = attributeDict["Duration"], let duration = Double(durationString),
                let powerLowString = attributeDict["PowerLow"], let powerLow = Double(powerLowString),
                let powerHighString = attributeDict["PowerHigh"], let powerHigh = Double(powerHighString)  else {
                    return
            }
            self.workoutSegments.append(.cooldown(duration: duration, powerLow: powerLow, powerHigh: powerHigh))
        default:
            break
        }
        print(elementName)
    }
    
    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
        print(elementName)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let characters = self.characters else {
            self.characters = string
            return
        }
        self.characters = characters + string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "name":
            self.workoutName = self.characters?.trimmingCharacters(in: .whitespacesAndNewlines)
        case "description":
            self.workoutDescription = self.characters?.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            break
        }
        characters = nil
        print(elementName + "ended")
    }
}

let zwoParser = ZWOParser()

let fileURL = Bundle.main.url(forResource: "Jon_s_Short_Mix", withExtension: "zwo")
let content = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)

let xmlData = content.data(using: .utf8)!
let parser = XMLParser(data: xmlData)

parser.delegate = zwoParser;

parser.parse()

let w = zwoParser.workout()
print(w)
