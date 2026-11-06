import Foundation

struct MoyaEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt = Date()
    var updatedAt: Date?
    var text = ""
    var emotions: [String] = []
    var intensity = 5
    var reflection = ""
    var controllable: Bool?
    var action = ""
    var actionDone = false

    /// iCloud 同期で新しいほうを採用するための最終更新日時。古いデータには無いので createdAt で代用する。
    var modifiedAt: Date { updatedAt ?? createdAt }

    var hasAction: Bool { controllable == true && !action.isEmpty }
}

/// 記録には安定したIDだけを保存する(`rawValue`)。表示名はロケールごとに
/// `displayName` で引く。言語を切り替えても過去の記録が指す感情が変わらないように。
enum Emotion: String, CaseIterable {
    case anxious, irritated, sad, impatient, empty
    case jealous, ashamed, tired, lonely, unclear

    static var all: [String] { allCases.map(\.rawValue) }

    static func displayName(for rawValue: String) -> String {
        Emotion(rawValue: rawValue)?.displayName ?? rawValue
    }

    var displayName: String {
        NSLocalizedString("emotion.\(rawValue)", value: fallback, comment: "Emotion chip label")
    }

    /// 開発言語(日本語)のフォールバック。Localizable.strings が見つからないときの保険。
    private var fallback: String {
        switch self {
        case .anxious: return "不安"
        case .irritated: return "イライラ"
        case .sad: return "悲しい"
        case .impatient: return "焦り"
        case .empty: return "むなしい"
        case .jealous: return "嫉妬"
        case .ashamed: return "情けない"
        case .tired: return "疲れた"
        case .lonely: return "寂しい"
        case .unclear: return "よくわからない"
        }
    }
}
