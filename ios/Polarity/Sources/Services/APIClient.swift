import Foundation

actor APIClient {
    static let shared = APIClient()

    var baseURL: URL = URL(string: "https://polarity-backend-hudjhuhbta-ue.a.run.app")!

    private struct DeviceRegisterPayload: Encodable {
        let token: String
        let platform: String
        let timezone: String?
        let enabled: Bool
        let notifyHour: Int?
        let notifyMinute: Int?

        enum CodingKeys: String, CodingKey {
            case token
            case platform
            case timezone
            case enabled
            case notifyHour = "notify_hour"
            case notifyMinute = "notify_minute"
        }
    }

    private struct DeviceTogglePayload: Encodable {
        let token: String
        let enabled: Bool
    }

    func updateBaseURL(_ value: String) {
        if let url = URL(string: value) {
            baseURL = url
        }
    }

    func fetchWordOfDay() async throws -> WordPair {
        let url = baseURL.appendingPathComponent("api/word-of-day")
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WordPairResponse.self, from: data)
        return WordPair(
            date: response.date,
            wordA: response.wordA,
            wordB: response.wordB,
            wordADefinition: response.wordADefinition,
            wordBDefinition: response.wordBDefinition
        )
    }

    func fetchHistory(days: Int) async throws -> [WordPair] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/history"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "days", value: String(days))]
        guard let url = components?.url else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(HistoryResponse.self, from: data)
        return response.items.map {
            WordPair(
                date: $0.date,
                wordA: $0.wordA,
                wordB: $0.wordB,
                wordADefinition: $0.wordADefinition,
                wordBDefinition: $0.wordBDefinition
            )
        }
    }

    func registerDevice(token: String, timezone: String?, notifyHour: Int?, notifyMinute: Int?, enabled: Bool) async {
        let url = baseURL.appendingPathComponent("api/devices/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = DeviceRegisterPayload(
            token: token,
            platform: "ios",
            timezone: timezone,
            enabled: enabled,
            notifyHour: notifyHour,
            notifyMinute: notifyMinute
        )
        request.httpBody = try? JSONEncoder().encode(payload)
        _ = try? await URLSession.shared.data(for: request)
    }

    func toggleDevice(token: String, enabled: Bool) async {
        let url = baseURL.appendingPathComponent("api/devices/toggle")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = DeviceTogglePayload(token: token, enabled: enabled)
        request.httpBody = try? JSONEncoder().encode(payload)
        _ = try? await URLSession.shared.data(for: request)
    }
}
