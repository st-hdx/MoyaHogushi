import SwiftUI

/// 週のふりかえり(Pro)。
struct InsightsView: View {
    @EnvironmentObject private var store: MoyaStore

    var body: some View {
        let insights = Insights(entries: store.entries)

        ZStack {
            Theme.background.ignoresSafeArea()
            FogView().opacity(0.15).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(insights.headline)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Theme.text)
                        .lineSpacing(5)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()

                    HStack(spacing: 10) {
                        tile(
                            title: NSLocalizedString("insights.tile.records", value: "記録", comment: "Insights tile title"),
                            value: String(format: NSLocalizedString("insights.count_entries", value: "%d件", comment: "Entry count"), insights.thisWeek.count),
                            caption: String(format: NSLocalizedString("insights.last_week_count", value: "先週 %d件", comment: "Last week's count"), insights.lastWeek.count)
                        )
                        tile(
                            title: NSLocalizedString("insights.tile.average_intensity", value: "平均の濃さ", comment: "Insights tile title"),
                            value: format(insights.thisWeek.averageIntensity),
                            caption: String(format: NSLocalizedString("insights.last_week_value", value: "先週 %@", comment: "Last week's value"), format(insights.lastWeek.averageIntensity))
                        )
                        tile(
                            title: NSLocalizedString("insights.tile.action_rate", value: "一歩の達成", comment: "Insights tile title"),
                            value: insights.actionRate.map { "\(Int(($0 * 100).rounded()))%" } ?? "–",
                            caption: NSLocalizedString("insights.last_30_days", value: "直近30日", comment: "Last 30 days caption")
                        )
                    }

                    emotionSection(insights.emotions)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("週のふりかえり")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
    }

    private func format(_ value: Double?) -> String {
        guard let value else { return "–" }
        return String(format: "%.1f", value)
    }

    private func tile(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Theme.secondaryText)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundColor(Theme.text)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(caption)
                .font(.system(.caption2, design: .rounded).monospacedDigit())
                .foregroundColor(Theme.tertiaryText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private func emotionSection(_ emotions: [EmotionCount]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("よく感じていたこと(直近30日)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(Theme.secondaryText)

            if emotions.isEmpty {
                Text("感じ方を選んで記録すると、ここに傾向が出ます。")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(Theme.tertiaryText)
            } else {
                let maxCount = max(emotions.map(\.count).max() ?? 1, 1)
                VStack(spacing: 12) {
                    ForEach(emotions) { item in
                        HStack(spacing: 12) {
                            Text(item.name)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(Theme.text)
                                .frame(width: 92, alignment: .leading)
                                .lineLimit(1)
                            GeometryReader { geo in
                                Capsule()
                                    .fill(Theme.accent)
                                    .frame(
                                        width: max(8, geo.size.width * CGFloat(item.count) / CGFloat(maxCount)),
                                        height: 10
                                    )
                                    .frame(maxHeight: .infinity, alignment: .center)
                            }
                            .frame(height: 14)
                            Text("\(item.count)")
                                .font(.system(.footnote, design: .rounded).monospacedDigit())
                                .foregroundColor(Theme.secondaryText)
                                .frame(minWidth: 22, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
