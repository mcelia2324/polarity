import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @Published var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "baseURL")
            Task { await APIClient.shared.updateBaseURL(baseURL) }
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var notifyHour: Int {
        didSet {
            UserDefaults.standard.set(notifyHour, forKey: "notifyHour")
        }
    }

    @Published var notifyMinute: Int {
        didSet {
            UserDefaults.standard.set(notifyMinute, forKey: "notifyMinute")
        }
    }

    @Published var iCloudEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudEnabled, forKey: "iCloudEnabled")
        }
    }

    init() {
        baseURL = UserDefaults.standard.string(forKey: "baseURL") ?? "http://localhost:8069"
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        notifyHour = UserDefaults.standard.object(forKey: "notifyHour") as? Int ?? 8
        notifyMinute = UserDefaults.standard.object(forKey: "notifyMinute") as? Int ?? 0
        iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudEnabled")
        Task { await APIClient.shared.updateBaseURL(baseURL) }
    }
}
