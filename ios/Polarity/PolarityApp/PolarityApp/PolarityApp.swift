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
            RootView()
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

/// Shows first-run onboarding for brand-new users, otherwise the main app. Existing users
/// (who already have journal entries) skip onboarding even before the flag is set.
private struct RootView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var journalStore: JournalStore

    var body: some View {
        if settings.hasCompletedOnboarding || !journalStore.entries.isEmpty {
            ContentView()
        } else {
            OnboardingView(
                settings: settings,
                journalStore: journalStore,
                notificationManager: notificationManager
            ) {
                withAnimation(.easeInOut) { settings.hasCompletedOnboarding = true }
            }
        }
    }
}
