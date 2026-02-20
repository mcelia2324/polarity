import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var journalStore: JournalStore

    private var notifyTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = settings.notifyHour
                components.minute = settings.notifyMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings.notifyHour = components.hour ?? 8
                settings.notifyMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Daily Reminder", isOn: $settings.notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _ in
                            Task {
                                if settings.notificationsEnabled {
                                    await notificationManager.requestAuthorization()
                                }
                                notificationManager.updateServerToggle(settings: settings)
                            }
                        }

                    if settings.notificationsEnabled {
                        DatePicker("Remind me at", selection: notifyTimeBinding, displayedComponents: .hourAndMinute)
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
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            .onAppear {
                notificationManager.refreshAuthorizationStatus()
            }
        }
    }
}
