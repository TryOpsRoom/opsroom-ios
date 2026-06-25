import Foundation

/// Persists feedback responses locally when offline and flushes on next launch.
@MainActor
struct FeedbackResponseQueue {
    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "opsroom.feedbackResponseQueue"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func enqueue(_ payload: FeedbackResponseSubmit) {
        var items = load()
        items.append(payload)
        save(items)
    }

    func flush(using client: FeedbackResponseClient) async {
        let items = load()
        guard !items.isEmpty else { return }

        var remaining: [FeedbackResponseSubmit] = []
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

    private func load() -> [FeedbackResponseSubmit] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        return (try? JSONDecoder().decode([FeedbackResponseSubmit].self, from: data)) ?? []
    }

    private func save(_ items: [FeedbackResponseSubmit]) {
        if items.isEmpty {
            defaults.removeObject(forKey: storageKey)
            return
        }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
