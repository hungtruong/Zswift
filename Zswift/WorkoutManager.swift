import Foundation

class WorkoutManager {
    static let shared = WorkoutManager()
    private(set) var workouts: [Workout] = []
    private init() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "zwo", subdirectory: "Workouts") else {
            return
        }
        
        for url in urls {
            let zwoParser = ZWOParser()
            guard let content = try? String(contentsOf: url, encoding: String.Encoding.utf8),
                let xmlData = content.data(using: .utf8) else {
                    return
            }
            
            let parser = XMLParser(data: xmlData)
            
            parser.delegate = zwoParser;
            parser.parse()
            
            if let workout = zwoParser.workout() {
                self.workouts.append(workout)
            }
        }
    }
}
