import Combine
import CoreBluetooth

protocol ZswiftBluetoothService {
    var wattValueSubject: CurrentValueSubject<Int, Never> { get }
    var metersTraveledSubject: CurrentValueSubject<Int, Never> { get }
    var caloriesBurnedSubject: CurrentValueSubject<Int, Never> { get }
    var cadenceValueSubject: CurrentValueSubject<Int, Never> { get }
}

class PM5BluetoothService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ZswiftBluetoothService {
    var wattValueSubject = CurrentValueSubject<Int, Never>(0)
    var metersTraveledSubject = CurrentValueSubject<Int, Never>(0)
    var caloriesBurnedSubject = CurrentValueSubject<Int, Never>(0)
    var cadenceValueSubject = CurrentValueSubject<Int, Never>(0)

    let centralManager = CBCentralManager()
    var connectedPeripherals: [CBPeripheral] = []
            
    let service = CBUUID(string: "CE060030-43E5-11E4-916C-0800200C9A66")
    
    let characteristic31 = CBUUID(string: "CE060031-43E5-11E4-916C-0800200C9A66")
    let characteristic32 = CBUUID(string: "CE060032-43E5-11E4-916C-0800200C9A66")
    let characteristic33 = CBUUID(string: "CE060033-43E5-11E4-916C-0800200C9A66")
    let characteristic36 = CBUUID(string: "CE060036-43E5-11E4-916C-0800200C9A66")
    
    var desiredCharacteristics: [CBUUID] = []
    
    override init() {
        super.init()
        self.centralManager.delegate = self
        self.desiredCharacteristics = [characteristic31, characteristic32, characteristic33, characteristic36]
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
        central.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected")
        self.scan()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("failed to connect")
        self.scan()
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
        service.characteristics?.forEach({
            if desiredCharacteristics.contains($0.uuid) {
                peripheral.setNotifyValue(true, for: $0)
            }
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("discovered included characteristics for \(service)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("discovered services")
        print(peripheral.services ?? "")
        if let services = peripheral.services {
            services.forEach {
                if $0.uuid == service {
                    peripheral.discoverCharacteristics(nil, for: $0)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("updated notification state for \(characteristic)")
        if let error = error {
            print(error)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let array = [UInt8](characteristic.value!)
        switch characteristic.uuid {
        case characteristic32:
            self.cadenceValueSubject.send(Int(array[5]))
        case characteristic33:
            self.caloriesBurnedSubject
                .send(Int((UInt16(array[7]) << 8) | UInt16(array[6])))
        case characteristic31:
            self.metersTraveledSubject
                .send(Int((UInt32(array[5]) << 16 | UInt32(array[4]) << 8 | UInt32(array[3]))) / 10)
        case characteristic36:
            self.wattValueSubject.send(Int((UInt16(array[4]) << 8) | UInt16(array[3])))
        default:
            break
        }
    }
}
