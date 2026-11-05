# もやほぐし (MoyaHogushi)

もやもやを「書く → 感じる → 考える → 手放す」の4ステップで整理する iPhone アプリ。
SwiftUI / iOS 16+ / 外部ライブラリなし / データは端末内の JSON のみ(通信なし)。

## 状態
無料版コアのみ。まだ Xcode でビルドしていない(執筆環境に Xcode がなかったため)。最初のビルドで型エラーが出たら修正すること。

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

## 次にやること(課金まわり)
1. RevenueCat を BloomJournal と同じ構成で導入(`PurchaseManager` / `PaywallView` を参考にする)
2. 無料は直近の記録のみ、有料で長期振り返り・リマインド通知・ウィジェット・エクスポートを解放
3. iCloud(CloudKit)同期
