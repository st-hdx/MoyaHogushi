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

enum Emotion {
    static let all = [
        "不安", "イライラ", "悲しい", "焦り", "むなしい",
        "嫉妬", "情けない", "疲れた", "寂しい", "よくわからない"
    ]
}
