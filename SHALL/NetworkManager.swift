import Foundation

struct LEDStatus: Decodable {
    var power: Bool
    var brightness: Int
    var hue: Int
    var saturation: Int
    var adaptive_mode: Bool
}

struct NetworkManager {
    static func fetchLEDStatus() async -> LEDStatus? {
        guard let url = URL(string: "http://4827E2662CF8.local/api/status") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(LEDStatus.self, from: data)
        } catch {
            // handle error
            return nil
        }
    }
    
    // Set power
    struct PowerResponse: Decodable {
        let success: Bool
        let power: Bool
    }
    static func setPower(_ power: Bool) async -> Bool? {
        guard let url = URL(string: "http://4827E2662CF8.local/api/power") else { return nil }
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
        guard let url = URL(string: "http://4827E2662CF8.local/api/brightness") else { return nil }
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
        guard let url = URL(string: "http://4827E2662CF8.local/api/color") else { return nil }
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
    
    // Set adaptive mode
    struct AdaptiveModeResponse: Decodable {
        let success: Bool
        let adaptive_mode: Bool
    }
    static func setAdaptiveMode(_ mode: Bool) async -> Bool? {
        guard let url = URL(string: "http://4827E2662CF8.local/api/adaptive_mode") else { return nil }
        let payload = ["adaptive_mode": mode]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AdaptiveModeResponse.self, from: data)
            return response.adaptive_mode
        } catch {
            return nil
        }
    }
}
