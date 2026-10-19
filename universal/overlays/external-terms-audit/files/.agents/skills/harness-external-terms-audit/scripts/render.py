#!/usr/bin/env python3
"""report.json を Markdown / HTML に描く (標準ライブラリのみ、Python 3.9+)。

usage:
  python3 render.py report.json --check
  python3 render.py report.json --format md|html|both [--out DIR] [--name BASENAME] [--force]

構造や参照のエラーがあると描画しない (--force で強行)。警告は描画を止めない。
"""
import argparse
import html
import json
import os
import re
import sys

SEV = {"V": "違反の疑い", "J": "要判断", "U": "未確認", "OK": "適合"}
SHORT = {"V": "違反", "J": "要判断", "U": "未確認", "OK": "適合"}
ORDER = ["V", "J", "U", "OK"]
DEFAULT_ACTORS = {
    "platform": {"label": "Platform", "desc": "外部プラットフォーム側 (チャット基盤、アプリ内ブラウザの画面など)", "color": "#06a050"},
    "app": {"label": "自社", "desc": "自社の実行環境と DB", "color": "#2f5bd8"},
    "vendor": {"label": "Vendor", "desc": "外部の API・SaaS・生成 AI", "color": "#c5221f"},
    "source": {"label": "提供元", "desc": "データ提供元・その他", "color": "#5f6368"},
}
EFFORT_CLASS = {"工数小": "s", "工数中": "m", "工数大": "l"}
AGREE_TEXT = {"同": "同じ判定", "強": "相手の方が重い", "弱": "相手の方が軽い", "新": "自分に無かった指摘", "否": "採用しない"}
TOP_KEYS = {"meta", "survey", "services", "findings", "actors", "owners", "flows", "flows_intro", "categories",
            "categories_intro", "checks", "cross_review", "sources", "evidence", "questions"}
LIST_KEYS = ["services", "findings", "owners", "flows", "categories", "checks", "sources", "evidence", "questions"]
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")
REF_RE = re.compile(r"\b[A-Z][A-Z0-9]{0,4}-\d{1,4}\b")
COLOR_RE = re.compile(r"^#[0-9a-fA-F]{3,8}$")


# ------------------------------------------------------------------ helpers
def as_list(v):
    return v if isinstance(v, list) else []


def ref_ids(v):
    """参照フィールド (配列か文字列) から ID を取り出す。"""
    if isinstance(v, list):
        return [str(x) for x in v]
    if isinstance(v, str):
        return REF_RE.findall(v)
    return []


def esc(s):
    return html.escape("" if s is None else str(s), quote=True)


def safe_url(u):
    u = (u or "").strip()
    if re.match(r"^https?://", u, re.I):
        return u
    if u and not re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", u) and not u.startswith("//"):
        return u  # 相対パス
    return None


def safe_color(c, default="#5f6368"):
    return c if isinstance(c, str) and COLOR_RE.match(c) else default


def anchor(i):
    return "f-" + re.sub(r"[^A-Za-z0-9_-]", "_", str(i))


def md_text(s):
    """Markdown の地の文。生 HTML として解釈されないよう < > をエスケープする。"""
    return ("" if s is None else str(s)).replace("<", "&lt;").replace(">", "&gt;")


def md_cell(s):
    return md_text(s).replace("|", "\\|").replace("\n", " ")


def md_fence(lines, lang="text", indent=""):
    body = "\n".join(lines)
    n = max([3] + [len(m) + 1 for m in re.findall(r"`{3,}", body)])
    f = "`" * n
    return [indent + f + lang] + [indent + ln for ln in lines] + [indent + f]


# ------------------------------------------------------------------ model
class Report:
    def __init__(self, data):
        if not isinstance(data, dict):
            raise ValueError("report.json の最上位はオブジェクトにしてください")
        for k in LIST_KEYS:
            if k in data and not isinstance(data[k], list):
                data[k] = []
        self.d = data
        self.meta = data.get("meta") if isinstance(data.get("meta"), dict) else {}
        self.findings = [f for f in as_list(data.get("findings")) if isinstance(f, dict)]
        self.by_id = {}
        for f in self.findings:
            self.by_id.setdefault(f.get("id"), f)
        self.checks = [c for c in as_list(data.get("checks")) if isinstance(c, dict)]
        self.check_ids = {c.get("id") for c in self.checks}
        self.services = [s for s in as_list(data.get("services")) if isinstance(s, dict)]
        self.sources = [s for s in as_list(data.get("sources")) if isinstance(s, dict)]
        self.source_ids = {s.get("id"): s for s in self.sources if s.get("id")}
        actors = {k: dict(v) for k, v in DEFAULT_ACTORS.items()}
        for k, v in (data.get("actors") or {}).items():
            if isinstance(v, dict):
                actors[k] = {**actors.get(k, {"label": k, "desc": "", "color": "#5f6368"}), **v}
        self.actors = actors

    def sev(self, i):
        f = self.by_id.get(i)
        return f.get("sev") if f and f.get("sev") in SEV else "U"

    def title(self, i):
        f = self.by_id.get(i)
        return (f or {}).get("title", "")

    def counts(self):
        return {k: sum(1 for f in self.findings if f.get("sev") == k) for k in ORDER}

    def owner_of(self, f):
        return f.get("owner") or f.get("service") or "その他"

    def owners(self):
        if self.d.get("owners"):
            return [str(o) for o in self.d["owners"]]
        seen = []
        for f in self.findings:
            o = self.owner_of(f)
            if o not in seen:
                seen.append(o)
        return seen

    def groups(self):
        """findings を章に分ける。services に無いものは「その他」に必ず出す。"""
        keys = []
        out = []
        for s in self.services:
            k = s.get("key")
            if k in keys:
                continue
            keys.append(k)
            items = [f for f in self.findings if f.get("service") == k]
            if items:
                out.append((s.get("name") or str(k), s.get("sub", ""), items))
        rest = [f for f in self.findings if f.get("service") not in keys]
        if rest:
            out.append(("その他 (services に未登録)" if self.services else "項目", "", rest))
        return out

    def matrix(self):
        owners = self.owners()
        rows = []
        for fl in as_list(self.d.get("flows")):
            ids = []
            for st in as_list(fl.get("steps")):
                for it in as_list(st.get("items")):
                    for i in as_list(it[1] if isinstance(it, list) and len(it) > 1 else []):
                        if i not in ids:
                            ids.append(i)
            cols = {o: [] for o in owners}
            for i in ids:
                f = self.by_id.get(i)
                o = self.owner_of(f) if f else "その他"
                cols.setdefault(o, []).append(i)
            rows.append((fl, cols))
        order = owners + [o for _, c in rows for o in c if o not in owners]
        order = list(dict.fromkeys(order))
        return [o for o in order if any(c.get(o) for _, c in rows)] or owners, rows

    # -------------------------------------------------------------- checks
    def validate(self):
        errors, warns = [], []
        d = self.d
        for k in d:
            if k not in TOP_KEYS:
                warns.append(f"未知のキー: {k} (無視される)")

        def need(obj, keys, where):
            for k in keys:
                if not obj.get(k):
                    errors.append(f"{where}: 必須キー '{k}' が無い")

        seen = {}
        for n, f in enumerate(self.findings):
            where = f"findings[{n}]"
            need(f, ["id", "sev", "title"], where)
            i = f.get("id")
            if i and not ID_RE.match(str(i)):
                errors.append(f"{where}: id '{i}' に使えない文字がある (英数字と - _ . のみ)")
            if i in seen:
                errors.append(f"{where}: id '{i}' が findings[{seen[i]}] と重複")
            seen.setdefault(i, n)
            if f.get("sev") and f.get("sev") not in SEV:
                errors.append(f"{where}: sev は V / J / U / OK のどれか ('{f.get('sev')}')")
        cseen = set()
        for n, c in enumerate(self.checks):
            need(c, ["id", "question"], f"checks[{n}]")
            if c.get("id") in cseen:
                errors.append(f"checks[{n}]: id '{c.get('id')}' が重複")
            if c.get("id") in self.by_id:
                errors.append(f"checks[{n}]: id '{c.get('id')}' が findings の id と衝突")
            cseen.add(c.get("id"))
        skeys = []
        for n, s in enumerate(self.services):
            need(s, ["key", "name"], f"services[{n}]")
            if s.get("key") in skeys:
                errors.append(f"services[{n}]: key '{s.get('key')}' が重複")
            skeys.append(s.get("key"))
        if self.services:
            for f in self.findings:
                if f.get("service") not in skeys:
                    warns.append(f"{f.get('id')}: service '{f.get('service')}' が services に無い (「その他」の章に出す)")

        def ref(i, where):
            if i not in self.by_id and i not in self.check_ids:
                errors.append(f"{where}: 参照先 '{i}' が findings にも checks にも無い")

        for f in self.findings:
            for i in as_list(f.get("related")):
                ref(i, f"{f.get('id')}.related")
            for s in as_list(f.get("refs")):
                if s not in self.source_ids:
                    errors.append(f"{f.get('id')}.refs: sources に id '{s}' が無い")
        for n, fl in enumerate(as_list(d.get("flows"))):
            need(fl, ["key", "title"], f"flows[{n}]")
            for m, st in enumerate(as_list(fl.get("steps"))):
                where = f"flows[{n}].steps[{m}]"
                need(st, ["actor", "title"], where)
                if st.get("actor") and st.get("actor") not in self.actors:
                    errors.append(f"{where}: actor '{st.get('actor')}' が actors に無い")
                for it in as_list(st.get("items")):
                    if not (isinstance(it, list) and len(it) == 2 and isinstance(it[1], list)):
                        errors.append(f"{where}: items の要素は [文, [ID, ...]] にする")
                        continue
                    for i in it[1]:
                        ref(i, where)
        cats = [c for c in as_list(d.get("categories")) if isinstance(c, dict)]
        placed = []
        for n, c in enumerate(cats):
            need(c, ["code", "title"], f"categories[{n}]")
            for i in as_list(c.get("ids")):
                ref(i, f"categories[{n}]")
                placed.append(i)
        if cats:
            for i, f in self.by_id.items():
                if f.get("sev") in ("V", "J", "U"):
                    k = placed.count(i)
                    if k == 0:
                        warns.append(f"{i} ({SEV[f['sev']]}) がどのカテゴリにも入っていない")
                    elif k > 1:
                        warns.append(f"{i} が {k} つのカテゴリに入っている")
        for n, c in enumerate(self.checks):
            for i in ref_ids(c.get("related")):
                if i not in self.by_id:
                    errors.append(f"checks[{n}].related: '{i}' が findings に無い")
        cr = d.get("cross_review") if isinstance(d.get("cross_review"), dict) else {}
        for n, row in enumerate(as_list(cr.get("rows"))):
            if row.get("agree") and row.get("agree") not in AGREE_TEXT:
                warns.append(f"cross_review.rows[{n}]: agree は 同 / 強 / 弱 / 新 / 否 のどれか")
            for i in ref_ids(row.get("mine")):
                ref(i, f"cross_review.rows[{n}]")
        for i in as_list(cr.get("missing")):
            ref(i, "cross_review.missing")
        for n, s in enumerate(self.sources):
            if s.get("url") and not safe_url(s.get("url")):
                warns.append(f"sources[{n}]: url が http(s) でも相対パスでもないのでリンクにしない")
        for k, a in self.actors.items():
            if a.get("color") and not COLOR_RE.match(str(a.get("color"))):
                warns.append(f"actors.{k}.color は #rgb か #rrggbb にする (既定色を使う)")
        return errors, warns


# ------------------------------------------------------------------ markdown
def md_ref(r, i):
    return f"[{SHORT[r.sev(i)]}] {md_text(i)}"


def md_policy(lines):
    out = []
    for line in as_list(lines):
        if isinstance(line, dict):
            out.append(f"- {md_text(line.get('text', ''))}")
            out.extend(f"  - {md_text(c)}" for c in as_list(line.get("children")))
        else:
            out.append(f"- {md_text(line)}")
    return out


def render_md(r):
    m = r.meta
    o = [f"# {md_text(m.get('title', 'レビュー'))}", ""]
    if m.get("subtitle"):
        o += [md_text(m["subtitle"]), ""]
    info = " / ".join(md_text(x) for x in [m.get("target"), m.get("date"), m.get("authors")] if x)
    if info:
        o += [info, ""]
    if m.get("lead"):
        o += [md_text(m["lead"]), ""]
    if r.findings:
        c = r.counts()
        o += ["| 判定 | 件数 |", "|---|---|"] + [f"| {SEV[k]} | {c[k]} |" for k in ORDER] + [""]

    sv = r.d.get("survey") if isinstance(r.d.get("survey"), dict) else None
    if sv:
        o += ["## システム概要", ""]
        o += [f"- {md_text(x)}" for x in as_list(sv.get("overview"))] + [""]

        def tbl(title, head, keys, rows):
            if not rows:
                return []
            t = [f"### {title}", "", "| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
            t += ["| " + " | ".join(md_cell(x.get(k, "")) for k in keys) + " |" for x in rows if isinstance(x, dict)]
            return t + [""]
        o += tbl("構成要素", ["名前", "役割", "場所"], ["name", "role", "where"], as_list(sv.get("components")))
        o += tbl("外部サービス台帳", ["サービス", "分類", "API", "呼び出し", "送るもの", "受け取るもの", "保存", "表示先", "認証", "確認方法"],
                 ["name", "category", "apis", "calls", "sends", "receives", "stores", "shows", "auth", "basis"], as_list(sv.get("services")))
        o += tbl("データの保存先", ["場所", "中身", "由来", "保持", "根拠"], ["where", "what", "origin", "retention", "ref"], as_list(sv.get("storage")))
        if sv.get("flows_summary"):
            o += ["### 主な経路", ""] + [f"- **{md_text(x.get('name',''))}**: {md_text(x.get('path',''))}" for x in as_list(sv["flows_summary"])] + [""]
        for dg in as_list(sv.get("diagrams")):
            o += [f"### {md_text(dg.get('title', '図'))}", ""]
            o += md_fence(str(dg.get("body", "")).rstrip().split("\n"), "mermaid" if dg.get("kind") == "mermaid" else "text") + [""]
        if sv.get("unverified"):
            o += ["### 未確認の範囲", ""] + [f"- {md_text(x)}" for x in as_list(sv["unverified"])] + [""]

    if r.d.get("flows"):
        o += ["## 経路ごとの流れと該当項目 (具体例)", ""]
        if r.d.get("flows_intro"):
            o += [md_text(r.d["flows_intro"]), ""]
        cols, rows = r.matrix()
        o += ["| 経路 | " + " | ".join(f"{md_cell(c)} の規約" for c in cols) + " |", "|---" * (len(cols) + 1) + "|"]
        for fl, cmap in rows:
            cells = [", ".join(md_ref(r, i) for i in sorted(cmap.get(c, []), key=lambda x: ORDER.index(r.sev(x)))) or "-" for c in cols]
            o.append(f"| {md_cell(fl.get('title',''))} | " + " | ".join(cells) + " |")
        o.append("")
        for fl in as_list(r.d["flows"]):
            o += [f"### {md_text(fl.get('title',''))}", ""]
            if fl.get("sub"):
                o += [md_text(fl["sub"]), ""]
            for st in as_list(fl.get("steps")):
                label = r.actors.get(st.get("actor"), {}).get("label", st.get("actor"))
                o.append(f"- **[{md_text(label)}] {md_text(st.get('title',''))}**")
                if st.get("data"):
                    o.append("")
                    o += md_fence([str(d).replace("{{", "").replace("}}", "") for d in as_list(st["data"])], "text", "  ")
                    o.append("")
                for it in as_list(st.get("items")):
                    if isinstance(it, list) and len(it) == 2:
                        o.append(f"  - {md_text(it[0])}" + ((" " + " ".join(md_ref(r, i) for i in as_list(it[1]))) if it[1] else ""))
            o.append("")

    cats = [c for c in as_list(r.d.get("categories")) if isinstance(c, dict)]
    if cats:
        o += ["## 対応方針", ""]
        if r.d.get("categories_intro"):
            o += [md_text(r.d["categories_intro"]), ""]
        for c in cats:
            eff = f" [{md_text(c['effort'])}]" if c.get("effort") else ""
            o += [f"### {md_text(c.get('code',''))}. {md_text(c.get('title',''))}{eff}", ""]
            o += md_policy(c.get("policy")) + ["", "対象:", ""]
            o += [f"- {md_text(i)} [{SEV[r.sev(i)]}] {md_text(r.title(i))}" for i in as_list(c.get("ids"))] + [""]

    for name, sub, items in r.groups():
        o += [f"## {md_text(name)}", ""]
        if sub:
            o += [md_text(sub), ""]
        for f in sorted(items, key=lambda x: ORDER.index(x.get("sev")) if x.get("sev") in ORDER else 9):
            o += [f"### {md_text(f.get('id'))} [{SEV.get(f.get('sev'), '?')}] {md_text(f.get('title',''))}", ""]
            for label, key in [("根拠の種類", "basis"), ("規約", "clause"), ("実装", "fact"), ("対応", "action")]:
                if f.get(key):
                    o.append(f"- {label}: {md_text(f[key])}")
            if f.get("refs"):
                o.append("- 出典: " + ", ".join(md_text(r.source_ids.get(s, {}).get("name", s)) for s in as_list(f["refs"])))
            if f.get("related"):
                o.append("- 関連: " + ", ".join(md_ref(r, i) for i in as_list(f["related"])))
            o.append("")

    if r.checks:
        o += ["## コードの外で確認が要ること", "", "| ID | 確認したいこと | 関連 |", "|---|---|---|"]
        o += [f"| {md_cell(c.get('id'))} | {md_cell(c.get('question',''))} | {md_cell(', '.join(ref_ids(c.get('related'))) if isinstance(c.get('related'), list) else c.get('related',''))} |" for c in r.checks] + [""]

    cr = r.d.get("cross_review") if isinstance(r.d.get("cross_review"), dict) else None
    if cr:
        o += ["## 独立レビューとの照合", ""]
        if cr.get("reviewer"):
            o += [f"レビュー: {md_text(cr['reviewer'])}" + (f" ({md_text(cr['file'])})" if cr.get("file") else ""), ""]
        o += ["| 相手 | 自分 | 一致 | メモ |", "|---|---|---|---|"]
        o += [f"| {md_cell(x.get('theirs',''))} | {md_cell(x.get('mine',''))} | {md_cell(x.get('agree',''))} | {md_cell(x.get('note',''))} |" for x in as_list(cr.get("rows"))]
        if cr.get("missing"):
            o += ["", "自分にあって相手に無い項目: " + ", ".join(md_text(i) for i in as_list(cr["missing"]))]
        o.append("")

    if r.sources:
        o += ["## 参照した規約", "", "| 文書 | URL | 版・施行日 | 取得日 |", "|---|---|---|---|"]
        o += [f"| {md_cell(s.get('name',''))} | {md_cell(s.get('url',''))} | {md_cell(s.get('version',''))} | {md_cell(s.get('fetched',''))} |" for s in r.sources] + [""]
    if r.d.get("evidence"):
        o += ["### 根拠資料", ""] + [f"- {md_text(e.get('file',''))} ({md_text(e.get('label',''))})" for e in as_list(r.d["evidence"]) if isinstance(e, dict)] + [""]
    if r.d.get("questions"):
        o += ["## 付録: 依頼者の疑問への回答", ""]
        for q in as_list(r.d["questions"]):
            if isinstance(q, dict):
                o += [f"### {md_text(q.get('q',''))}", "", md_text(q.get("a", "")), ""]
    return "\n".join(o).rstrip() + "\n"


# ------------------------------------------------------------------ html
CSS = """
:root{--fg:#1a1a1c;--muted:#5f6368;--line:#d9dbe0;--bg:#fff;--soft:#f5f6f8;--key:#2f5bd8;--hero:#eef3ff;
--v:#b3000c;--vbg:#fdecec;--j:#a14a00;--jbg:#fff6e0;--jbd:#e08a00;--u:#3c4043;--ubg:#f1f3f4;--ubd:#9aa0a6;--ok:#11663a;--okbg:#e8f5ec;--okbd:#2e9e5b;--mark:#fde68a;--markfg:#7c2d12}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--fg:#e8eaed;--muted:#a0a4ab;--line:#3c4043;--bg:#17181b;--soft:#202125;--hero:#1c2333;
--vbg:#3b1416;--v:#ff8a8a;--jbg:#3a2a10;--j:#ffc46b;--ubg:#2a2b2f;--u:#c4c7cc;--okbg:#14301f;--ok:#7ad69c;--mark:#5c4a12;--markfg:#ffe7a3}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font-family:"Noto Sans JP","Hiragino Sans","Yu Gothic UI",system-ui,sans-serif;line-height:1.7;font-size:16px}
a{color:var(--key)}code,pre{font-family:ui-monospace,"SFMono-Regular",Menlo,Consolas,monospace}
.wrap{max-width:1080px;margin:0 auto;padding:0 16px}
.hero{background:var(--hero);padding:32px 0 24px;margin-bottom:24px}.hero h1{margin:0 0 4px;font-size:30px;line-height:1.3}.hero .sub{margin:0 0 12px;color:var(--muted)}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:10px;margin-top:16px}.stat{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:10px 14px}
.stat b{display:block;font-size:26px;line-height:1.2}.stat span{font-size:13px;color:var(--muted)}
.stat--V b{color:var(--v)}.stat--J b{color:var(--j)}.stat--OK b{color:var(--ok)}
nav.toc{border:1px solid var(--line);border-radius:8px;padding:12px 18px;margin-bottom:24px}nav.toc ol{margin:6px 0 0;padding-left:1.4em}
h2{font-size:24px;margin:40px 0 12px;padding-bottom:6px;border-bottom:2px solid var(--line)}h3{font-size:18px;margin:20px 0 8px}
table{border-collapse:collapse;width:100%;margin:8px 0 16px;font-size:14px}th,td{border:1px solid var(--line);padding:7px 10px;vertical-align:top;text-align:left}thead th{background:var(--soft)}
.tablewrap{overflow-x:auto}
.chip{display:inline-flex;align-items:center;height:20px;padding:0 8px;margin:2px 4px 2px 0;border-radius:6px;border:1px solid;font-size:11px;font-weight:700;text-decoration:none;white-space:nowrap;vertical-align:middle}
.chip--V{color:var(--v);background:var(--vbg);border-color:var(--v)}.chip--J{color:var(--j);background:var(--jbg);border-color:var(--jbd)}
.chip--U{color:var(--u);background:var(--ubg);border-color:var(--ubd)}.chip--OK{color:var(--ok);background:var(--okbg);border-color:var(--okbd)}
.actor{display:inline-flex;align-items:center;justify-content:center;min-width:64px;height:24px;padding:0 8px;border-radius:6px;font-size:12px;font-weight:700;color:#fff;white-space:nowrap}
.legend{display:flex;flex-wrap:wrap;gap:6px 14px;align-items:center;margin:8px 0 14px;font-size:13px}
.flow{border:1px solid var(--line);border-radius:8px;padding:14px 16px 6px;margin:16px 0}.flow h3{margin:0 0 4px}.flow .sub{margin:0 0 10px;font-size:14px;color:var(--muted)}
ol.steps{list-style:none;margin:0;padding:0}.step{display:grid;grid-template-columns:80px minmax(0,1fr);gap:0 12px;padding:0 0 14px}
.rail{position:relative;display:flex;justify-content:center;align-items:flex-start;padding-top:2px}.rail:before{content:"";position:absolute;top:28px;bottom:-14px;left:50%;width:2px;background:var(--line)}
.step:last-child .rail:before{display:none}.step .title{font-weight:700;font-size:15px;margin:2px 0 6px}
pre.data{margin:0 0 6px;padding:10px 12px;background:var(--soft);border:1px solid var(--line);border-radius:6px;font-size:12.5px;line-height:1.55;white-space:pre-wrap;overflow-x:auto}
pre.data mark{background:var(--mark);color:var(--markfg);padding:0 2px;border-radius:3px}pre.data .note{color:var(--muted)}
ul.items{margin:0;padding-left:1.1em;font-size:14px}ul.items li{margin:3px 0}ul.items li>span{margin-right:6px}
.cat{border:1px solid var(--line);border-left-width:6px;border-radius:8px;padding:14px 16px;margin:12px 0}
.cat--s{border-left-color:var(--okbd)}.cat--m{border-left-color:var(--jbd)}.cat--l{border-left-color:var(--v)}.cat--w{border-left-color:var(--ubd)}
.cat h3{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin:0 0 8px;line-height:1.4}
.code{display:inline-flex;align-items:center;justify-content:center;min-width:1.6em;height:1.6em;background:var(--key);color:#fff;border-radius:6px;padding:0 6px;line-height:1}
.effort{display:inline-flex;align-items:center;height:22px;padding:0 10px;border-radius:999px;font-size:12px;font-weight:700;border:1px solid;white-space:nowrap}
.effort--s{color:var(--ok);background:var(--okbg);border-color:var(--okbd)}.effort--m{color:var(--j);background:var(--jbg);border-color:var(--jbd)}
.effort--l{color:var(--v);background:var(--vbg);border-color:var(--v)}.effort--w{color:var(--u);background:var(--ubg);border-color:var(--ubd)}
ul.policy{font-size:14px;margin:0 0 10px;padding-left:1.2em}ul.policy li{margin:3px 0}ul.policy ul{margin:2px 0 4px;padding-left:1.3em;list-style:none}
ul.policy ul li{position:relative}ul.policy ul li:before{content:"-";position:absolute;left:-1em;color:var(--muted)}
.cat .ids{font-size:13px;font-weight:700;color:var(--muted);margin:0 0 4px}.cat ul.idl{margin:0;padding-left:1.2em;font-size:14px}
.f{border:1px solid var(--line);border-left-width:6px;border-radius:8px;padding:12px 16px;margin:12px 0}
.f--V{border-left-color:var(--v)}.f--J{border-left-color:var(--jbd)}.f--U{border-left-color:var(--ubd)}.f--OK{border-left-color:var(--okbd)}
.f .head{display:flex;flex-wrap:wrap;align-items:center;gap:6px 10px;margin-bottom:6px}.f .id{font-family:ui-monospace,Menlo,monospace;font-weight:700;color:var(--muted)}.f .t{font-weight:700}
.f dl{margin:0;display:grid;grid-template-columns:4.5em 1fr;gap:4px 12px;font-size:14px}.f dt{font-weight:700;color:var(--muted)}.f dd{margin:0}
.answer{border:1px solid var(--line);background:var(--hero);border-radius:8px;padding:12px 16px;margin:12px 0}.answer h3{margin:0 0 6px;font-size:16px}.answer p{margin:0}
pre.mermaid{background:var(--soft);border:1px solid var(--line);border-radius:6px;padding:12px;overflow-x:auto}
pre.diagram{background:var(--soft);border:1px solid var(--line);border-radius:6px;padding:12px;overflow-x:auto;font-size:12.5px;line-height:1.45}
footer{margin:48px 0 32px;color:var(--muted);font-size:13px}
@media (max-width:640px){.step{grid-template-columns:1fr}.rail{justify-content:flex-start}.rail:before{display:none}.f dl{grid-template-columns:1fr}.hero h1{font-size:24px}}
dt{white-space:nowrap}
"""


def chip(r, i):
    s = r.sev(i)
    if i in r.by_id:
        href = "#" + anchor(i)
    elif i in r.check_ids:
        href = "#checks"
    else:
        return f'<span class="chip chip--U">[?] {esc(i)}</span>'
    return f'<a class="chip chip--{s}" href="{href}">[{SHORT[s]}] {esc(i)}</a>'


def data_line(s):
    out = re.sub(r"\{\{(.+?)\}\}", r"<mark>\1</mark>", esc(s))
    return re.sub(r"(\s{2,}&lt;- .*)$", r'<span class="note">\1</span>', out)


def actor_badge(r, key):
    a = r.actors.get(key, {"label": key})
    return f'<span class="actor" style="background:{safe_color(a.get("color"))}">{esc(a.get("label", key))}</span>'


def link(url, text):
    u = safe_url(url)
    return f'<a href="{esc(u)}" rel="noopener noreferrer">{esc(text)}</a>' if u else esc(text)


def policy_html(lines):
    out = []
    for line in as_list(lines):
        if isinstance(line, dict):
            kids = "".join(f"<li>{esc(c)}</li>" for c in as_list(line.get("children")))
            out.append(f"<li>{esc(line.get('text', ''))}<ul>{kids}</ul></li>")
        else:
            out.append(f"<li>{esc(line)}</li>")
    return "".join(out)


def table(head, rows):
    h = "".join(f'<th scope="col">{esc(x)}</th>' for x in head)
    b = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in row) + "</tr>" for row in rows)
    return f'<div class="tablewrap"><table><thead><tr>{h}</tr></thead><tbody>{b}</tbody></table></div>'


def render_html(r):
    m = r.meta
    secs = []  # (section id, title, html)
    sv = r.d.get("survey") if isinstance(r.d.get("survey"), dict) else None
    has_mermaid = False
    if sv:
        p = ["<ul>" + "".join(f"<li>{esc(x)}</li>" for x in as_list(sv.get("overview"))) + "</ul>"]

        def tbl(title, head, keys, rows):
            rows = [x for x in rows if isinstance(x, dict)]
            return f"<h3>{esc(title)}</h3>" + table(head, [[esc(x.get(k, "")) for k in keys] for x in rows]) if rows else ""
        p.append(tbl("構成要素", ["名前", "役割", "場所"], ["name", "role", "where"], as_list(sv.get("components"))))
        p.append(tbl("外部サービス台帳", ["サービス", "分類", "API", "呼び出し", "送るもの", "受け取るもの", "保存", "表示先", "認証", "確認方法"],
                     ["name", "category", "apis", "calls", "sends", "receives", "stores", "shows", "auth", "basis"], as_list(sv.get("services"))))
        p.append(tbl("データの保存先", ["場所", "中身", "由来", "保持", "根拠"], ["where", "what", "origin", "retention", "ref"], as_list(sv.get("storage"))))
        if sv.get("flows_summary"):
            p.append("<h3>主な経路</h3><ul>" + "".join(f"<li><b>{esc(x.get('name',''))}</b>: {esc(x.get('path',''))}</li>" for x in as_list(sv["flows_summary"]) if isinstance(x, dict)) + "</ul>")
        for dg in as_list(sv.get("diagrams")):
            if not isinstance(dg, dict):
                continue
            cls = "mermaid" if dg.get("kind") == "mermaid" else "diagram"
            has_mermaid = has_mermaid or cls == "mermaid"
            p.append(f'<h3>{esc(dg.get("title","図"))}</h3><pre class="{cls}">{esc(dg.get("body",""))}</pre>')
        if sv.get("unverified"):
            p.append("<h3>未確認の範囲</h3><ul>" + "".join(f"<li>{esc(x)}</li>" for x in as_list(sv["unverified"])) + "</ul>")
        secs.append(("survey", "システム概要", "".join(p)))

    flows = [fl for fl in as_list(r.d.get("flows")) if isinstance(fl, dict)]
    if flows:
        p = []
        if r.d.get("flows_intro"):
            p.append(f"<p>{esc(r.d['flows_intro'])}</p>")
        used = list(dict.fromkeys(st.get("actor") for fl in flows for st in as_list(fl.get("steps")) if isinstance(st, dict)))
        p.append('<div class="legend">' + "".join(f'{actor_badge(r, k)}<span>{esc(r.actors.get(k, {}).get("desc", ""))}</span>' for k in used) + "</div>")
        cols, rows = r.matrix()
        trs = []
        for n, (fl, cmap) in enumerate(rows):
            cells = ["".join(chip(r, i) for i in sorted(cmap.get(c, []), key=lambda x: ORDER.index(r.sev(x)))) or "-" for c in cols]
            trs.append([f'<a href="#flow-{n}"><b>{esc(fl.get("title",""))}</b></a>'] + cells)
        p.append(table(["経路"] + [f"{c} の規約" for c in cols], trs))
        for n, fl in enumerate(flows):
            p.append(f'<div class="flow" id="flow-{n}"><h3>{esc(fl.get("title",""))}</h3>')
            if fl.get("sub"):
                p.append(f'<p class="sub">{esc(fl["sub"])}</p>')
            p.append('<ol class="steps">')
            for st in as_list(fl.get("steps")):
                if not isinstance(st, dict):
                    continue
                color = safe_color(r.actors.get(st.get("actor"), {}).get("color"))
                p.append(f'<li class="step"><div class="rail">{actor_badge(r, st.get("actor"))}</div><div><div class="title" style="color:{color}">{esc(st.get("title",""))}</div>')
                if st.get("data"):
                    p.append('<pre class="data">' + "\n".join(data_line(d) for d in as_list(st["data"])) + "</pre>")
                items = [it for it in as_list(st.get("items")) if isinstance(it, list) and len(it) == 2]
                if items:
                    p.append('<ul class="items">' + "".join(f"<li><span>{esc(t)}</span>{''.join(chip(r, i) for i in as_list(ids))}</li>" for t, ids in items) + "</ul>")
                p.append("</div></li>")
            p.append("</ol></div>")
        secs.append(("flows", "経路ごとの流れと該当項目 (具体例)", "".join(p)))

    cats = [c for c in as_list(r.d.get("categories")) if isinstance(c, dict)]
    if cats:
        p = []
        if r.d.get("categories_intro"):
            p.append(f"<p>{esc(r.d['categories_intro'])}</p>")
        for c in cats:
            ecls = EFFORT_CLASS.get(c.get("effort", ""), "w")
            eff = f'<span class="effort effort--{ecls}">{esc(c["effort"])}</span>' if c.get("effort") else ""
            p.append(f'<div class="cat cat--{ecls}"><h3><span class="code">{esc(c.get("code",""))}</span><span>{esc(c.get("title",""))}</span>{eff}</h3>')
            p.append(f'<ul class="policy">{policy_html(c.get("policy"))}</ul><p class="ids">対象</p><ul class="idl">')
            p += [f"<li>{chip(r, i)} {esc(r.title(i))}</li>" for i in as_list(c.get("ids"))]
            p.append("</ul></div>")
        secs.append(("categories", "対応方針", "".join(p)))

    for n, (name, sub, items) in enumerate(r.groups()):
        p = [f"<p>{esc(sub)}</p>"] if sub else []
        for f in sorted(items, key=lambda x: ORDER.index(x.get("sev")) if x.get("sev") in ORDER else 9):
            s = f.get("sev") if f.get("sev") in SEV else "U"
            rows = [(lab, esc(f[k])) for lab, k in [("根拠", "basis"), ("規約", "clause"), ("実装", "fact"), ("対応", "action")] if f.get(k)]
            if f.get("refs"):
                rows.append(("出典", ", ".join(link(r.source_ids.get(x, {}).get("url"), r.source_ids.get(x, {}).get("name", x)) for x in as_list(f["refs"]))))
            if f.get("related"):
                rows.append(("関連", "".join(chip(r, i) for i in as_list(f["related"]))))
            dl = "".join(f"<dt>{lab}</dt><dd>{v}</dd>" for lab, v in rows)
            p.append(f'<article class="f f--{s}" id="{anchor(f.get("id"))}"><div class="head"><span class="id">{esc(f.get("id"))}</span>'
                     f'<span class="chip chip--{s}">{SEV[s]}</span><span class="t">{esc(f.get("title",""))}</span></div><dl>{dl}</dl></article>')
        secs.append((f"svc-{n}", name, "".join(p)))

    if r.checks:
        secs.append(("checks", "コードの外で確認が要ること", table(["ID", "確認したいこと", "関連"], [
            [esc(c.get("id")), esc(c.get("question", "")), "".join(chip(r, i) for i in ref_ids(c.get("related"))) or esc(c.get("related", ""))] for c in r.checks])))
    cr = r.d.get("cross_review") if isinstance(r.d.get("cross_review"), dict) else None
    if cr:
        p = []
        if cr.get("reviewer"):
            fl = f" ({link(cr.get('file'), cr.get('file'))})" if cr.get("file") else ""
            p.append(f"<p>レビュー: {esc(cr['reviewer'])}{fl}</p>")
        rows_cr = [x for x in as_list(cr.get("rows")) if isinstance(x, dict)]
        cnt = {k: sum(1 for x in rows_cr if x.get("agree") == k) for k in AGREE_TEXT}
        p.append("<p>" + " / ".join(f"{AGREE_TEXT[k]}: {v}" for k, v in cnt.items() if v) + "</p>")

        def mine(s):
            ids = ref_ids(s)
            return "".join(chip(r, i) for i in ids) if ids else esc(s)
        p.append(table(["相手", "自分", "一致", "メモ"], [[esc(x.get("theirs", "")), mine(x.get("mine")), esc(x.get("agree", "")), esc(x.get("note", ""))] for x in rows_cr]))
        if cr.get("missing"):
            p.append("<p>自分にあって相手に無い項目: " + "".join(chip(r, i) for i in as_list(cr["missing"])) + "</p>")
        secs.append(("cross", "独立レビューとの照合", "".join(p)))
    if r.sources or r.d.get("evidence"):
        p = []
        if r.sources:
            p.append(table(["文書", "版・施行日", "取得日"], [[link(s.get("url"), s.get("name", "")), esc(s.get("version", "")), esc(s.get("fetched", ""))] for s in r.sources]))
        ev = [e for e in as_list(r.d.get("evidence")) if isinstance(e, dict)]
        if ev:
            p.append("<h3>根拠資料</h3><ul>" + "".join(f'<li>{link(e.get("file"), e.get("file",""))} ({esc(e.get("label",""))})</li>' for e in ev) + "</ul>")
        secs.append(("sources", "参照した規約", "".join(p)))
    qs = [q for q in as_list(r.d.get("questions")) if isinstance(q, dict)]
    if qs:
        secs.append(("answers", "付録: 依頼者の疑問への回答", "".join(f'<div class="answer"><h3>{esc(q.get("q",""))}</h3><p>{esc(q.get("a",""))}</p></div>' for q in qs)))

    stats = ""
    if r.findings:
        c = r.counts()
        stats = '<div class="stats">' + "".join(f'<div class="stat stat--{k}"><b>{c[k]}</b><span>{SEV[k]}</span></div>' for k in ORDER) + "</div>"
    info = " / ".join(esc(x) for x in [m.get("target"), m.get("date"), m.get("authors")] if x)
    numbered = []
    n = 0
    for sid, t, body in secs:
        if t.startswith("付録"):
            numbered.append((sid, t, t, body))
        else:
            n += 1
            numbered.append((sid, f"{n}. {t}", t, body))
    toc = '<nav class="toc"><b>目次</b><ol>' + "".join(f'<li><a href="#{sid}">{esc(short)}</a></li>' for sid, _, short, _ in numbered) + "</ol></nav>"
    body = "".join(f'<section id="{sid}"><h2>{esc(t)}</h2>{h}</section>' for sid, t, _, h in numbered)
    mermaid = ('<script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"></script>'
               '<script>mermaid.initialize({startOnLoad:true,securityLevel:"strict",theme:(matchMedia("(prefers-color-scheme: dark)").matches&&document.documentElement.dataset.theme!=="light")?"dark":"default"});</script>') if has_mermaid else ""
    title = esc(m.get("title", "レビュー"))
    return (f'<!doctype html><html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            f"<title>{title}</title><style>{CSS}</style></head><body>"
            f'<div class="hero"><div class="wrap"><h1>{title}</h1>'
            + (f'<p class="sub">{esc(m["subtitle"])}</p>' if m.get("subtitle") else "")
            + (f"<p>{info}</p>" if info else "")
            + (f"<p>{esc(m['lead'])}</p>" if m.get("lead") else "")
            + f'{stats}</div></div><div class="wrap">{toc}{body}<footer>{title}{(" / " + info) if info else ""}</footer></div>{mermaid}</body></html>\n')


# ------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("report")
    ap.add_argument("--format", choices=["md", "html", "both"], default="md")
    ap.add_argument("--out", default=None, help="出力ディレクトリ (既定: report.json と同じ場所)")
    ap.add_argument("--name", default="report", help="出力ファイル名 (拡張子なし)")
    ap.add_argument("--check", action="store_true", help="検査だけ行う")
    ap.add_argument("--force", action="store_true", help="エラーがあっても描画する")
    a = ap.parse_args()
    try:
        with open(a.report, encoding="utf-8") as fp:
            r = Report(json.load(fp))
    except (OSError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(2)
    errors, warns = r.validate()
    for e in errors:
        print("error:", e, file=sys.stderr)
    for w in warns:
        print("warn:", w, file=sys.stderr)
    if a.check:
        print(f"{len(r.findings)} findings, {len(errors)} errors, {len(warns)} warnings")
        sys.exit(2 if errors else (1 if warns else 0))
    if errors and not a.force:
        print(f"{len(errors)} 件のエラーがあるので描画しない (--force で強行)", file=sys.stderr)
        sys.exit(2)
    out = a.out or os.path.dirname(os.path.abspath(a.report))
    os.makedirs(out, exist_ok=True)
    written = []
    if a.format in ("md", "both"):
        p = os.path.join(out, a.name + ".md")
        with open(p, "w", encoding="utf-8") as fp:
            fp.write(render_md(r))
        written.append(p)
    if a.format in ("html", "both"):
        p = os.path.join(out, a.name + ".html")
        with open(p, "w", encoding="utf-8") as fp:
            fp.write(render_html(r))
        written.append(p)
    c = r.counts()
    print("wrote", ", ".join(written), "|", " ".join(f"{SEV[k]}={c[k]}" for k in ORDER), f"| errors={len(errors)} warnings={len(warns)}")


if __name__ == "__main__":
    main()
