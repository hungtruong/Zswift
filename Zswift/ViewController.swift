import CoreBluetooth
import UIKit

class ViewController: UIViewController {
    @IBOutlet var wattLabel: UILabel!
    
    let bluetoothService = BluetoothService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // made a timer cause I didn't make the vc the delegate like almost everyone else does
        let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            self.checkService()
        }
        RunLoop.current.add(timer, forMode: .default)
    }
    
    func checkService() {
        self.updateWattLabel(String(format: "%i", self.bluetoothService.wattValue))
    }

    func updateWattLabel(_ title: String) {
        self.wattLabel.text = title
    }

}

class BluetoothService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let centralManager = CBCentralManager()
    var connectedPeripherals: [CBPeripheral] = []
    var wattValue: Int = 0
    
    override init() {
        super.init()
        self.centralManager.delegate = self
    }
    
    func scan() {
        self.centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "PM5 430785713" {
            // I got an error when I didn't retain this peripheral
            connectedPeripherals.append(peripheral)
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("failed to connect")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            scan()
        default:
            break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discovered characteristics for \(service)")
        print("\(String(describing: service.characteristics))")
        service.characteristics?.forEach({ peripheral.setNotifyValue(true, for: $0) })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("discovered included characteristics for \(service)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("discovered services")
        print(peripheral.services ?? "")
        if let services = peripheral.services {
            services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("updated notification state for \(characteristic)")
        if let error = error {
            print(error)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print(characteristic.uuid)
        let array = [UInt8](characteristic.value!)
        print(array)
        // this is the characteristic's uuid that contains wattage info which is the only one i care about right now
        if characteristic.uuid == CBUUID(string: "CE060036-43E5-11E4-916C-0800200C9A66") {
            self.wattValue = Int(array[3])
        }
    }
}
