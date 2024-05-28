//
//  InfoView.swift
//  ESP32 Fridge
//
//  Created by Anshul Gupta on 5/26/24.
//

import CoreBluetooth
import SwiftUI

struct InfoView<Device>: View where Device: FridgeDevice {
    @ObservedObject private var device: Device

    let dateFormatter: DateFormatter
    let timeFormatter: DateComponentsFormatter

    init(device: Device) {
        self.device = device

        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long

        timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
        timeFormatter.unitsStyle = .abbreviated
    }

    var body: some View {
        let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()

        VStack {
            if !device.connected {
                ProgressView()
                    .onReceive(timer, perform: { _ in
                        device.retrieve(for: .all)
                    })
            } else if device.receivedAttribs.count != FridgeDeviceAttributes.totalAttribs {
                ProgressView(value: Float(device.receivedAttribs.count), total: Float(FridgeDeviceAttributes.totalAttribs)) {
                    Text("Recieved Characteristics: \(device.receivedAttribs.count) of \(FridgeDeviceAttributes.totalAttribs)")
                }
                .padding()
                .onReceive(timer, perform: { _ in
                    device.retrieve(for: .all)
                })
            } else {
                VStack(spacing: 16) {
                    Text(device.name ?? "Unknown")
                        .font(.title)
                        .bold()
                        .lineLimit(1)
                        .padding()
                    InfoRow(title: "Version", value: String(device.version), iconName: "info.circle")

                    Divider()
                    InfoRow(title: "Device Time", value: dateFormatter.string(from: device.time), iconName: "clock")
                    Divider()
                    InfoRow(title: "Time Offset", value: timeFormatter.string(from: device.time, to: Date()) ?? "unknown", iconName: "clock.arrow.2.circlepath") {
                        Button(action: {
                            device.setTime(Date())
                        }) {
                            Text("Sync Time")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Divider()
                    InfoRow(title: "Cooler Temperature", value: device.coolerTemp.formatted(), iconName: "thermometer.snowflake")

                    Divider()
                    InfoRow(title: "Ambient Temperature", value: device.ambientTemp.formatted(), iconName: "thermometer")

                    Divider()
                    InfoRow(title: "Water Temperature", value: device.waterTemp.formatted(), iconName: "thermometer.and.liquid.waves")
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .shadow(radius: 3)
            }
            Spacer()
        }
        .onAppear {
            device.retrieve(for: .all)
        }
        .onReceive(timer) { _ in
            device.retrieve(for: .time)
        }
    }
}

struct InfoRow<Content: View>: View {
    let title: String
    var value: String
    let iconName: String
    var extra: Content?

    init(title: String, value: String, iconName: String, @ViewBuilder extra: () -> Content) {
        self.title = title
        self.value = value
        self.iconName = iconName
        self.extra = extra()
    }

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title)
                .frame(width: 36)
                .foregroundColor(.primary)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            extra
        }
    }
}

extension InfoRow where Content == EmptyView {
    init(title: String, value: String, iconName: String) {
        self.title = title
        self.value = value
        self.iconName = iconName
    }
}

#Preview {
    InfoView(device: MockFridgeDevice())
}
