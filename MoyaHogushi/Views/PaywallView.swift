import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject private var purchase: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedID: String?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var isLoadingPlans = false
    @State private var errorMessage: String?

    private var selectedPackage: Package? {
        purchase.packages.first { $0.identifier == selectedID } ?? purchase.packages.first
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.background.ignoresSafeArea()
            FogView().opacity(0.35).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    header
                    features
                    plans
                    footer
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 32)
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.secondaryText)
                    .frame(width: 34, height: 34)
                    .background(Theme.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.line, lineWidth: 1))
            }
            .accessibilityLabel("閉じる")
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .task {
            if purchase.packages.isEmpty { await purchase.loadOfferings() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.accent)
            Text("もやもやを、\nもっと遠くまで見渡す")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
            Text(String(format: NSLocalizedString("paywall.free_limit_header", value: "無料版は直近%d件まで。\nProで、積み重ねた記録が自分のヒントになります。", comment: "Paywall header subtitle"), PurchaseManager.freeEntryLimit))
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow("clock.arrow.circlepath", "過去の記録をすべてさかのぼれる")
            featureRow("chart.bar.xaxis", "週のふりかえりで、感じ方の傾向がわかる")
            featureRow("bell", "毎日のリマインドで書く習慣をつくる")
            featureRow("square.and.arrow.up", "記録をテキストで書き出せる")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func featureRow(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(.body))
                .foregroundColor(Theme.accent)
                .frame(width: 26)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var plans: some View {
        if purchase.packages.isEmpty {
            VStack(spacing: 12) {
                Text(PurchaseManager.isConfigurable
                     ? LocalizedStringKey("プランを読み込めませんでした")
                     : LocalizedStringKey("購入機能は準備中です"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(Theme.secondaryText)
                if PurchaseManager.isConfigurable {
                    Button("もう一度読み込む") {
                        Task {
                            isLoadingPlans = true
                            await purchase.loadOfferings()
                            isLoadingPlans = false
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isLoadingPlans)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(purchase.packages, id: \.identifier) { package in
                    planRow(package)
                }
            }
        }
    }

    private func planRow(_ package: Package) -> some View {
        let isOn = package.identifier == (selectedPackage?.identifier)
        let isAnnual = package.packageType == .annual
        return Button {
            selectedID = package.identifier
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isOn ? Theme.accent : Theme.tertiaryText)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(isAnnual ? LocalizedStringKey("年額プラン") : LocalizedStringKey("月額プラン"))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(Theme.text)
                        if isAnnual {
                            Text("おすすめ")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .foregroundColor(Theme.accentInk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Theme.accentSoft)
                                .clipShape(Capsule())
                        }
                    }
                    if isAnnual, let perMonth = package.storeProduct.localizedPricePerMonth {
                        Text(String(format: NSLocalizedString("paywall.per_month_price", value: "月あたり %@", comment: "Per-month equivalent price"), perMonth))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Theme.tertiaryText)
                    }
                }
                Spacer(minLength: 8)
                Text(String(
                    format: NSLocalizedString(
                        isAnnual ? "paywall.price_per_year" : "paywall.price_per_month",
                        value: isAnnual ? "%@ / 年" : "%@ / 月",
                        comment: "Plan price with its billing period"
                    ),
                    package.storeProduct.localizedPriceString
                ))
                    .font(.system(.subheadline, design: .rounded).weight(.medium).monospacedDigit())
                    .foregroundColor(Theme.text)
            }
            .padding(16)
            .background(isOn ? Theme.accentSoft : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isOn ? Theme.accent : Theme.line, lineWidth: isOn ? 1.5 : 1)
            )
        }
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var footer: some View {
        VStack(spacing: 14) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await subscribe() }
            } label: {
                if isPurchasing {
                    ProgressView().tint(Theme.onAccent)
                } else {
                    Text("Proを始める")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedPackage == nil || isPurchasing || isRestoring)

            Button {
                Task { await restore() }
            } label: {
                if isRestoring {
                    ProgressView()
                } else {
                    Text("購入を復元する")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .disabled(isPurchasing || isRestoring)

            Text("購読は自動更新されます。現在の期間が終了する24時間以上前にApple IDの設定から解約しない限り、同じ金額で更新されます。解約は設定アプリの「サブスクリプション」からいつでもできます。")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(Theme.tertiaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            HStack(spacing: 18) {
                Link("利用規約", destination: AppLinks.terms)
                Link("プライバシーポリシー", destination: AppLinks.privacyPolicy)
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(Theme.secondaryText)
        }
    }

    // MARK: - Actions

    private func subscribe() async {
        guard let package = selectedPackage else { return }
        isPurchasing = true
        errorMessage = nil
        let startedAt = Date()
        do {
            try await purchase.purchase(package)
            dismiss()
        } catch PurchaseError.cancelled {
            // タップから1秒未満のキャンセルは人間の操作ではなく、端末側の制限(スクリーンタイム等)で
            // 確認シートが出ないまま弾かれたと見なす。他アプリでも同じ現象を確認済み。
            if Date().timeIntervalSince(startedAt) < 1.0 {
                errorMessage = NSLocalizedString(
                    "purchase_blocked_by_restriction_message",
                    value: "購入の確認画面を開けませんでした。端末の制限(スクリーンタイムなど)をご確認ください。",
                    comment: "Shown when the purchase sheet never appeared"
                )
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? NSLocalizedString(
                "purchase_failed_message",
                value: "購入に失敗しました。時間をおいてもう一度お試しください。",
                comment: "Generic purchase failure"
            )
        }
        isPurchasing = false
    }

    private func restore() async {
        isRestoring = true
        errorMessage = nil
        do {
            try await purchase.restore()
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? NSLocalizedString(
                "restore_failed_message",
                value: "購入の復元に失敗しました。時間をおいてもう一度お試しください。",
                comment: "Generic restore failure"
            )
        }
        isRestoring = false
    }
}
