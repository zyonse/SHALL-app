import SwiftUI

class AppSettings: ObservableObject {
    // Default MAC address can be empty or a placeholder
    @AppStorage("deviceMacAddress") var macAddress: String = "24587CEB4834"
    
    static let shared = AppSettings()
    
    private init() {}
    
    var baseURL: String {
        "http://\(macAddress).local"
    }
}
