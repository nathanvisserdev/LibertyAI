//
//  AIChatRecordKeeperApp.swift
//  AIChatRecordKeeper
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
import SwiftData

@main
struct AIChatRecordKeeperApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChatTranscript.self,
            HashPublication.self,
            ChainOfCustodyEntry.self,
            StorageLocation.self,
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
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Transcript") {
                    // This will be handled by the view
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
