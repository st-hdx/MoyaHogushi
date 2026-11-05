import Foundation

/// 端末内の記録と iCloud 上の記録を突き合わせるルール。入出力だけの純粋な関数にしてある。
///
/// 削除は「以前に同期できていた(syncedIDs)のに、片方から消えた」ことで判定する。
/// 誤って記録を失うほうが重大なので、迷う場面(まだ読み込めないファイル)では必ず残す側に倒す。
/// アカウントが変わった場合は呼び出し側が syncedIDs を空にして渡すこと。
enum SyncMerge {
    struct Outcome {
        var entries: [MoyaEntry]
        var toPush: [MoyaEntry]
        var toDelete: [UUID]
        var syncedIDs: Set<UUID>
    }

    /// 保存時の丸め(ミリ秒・秒)で生じる誤差を同じ時刻と見なす。これが無いと、自分が書いたファイルを
    /// 「自分のほうが新しい」と誤判定して、書き込みが無限に繰り返される。
    private static let tolerance: TimeInterval = 0.01

    private static func isNewer(_ a: Date, than b: Date) -> Bool {
        a.timeIntervalSince(b) > tolerance
    }

    /// - Parameter unreadable: iCloud 上にファイルはあるが、まだ中身を読めない記録のID(未ダウンロード等)。
    static func merge(
        local: [MoyaEntry],
        remote: [MoyaEntry],
        unreadable: Set<UUID>,
        syncedIDs: Set<UUID>
    ) -> Outcome {
        let newer: (MoyaEntry, MoyaEntry) -> MoyaEntry = { $0.modifiedAt >= $1.modifiedAt ? $0 : $1 }
        let localByID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: newer)
        let remoteByID = Dictionary(remote.map { ($0.id, $0) }, uniquingKeysWith: newer)

        var merged: [UUID: MoyaEntry] = [:]
        var toPush: [MoyaEntry] = []
        var toDelete: [UUID] = []

        for (id, r) in remoteByID {
            if let l = localByID[id] {
                if isNewer(r.modifiedAt, than: l.modifiedAt) {
                    merged[id] = r
                } else {
                    merged[id] = l
                    if isNewer(l.modifiedAt, than: r.modifiedAt) { toPush.append(l) }
                }
            } else if syncedIDs.contains(id) {
                toDelete.append(id)
            } else {
                merged[id] = r
            }
        }

        for (id, l) in localByID where remoteByID[id] == nil {
            if unreadable.contains(id) {
                merged[id] = l
            } else if syncedIDs.contains(id) {
                continue
            } else {
                merged[id] = l
                toPush.append(l)
            }
        }

        let known = Set(localByID.keys).union(remoteByID.keys).union(unreadable)
        var synced = syncedIDs.intersection(known)
        synced.formUnion(merged.keys)

        return Outcome(
            entries: merged.values.sorted { $0.createdAt > $1.createdAt },
            toPush: toPush,
            toDelete: toDelete,
            syncedIDs: synced
        )
    }
}
