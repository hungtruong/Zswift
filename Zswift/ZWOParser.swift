import Foundation
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
    }
    
    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
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
    }
}
