import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: MoyaStore
    @EnvironmentObject private var purchase: PurchaseManager
    @State private var showPaywall = false

    private var visibleEntries: [MoyaEntry] {
        purchase.isPro ? store.entries : Array(store.entries.prefix(PurchaseManager.freeEntryLimit))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            FogView().opacity(0.15).ignoresSafeArea()

            if store.entries.isEmpty {
                VStack(spacing: 8) {
                    Text("まだ記録がありません")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Theme.text)
                    Text("最初のもやもやを書いてみよう")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        StatsRow()
                        ForEach(visibleEntries) { entry in
                            EntryCard(entry: entry)
                        }
                        if visibleEntries.count < store.entries.count {
                            lockedCard(hiddenCount: store.entries.count - visibleEntries.count)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("記録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchase)
        }
    }

    private func lockedCard(hiddenCount: Int) -> some View {
        Button { showPaywall = true } label: {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(Theme.accent)
                Text("さらに\(hiddenCount)件の記録があります")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(Theme.text)
                Text("Proで、これまでの記録をすべてさかのぼれます")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Theme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.accent.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StatsRow: View {
    @EnvironmentObject private var store: MoyaStore

    var body: some View {
        HStack(spacing: 8) {
            pill("全 \(store.entries.count) 件")
            pill("今週 \(store.thisWeekCount) 件")
            if let top = store.topEmotion {
                pill("多い感じ: \(top)")
            }
            Spacer(minLength: 0)
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded).weight(.medium))
            .foregroundColor(Theme.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }
}

struct EntryCard: View {
    @EnvironmentObject private var store: MoyaStore
    let entry: MoyaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundColor(Theme.tertiaryText)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...10, id: \.self) { index in
                        Capsule()
                            .fill(index <= entry.intensity ? Theme.accent : Theme.line)
                            .frame(width: 5, height: 10)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("もやもやの濃さ \(entry.intensity)")
            }

            Text(entry.text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Theme.text)
                .lineSpacing(3)
                .lineLimit(4)

            if !entry.emotions.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(entry.emotions, id: \.self) { emotion in
                        Text(emotion)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(Theme.cardSoft)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }
                }
            }

            if entry.hasAction {
                ActionRow(entry: entry)
            } else if entry.controllable == false {
                Label("手放した(相手や状況次第)", systemImage: "wind")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(Theme.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
        .contextMenu {
            Button(role: .destructive) {
                store.delete(entry)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

struct ActionRow: View {
    @EnvironmentObject private var store: MoyaStore
    let entry: MoyaEntry

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            store.toggleActionDone(entry)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: entry.actionDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(entry.actionDone ? Theme.good : Theme.tertiaryText)
                Text(entry.action)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(entry.actionDone ? Theme.tertiaryText : Theme.text)
                    .strikethrough(entry.actionDone)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.cardSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("最初の一歩: \(entry.action)")
        .accessibilityValue(entry.actionDone ? "完了" : "未完了")
    }
}
