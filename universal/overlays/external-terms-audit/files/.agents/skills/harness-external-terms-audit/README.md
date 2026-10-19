# harness-external-terms-audit

アプリのコードを読んで、システム構成・データの流れ・外部サービス連携を把握し、アプリが関わるすべての外部サービスの利用規約・API ポリシーに違反し得る箇所を洗い出して、Markdown か HTML のレポートにまとめるためのスキルとプロンプトです。

## 中身

| パス | 用途 |
|---|---|
| `SKILL.md` | スキル本体 (Claude Code が読む入口) |
| `references/` | Phase ごとの手順、外部サービスの論点、`report.json` の形 |
| `scripts/render.py` | `report.json` を Markdown / HTML に描く (Python 3.9+、標準ライブラリのみ) |
| `prompts/standalone-prompt.md` | スキルを使わずに任意のエージェントに貼るプロンプト |
| `prompts/cross-review-prompt.md` | 独立レビュー (codex など) に渡すプロンプト |
| `examples/report.example.json` | 描画デモ (架空アプリ。監査の完成例ではない) |

## 使い方

### Claude Code のスキルとして使う

```bash
# 個人用 (全プロジェクトで使える)
cp -R harness-external-terms-audit ~/.claude/skills/
# プロジェクト用 (そのリポジトリだけ)
cp -R harness-external-terms-audit <repo>/.claude/skills/
```

Claude Code で「このアプリの外部サービスの利用規約違反を洗い出して、HTML でレポートにして」のように頼むと、スキルが読み込まれます。システム把握だけなら「システム構成と外部サービス連携を把握して md にまとめて」で Phase 1 だけ実行します。

### スキルを使わずに使う

`prompts/standalone-prompt.md` の `{{ }}` を埋めて、Claude、codex、Cursor などのエージェントに貼ってください。Markdown 1 ファイルで出力させるか、`report.json` を書かせて `scripts/render.py` で描きます。

### 描画だけ試す

```bash
python3 scripts/render.py examples/report.example.json --check
python3 scripts/render.py examples/report.example.json --format both --out /tmp/audit-example
```

## 注意

- 法的判断はしません。規約の文面と実装を突き合わせ、判断が要る箇所を整理するところまでです。結論は法務や相手先に確認してください。
- 規約は改定されます。`references/pitfalls.md` の個別サービスの論点は 2026-10 時点の控えで、判定は毎回最新の原文で行う前提です。
- 範囲は外部サービスの契約・規約・ポリシー・ガイドラインと提供データのライセンスです。法令や OSS ライセンスの包括監査は既定で対象外です。
- 既定ではアプリを起動せず、コードを静的に読みます。
- HTML は 1 ファイルで完結します。Mermaid の図を含むときだけ、表示時に jsDelivr から mermaid を読み込みます。
