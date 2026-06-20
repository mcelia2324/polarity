import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var journalStore: JournalStore

    var body: some View {
        ZStack {
            Theme.appBackground
                .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.accent.opacity(0.06), .clear],
                center: UnitPoint(x: 0.5, y: 0.04),
                startRadius: 0,
                endRadius: 340
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            TabView {
                TodayView(journalStore: journalStore)
                    .tabItem {
                        Label("Today", systemImage: "sun.max")
                    }

                JournalView(journalStore: journalStore)
                    .tabItem {
                        Label("Journal", systemImage: "book.closed")
                    }

                HistoryView(journalStore: journalStore)
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                ConsciousnessMirrorView(journalStore: journalStore)
                    .tabItem {
                        Label("Mirror", systemImage: "sparkles")
                    }

                SettingsView(settings: settings, notificationManager: notificationManager, journalStore: journalStore)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
        .accentColor(Theme.accent)
        .preferredColorScheme(settings.appearance.colorScheme)
        .toolbarBackground(Theme.card.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            Task {
                await APIClient.shared.updateBaseURL(settings.baseURL)
            }
            notificationManager.registerIfEnabled(settings: settings)
        }
        .onChange(of: settings.notificationsEnabled) { _ in
            notificationManager.updateServerToggle(settings: settings)
        }
    }
}
