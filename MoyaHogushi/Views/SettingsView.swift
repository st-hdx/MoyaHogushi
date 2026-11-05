import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MoyaStore
    @EnvironmentObject private var purchase: PurchaseManager
    @EnvironmentObject private var reminder: ReminderManager
    @Environment(\.openURL) private var openURL

    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminder.hour, minute: reminder.minute, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminder.setTime(hour: parts.hour ?? 21, minute: parts.minute ?? 0)
            }
        )
    }

    private var reminderEnabled: Binding<Bool> {
        Binding(
            get: { reminder.isEnabled },
            set: { on in Task { await reminder.setEnabled(on) } }
        )
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        Form {
            proSection
            reminderSection
            SyncSection(sync: store.sync)
            dataSection
            aboutSection
            #if DEBUG
            Section("開発用") {
                Toggle("Pro(デバッグ)", isOn: Binding(
                    get: { purchase.isPro },
                    set: { _ in purchase.toggleProForDebug() }
                ))
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchase)
        }
    }

    // MARK: - Sections

    private var proSection: some View {
        Section {
            if purchase.isPro {
                Label("Pro をご利用中です", systemImage: "checkmark.seal")
                    .foregroundColor(Theme.good)
                    .listRowBackground(Theme.card)
                Button("サブスクリプションを管理") { openURL(AppLinks.manageSubscriptions) }
                    .foregroundColor(Theme.text)
                    .listRowBackground(Theme.card)
            } else {
                Button { showPaywall = true } label: {
                    HStack {
                        Text("Pro にアップグレード")
                            .foregroundColor(Theme.accentInk)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(Theme.tertiaryText)
                    }
                }
                .listRowBackground(Theme.accentSoft)
            }

            Button {
                Task { await restore() }
            } label: {
                HStack {
                    Text("購入を復元する").foregroundColor(Theme.text)
                    if isRestoring { Spacer(); ProgressView() }
                }
            }
            .disabled(isRestoring)
            .listRowBackground(Theme.card)

            if let restoreMessage {
                Text(restoreMessage)
                    .font(.footnote)
                    .foregroundColor(Theme.secondaryText)
                    .listRowBackground(Theme.card)
            }
        } header: {
            Text("プラン")
        }
    }

    @ViewBuilder
    private var reminderSection: some View {
        Section {
            if purchase.isPro {
                Toggle("毎日のリマインド", isOn: reminderEnabled)
                    .tint(Theme.accent)
                    .listRowBackground(Theme.card)
                if reminder.isEnabled {
                    DatePicker("時刻", selection: reminderTime, displayedComponents: .hourAndMinute)
                        .listRowBackground(Theme.card)
                }
                if reminder.permissionDenied {
                    Button("通知がオフです。設定アプリで許可する") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .font(.footnote)
                    .foregroundColor(Theme.accentInk)
                    .listRowBackground(Theme.card)
                }
            } else {
                lockedRow("毎日のリマインド")
            }
        } header: {
            Text("リマインド")
        } footer: {
            Text("決めた時刻に「今日、もやもやしたことはあった?」とお知らせします。")
        }
    }

    @ViewBuilder
    private var dataSection: some View {
        Section {
            if purchase.isPro {
                ShareLink(item: store.exportText()) {
                    Label("記録をテキストで書き出す", systemImage: "square.and.arrow.up")
                        .foregroundColor(Theme.text)
                }
                .listRowBackground(Theme.card)
            } else {
                lockedRow("記録をテキストで書き出す")
            }
        } header: {
            Text("データ")
        } footer: {
            Text("書き出した内容は、共有先に選んだアプリやサービスに渡ります。")
        }
    }

    private var aboutSection: some View {
        Section {
            Link("プライバシーポリシー", destination: AppLinks.privacyPolicy)
                .foregroundColor(Theme.text)
                .listRowBackground(Theme.card)
            Link("利用規約", destination: AppLinks.terms)
                .foregroundColor(Theme.text)
                .listRowBackground(Theme.card)
            HStack {
                Text("バージョン")
                Spacer()
                Text(appVersion).foregroundColor(Theme.tertiaryText)
            }
            .listRowBackground(Theme.card)
        } header: {
            Text("このアプリについて")
        }
    }

    private func lockedRow(_ title: String) -> some View {
        Button { showPaywall = true } label: {
            HStack {
                Text(title).foregroundColor(Theme.text)
                Spacer()
                Label("Pro", systemImage: "lock.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.accentInk)
            }
        }
        .listRowBackground(Theme.card)
    }

    private func restore() async {
        isRestoring = true
        restoreMessage = nil
        do {
            try await purchase.restore()
            restoreMessage = "購入を復元しました。"
        } catch {
            restoreMessage = (error as? LocalizedError)?.errorDescription ?? "購入の復元に失敗しました。"
        }
        isRestoring = false
    }
}

private struct SyncSection: View {
    @ObservedObject var sync: CloudSync

    private var statusText: String? {
        switch sync.status {
        case .off: return nil
        case .unavailable: return "iCloudにサインインしていないか、このアプリのiCloudが許可されていません。"
        case .syncing: return "同期しています…"
        case .synced(let date): return "最終同期 " + date.formatted(date: .omitted, time: .shortened)
        }
    }

    var body: some View {
        Section {
            Toggle("iCloudで同期", isOn: Binding(
                get: { sync.isEnabled },
                set: { sync.setEnabled($0) }
            ))
            .tint(Theme.accent)
            .listRowBackground(Theme.card)

            if let statusText = statusText {
                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(Theme.secondaryText)
                    .listRowBackground(Theme.card)
            }
        } header: {
            Text("同期")
        } footer: {
            Text("オンにすると、記録があなたのiCloudにも保存され、同じApple IDの端末で引き継げます。開発者が記録を見ることはできません。オフでも記録はこの端末に残ります。")
        }
    }
}
