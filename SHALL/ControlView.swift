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
    @State private var selectedColor: Color = .white
    @State private var selectedMode: LEDMode = .manual
    @State private var ledStatus: LEDStatus?
    @State private var spotifyAccessToken: String?
    @State private var spotifyTracks: [SpotifyTrack] = []
    @State private var spotifyStatusMessage: String = "Loading Spotify tracks..."

    var body: some View {
        Form {
            // MARK: - LED Control Section
            Section("LED Control") {
                // Power toggle applies immediately
                Toggle("Power", isOn: $power)
                    .onChange(of: power) { oldValue, newValue in
                        Task {
                            if let confirmed = await NetworkManager.setPower(newValue) {
                                power = confirmed
                            } else {
                                power = oldValue
                            }
                        }
                    }

                // Brightness slider applies on release
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "sun.min.fill")
                            .foregroundColor(.gray)
                        Slider(value: $brightness, in: 0...255, step: 1) {
                            // onEditingChanged: true when user starts, false when ends
                        } onEditingChanged: { isEditing in
                            if !isEditing {
                                let old = Int(brightness)
                                Task {
                                    if let confirmed = await NetworkManager.setBrightness(old) {
                                        brightness = Double(confirmed)
                                    } else {
                                        brightness = Double(old) // revert to last known
                                    }
                                }
                            }
                        }
                        .tint(.yellow)  // apply yellow accent
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.yellow)
                    }
                    Text("Brightness: \(Int(brightness))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Color picker applies on change (no longer overwrite local color)
                ColorPicker("Color", selection: $selectedColor)
                    .onChange(of: selectedColor) { _, newValue in
                        let ui = UIColor(newValue)
                        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                        let hueInt = Int(h * 360), satInt = Int(s * 255)
                        Task {
                            _ = await NetworkManager.setColor(hue: hueInt, saturation: satInt)
                            // no local state update here
                        }
                    }

                // Mode picker applies on change
                Picker("Mode", selection: $selectedMode) {
                    ForEach(LEDMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedMode) { oldValue, newValue in
                    Task {
                        if let confirmed = await NetworkManager.setMode(newValue.rawValue),
                           let mode = LEDMode(rawValue: confirmed) {
                            selectedMode = mode
                        } else {
                            selectedMode = oldValue
                        }
                    }
                }
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
        .navigationTitle("Control LED")
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
              let imageUrl = URL(string: imageUrlString),
              let averageUIColor = await getAverageColor(from: imageUrl) else {
            return
        }

        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        averageUIColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let hueInt = Int(hue * 360)
        let saturationInt = Int(max(0.1, saturation) * 255)

        // send new color, but do not overwrite selectedColor
        _ = await NetworkManager.setColor(hue: hueInt, saturation: saturationInt)
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
