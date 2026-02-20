import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var journalStore: JournalStore

    var body: some View {
        ZStack {
            Theme.appBackground
                .ignoresSafeArea()

            TabView {
                TodayView(journalStore: journalStore)
                    .tabItem {
                        Label("Today", systemImage: "sun.max")
                    }

                JournalView(journalStore: journalStore)
                    .tabItem {
                        Label("Journal", systemImage: "book.closed")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                SettingsView(settings: settings, notificationManager: notificationManager, journalStore: journalStore)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
        .accentColor(Theme.accent)
        .toolbarBackground(Theme.card.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            Task {
                await APIClient.shared.updateBaseURL(settings.baseURL)
            }
        }
        .onChange(of: settings.notificationsEnabled) { _ in
            notificationManager.updateServerToggle(settings: settings)
        }
    }
}
