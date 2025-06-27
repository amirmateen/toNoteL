import SwiftUI

// MARK: - Main App Entry Point

@main
struct toNoteLApp: App {
    @StateObject private var dataStore = AppDataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}

