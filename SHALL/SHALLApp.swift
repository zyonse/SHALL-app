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
        WindowGroup {
            TabView {
                ControlView()
                    .tabItem {
                        Label("Controls", systemImage: "lightbulb")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}
