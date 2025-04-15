import Foundation

struct LEDStatus: Decodable {
    var power: Bool
    var brightness: Int
    var hue: Int
    var saturation: Int
    var mode: String
}

struct NetworkManager {
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
}
