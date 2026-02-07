//
//  SettingsView.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI

/// App settings view
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrency = "MYR"
    @AppStorage("defaultTaxPercentage") private var defaultTaxPercentage = 6.0
    @AppStorage("defaultServiceChargePercentage") private var defaultServiceChargePercentage = 0.0
    @AppStorage("roundToNearest") private var roundToNearest = "0.01"
    
    var body: some View {
        TabView {
            // General settings tab
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            // Appearance tab
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            // About tab
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        Form {
            Section("Default Values for New Bills") {
                // Default currency
                Picker("Default Currency", selection: $defaultCurrency) {
                    ForEach(CurrencyManager.supportedCurrencies) { currency in
                        Text(currency.displayName).tag(currency.code)
                    }
                }
                
                // Default tax
                HStack {
                    Text("Default Tax Rate")
                    Spacer()
                    TextField("", value: $defaultTaxPercentage, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("%")
                        .foregroundStyle(.secondary)
                }
                
                // Default service charge
                HStack {
                    Text("Default Service Charge")
                    Spacer()
                    TextField("", value: $defaultServiceChargePercentage, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("%")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Calculation") {
                Picker("Round amounts to nearest", selection: $roundToNearest) {
                    Text("0.01 (cents)").tag("0.01")
                    Text("0.05 (5 cents)").tag("0.05")
                    Text("0.10 (10 cents)").tag("0.10")
                    Text("1.00 (whole dollar)").tag("1.00")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Appearance Tab
    
    private var appearanceTab: some View {
        Form {
            Section("Theme") {
                Text("The app follows your system appearance settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Go to System Settings > Appearance to change between Light and Dark mode.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Section("Tips") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Press ⌘N to create a new bill", systemImage: "keyboard")
                    Label("Press ⌘I to add an item", systemImage: "keyboard")
                    Label("Press ⌘P to add a person", systemImage: "keyboard")
                    Label("Press ⌘K to open contacts", systemImage: "keyboard")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - About Tab
    
    private var aboutTab: some View {
        VStack(spacing: 24) {
            // App icon placeholder
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            VStack(spacing: 4) {
                Text("IOU Bill Splitter")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("A simple and elegant way to split bills with friends and track who owes what.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 4) {
                Text("Developed by")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Text("Yew Mun Thian")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.top, 32)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
