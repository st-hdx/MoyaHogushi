import Foundation
import Combine

/// 記録を1件1ファイルで iCloud Drive のアプリ専用コンテナに置く。
/// 突き合わせのルールは SyncMerge、ここはファイルの読み書きと変更の検知だけを担当する。
final class CloudSync: ObservableObject {
    enum Status: Equatable {
        case off
        case unavailable
        case syncing
        case synced(Date)
    }

    @Published private(set) var status: Status = .off
    @Published private(set) var isEnabled: Bool

    /// iCloud 上の記録を読み終えるたびに main スレッドで呼ばれる。
    var onRemoteEntries: ((_ entries: [MoyaEntry], _ unreadable: Set<UUID>) -> Void)?

    private static let enabledKey = "iCloudSyncEnabled"
    private let queue = DispatchQueue(label: "app.moyahogushi.cloudsync")
    private var directory: URL?          // queue からのみ触る
    private var query: NSMetadataQuery?  // main からのみ触る
    private var observers: [NSObjectProtocol] = []

    init() {
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// iCloud アカウントの識別用。アカウントが変わったら過去の同期履歴は当てにならない。
    static func currentAccountFingerprint() -> Data? {
        guard let token = FileManager.default.ubiquityIdentityToken else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
    }

    // MARK: - Lifecycle

    func start() {
        guard isEnabled else { status = .off; return }
        guard FileManager.default.ubiquityIdentityToken != nil else { status = .unavailable; return }
        status = .syncing
        queue.async { [weak self] in
            let dir = Self.resolveDirectory()
            self?.directory = dir
            DispatchQueue.main.async {
                guard let self = self else { return }
                if dir == nil {
                    self.status = .unavailable
                } else {
                    self.startQuery()
                }
            }
        }
    }

    func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: Self.enabledKey)
        isEnabled = on
        if on { start() } else { stop() }
    }

    private func stop() {
        query?.stop()
        query = nil
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
        queue.async { [weak self] in self?.directory = nil }
        status = .off
    }

    // MARK: - Operations

    func upsert(_ entry: MoyaEntry) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            guard let dir = self?.directory else { return }
            Self.write(entry, in: dir)
        }
    }

    func remove(id: UUID) {
        guard isEnabled else { return }
        queue.async { [weak self] in
            guard let dir = self?.directory else { return }
            Self.delete(id, in: dir)
        }
    }

    func reload() {
        queue.async { [weak self] in
            guard let self = self, let dir = self.directory else { return }
            // 一覧を取れなかったときは何も返さない。空として扱うと、全件が削除扱いになってしまう。
            guard let result = Self.readEntries(in: dir) else { return }
            DispatchQueue.main.async {
                self.status = .synced(Date())
                self.onRemoteEntries?(result.entries, result.unreadable)
            }
        }
    }

    // MARK: - Change detection

    private func startQuery() {
        guard query == nil else { reload(); return }
        let q = NSMetadataQuery()
        q.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        q.predicate = NSPredicate(format: "%K LIKE '*.json'", NSMetadataItemFSNameKey)
        let names: [Notification.Name] = [.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate]
        for name in names {
            observers.append(
                NotificationCenter.default.addObserver(forName: name, object: q, queue: .main) { [weak self] _ in
                    self?.reload()
                }
            )
        }
        q.start()
        query = q
        reload()
    }

    // MARK: - File access (queue 上で呼ぶ)

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .millisecondsSince1970
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .millisecondsSince1970
        return d
    }()

    private static func resolveDirectory() -> URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let dir = container.appendingPathComponent("Documents/Entries", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func fileURL(_ id: UUID, in dir: URL) -> URL {
        dir.appendingPathComponent("\(id.uuidString).json")
    }

    private static func write(_ entry: MoyaEntry, in dir: URL) {
        guard let data = try? encoder.encode(entry) else { return }
        var error: NSError?
        NSFileCoordinator().coordinate(writingItemAt: fileURL(entry.id, in: dir), options: .forReplacing, error: &error) { target in
            try? data.write(to: target, options: .atomic)
        }
    }

    private static func delete(_ id: UUID, in dir: URL) {
        var error: NSError?
        NSFileCoordinator().coordinate(writingItemAt: fileURL(id, in: dir), options: .forDeleting, error: &error) { target in
            try? FileManager.default.removeItem(at: target)
        }
    }

    /// 読めなかったファイルのIDは unreadable に入れる。未ダウンロードのファイルは
    /// 「.<名前>.json.icloud」という空のプレースホルダとして並ぶので、ダウンロードを要求しておく。
    private static func readEntries(in dir: URL) -> (entries: [MoyaEntry], unreadable: Set<UUID>)? {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return nil }

        var entries: [MoyaEntry] = []
        var unreadable = Set<UUID>()

        for url in urls {
            let name = url.lastPathComponent
            if name.hasPrefix(".") && name.hasSuffix(".icloud") {
                let realName = String(name.dropFirst().dropLast(".icloud".count))
                let real = dir.appendingPathComponent(realName)
                try? fm.startDownloadingUbiquitousItem(at: real)
                if let id = UUID(uuidString: real.deletingPathExtension().lastPathComponent) {
                    unreadable.insert(id)
                }
                continue
            }
            guard url.pathExtension == "json" else { continue }

            var data: Data?
            var error: NSError?
            NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &error) { source in
                data = try? Data(contentsOf: source)
            }
            if let data = data, let entry = try? decoder.decode(MoyaEntry.self, from: data) {
                entries.append(entry)
            } else if let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) {
                unreadable.insert(id)
            }
        }
        return (entries, unreadable)
    }
}
