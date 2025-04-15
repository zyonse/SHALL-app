//
//  ControlView.swift
//  SHALL
//
//  Created by Gavin Zyonse on 3/13/25.
//

import SwiftUI

// Define the possible modes
enum LEDMode: String, CaseIterable, Identifiable {
    case manual, adaptive, environmental
    var id: String { self.rawValue }
}

struct ControlView: View {
    @State private var power: Bool = false
    @State private var brightness: Double = 128
    @State private var selectedMode: LEDMode = .manual // Changed from adaptiveMode: Bool
    @State private var statusMessage: String = ""
    @State private var ledStatus: LEDStatus?
    @State private var selectedColor: Color = .white

    var body: some View {
        Form {
            Toggle("Power", isOn: $power)
                .onChange(of: power) { _, newValue in
                    // Optionally apply power change immediately
                    // Task { await applyPower(newValue) }
                }
            
            VStack(alignment: .leading) {
                Text("Brightness: \(Int(brightness))")
                Slider(value: $brightness, in: 0...255, step: 1)
            }
            
            ColorPicker("Color", selection: $selectedColor)
            
            // Replace Toggle with Picker for mode selection
            Picker("Mode", selection: $selectedMode) {
                ForEach(LEDMode.allCases) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented) // Use segmented style
            
            Button("Apply All Changes") { // Changed button text for clarity
                Task {
                    var msg = ""
                    // Power
                    if let newPower = await NetworkManager.setPower(power) {
                        msg += "Power set to \(newPower ? "On" : "Off"). "
                    } else {
                        msg += "Power update failed. "
                    }
                    // Brightness
                    if let newBrightness = await NetworkManager.setBrightness(Int(brightness)) {
                        msg += "Brightness set to \(newBrightness). "
                    } else {
                        msg += "Brightness update failed. "
                    }
                    // Color
                    var hue: CGFloat = 0
                    var saturation: CGFloat = 0
                    var br: CGFloat = 0 // Renamed to avoid conflict
                    var alpha: CGFloat = 0
                    UIColor(selectedColor).getHue(&hue, saturation: &saturation, brightness: &br, alpha: &alpha)
                    let hueInt = Int(hue * 360)
                    let saturationInt = Int(saturation * 255)
                    if let color = await NetworkManager.setColor(hue: hueInt, saturation: saturationInt) {
                        msg += "Color set: Hue \(color.hue), Saturation \(color.saturation). "
                    } else {
                        msg += "Color update failed. "
                    }
                    // Mode
                    if let newMode = await NetworkManager.setMode(selectedMode.rawValue) {
                        msg += "Mode set to \(newMode.capitalized). "
                        // Update local state if server confirms a different mode than selected (unlikely but possible)
                        if let confirmedMode = LEDMode(rawValue: newMode) {
                            selectedMode = confirmedMode
                        }
                    } else {
                        msg += "Mode update failed. "
                    }
                    statusMessage = msg
                }
            }
            
            Text(statusMessage)
                .foregroundColor(.secondary)
                .lineLimit(nil) // Allow multiple lines for status
        }
        .navigationTitle("Control LED")
        .task {
            await loadInitialStatus()
        }
    }

    // Helper function to load initial status
    private func loadInitialStatus() async {
        ledStatus = await NetworkManager.fetchLEDStatus()
        if let status = ledStatus {
            power = status.power
            brightness = Double(status.brightness)
            selectedColor = Color(
                hue: Double(status.hue) / 360.0,
                saturation: Double(status.saturation) / 255.0,
                brightness: 1.0 // Keep color picker brightness full
            )
            // Initialize selectedMode from fetched status
            selectedMode = LEDMode(rawValue: status.mode) ?? .manual // Default to manual if unknown mode received
            statusMessage = "Current status loaded."
        } else {
            statusMessage = "Failed to load initial status."
        }
    }

    // Optional: Function to apply power immediately if needed
    // private func applyPower(_ state: Bool) async {
    //     if let newPower = await NetworkManager.setPower(state) {
    //         statusMessage = "Power set to \(newPower ? "On" : "Off")."
    //     } else {
    //         statusMessage = "Power update failed."
    //         // Revert toggle if failed?
    //         // power = !state
    //     }
    // }
}

#Preview {
    NavigationView { // Wrap in NavigationView for title
        ControlView()
    }
}
