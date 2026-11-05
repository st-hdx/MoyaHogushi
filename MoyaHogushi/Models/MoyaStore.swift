import Foundation
import Combine

final class MoyaStore: ObservableObject {
    @Published private(set) var entries: [MoyaEntry] = []

    private let saveURL: URL

    init(saveURL: URL? = nil) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.saveURL = saveURL ?? docs.appendingPathComponent("moya_entries.json")
        load()
    }

    func add(_ entry: MoyaEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: MoyaEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func toggleActionDone(_ entry: MoyaEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].actionDone.toggle()
        save()
    }

    var pendingActions: [MoyaEntry] {
        entries.filter { $0.hasAction && !$0.actionDone }
    }

    var thisWeekCount: Int {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return entries.filter { interval.contains($0.createdAt) }.count
    }

    var topEmotion: String? {
        let counts = entries.flatMap(\.emotions).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .first?.key
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? decoder.decode([MoyaEntry].self, from: data) else { return }
        entries = decoded
    }
}
