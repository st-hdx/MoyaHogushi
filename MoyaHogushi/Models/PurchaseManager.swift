import Foundation
import Combine
import RevenueCat

/// サブスクリプション(Pro)の状態管理。RevenueCat のキー未設定でもアプリは無料版として動く。
final class PurchaseManager: ObservableObject {
    static let apiKey = "appl_XjCgmyZfPDtVEVdfBjXBhcyofiq"
    static let entitlementID = "moyahogushi_pro"
    static let freeEntryLimit = 10

    @Published private(set) var isPro = false
    @Published private(set) var packages: [Package] = []
    /// 購読状態を一度でも確定できたら true。未確定の間に Pro 限定機能を止めないために使う。
    @Published private(set) var isLoaded = false

    static var isConfigurable: Bool { !apiKey.contains("REPLACE") }

    static func configure() {
        guard isConfigurable else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }

    @MainActor
    func start() async {
        guard Self.isConfigurable, Purchases.isConfigured else {
            isLoaded = true
            return
        }
        Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
            isLoaded = true
        }
        await loadOfferings()
    }

    @MainActor
    func loadOfferings() async {
        guard Purchases.isConfigured,
              let offerings = try? await Purchases.shared.offerings() else { return }
        let current = offerings.current
        packages = [current?.annual, current?.monthly].compactMap { $0 }
    }

    @MainActor
    func purchase(_ package: Package) async throws {
        guard Purchases.isConfigured else { throw PurchaseError.notConfigured }
        // RevenueCat は「やめた」で例外を投げず userCancelled: true で正常に返す。
        // これを見ずにエンタイトルメントの有無だけで判定すると、キャンセルが失敗表示になる。
        let result = try await Purchases.shared.purchase(package: package)
        apply(result.customerInfo)
        if result.userCancelled { throw PurchaseError.cancelled }
        if !isPro { throw PurchaseError.notEntitled }
    }

    @MainActor
    func restore() async throws {
        guard Purchases.isConfigured else { throw PurchaseError.notConfigured }
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
        if !isPro { throw PurchaseError.notEntitled }
    }

    @MainActor
    private func apply(_ info: CustomerInfo) {
        isPro = info.entitlements[Self.entitlementID]?.isActive == true
    }

    #if DEBUG
    func toggleProForDebug() { isPro.toggle() }
    #endif
}

enum PurchaseError: LocalizedError {
    case notConfigured
    case notEntitled
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return NSLocalizedString("purchase_error.not_configured", value: "購入機能は準備中です。", comment: "")
        case .notEntitled:
            return NSLocalizedString("purchase_error.not_entitled", value: "購入情報が見つかりませんでした。", comment: "")
        case .cancelled: return nil
        }
    }
}
