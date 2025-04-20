import Foundation

struct LEDStatus: Decodable {
    var power: Bool
    var brightness: Int
    var hue: Int
    var saturation: Int
    var mode: String
}

// MARK: - Spotify Structures
struct SpotifyTokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct SpotifyImage: Decodable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyArtist: Decodable {
    let name: String
}

struct SpotifyAlbum: Decodable {
    let name: String
    let images: [SpotifyImage]
}

struct SpotifyTrack: Decodable, Identifiable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    var preview_url: String? // Optional: Some tracks might not have previews
}

struct NetworkManager {
    // --- Spotify Credentials ---
    private static let spotifyClientId = ""
    private static let spotifyClientSecret = ""
    // Predefined list of Track IDs
    static let predefinedTrackIds = [
        "0VjIjW4GlUZAMYd2vXMi3b", // Blinding Lights - The Weeknd
        "7tFiyTwD0nx5a1eklYtX2J", // Bohemian Rhapsody - Queen
        "4r6eNCsrZnQWJzzvFh4nlg", // Take On Me - a-ha
        "2takcwOaAZWiXQijPHIx7B", // Africa - TOTO
        "6ZG5lRT77aJ3btmArcykra"  // Levitating - Dua Lipa
    ]
    // -----------------------------------------------------------------

    static func fetchLEDStatus() async -> LEDStatus? {
        guard let url = URL(string: "\(AppSettings.shared.baseURL)/api/status") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            return try decoder.decode(LEDStatus.self, from: data)
        } catch {
            print("Error fetching status: \(error)")
            return nil
        }
    }
    
    // Set power
    struct PowerResponse: Decodable {
        let success: Bool
        let power: Bool
    }
    static func setPower(_ power: Bool) async -> Bool? {
        guard let url = URL(string: "\(AppSettings.shared.baseURL)/api/power") else { return nil }
        let payload = ["power": power]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(PowerResponse.self, from: data)
            return response.power
        } catch {
            return nil
        }
    }
    
    // Set brightness
    struct BrightnessResponse: Decodable {
        let success: Bool
        let brightness: Int
    }
    static func setBrightness(_ brightness: Int) async -> Int? {
        guard let url = URL(string: "\(AppSettings.shared.baseURL)/api/brightness") else { return nil }
        let payload = ["brightness": brightness]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(BrightnessResponse.self, from: data)
            return response.brightness
        } catch {
            return nil
        }
    }
    
    // Set color (hue and saturation)
    struct ColorResponse: Decodable {
        let success: Bool
        let hue: Int
        let saturation: Int
    }
    static func setColor(hue: Int, saturation: Int) async -> (hue: Int, saturation: Int)? {
        guard let url = URL(string: "\(AppSettings.shared.baseURL)/api/color") else { return nil }
        let payload = ["hue": hue, "saturation": saturation]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ColorResponse.self, from: data)
            return (response.hue, response.saturation)
        } catch {
            return nil
        }
    }
    
    // Set mode
    struct ModeResponse: Decodable {
        let success: Bool
        let mode: String
    }
    static func setMode(_ mode: String) async -> String? {
        guard let url = URL(string: "\(AppSettings.shared.baseURL)/api/mode") else { return nil }
        let payload = ["mode": mode]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ModeResponse.self, from: data)
            return response.mode
        } catch {
            print("Error setting mode: \(error)") // Added error logging
            return nil
        }
    }

    // MARK: - Spotify API Calls

    // Get Spotify Access Token (Client Credentials Flow)
    static func getSpotifyAccessToken() async -> String? {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let credentials = "\(spotifyClientId):\(spotifyClientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else { return nil }
        let base64Credentials = credentialsData.base64EncodedString()

        request.addValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Spotify Auth Error: Status code \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let errorData = String(data: data, encoding: .utf8) { print(errorData) }
                return nil
            }
            let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
            return tokenResponse.access_token
        } catch {
            print("Error fetching Spotify token: \(error)")
            return nil
        }
    }

    // Fetch Details for a Single Spotify Track
    static func fetchSpotifyTrackDetails(trackId: String, accessToken: String) async -> SpotifyTrack? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/tracks/\(trackId)"
        // No query items needed for basic track details

        guard let url = components.url else {
            print("Error constructing Spotify track details URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                 print("Spotify Track Details Error: Status code \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                 if let errorData = String(data: data, encoding: .utf8) { print(errorData) }
                return nil
            }
            // Decode directly into SpotifyTrack
            let track = try JSONDecoder().decode(SpotifyTrack.self, from: data)
            return track
        } catch {
            print("Error fetching Spotify track details: \(error)")
            return nil
        }
    }

    // Fetch Details for Multiple Spotify Tracks by ID
    static func fetchMultipleSpotifyTrackDetails(trackIds: [String], accessToken: String) async -> [SpotifyTrack] {
        var fetchedTracks: [SpotifyTrack] = []
        // Use a TaskGroup for concurrent fetching
        await withTaskGroup(of: SpotifyTrack?.self) { group in
            for trackId in trackIds {
                group.addTask {
                    // Call the existing single track fetch function
                    return await fetchSpotifyTrackDetails(trackId: trackId, accessToken: accessToken)
                }
            }
            // Collect results from the group
            for await track in group {
                if let track = track {
                    fetchedTracks.append(track)
                }
            }
        }
        // Note: The order might not be preserved due to concurrency.
        // If order matters, you might need to sort fetchedTracks based on the original trackIds array.
        return fetchedTracks
    }
}
