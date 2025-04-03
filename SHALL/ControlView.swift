//
//  ControlView.swift
//  SHALL
//
//  Created by Gavin Zyonse on 3/13/25.
//

import SwiftUI

struct ControlView: View {
    @State private var power: Bool = false
    @State private var brightness: Double = 128
    @State private var hue: Double = 180
    @State private var saturation: Double = 128
    @State private var adaptiveMode: Bool = false
    @State private var statusMessage: String = ""
    @State private var ledStatus: LEDStatus?

    var body: some View {
        Form {
            Toggle("Power", isOn: $power)
            
            VStack(alignment: .leading) {
                Text("Brightness: \(Int(brightness))")
                Slider(value: $brightness, in: 0...255, step: 1)
            }
            
            VStack(alignment: .leading) {
                Text("Hue: \(Int(hue))")
                Slider(value: $hue, in: 0...359, step: 1)
            }
            
            VStack(alignment: .leading) {
                Text("Saturation: \(Int(saturation))")
                Slider(value: $saturation, in: 0...255, step: 1)
            }
            
            Toggle("Adaptive Mode", isOn: $adaptiveMode)
            
            Button("Apply") {
                Task {
                    var msg = ""
                    if let newPower = await NetworkManager.setPower(power) {
                        msg += "Power set to \(newPower ? "On" : "Off"). "
                    } else {
                        msg += "Power update failed. "
                    }
                    if let newBrightness = await NetworkManager.setBrightness(Int(brightness)) {
                        msg += "Brightness set to \(newBrightness). "
                    } else {
                        msg += "Brightness update failed. "
                    }
                    if let color = await NetworkManager.setColor(hue: Int(hue), saturation: Int(saturation)) {
                        msg += "Color set: Hue \(color.hue), Saturation \(color.saturation). "
                    } else {
                        msg += "Color update failed. "
                    }
                    if let newAdaptive = await NetworkManager.setAdaptiveMode(adaptiveMode) {
                        msg += "Adaptive Mode set to \(newAdaptive ? "On" : "Off"). "
                    } else {
                        msg += "Adaptive Mode update failed. "
                    }
                    statusMessage = msg
                }
            }
            
            Text(statusMessage)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Control LED")
        .task {
            ledStatus = await NetworkManager.fetchLEDStatus()
        }
    }
}

#Preview {
    ControlView()
}
