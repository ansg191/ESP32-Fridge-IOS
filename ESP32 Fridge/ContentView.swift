//
//  ContentView.swift
//  ESP32 Fridge
//
//  Created by Anshul Gupta on 5/26/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var bluetoothApi = BluetoothApi()

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                if bluetoothApi.isBluetoothAllowed {
                    Button(action: { bluetoothApi.toggleBluetooth() }, label: {
                        Text(bluetoothApi.isBluetoothEnabled ? "Turn Off Bluetooth" : "Turn On Bluetooth")
                            .padding()
                    })

                    List(bluetoothApi.discoveredDevices, id: \.identifier) { device in
                        NavigationLink(destination: InfoView<ESP32Device>(device: device)) {
                            Text(device.name ?? "Unknown")
                        }
                    }
                } else {
                    Text("Bluetooth permission was denied for this application")
                        .bold()
                        .font(.title)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
