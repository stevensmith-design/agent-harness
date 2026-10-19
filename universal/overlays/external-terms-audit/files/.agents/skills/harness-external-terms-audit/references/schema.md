# report.json の形

`<skill>/scripts/render.py` が読む形。**トップレベルのセクションはすべて任意**で、無いセクションは描かれない。セクションの中の要素には必須キーがある (下の表)。描画デモ用の例は [../examples/report.example.json](../examples/report.example.json)。

## 必須キー

| 要素 | 必須 | 任意 |
|---|---|---|
| `findings[]` | `id`, `sev`, `title` | `service`, `owner`, `clause`, `fact`, `action`, `basis`, `refs`, `related` |
| `services[]` | `key`, `name` | `sub`, `prefix` |
| `flows[]` | `key`, `title` | `sub`, `steps` |
| `flows[].steps[]` | `actor`, `title` | `data`, `items` |
| `categories[]` | `code`, `title` | `effort`, `policy`, `ids` |
| `checks[]` | `id`, `question` | `related` |
| `sources[]` | (なし) | `id`, `name`, `url`, `version`, `fetched` |

## ID の決まり

- findings の `id` は英数字と `- _ .` だけ。サービスの頭文字 + 連番 (`G-01`, `L-01`) を推奨。重複は不可
- checks の `id` は `K-01` のように findings と別の名前空間にする。findings の ID と重なると不可
- `services[].key` は重複不可
- 参照フィールド (`flows[].steps[].items` の ID、`categories[].ids`、`findings[].related`、`checks[].related`、`cross_review.rows[].mine`、`cross_review.missing`) は ID の配列で書く。`checks[].related` と `cross_review.rows[].mine` は文字列でもよく、その場合は文字列中の `XX-00` 形式の ID を拾う
- `findings[].refs` は `sources[].id` を指す

## 全体

```jsonc
{
  "meta": {
    "title": "外部サービス利用規約レビュー",
    "subtitle": "対象アプリの一行説明",
    "target": "repo-name (branch @ abc1234)",
    "date": "2026-10-16",
    "authors": "作成者",
    "lead": "冒頭の説明 (前提、範囲、法的判断ではない旨、独立レビューの有無)"
  },

  // ---------- Phase 1 ----------
  "survey": {
    "overview": ["要約を 1 行ずつ"],
    "components": [{"name": "Cloud Run app", "role": "Web + API + Webhook", "where": "src/app/"}],
    "services": [{
      "name": "Stripe", "category": "決済・課金", "apis": "Checkout、Webhook",
      "calls": "src/billing/checkout.ts:42", "sends": "注文 ID、金額 (カード情報は送らない)", "receives": "決済結果",
      "stores": "payment_intent_id を無期限", "shows": "購入完了画面", "auth": "シークレットキー",
      "basis": "コードで確認"                       // コードで確認 | 設定資料が必要 | 未確認
    }],
    "storage": [{"where": "messages.text", "what": "チャット本文", "origin": "LINE", "retention": "無期限", "ref": "prisma/schema.prisma:120"}],
    "flows_summary": [{"name": "チャットで相談", "path": "LINE -> webhook -> DB -> LLM -> reply"}],
    "diagrams": [
      {"title": "構成図", "kind": "ascii", "body": "..."},
      {"title": "相談のシーケンス", "kind": "mermaid", "body": "sequenceDiagram\n  ..."}
    ],
    "unverified": ["GTM の管理画面で追加されたタグ (管理画面を見ていない)"]
  },

  // ---------- Phase 2-5 ----------
  "services": [{"key": "maps", "name": "Google Maps Platform", "sub": "使っている API", "prefix": "G"}],
  "findings": [{
    "id": "G-01", "service": "maps", "owner": "Google",
    "sev": "V",                                    // V | J | U | OK
    "title": "...", "clause": "...", "fact": "...", "action": "...",
    "basis": "規約",                               // 規約 | ポリシー | ガイドライン (推奨) | ライセンス | 個別契約 | 法令
    "refs": ["S-MAPS-TOS"],                        // sources[].id
    "related": ["L-02"]                            // 同じ事実から生じる別の義務
  }],
  "actors": {                                      // 任意。flows の境界の名前と色 (#rgb / #rrggbb)
    "platform": {"label": "LINE", "desc": "LINE 側", "color": "#06c755"}
  },
  "owners": ["LINE", "Google", "提供元"],          // 任意。一覧表の列の順 (無ければ findings の owner の出現順)
  "flows_intro": "経路の章の前書き",
  "flows": [{
    "key": "A", "title": "例 A: チャットで相談する", "sub": "説明",
    "steps": [{
      "actor": "platform",                         // platform | app | vendor | source、または actors のキー
      "title": "ステップ名",
      "data": ["実物の形の行", "注目する値は {{ここ}}", "値  <- 注記 (2 つ以上の空白 + <- で薄く表示)"],
      "items": [["このステップで関わること", ["L-04", "L-06"]]]
    }]
  }],
  "categories_intro": "対応方針の章の前書き",
  "categories": [{
    "code": "A", "title": "利用規約・プライバシーポリシーの変更で済む", "effort": "工数小",   // 工数小 | 工数中 | 工数大 | その他の文字列
    "policy": ["1 行 1 文", {"text": "親", "children": ["子 1", "子 2"]}],
    "ids": ["L-01", "G-01"]
  }],
  "checks": [{"id": "K-01", "question": "コードの外で確認すること", "related": ["L-10"]}],
  "cross_review": {
    "reviewer": "codex (web 検索あり)",            // 使えなかったら「独立レビューなし (自己再検証のみ)」
    "file": "cross-review.md",
    "rows": [{"theirs": "01", "mine": "G-01", "agree": "同", "note": ""}],   // agree: 同 | 強 | 弱 | 新 | 否
    "missing": ["G-07"]
  },
  "sources": [{"id": "S-MAPS-TOS", "name": "Google Maps Platform Terms of Service", "url": "https://...", "version": "Last modified 2026-08-26", "fetched": "2026-10-16"}],
  "evidence": [{"file": "terms/google.md", "label": "Google の規約 (原文引用)"}],
  "questions": [{"q": "依頼者の疑問 (原文)", "a": "直接の回答"}]
}
```

## 検査 (`--check`)

エラー (描画を止める。`--force` で強行):

- 必須キーの欠落、`sev` の値、ID の形式
- findings の `id`、checks の `id`、`services[].key` の重複。checks と findings の ID の衝突
- 参照フィールドの参照切れ (上の「ID の決まり」のすべて)、`refs` の参照切れ
- `flows[].steps[].actor` が actors に無い、`items` の形が `[文, [ID, ...]]` でない

警告 (描画は続ける):

- 違反の疑い・要判断・未確認の finding が、どのカテゴリにも入っていない、または 2 つ以上に入っている (categories がある場合)
- finding の `service` が `services` に無い (「その他」の章に出す)
- 未知のトップレベルのキー、http(s) でも相対パスでもない URL (リンクにしない)、色の形式

HTML の出力では、すべての値をエスケープし、リンクは http(s) と相対パスだけにする。Markdown の出力では `<` `>` をエスケープし、コードブロックの区切りは中身より長くする。
