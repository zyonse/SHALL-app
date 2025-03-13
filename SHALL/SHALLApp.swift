//
//  SHALLApp.swift
//  SHALL
//
//  Created by Gavin Zyonse on 3/13/25.
//

import SwiftUI

@main
struct SHALLApp: App {
    var body: some Scene {
        // Tabbed view with main control tab and settings tab
        WindowGroup {
            TabView {
                Tab("Controls", systemImage: "lightbulb.max") {
                    ContentView()
                }
                Tab("Settings", systemImage: "gear") {
                    SettingsView()
                }
            }
        }
    }
}
