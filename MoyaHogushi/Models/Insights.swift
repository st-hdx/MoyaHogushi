import Foundation

struct EmotionCount: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

/// 直近7日と、その前の7日を比べた「週のふりかえり」。
struct Insights {
    struct Period {
        let count: Int
        let averageIntensity: Double?
    }

    let thisWeek: Period
    let lastWeek: Period
    let emotions: [EmotionCount]
    let actionRate: Double?
    let headline: String

    init(entries: [MoyaEntry], now: Date = Date(), calendar: Calendar = .current) {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        let current = entries.filter { $0.createdAt > weekAgo && $0.createdAt <= now }
        let previous = entries.filter { $0.createdAt > twoWeeksAgo && $0.createdAt <= weekAgo }
        let month = entries.filter { $0.createdAt > monthAgo && $0.createdAt <= now }

        let thisPeriod = Self.period(current)
        let lastPeriod = Self.period(previous)
        thisWeek = thisPeriod
        lastWeek = lastPeriod

        let counts = month.flatMap(\.emotions).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        emotions = counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(5)
            .map { EmotionCount(name: $0.key, count: $0.value) }

        let withAction = month.filter(\.hasAction)
        actionRate = withAction.isEmpty
            ? nil
            : Double(withAction.filter(\.actionDone).count) / Double(withAction.count)

        headline = Self.makeHeadline(current: current, thisWeek: thisPeriod, lastWeek: lastPeriod)
    }

    private static func period(_ list: [MoyaEntry]) -> Period {
        let average = list.isEmpty
            ? nil
            : Double(list.map(\.intensity).reduce(0, +)) / Double(list.count)
        return Period(count: list.count, averageIntensity: average)
    }

    private static func makeHeadline(current: [MoyaEntry], thisWeek: Period, lastWeek: Period) -> String {
        guard thisWeek.count > 0, let now = thisWeek.averageIntensity else {
            return "この7日間はまだ記録がありません。もやもやしたら、いつでも書いてみて。"
        }

        let counts = current.flatMap(\.emotions).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        let top = counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.first?.key

        var sentences: [String] = []
        if let top = top {
            sentences.append("この7日間は「\(top)」が多めでした。")
        } else {
            sentences.append("この7日間に\(thisWeek.count)件、向き合いました。")
        }

        if let before = lastWeek.averageIntensity {
            let delta = now - before
            if delta <= -0.5 {
                sentences.append("もやもやの濃さは先週より下がっています。")
            } else if delta >= 0.5 {
                sentences.append("もやもやの濃さは先週より上がっています。ゆっくり休んでね。")
            } else {
                sentences.append("もやもやの濃さは先週と同じくらいです。")
            }
        }
        return sentences.joined()
    }
}
