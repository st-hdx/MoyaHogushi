# App Store Connect 文章案(下書き)

実装済みの機能のみに基づく。医療・治療効果は謳わない。価格は未定のため `(価格)` のまま。
英語版は今回のローカライズ(Localizable.strings)と同じ訳語で統一した。

## 日本語(プライマリ)

### アプリ名(30文字以内)
候補1: `もやほぐし - もやもや整理ジャーナル`(18文字)
候補2: `もやほぐし: 書いて手放す4ステップ`(16文字)

### サブタイトル(30文字以内)
候補1: `書く・感じる・考える・手放す4ステップ`(19文字)
候補2: `もやもやを3分で整理するジャーナル`(16文字)

### キーワード(100文字以内、カンマ区切り)
候補1(66文字):
`日記,ジャーナリング,感情記録,モヤモヤ,ストレス発散,セルフケア,メンタルケア,マインドフルネス,振り返り,習慣化,手放す,気持ち整理`

候補2(74文字):
`気持ち,心の整理,モヤモヤ解消,感情日記,内省,セルフケア,振り返り習慣,ストレス,メンタルヘルス,デジタル日記,もやもや,ジャーナリング`

(「もやほぐし」とアプリ名に含まれる語はキーワードから除外、「日記」「ジャーナリング」はサブタイトルと重複しない組み合わせにしてある)

### 説明文

```
その日のもやもやを、書く→感じる→考える→手放すの4ステップで、3分ほどで整理するジャーナルアプリです。
頭の中だけで考え続けるより、書き出して手放すほうが、次の一歩を決めやすくなります。
記録は端末内(iCloudで同期オン時はご自身のiCloud Driveにも)に保存され、開発者のサーバーには送信されません。

【できること】
・書く → 感じる → 考える → 手放す、の4ステップでもやもやを整理
・感情のタグ付けと、もやもやの濃さ(1〜10)を記録
・自分の行動で変えられることなら、最初の一歩だけを決めて手放す
・記録の一覧から、決めた一歩をあとからチェック

【Pro(月額/年額 (価格))でできること】
・記録をすべてさかのぼって閲覧(無料版は直近10件まで)
・週のふりかえりで、感じ方や濃さの傾向を見る
・毎日決まった時刻にリマインド通知
・記録をテキストでまとめて書き出し、共有

【購読について】
・Pro は自動更新の定期購読です(月額 (価格) / 年額 (価格))
・購読は現在の期間が終了する24時間以上前に解約しない限り、同じ金額で自動更新されます
・解約はいつでも、設定アプリの「サブスクリプション」から行えます
・利用規約: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
・プライバシーポリシー: https://st-hdx.github.io/moyahogushi-docs/privacy.html
```

### プロモーションテキスト(170文字以内、随時更新可)
候補1: `頭の中だけで考え続けるより、書いて手放すほうが、次の一歩が決まる。3分でできるもやもや整理。`
候補2: `今日のもやもやを、書く→感じる→考える→手放すの4ステップで。iCloud同期は無料でご利用いただけます。`

---

## English

### Name (≤30 chars)
Option 1: `MoyaHogushi: Untangle & Write` (29 chars)
Option 2: `MoyaHogushi - Clear Your Mind` (29 chars)

### Subtitle (≤30 chars)
Option 1: `Write, feel, think, release` (28 chars)
Option 2: `A 3-minute journal for worry` (28 chars)

### Keywords (≤100 chars, comma-separated)
Option 1 (86 chars):
`journal,journaling,mood tracker,anxiety relief,self care,mindfulness,declutter mind,vent`

Option 2 (84 chars):
`clear mind,emotional journal,stress relief,daily journal,mindfulness,self reflection,vent`

(Avoids repeating words already in the name/subtitle: "write", "release", "worry".)

### Description

```
A gentle journaling app that helps you untangle whatever's weighing on your mind, in four
steps — write, feel, think, release — in about 3 minutes.
Writing it down and setting it aside makes the next step easier to see than just turning
it over in your head. Your entries stay on your device (and in your own iCloud, if sync
is on) — nothing is ever sent to our servers.

WHAT YOU CAN DO
• Untangle a foggy feeling in four steps: write, feel, think, release
• Tag how you feel and rate how heavy it feels (1–10)
• If it's something you can act on, decide just the first step and let the rest go
• Check off your next steps later from your entry list

WITH PRO (monthly/annual, (price))
• Look back through every past entry (free plan shows your most recent 10)
• See a weekly review of how you've been feeling
• Get a daily reminder at a time you choose
• Export your entries as text to share

ABOUT THE SUBSCRIPTION
• Pro is an auto-renewing subscription (monthly (price) / annual (price))
• It renews automatically at the same price unless cancelled at least 24 hours before
  the current period ends
• Cancel anytime from Settings → Subscriptions
• Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
• Privacy Policy: https://st-hdx.github.io/moyahogushi-docs/privacy.html
```

### Promotional text (≤170 chars)
Option 1: `Writing it down and letting it go beats turning it over in your head. Untangle today's foggy feeling in about 3 minutes.`
Option 2: `Write, feel, think, release — four steps for whatever's on your mind today. iCloud sync included free.`

---

## App Privacy(アプリのプライバシー申告)下書き

コードと `docs/privacy.html` を根拠に作成。**要確認の項目あり。**

| データの種類 | 収集 | 用途 | 本人に紐づけ | 備考 |
|---|---|---|---|---|
| 記録の内容(テキスト・感情・濃さ等) | いいえ | - | - | 端末内のみ。iCloud同期時もApple自身のiCloud Driveで、開発者には送信されない |
| 購入情報(匿名のユーザーID・購入プラン) | はい(RevenueCat経由) | アプリの機能(購読状況の確認) | 本人に紐づけない(匿名ID) | 要確認: RevenueCatの公式ガイド(https://www.revenuecat.com/docs/) の最新のApp Privacy記載例と突き合わせること |
| 診断情報・クラッシュログ | 要確認 | - | - | Apple純正のクラッシュ収集(Xcode Organizer)を使う場合はAppleのプライバシー申告ルールに従う。サードパーティの計測SDKは組み込んでいない |

申告しないでよいもの(コード上、未実装・未収集): 位置情報、連絡先、閲覧履歴、識別子(広告ID)、他社とのデータ共有によるトラッキング。

**公開前に確認してほしいこと**
1. RevenueCatのApp Privacy申告ガイド最新版と、上表が食い違っていないか
2. `docs/privacy.html` の内容(特に第4項・第5項)と、ここの申告が矛盾していないか
3. 価格(月額・年額)が決まったら、説明文と本ドキュメントの `(価格)` をすべて置き換える
