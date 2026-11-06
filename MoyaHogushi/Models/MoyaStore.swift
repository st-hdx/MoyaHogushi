import Foundation
import Combine

final class MoyaStore: ObservableObject {
    @Published private(set) var entries: [MoyaEntry] = []

    let sync: CloudSync

    private let saveURL: URL
    private var syncedIDs: Set<UUID>
    private static let syncedIDsKey = "iCloudSyncedIDs"
    private static let accountKey = "iCloudAccountFingerprint"

    init(saveURL: URL? = nil) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.saveURL = saveURL ?? docs.appendingPathComponent("moya_entries.json")
        self.sync = CloudSync()

        let defaults = UserDefaults.standard
        var synced = Set((defaults.stringArray(forKey: Self.syncedIDsKey) ?? []).compactMap(UUID.init(uuidString:)))
        if let fingerprint = CloudSync.currentAccountFingerprint(),
           fingerprint != defaults.data(forKey: Self.accountKey) {
            // iCloud アカウントが変わった(または初回)。過去の同期履歴は削除の判定に使えない。
            synced = []
            defaults.set(fingerprint, forKey: Self.accountKey)
        }
        self.syncedIDs = synced

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uitestReset") {
            try? FileManager.default.removeItem(at: self.saveURL)
        }
        #endif

        load()
        sync.onRemoteEntries = { [weak self] remote, unreadable in
            self?.mergeRemote(remote, unreadable: unreadable)
        }
        sync.start()
    }

    func add(_ entry: MoyaEntry) {
        var saved = entry
        saved.updatedAt = Date()
        entries.insert(saved, at: 0)
        save()
        sync.upsert(saved)
    }

    func delete(_ entry: MoyaEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
        sync.remove(id: entry.id)
    }

    func toggleActionDone(_ entry: MoyaEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].actionDone.toggle()
        entries[index].updatedAt = Date()
        save()
        sync.upsert(entries[index])
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

    func exportText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMddHHmm")

        let blocks = entries.map { entry -> String in
            var lines = [String(
                format: NSLocalizedString("export.entry_header", value: "[%@] 濃さ %d/10", comment: "Exported entry header: date, intensity"),
                formatter.string(from: entry.createdAt), entry.intensity
            )]
            if !entry.emotions.isEmpty {
                let names = entry.emotions.map(Emotion.displayName(for:)).joined(separator: NSLocalizedString("export.list_separator", value: "、", comment: "Separator between listed items"))
                lines.append(String(format: NSLocalizedString("export.emotions_line", value: "感じたこと: %@", comment: "Exported entry: emotions line"), names))
            }
            lines.append(entry.text)
            if !entry.reflection.isEmpty {
                lines.append(String(format: NSLocalizedString("export.reflection_line", value: "引っかかり: %@", comment: "Exported entry: reflection line"), entry.reflection))
            }
            if entry.hasAction {
                let actionLine = entry.actionDone
                    ? String(format: NSLocalizedString("export.first_step_done", value: "最初の一歩: %@(完了)", comment: "Exported entry: first step, done"), entry.action)
                    : String(format: NSLocalizedString("export.first_step", value: "最初の一歩: %@", comment: "Exported entry: first step"), entry.action)
                lines.append(actionLine)
            }
            if entry.controllable == false {
                lines.append(NSLocalizedString("export.released_uncontrollable", value: "手放した(相手や状況次第)", comment: "Exported entry: released as uncontrollable"))
            }
            return lines.joined(separator: "\n")
        }
        let header = String(format: NSLocalizedString("export.header", value: "もやほぐし 記録(%d件)", comment: "Exported text header: total count"), entries.count)
        return ([header] + blocks).joined(separator: "\n\n")
    }

    // MARK: - iCloud

    private func mergeRemote(_ remote: [MoyaEntry], unreadable: Set<UUID>) {
        let outcome = SyncMerge.merge(local: entries, remote: remote, unreadable: unreadable, syncedIDs: syncedIDs)

        syncedIDs = outcome.syncedIDs
        UserDefaults.standard.set(syncedIDs.map(\.uuidString), forKey: Self.syncedIDsKey)

        if outcome.entries != entries {
            entries = outcome.entries
            save()
        }
        outcome.toPush.forEach { sync.upsert($0) }
        outcome.toDelete.forEach { sync.remove(id: $0) }
    }

    // MARK: - Local file

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
