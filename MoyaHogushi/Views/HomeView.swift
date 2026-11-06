import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MoyaStore
    @EnvironmentObject private var purchase: PurchaseManager
    @State private var showFlow = false
    @State private var showJournal = false
    @State private var showSettings = false
    @State private var showInsights = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                FogView().opacity(0.8).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        startCard
                        if !store.entries.isEmpty { insightsCard }
                        if !store.pendingActions.isEmpty { pendingSection }
                        if !store.entries.isEmpty { recentSection }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showJournal) { JournalView() }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(isPresented: $showInsights) { InsightsView() }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchase)
        }
        .fullScreenCover(isPresented: $showFlow) {
            FlowView(onClose: { showFlow = false })
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 0) {
                Text("もや").foregroundColor(Theme.text)
                Text("ほぐし").foregroundColor(Theme.accent)
            }
            .font(.system(size: 30, weight: .bold, design: .rounded))
            Spacer()
            HStack(spacing: 8) {
                Button("記録") { showJournal = true }
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(Theme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Theme.card)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                        .frame(width: 34, height: 34)
                        .background(Theme.card)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.line, lineWidth: 1))
                }
                .accessibilityLabel("設定")
            }
        }
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("そのもやもや、\nちょっとだけ整理してみよう")
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundColor(Theme.text)
                .lineSpacing(4)
            Text("書く・感じる・考える・手放す。4ステップで3分ほど。")
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(Theme.secondaryText)
            Button("書いてみる") { showFlow = true }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var insightsCard: some View {
        Button {
            if purchase.isPro { showInsights = true } else { showPaywall = true }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("週のふりかえり")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Theme.text)
                    Text("この7日間の感じ方を見てみる")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                }
                Spacer(minLength: 8)
                if purchase.isPro {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(Theme.tertiaryText)
                } else {
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.accentInk)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("決めた一歩")
            ForEach(store.pendingActions.prefix(3)) { entry in
                ActionRow(entry: entry)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.line, lineWidth: 1)
                    )
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("最近の記録")
                Spacer()
                Button("すべて見る") { showJournal = true }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(Theme.accentInk)
            }
            StatsRow()
            ForEach(store.entries.prefix(2)) { entry in
                EntryCard(entry: entry)
            }
        }
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundColor(Theme.secondaryText)
    }
}
