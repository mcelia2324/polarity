import SwiftUI

@main
struct PolarityApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = SettingsStore()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var journalStore: JournalStore

    init() {
        let settings = SettingsStore()
        _settings = StateObject(wrappedValue: settings)
        _notificationManager = StateObject(wrappedValue: NotificationManager())
        _journalStore = StateObject(wrappedValue: JournalStore(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(notificationManager)
                .environmentObject(journalStore)
                .onAppear {
                    appDelegate.notificationManager = notificationManager
                    appDelegate.settingsStore = settings
                }
        }
    }
}
