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
    @State private var adaptiveMode: Bool = false
    @State private var statusMessage: String = ""
    @State private var ledStatus: LEDStatus?
    @State private var selectedColor: Color = .white

    var body: some View {
        Form {
            Toggle("Power", isOn: $power)
            
            VStack(alignment: .leading) {
                Text("Brightness: \(Int(brightness))")
                Slider(value: $brightness, in: 0...255, step: 1)
            }
            
            ColorPicker("Color", selection: $selectedColor)
            
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
                    var hue: CGFloat = 0
                    var saturation: CGFloat = 0
                    var br: CGFloat = 0
                    var alpha: CGFloat = 0
                    UIColor(selectedColor).getHue(&hue, saturation: &saturation, brightness: &br, alpha: &alpha)
                    let hueInt = Int(hue * 360)
                    let saturationInt = Int(saturation * 255)
                    if let color = await NetworkManager.setColor(hue: hueInt, saturation: saturationInt) {
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
            if let status = ledStatus {
                selectedColor = Color(
                    hue: Double(status.hue) / 360.0,
                    saturation: Double(status.saturation) / 255.0,
                    brightness: 1.0
                )
            }
        }
    }
}

#Preview {
    ControlView()
}
