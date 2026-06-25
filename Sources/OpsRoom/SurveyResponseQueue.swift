import Foundation

/// Persists survey responses locally when offline and flushes on next launch.
@MainActor
struct SurveyResponseQueue {
    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "opsroom.surveyResponseQueue"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func enqueue(_ payload: SurveyResponseSubmit) {
        var items = load()
        items.append(payload)
        save(items)
    }

    func flush(using client: SurveyResponseClient) async {
        let items = load()
        guard !items.isEmpty else { return }

        var remaining: [SurveyResponseSubmit] = []
        for item in items {
            let ok = await client.submit(item)
            if !ok {
                remaining.append(item)
            }
        }
        save(remaining)
    }

    #if DEBUG
    func resetForTesting() {
        defaults.removeObject(forKey: storageKey)
    }
    #endif

    private func load() -> [SurveyResponseSubmit] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        return (try? JSONDecoder().decode([SurveyResponseSubmit].self, from: data)) ?? []
    }

    private func save(_ items: [SurveyResponseSubmit]) {
        if items.isEmpty {
            defaults.removeObject(forKey: storageKey)
            return
        }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
