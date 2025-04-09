//
//  SettingsView.swift
//  SHALL
//
//  Created by Gavin Zyonse on 3/13/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var appSettings = AppSettings.shared
    @State private var temporaryMacAddress: String = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Configuration")) {
                    HStack {
                        Text("MAC Address")
                        Spacer()
                        TextField("Enter MAC Address", text: $temporaryMacAddress)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit {
                                appSettings.macAddress = temporaryMacAddress
                                showingAlert = true
                            }
                    }
                    
                    Button("Save") {
                        appSettings.macAddress = temporaryMacAddress
                        showingAlert = true
                    }
                    .disabled(temporaryMacAddress.isEmpty)
                }
                
                Section(header: Text("Connection Info")) {
                    Text("Device URL:")
                    Text("\(appSettings.baseURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("About")) {
                    Text("SHALL LED Control App")
                    Text("Version 1.0")
                }
            }
            .navigationTitle("Settings")
            .alert("Settings Updated", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The device MAC address has been updated.")
            }
            .onAppear {
                temporaryMacAddress = appSettings.macAddress
            }
        }
    }
}

#Preview {
    SettingsView()
}
