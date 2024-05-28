//
//  ESP32Device.swift
//  ESP32 Fridge
//
//  Created by Anshul Gupta on 5/26/24.
//

import Foundation
import CoreBluetooth

class ESP32Device: NSObject, CBPeripheralDelegate, ObservableObject, FridgeDevice {
    @Published var time: Date = Date(timeIntervalSince1970: 0)
    @Published var version: UInt32 = 0
    
    static let defaultTemp = Measurement(value: 0, unit: UnitTemperature.celsius)
    @Published var coolerTemp = defaultTemp
    @Published var ambientTemp = defaultTemp
    @Published var waterTemp = defaultTemp
    
    @Published var receivedAttribs = Set<FridgeDeviceAttributes>()
    
    var name: String? {
        get { peripheral.name }
    }
    var identifier: UUID {
        get { peripheral.identifier }
    }
    
    @Published var connected = false

    private var peripheral: CBPeripheral
    
    static let requiredServices = [
        ESP32DeviceConstants.deviceInfoService,
        ESP32DeviceConstants.tempService,
        ESP32DeviceConstants.timeService
    ]

    override var description: String {
        get {
            return "ESP32Device: \(peripheral)"
        }
    }

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
        self.connected = self.peripheral.state == .connected
    }
    
    func retrieve(for attrs: FridgeDeviceAttributes) {
        self.connected = self.peripheral.state == .connected
        guard self.connected else { return }

        if attrs.contains(.version) {
            self.read(suuid: ESP32DeviceConstants.deviceInfoService, cuuid: ESP32DeviceConstants.versionChar)
        }
        if attrs.contains(.time) {
            self.read(suuid: ESP32DeviceConstants.timeService, cuuid: ESP32DeviceConstants.getTimeChar)
        }
        if attrs.contains(.cooler) {
            self.read(suuid: ESP32DeviceConstants.tempService, cuuid: ESP32DeviceConstants.coolerChar)
        }
        if attrs.contains(.ambient) {
            self.read(suuid: ESP32DeviceConstants.tempService, cuuid: ESP32DeviceConstants.ambientChar)
        }
        if attrs.contains(.water) {
            self.read(suuid: ESP32DeviceConstants.tempService, cuuid: ESP32DeviceConstants.waterChar)
        }
    }
    
    func setTime(_ date: Date) {
        guard let char = self.findCharacteristic(suuid: ESP32DeviceConstants.timeService, cuuid: ESP32DeviceConstants.setTimeChar) else { return }
        self.peripheral.writeValue(dateToData(date), for: char, type: .withResponse)
    }
    
    /// Equality Override
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? ESP32Device {
            return self.identifier == other.identifier
        } else {
            return false
        }
    }
    
    /// Connect to device using `CBCentralManager`.
    func connect(manager: CBCentralManager) {
        manager.connect(self.peripheral)
    }
    
    /// Disconnect from device.
    func disconnect(manager: CBCentralManager) {
        manager.cancelPeripheralConnection(self.peripheral)
    }
    
    /// Read a characteristic from a service UUID and characteristic UUID.
    func read(suuid: CBUUID, cuuid: CBUUID) {
        guard let char = self.findCharacteristic(suuid: suuid, cuuid: cuuid) else { return }
        self.peripheral.readValue(for: char)
    }
    
    /// Find the `CBCharacteristic` object from a service UUID and characteristic UUID.
    func findCharacteristic(suuid: CBUUID, cuuid: CBUUID) -> CBCharacteristic? {
        guard let services = peripheral.services else { return nil }
        
        for service in services {
            if service.uuid != suuid { continue }
            guard let chars = service.characteristics else { return nil }
            for char in chars {
                if char.uuid == cuuid {
                    return char
                }
            }
        }
        
        return nil
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let service = characteristic.service else { return }
        
        switch service.uuid {
        case ESP32DeviceConstants.deviceInfoService:
            switch characteristic.uuid {
            case ESP32DeviceConstants.versionChar:
                let x = characteristic.value.map(dataToUInt32)
                self.version = (x ?? 0) ?? 0
                self.receivedAttribs.insert(.version)
            default:
                print("Oh No2!")
            }
        case ESP32DeviceConstants.timeService:
            switch characteristic.uuid {
            case ESP32DeviceConstants.getTimeChar:
                let x = characteristic.value.map(dataToUInt32)
                let timestamp = TimeInterval((x ?? 0) ?? 0)
                self.time = Date(timeIntervalSince1970: timestamp)
                self.receivedAttribs.insert(.time)
            default:
                print("Oh No3!")
            }
        case ESP32DeviceConstants.tempService:
            switch characteristic.uuid {
            case ESP32DeviceConstants.coolerChar:
                self.coolerTemp = (characteristic.value.map(dataToTemp) ?? ESP32Device.defaultTemp) ?? ESP32Device.defaultTemp
                self.receivedAttribs.insert(.cooler)
            case ESP32DeviceConstants.ambientChar:
                self.ambientTemp = (characteristic.value.map(dataToTemp) ?? ESP32Device.defaultTemp) ?? ESP32Device.defaultTemp
                self.receivedAttribs.insert(.ambient)
            case ESP32DeviceConstants.waterChar:
                self.waterTemp = (characteristic.value.map(dataToTemp) ?? ESP32Device.defaultTemp) ?? ESP32Device.defaultTemp
                self.receivedAttribs.insert(.water)
            default:
                print("Oh No4!")
            }
        default:
            print("Oh No!")
        }
    }
}

struct ESP32DeviceConstants {
    static let deviceInfoService = CBUUID(string: "0x180A")
    static let versionChar = CBUUID(string: "0x2A28")
    
    static let timeService = CBUUID(string: "0x1847")
    static let getTimeChar = CBUUID(string: "0x2A2B")
    static let setTimeChar = CBUUID(string: "65625049-d533-4c6c-9c2b-b2a1291d146f")
    
    static let tempService = CBUUID(string: "3cfc3156-2944-489c-b82d-554c3c422281")
    static let coolerChar = CBUUID(string: "dd45aa1d-a42d-4ada-8cc6-6bbb87b681b0")
    static let ambientChar = CBUUID(string: "ecbc2ad7-c41b-4b67-95b6-865255a8cb59")
    static let waterChar = CBUUID(string: "fee1b7f3-5e0f-47eb-964d-8d5913e0ca86")
}

/// Convert `Data` to a `UInt32` as specified by ESP32-Fridge
func dataToUInt32(_ data: Data) -> UInt32? {
    guard data.count == 4 else { return nil }
    return data.withUnsafeBytes {
        $0.load(as: UInt32.self)
    }.littleEndian
}

/// Convert `Data` to a `Float32` as specified by ESP32-Fridge
func dataToFloat32(_ data: Data) -> Float32? {
    guard let int = dataToUInt32(data) else { return nil }
    return Float(bitPattern: int)
}

/// Convert `Data` to a Temperature as specified by ESP32-Fridge
func dataToTemp(_ data: Data) -> Measurement<UnitTemperature>? {
    guard let float = dataToFloat32(data) else { return nil }
    return Measurement(value: Double(float), unit: .celsius)
}

/// Convert a `Date` to `Data` as specified by ESP32-Fridge
func dateToData(_ date: Date) -> Data {
    let timestamp = UInt32(date.timeIntervalSince1970).littleEndian
    
    var data = Data()
    withUnsafeBytes(of: timestamp, { bytes in
        data.append(contentsOf: bytes)
    })
    
    return data
}
