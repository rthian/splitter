//
//  splitterApp.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

@main
struct splitterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bill.self,
            BillItem.self,
            Person.self,
            ItemSplit.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Bill") {
                    NotificationCenter.default.post(name: .createNewBill, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Edit menu additions
            CommandGroup(after: .pasteboard) {
                Divider()
                
                Button("Add Item") {
                    NotificationCenter.default.post(name: .addItem, object: nil)
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Button("Add Person") {
                    NotificationCenter.default.post(name: .addPerson, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
            }
            
            // View menu additions
            CommandGroup(after: .sidebar) {
                Divider()
                
                Button("Show Contacts") {
                    NotificationCenter.default.post(name: .showContacts, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            
            // Help menu - Settings
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        // Settings window
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let createNewBill = Notification.Name("createNewBill")
    static let addItem = Notification.Name("addItem")
    static let addPerson = Notification.Name("addPerson")
    static let showContacts = Notification.Name("showContacts")
    static let showSettings = Notification.Name("showSettings")
}
