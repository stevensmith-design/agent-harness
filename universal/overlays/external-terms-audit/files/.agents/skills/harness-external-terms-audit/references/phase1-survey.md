# Phase 1: システムを把握する

目的は、後の監査で「どのデータが、どこから来て、どこへ行き、どこに残るか」を `file:line` 付きで言える状態にすること。きれいな設計書を作ることではない。

## 1. 全体を掴む (30 分程度)

次を順に読む。全部読み切らなくてよい。

- README、docs/、ADR、`.env.example` (どの外部サービスの鍵を使うかが一番早く分かる)
- パッケージ定義: `package.json` / `requirements.txt` / `pyproject.toml` / `go.mod` / `Gemfile` / `pom.xml` など。外部 SDK (`@line/bot-sdk`, `@googlemaps/*`, `@google-cloud/vertexai`, `openai`, `stripe`, `firebase-admin` など) を拾う
- インフラ定義: Dockerfile、compose、Terraform、`cloudbuild.yaml`、GitHub Actions、`vercel.json`、Cloud Run / Lambda の設定
- DB スキーマとマイグレーション: Prisma / TypeORM / Rails / Django / SQL ファイル。**マイグレーションの履歴**は「いつ何を保存しなくなったか」の証拠になる
- エントリポイント: Web のルート定義、API ハンドラ、Webhook、バッチ・cron、キューのワーカー

## 2. 外部サービス台帳を作る

アプリが関わる外部サービスを**全部**列挙する。特定のサービスだけを探さない。

### 外部サービスの分類

漏れを防ぐため、次の分類を 1 つずつ「このアプリにあるか」で確かめる。

| 分類 | 例 |
|---|---|
| メッセージング・チャット基盤 | LINE、Slack、Discord、WhatsApp、Teams |
| 地図・位置情報 | Google Maps Platform、Mapbox、国土地理院、HERE |
| 生成 AI・機械学習 API | Vertex AI / Gemini、OpenAI、Anthropic、Azure OpenAI、音声認識・翻訳 API |
| 決済・課金 | Stripe、PAY.JP、GMO PG、PayPay、App 内課金 (Apple / Google) |
| 認証・ソーシャルログイン | Firebase Auth、Auth0、Cognito、Sign in with Apple、Google / LINE / X ログイン |
| メール・SMS・電話 | SendGrid、Amazon SES、Twilio、Mailchimp |
| プッシュ通知 | FCM、APNs、OneSignal |
| 分析・計測・広告 | GA4、Firebase Analytics、Mixpanel、Amplitude、広告 SDK、各種タグ (GTM) |
| エラー監視・ログ・APM | Sentry、Datadog、New Relic、Cloud Logging |
| ストレージ・CDN・ホスティング・クラウド | S3、GCS、Cloudflare、Vercel、Cloud Run、Firebase Hosting |
| アプリストア・配布 | App Store Review Guidelines、Google Play デベロッパーポリシー |
| 外部データ API・オープンデータ・提供データ | 天気、交通、イベント情報、提携先から受け取るデータファイル |
| 埋め込み・ウィジェット | YouTube 埋め込み、SNS の埋め込み、reCAPTCHA、Web フォント |
| スクレイピング先 | 他社サイトから取得しているデータ (取得手段そのものが規約の論点) |

### 見つけ方

サーバーだけでなく、フロントエンド、モバイル、インフラ、CI も見る。モノレポでは各アプリ・各パッケージを再帰的に拾う。まず構成ファイルの一覧を作り、そこから読む対象を選ぶ (ルート直下だけ見ない)。

```bash
# 1. 構成ファイルを再帰的に列挙 (隠しディレクトリも含め、依存物とビルド成果物は除く)
rg --files --hidden -g '!.git' -g '!**/node_modules/**' -g '!**/vendor/**' -g '!**/dist/**' -g '!**/.next/**' -g '!**/build/**' \
  | rg -i '(package\.json|requirements.*\.txt|pyproject\.toml|go\.mod|Gemfile|pom\.xml|build\.gradle(\.kts)?|Podfile|pubspec\.yaml|Package\.swift|Dockerfile|compose.*\.ya?ml|\.tf$|cloudbuild.*\.ya?ml|\.github/workflows/.*\.ya?ml|vercel\.json|firebase\.json|app\.json|AndroidManifest\.xml|Info\.plist|PrivacyInfo\.xcprivacy|\.env\.(example|sample)|serverless\.ya?ml)$'

# 2. 外部ホストへの URL (lock と依存物は除く)
rg -n -o --hidden -g '!.git' -g '!**/node_modules/**' -g '!*.lock' "https?://[a-zA-Z0-9.-]+\.[a-z]{2,}" | sort -u

# 3. HTTP クライアント、埋め込みタグ、環境変数
rg -n --hidden -g '!.git' -g '!**/node_modules/**' "fetch\(|axios|got\(|requests\.(get|post)|httpx|http\.Client|URLSession|OkHttp|Retrofit"
rg -n --hidden -g '!.git' -g '!**/node_modules/**' "<script[^>]+src=|gtag\(|dataLayer|fbq\(|Sentry\.init|datadog|amplitude|mixpanel"
rg -n --hidden -g '!.git' -g '!**/node_modules/**' "process\.env\.|os\.environ|ENV\[|getenv|BuildConfig\." | rg -i "key|token|secret|url|endpoint|project|dsn|client_id"
```

ファイルは必要な部分を読み、途中で打ち切った場合は読んでいない範囲を `survey.unverified` に書く。秘密情報 (`.env` の実値、鍵ファイル) は読まない・写さない。

見つかった URL のホストと SDK 名を分類表に当てはめ、どれにも入らないものは「その他」として台帳に載せる。

### コードだけでは分からない外部サービス

次はリポジトリを検索しても出てこないことがある。あり得る箇所を書き出し、確認方法を台帳の「確認方法」(`basis`) 欄に「コードで確認」「設定資料が必要」「未確認」のどれかで残す。

- タグマネージャー (GTM など) の管理画面で追加されたタグ、Remote Config、機能フラグ
- クラウドの管理コンソールで設定したログ転送、分析基盤への連携、バックアップ先
- SDK が自動で集めるデータ (分析 SDK の自動イベント、クラッシュレポートの端末情報)、SDK の推移的な依存
- モバイルの権限 (AndroidManifest、Info.plist)、Privacy Manifest、ストアのプライバシー申告

サービスごとに次を埋める (`survey.services`)。

| 項目 | 例 |
|---|---|
| 名前と使っている API | Google Maps Platform: Places API (New) Details / Photos、Routes、Geocoding、Maps JavaScript |
| 呼び出し箇所 | `src/lib/places.ts:42` |
| 送るもの | place_id、FieldMask。利用者の位置情報は送らない |
| 受け取るもの | 写真、営業時間、電話、URL |
| 保存先と期間 | place_id は DB に無期限、座標は 30 日で削除、他は保存しない |
| 表示先 | LIFF の詳細画面、LINE の Flex には出さない |
| 認証 | サーバーキー、サービスアカウント、OAuth |

「送るもの」には **他社から受け取ったデータ** (チャットの本文、ユーザー ID、他 API の応答) が混ざっていないかを必ず書く。規約違反の多くはここで起きる。

## 3. データの保存先を洗う

DB のテーブル・列ごとに、どの外部サービス由来のデータが入るかを書く。列だけでなく次も見る。

- JSON 列 (`payload`, `data`, `raw`) に外部の応答や送信メッセージを丸ごと入れていないか
- ログ (アプリログ、ジョブのエラーログ、監査ログ) に応答本文を出していないか
- キャッシュ (Redis、CDN、`Cache-Control`、Next.js の fetch キャッシュ)
- エクスポート機能、バックアップ、分析基盤への連携
- ブラウザや端末内の保存: localStorage、sessionStorage、IndexedDB、Cookie、Service Worker のキャッシュ、端末の DB やファイル、OS のバックアップ対象
- 削除の仕組み (退会、保持期間ジョブ、送信取消) があるか、無いか

## 4. ユーザーフローと経路を書く

利用者の操作ごとに、入口から外部サービスと保存先を経て出口までを 1 本の経路として書く。経路は後で Phase 5 の「具体例」になるので、ここで漏れなく洗う。典型:

- チャットで相談する (受信 -> 保存 -> 生成 AI -> 返信 -> 保存)
- アプリ内画面で詳細を見る (DB -> 外部 API -> 表示)
- 定期配信 (スケジュール -> 対象者抽出 -> 配信)
- 日次バッチ (外部 API -> 保存、生成 AI での加工)
- 管理画面とエクスポート

画面のスクリーンショットが要る場合だけローカルで起動する。起動は、隔離した環境・架空のデータ・外部送信の無効化 (課金 API、メール、プッシュ、分析、ジョブを止めるかモックに向ける) が揃うときに限る。揃わない、または認証の都合で撮れない画面は「未確認」と書く。

## 5. 図を作る

`survey.diagrams` に入れる。`kind` は `ascii` か `mermaid`。

- **構成図 (ネットワーク)**: 利用者、外部プラットフォーム、自社の実行環境、DB、外部 API を箱と矢印で。矢印に番号を振り、凡例で「流れるもの」を書く
- **シーケンス図**: 主要な経路ごとに 1 枚。Mermaid の `sequenceDiagram` が書きやすい
- 図の中は ASCII を基本にする (日本語は桁がずれる)。日本語の説明は凡例に書く

## 6. survey の書き出し

`report.json` の `survey` に、`overview` (3〜6 行の要約)、`components`、`services` (分類 `category` と確認方法 `basis` を含む)、`storage`、`flows_summary`、`diagrams`、`unverified` (確認できなかった範囲) を入れる (形は [schema.md](schema.md))。Phase 1 だけで終える依頼なら、ここで `render.py` を回して報告する。
