import Combine
import Foundation

class MockBluetoothService: ZswiftBluetoothService {
    var wattValueSubject = CurrentValueSubject<Int, Never>(52)
    var metersTraveledSubject = CurrentValueSubject<Int, Never>(0)
    var caloriesBurnedSubject = CurrentValueSubject<Int, Never>(0)
    var cadenceValueSubject = CurrentValueSubject<Int, Never>(54)
    var timer: Cancellable?
    
    init() {
        timer = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] _ in
                self.wattValueSubject.send(
                    max(self.wattValueSubject.value + Int.random(in: -2...2), 41)
                )
                self.metersTraveledSubject.send(
                    self.metersTraveledSubject.value + Int.random(in: 1...25)
                )
                self.caloriesBurnedSubject.send(
                    self.caloriesBurnedSubject.value + Int.random(in: 0...1)
                )
                self.cadenceValueSubject.send(
                    self.cadenceValueSubject.value + Int.random(in: -1...1)
                )
            })
    }
}
