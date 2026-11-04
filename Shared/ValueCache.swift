import Foundation

/// A small in-memory cache: fetches a value once and reuses it, so unchanged album art and show
/// names aren't downloaded again on every poll. Failures (nil) aren't cached. Oldest entries are
/// dropped beyond `limit`.
actor ValueCache<Key: Hashable & Sendable, Value: Sendable> {
    private let limit: Int
    private var values: [Key: Value] = [:]
    private var order: [Key] = []

    init(limit: Int) {
        self.limit = limit
    }

    func value(for key: Key, fetch: @Sendable () async -> Value?) async -> Value? {
        if let cached = values[key] { return cached }
        guard let fresh = await fetch() else { return nil }
        if values.updateValue(fresh, forKey: key) == nil {
            order.append(key)
            if order.count > limit { values[order.removeFirst()] = nil }
        }
        return fresh
    }
}
