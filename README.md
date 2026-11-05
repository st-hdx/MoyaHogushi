# もやほぐし (MoyaHogushi)

もやもやを「書く → 感じる → 考える → 手放す」の4ステップで整理する iPhone アプリ。
SwiftUI / iOS 16+ / 外部ライブラリは RevenueCat のみ(課金用) / 記録は端末内の JSON にのみ保存し、サーバーには送らない。

## 状態
無料版コアと、Pro(サブスク)の実装まで入っている。まだ Xcode でビルドしていない(執筆環境に Xcode がなかったため)。最初のビルドで型エラーが出たら修正すること。

| | 無料 | Pro |
|---|---|---|
| 書く→手放す | ○ | ○ |
| 記録の閲覧 | 直近10件 | すべて |
| 週のふりかえり(傾向) | - | ○ |
| 毎日のリマインド通知 | - | ○ |
| 記録のテキスト書き出し | - | ○ |

## 開き方
```
cd apps/MoyaHogushi
python3 generate_project.py   # .swift を追加したら再実行
python3 generate_icon.py      # アイコンを作り直すとき(Pillow が必要)
open MoyaHogushi.xcodeproj
```
Bundle ID は `com.pandagiken.moyahogushi.app`、Team は他アプリと同じ設定。

## 構成
- `Models/` : `MoyaEntry`(1件の記録)、`MoyaStore`(JSON保存・集計)
- `Views/FlowView.swift` : 4ステップと手放す演出、完了画面
- `Views/FogView.swift` : 漂う霧。ステップが進むと薄くなり、手放すと消える
- `Views/HomeView.swift` / `JournalView.swift` : ホームと記録一覧(決めた一歩のチェック付き)

## 公開前にやること
1. RevenueCat でアプリを作り、公開APIキーを `Models/PurchaseManager.swift` の `apiKey` に入れる(未設定でも無料版として動く)
2. App Store Connect で月額・年額のサブスクを作り、RevenueCat の Entitlement `MoyaHogushi Pro` と Offering(月額・年額パッケージ)に紐づける
3. `docs/privacy.html` を公開し、`Models/AppLinks.swift` の URL が開けることを確認する
4. 実機/Sandbox で購入・復元・キャンセル、通知の許可と拒否を確認する
5. iCloud(CloudKit)同期は未実装。端末を変えると記録が引き継がれないため、課金後の不満になりやすい

## 開発メモ
- Debug ビルドでは設定画面の「開発用」トグルで Pro を切り替えられる(RevenueCat 未設定でも Pro 画面を確認できる)
- Pro が切れたら、予約済みのリマインドは起動時に自動で解除される
