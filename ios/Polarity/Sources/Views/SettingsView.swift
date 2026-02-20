import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var journalStore: JournalStore

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server")) {
                    TextField("Base URL", text: $settings.baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _ in
                            Task {
                                if settings.notificationsEnabled {
                                    await notificationManager.requestAuthorization()
                                }
                                notificationManager.updateServerToggle(settings: settings)
                            }
                        }

                    Stepper(value: $settings.notifyHour, in: 0...23) {
                        Text("Hour: \(settings.notifyHour)")
                    }
                    Stepper(value: $settings.notifyMinute, in: 0...59) {
                        Text("Minute: \(settings.notifyMinute)")
                    }
                }

                Section(header: Text("Storage")) {
                    Toggle("Sync with iCloud", isOn: $settings.iCloudEnabled)
                        .onChange(of: settings.iCloudEnabled) { _ in
                            journalStore.refreshStorageLocation()
                        }
                    Text("Your journal stays on-device. Enabling iCloud sync stores it in your private iCloud Drive.")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Settings")
            .onAppear {
                notificationManager.refreshAuthorizationStatus()
            }
        }
    }
}
