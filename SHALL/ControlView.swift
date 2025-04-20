//
//  ControlView.swift
//  SHALL
//
//  Created by Gavin Zyonse on 3/13/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// Define the possible modes
enum LEDMode: String, CaseIterable, Identifiable {
    case manual, adaptive, environmental
    var id: String { self.rawValue }
}

struct ControlView: View {
    @State private var power: Bool = false
    @State private var brightness: Double = 128
    @State private var selectedMode: LEDMode = .manual
    @State private var statusMessage: String = ""
    @State private var ledStatus: LEDStatus?
    @State private var selectedColor: Color = .white

    // MARK: - Spotify State
    @State private var spotifyAccessToken: String?
    @State private var spotifyTracks: [SpotifyTrack] = []
    @State private var spotifyStatusMessage: String = "Loading Spotify tracks..."

    var body: some View {
        Form {
            // MARK: - LED Control Section
            Section("LED Control") {
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
                
                Picker("Mode", selection: $selectedMode) {
                    ForEach(LEDMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Button("Apply All Changes") {
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
                        // Mode
                        if let newMode = await NetworkManager.setMode(selectedMode.rawValue) {
                            msg += "Mode set to \(newMode.capitalized). "
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
                    .lineLimit(nil)
            }

            // MARK: - Spotify Tracks Section (Predefined List)
            Section("Spotify Tracks (Featured)") {
                if spotifyTracks.isEmpty {
                    Text(spotifyStatusMessage)
                        .foregroundColor(.secondary)
                } else {
                    List(spotifyTracks) { track in
                        VStack(alignment: .leading) {
                            HStack {
                                if let imageUrlString = track.album.images.first?.url, let imageUrl = URL(string: imageUrlString) {
                                    AsyncImage(url: imageUrl) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(4)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(4)
                                }

                                VStack(alignment: .leading) {
                                    Text(track.name).font(.headline)
                                    Text(track.artists.map { $0.name }.joined(separator: ", ")).font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                            Button("Set Color from Album Art") {
                                Task {
                                    await setColorFromAlbumArt(track: track)
                                }
                            }
                            .disabled(track.album.images.first?.url == nil)
                            .buttonStyle(.borderless)
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Control & Music")
        .task {
            await loadInitialStatus()
            await loadSpotifyData()
        }
    }

    private func loadInitialStatus() async {
        ledStatus = await NetworkManager.fetchLEDStatus()
        if let status = ledStatus {
            power = status.power
            brightness = Double(status.brightness)
            selectedColor = Color(
                hue: Double(status.hue) / 360.0,
                saturation: Double(status.saturation) / 255.0,
                brightness: 1.0
            )
            selectedMode = LEDMode(rawValue: status.mode) ?? .manual
            statusMessage = "Current status loaded."
        } else {
            statusMessage = "Failed to load initial status."
        }
    }

    // MARK: - Spotify Data Loading (Fetch Predefined Tracks)
    private func loadSpotifyData() async {
        spotifyStatusMessage = "Loading Spotify tracks..."
        spotifyTracks = []

        guard let token = await NetworkManager.getSpotifyAccessToken() else {
            spotifyStatusMessage = "Failed to get Spotify access token."
            return
        }
        self.spotifyAccessToken = token
        spotifyStatusMessage = "Fetching track details..."

        let tracks = await NetworkManager.fetchMultipleSpotifyTrackDetails(trackIds: NetworkManager.predefinedTrackIds, accessToken: token)

        self.spotifyTracks = tracks
        if tracks.isEmpty {
            spotifyStatusMessage = "Failed to load any Spotify tracks."
        } else {
            spotifyStatusMessage = ""
        }
    }

    // MARK: - Album Art Color Logic (Accepts Track Parameter)
    private func setColorFromAlbumArt(track: SpotifyTrack) async {
        guard let imageUrlString = track.album.images.first?.url,
              let imageUrl = URL(string: imageUrlString) else {
            statusMessage = "No album art URL found for \(track.name)."
            return
        }

        statusMessage = "Analyzing album art for \(track.name)..."

        guard let averageUIColor = await getAverageColor(from: imageUrl) else {
            statusMessage = "Failed to analyze album art color."
            return
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        averageUIColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let hueInt = Int(hue * 360)
        let saturationInt = Int(max(0.1, saturation) * 255)

        statusMessage = "Setting color to Hue: \(hueInt), Sat: \(saturationInt)..."

        if let color = await NetworkManager.setColor(hue: hueInt, saturation: saturationInt) {
            statusMessage = "Color set from \(track.name): Hue \(color.hue), Sat \(color.saturation)."
        } else {
            statusMessage = "Failed to set color from album art."
        }
    }

    // Helper function to get average color from an image URL
    private func getAverageColor(from url: URL) async -> UIColor? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return nil }

            guard let ciImage = CIImage(image: uiImage) else { return nil }

            let extentVector = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y, z: ciImage.extent.size.width, w: ciImage.extent.size.height)
            
            guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]) else { return nil }
            guard let outputImage = filter.outputImage else { return nil }

            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: [.workingColorSpace: kCFNull!])
            
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

            let red   = CGFloat(bitmap[0]) / 255.0
            let green = CGFloat(bitmap[1]) / 255.0
            let blue  = CGFloat(bitmap[2]) / 255.0
            let alpha = CGFloat(bitmap[3]) / 255.0

            return UIColor(red: red, green: green, blue: blue, alpha: alpha)

        } catch {
            print("Error downloading or processing image: \(error)")
            return nil
        }
    }
}

#Preview {
    NavigationView {
        ControlView()
    }
}
