//
//  BluetoothApi.swift
//  ESP32 Fridge
//
//  Created by Anshul Gupta on 5/26/24.
//

import CoreBluetooth
import Foundation

class BluetoothApi: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var isBluetoothEnabled = false
    @Published var discoveredDevices = [ESP32Device]()
    private var discoveredPeripherals = [CBPeripheral]()

    private var centralManager: CBCentralManager!

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBluetoothEnabled = true
            centralManager.scanForPeripherals(withServices: ESP32Device.requiredServices, options: nil)
            // centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            isBluetoothEnabled = false
        }
    }

    func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
        // Ensure device has a name
        guard peripheral.name != nil else { return }

        // Handle duplicate peripherals
        // This prevents a ESP32Device from being assigned a delegate, then being destroyed
        if discoveredPeripherals.contains(peripheral) {
            return
        }

        // Construct device
        // This sets the delegate of the peripheral to the newly created ESP32Device
        let device = ESP32Device(peripheral: peripheral)
        print(device)

        // Add device to list & connect
        discoveredDevices.append(device)
        discoveredPeripherals.append(peripheral)
        device.connect(manager: centralManager)
    }

    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral)")
        peripheral.discoverServices(nil)
    }

    func toggleBluetooth() {
        if centralManager?.state == .poweredOn {
            centralManager.stopScan()

            for device in discoveredDevices {
                device.disconnect(manager: centralManager)
            }

            discoveredDevices = []
            discoveredPeripherals = []
            isBluetoothEnabled = false
            centralManager = nil
        } else {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
}
