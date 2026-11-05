import Foundation

enum AppLinks {
    /// 公開前に、このURLで実際にページが開ける状態にしておくこと(docs/privacy.html を公開する)。
    static let privacyPolicy = URL(string: "https://st-hdx.github.io/moyahogushi-docs/privacy.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
}
