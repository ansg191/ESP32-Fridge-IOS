//
//  BTDevice.swift
//  ESP32 Fridge
//
//  Created by Anshul Gupta on 5/26/24.
//

import Foundation

protocol FridgeDevice: ObservableObject {
    /// Device DateTime
    var time: Date { get }
    /// Device firmware version
    var version: UInt32 { get }
    
    /// Cooler Temperature
    var coolerTemp: Measurement<UnitTemperature> { get }
    /// Ambient Temperature
    var ambientTemp: Measurement<UnitTemperature> { get }
    /// Water Temperature
    var waterTemp: Measurement<UnitTemperature> { get }
    
    /// Attributes that have successfully been requested & retrieved
    var receivedAttribs: Set<FridgeDeviceAttributes> { get }
    
    /// Name of the device
    var name: String? { get }
    /// Device UUID
    var identifier: UUID { get }
    
    /// Start request to retrieve some `FridgeDeviceAttributes`
    func retrieve(for: FridgeDeviceAttributes)
    
    /// Set the DateTime of the device to the `date`
    func setTime(_ date: Date)
}


struct FridgeDeviceAttributes: OptionSet, Hashable {
    let rawValue: UInt8
    
    var hashValue: Int {
        return Int(self.rawValue)
    }
    
    static let totalAttribs: Int = 5;
    
    static let version = FridgeDeviceAttributes(rawValue: 0x01)
    static let time = FridgeDeviceAttributes(rawValue: 0x02)
    
    static let cooler = FridgeDeviceAttributes(rawValue: 0x04)
    static let ambient = FridgeDeviceAttributes(rawValue: 0x08)
    static let water = FridgeDeviceAttributes(rawValue: 0x10)
    
    static let all: FridgeDeviceAttributes = [.version, .time, .cooler, .ambient, .water]
}

class MockFridgeDevice: NSObject, ObservableObject, FridgeDevice {
    @Published var time = Date(timeIntervalSince1970: 0)
    @Published var version: UInt32 = 0
    
    @Published var coolerTemp = Measurement(value: 0, unit: UnitTemperature.celsius)
    @Published var ambientTemp = Measurement(value: 0, unit: UnitTemperature.celsius)
    @Published var waterTemp = Measurement(value: 0, unit: UnitTemperature.celsius)
    
    @Published var receivedAttribs = Set<FridgeDeviceAttributes>()
    
    var name: String? = "MockFridgeDevice"
    var identifier: UUID = UUID()
    
    func retrieve(for attrs: FridgeDeviceAttributes) {
        if attrs.contains(.version) {
            version = 1
            receivedAttribs.insert(.version)
        }
        if attrs.contains(.time) {
            time = Date()
            receivedAttribs.insert(.time)
        }
    }
    
    func setTime(_ date: Date) {}
}
