import Foundation

struct MoyaEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt = Date()
    var text = ""
    var emotions: [String] = []
    var intensity = 5
    var reflection = ""
    var controllable: Bool?
    var action = ""
    var actionDone = false

    var hasAction: Bool { controllable == true && !action.isEmpty }
}

enum Emotion {
    static let all = [
        "不安", "イライラ", "悲しい", "焦り", "むなしい",
        "嫉妬", "情けない", "疲れた", "寂しい", "よくわからない"
    ]
}
