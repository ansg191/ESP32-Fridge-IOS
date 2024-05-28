//
//  BluetoothApi.swift
//  ESP32 Fridge
//
//  Created by Anshul Gupta on 5/26/24.
//

import CoreBluetooth
import Foundation

class BluetoothApi : NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var isBluetoothEnabled = false
    @Published var discoveredDevices = [ESP32Device]()
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBluetoothEnabled = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            isBluetoothEnabled = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check UUID is our device
//        let uuid = UUID(uuidString: "D84C335E-02D6-51F3-8AE4-E94A749B5921")
        let uuid = UUID(uuidString: "1FF62685-8E4A-1751-4A14-DE683D1E602E")
        if (peripheral.identifier != uuid) {
            return
        }
        
        // Construct device
        let device = ESP32Device(peripheral: peripheral)
        print(device)
        
        // Add device to list & connect
        if !discoveredDevices.contains(device) {
            discoveredDevices.append(device)
            device.connect(manager: self.centralManager)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func toggleBluetooth() {
        if centralManager?.state == .poweredOn {
            centralManager.stopScan()
            
            for device in discoveredDevices {
                device.disconnect(manager: self.centralManager)
            }
            
            discoveredDevices = []
            isBluetoothEnabled = false
            centralManager = nil
        } else {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
}
