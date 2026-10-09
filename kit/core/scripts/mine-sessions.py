#!/usr/bin/env python3
"""mine-sessions.py — evidence for a retro, from the agent's saved sessions.

Two questions a retro cannot answer from memory:

  default   Where did the person correct the agent? Keeps only what the PERSON
            typed (never tool output, never the agent's own words) and prints
            the lines that match config/correction-signals.txt.
  --usage   Where did the tokens go? Tokens per session and how much was read
            from the prompt cache, the largest tool outputs, and the files read
            again and again. Each points at a fix: a read-first row, a file to
            split, output to filter, exploration to turn into a script.

It WRITES NOTHING. The output is evidence for a retro, read by a person. Copy
patterns into the journal or candidates, never a colleague's words about
someone else.

Optional. Needs python3, and a host that saves sessions as JSON lines — Claude
Code does, under ~/.claude/projects/<folder path with separators as dashes>/.
For another host, pass --dir; lines it cannot parse are counted, not guessed at.
Subagent sessions are not included. For the current session, the host's own
/usage is the better view; this covers every session since the last retro.

These are one person's sessions on one machine. Each person who works in the
harness runs it on their own; nobody collects anyone else's.

Usage:
  python3 scripts/mine-sessions.py                    corrections since the last retro
  python3 scripts/mine-sessions.py --usage
  python3 scripts/mine-sessions.py --since 2026-08-01 --dir /path/to/sessions
"""
import argparse
import datetime as dt
import glob
import json
import os
import re
import statistics
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RETROS = os.path.join(ROOT, "learning", "retros.md")
SIGNALS = os.path.join(ROOT, "config", "correction-signals.txt")


def last_retro():
    try:
        with open(RETROS, encoding="utf-8") as f:
            dates = re.findall(r"^\|\s*(20\d\d-\d\d-\d\d)\s*\|", f.read(), re.M)
        return dates[-1] if dates else None
    except OSError:
        return None


def signals():
    out = []
    with open(SIGNALS, encoding="utf-8") as f:
        for line in f:
            s = line.rstrip("\n")
            if s.strip() and not s.lstrip().startswith("#"):
                try:
                    out.append((s, re.compile(s, re.I)))
                except re.error as e:
                    sys.exit(f"{SIGNALS}: bad pattern {s!r}: {e}")
    return out


def default_dir():
    base = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
    projects = os.path.join(base, "projects")
    exact = os.path.join(projects, re.sub(r"[^A-Za-z0-9]", "-", ROOT))
    if os.path.isdir(exact):
        return exact, []
    tail = re.sub(r"[^A-Za-z0-9]", "-", os.path.basename(ROOT))
    near = sorted(glob.glob(os.path.join(projects, "*" + tail)))
    return (near[0], []) if len(near) == 1 else (None, near)


def records(files, since):
    """(session, record) for every parseable record on or after `since`; and the unreadable count."""
    bad = 0
    out = []
    for path in files:
        sess = os.path.basename(path)[:8]
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                try:
                    rec = json.loads(line)
                except ValueError:
                    bad += 1
                    continue
                if not isinstance(rec, dict):
                    continue
                day = str(rec.get("timestamp", ""))[:10]
                if day and day < since:
                    continue
                out.append((sess, day, rec))
    return out, bad


TAG_BLOCK = re.compile(r"<(system-reminder|local-command-stdout|command-[a-z-]+)>.*?</\1>", re.S)


def human_text(rec):
    """What the person typed, or None. Tool results and injected context are not the person."""
    if rec.get("type") != "user":
        return None
    if rec.get("isMeta") or rec.get("isSidechain") or rec.get("isCompactSummary") or rec.get("isVisibleInTranscriptOnly"):
        return None
    content = (rec.get("message") or {}).get("content")
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        # Text items only. A tool result is never the person, but a text item
        # beside one can be — an interruption arrives that way.
        text = "\n".join(i.get("text", "") for i in content if isinstance(i, dict) and i.get("type") == "text")
    else:
        return None
    text = TAG_BLOCK.sub("", text).strip()
    if not text or text.startswith("<") or text.startswith("Caveat:"):
        return None
    return text


def corrections(recs, a):
    sigs = signals()
    n_msgs = 0
    sessions = set()
    hits, by_signal = [], {}
    for sess, day, rec in recs:
        text = human_text(rec)
        if text is None:
            continue
        n_msgs += 1
        sessions.add(sess)
        if text.startswith("[Request interrupted by user"):
            label = "(stopped the agent mid-task)"
            by_signal[label] = by_signal.get(label, 0) + 1
            hits.append((day, sess, label, text[:60]))
            continue
        for raw, rx in sigs:
            m = rx.search(text)
            if m:
                label = raw.replace("\\b", "")
                by_signal[label] = by_signal.get(label, 0) + 1
                start = max(0, text.rfind("\n", 0, m.start()) + 1)
                hits.append((day, sess, label, " ".join(text[start:start + 240].split())))
                break
    print(f"{len(sessions)} with messages in range, {n_msgs} message(s) typed by the person, {len(hits)} matched\n")
    for day, sess, sig, snip in hits[: a.max]:
        print(f"{day}  {sess}  {sig}\n    {snip}")
    if len(hits) > a.max:
        print(f"... {len(hits) - a.max} more; raise --max to see them")
    if by_signal:
        print("\nBy signal:")
        for sig, n in sorted(by_signal.items(), key=lambda kv: -kv[1]):
            print(f"  {n:4d}  {sig}")
    print("\nA match is a place to look, not a finding. The same correction in two sessions is a candidate.")


def short(n):
    return f"{n / 1e6:.1f}M" if n >= 1e6 else f"{n / 1e3:.0f}k" if n >= 1e3 else str(n)


def rel(path):
    p = str(path or "")
    return p[len(ROOT) + 1:] if p.startswith(ROOT + os.sep) else p


def usage(recs, a):
    seen = set()
    per_sess = {}
    fresh = written = cached = output = 0
    tools = {}                       # tool_use id -> "Tool: what"
    results = []                     # (chars, label)
    reads = {}                       # file -> [count, set(sessions)]
    rereads = {}                     # (session, file) -> count
    for sess, day, rec in recs:
        msg = rec.get("message") or {}
        if rec.get("type") == "assistant":
            u = msg.get("usage") or {}
            key = msg.get("id") or rec.get("requestId") or rec.get("uuid")
            if u and key not in seen:        # one API response is written as several records
                seen.add(key)
                i, w, r = u.get("input_tokens", 0), u.get("cache_creation_input_tokens", 0), u.get("cache_read_input_tokens", 0)
                fresh, written, cached, output = fresh + i, written + w, cached + r, output + u.get("output_tokens", 0)
                per_sess[sess] = per_sess.get(sess, 0) + i + w + r
            for c in msg.get("content") or []:
                if isinstance(c, dict) and c.get("type") == "tool_use":
                    inp = c.get("input") or {}
                    name = c.get("name", "?")
                    what = inp.get("file_path") or inp.get("command") or inp.get("pattern") or inp.get("url") or ""
                    tools[c.get("id")] = f"{name}: {' '.join(rel(what).split())[:70]}"
                    if name == "Read" and inp.get("file_path"):
                        f = rel(inp["file_path"])
                        reads.setdefault(f, [0, set()])
                        reads[f][0] += 1
                        reads[f][1].add(sess)
                        rereads[(sess, f)] = rereads.get((sess, f), 0) + 1
        elif rec.get("type") == "user" and isinstance(msg.get("content"), list):
            for c in msg["content"]:
                if isinstance(c, dict) and c.get("type") == "tool_result":
                    body = c.get("content")
                    if isinstance(body, list):
                        body = "".join(i.get("text", "") for i in body if isinstance(i, dict))
                    results.append((len(str(body or "")), tools.get(c.get("tool_use_id"), "unknown tool")))
    total_in = fresh + written + cached
    if not seen:
        print("No token usage recorded in range. Nothing to report — this is not a clean result.")
        return 2
    vals = sorted(per_sess.values())
    print(f"{len(per_sess)} session(s), {len(seen)} model response(s)\n")
    print(f"Input per session    median {short(int(statistics.median(vals)))}, largest {short(vals[-1])}  (every response re-sends the conversation)")
    print(f"Prompt cache         {100 * cached / total_in:.0f}% of input read from cache, {100 * written / total_in:.0f}% written to it, {100 * fresh / total_in:.0f}% uncached")
    print(f"Output               {short(output)} tokens, thinking included")
    if total_in and written > cached:
        print("                     More written than read: sessions are short, idle past the cache lifetime, or something changes the prefix mid-session.")
    print("\nLargest tool outputs (about tokens = characters / 4):")
    for n, label in sorted(results, reverse=True)[: a.max_rows]:
        print(f"  {n:9,d} chars  ~{n // 4:7,d}  {label}")
    print("\nFiles read most (reads, sessions):")
    if not reads:
        print("  none — no file-read tool calls in range")
    for f, (n, ss) in sorted(reads.items(), key=lambda kv: -kv[1][0])[: a.max_rows]:
        print(f"  {n:4d} reads  {len(ss):3d} sessions  {f}")
    again = sorted(((n, s, f) for (s, f), n in rereads.items() if n >= 3), reverse=True)
    if again:
        print("\nRead 3+ times in one session:")
        for n, s, f in again[: a.max_rows]:
            print(f"  {n:4d}x  {s}  {f}")
    print("\nLarge outputs that recur are candidates for filtering or a script that returns a summary. A file read in"
          "\nmost sessions belongs in read-first or should be shorter. A large file read again and again may need splitting.")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--usage", action="store_true", help="where the tokens went, instead of corrections")
    ap.add_argument("--dir", help="session directory (default: the host's folder for this harness)")
    ap.add_argument("--since", help="YYYY-MM-DD (default: the last retro, else 30 days ago)")
    ap.add_argument("--days", type=int, help="look back this many days instead of --since")
    ap.add_argument("--max", type=int, default=100, help="most correction lines to print (default 100)")
    ap.add_argument("--max-rows", type=int, default=8, help="rows per usage table (default 8)")
    a = ap.parse_args()

    if a.days is not None:
        since = (dt.date.today() - dt.timedelta(days=a.days)).isoformat()
    else:
        since = a.since or last_retro() or (dt.date.today() - dt.timedelta(days=30)).isoformat()

    d = a.dir
    if not d:
        d, near = default_dir()
        if not d:
            print("No session folder found for this harness.", file=sys.stderr)
            if near:
                print("Several look close — pass one with --dir:", *near, sep="\n  ", file=sys.stderr)
            else:
                print("Pass --dir to where your host saves sessions. Nothing was read.", file=sys.stderr)
            return 2
    if not os.path.isdir(d):
        print(f"No such directory: {d}. Nothing was read.", file=sys.stderr)
        return 2

    files = sorted(glob.glob(os.path.join(d, "*.jsonl")))
    print(f"{'Usage' if a.usage else 'Corrections'} since {since} — {d}")
    if not files:
        print("No .jsonl files there. Nothing was read — this is not a clean result.")
        return 2
    recs, bad = records(files, since)
    print(f"{len(files)} session file(s)" + (f", {bad} unreadable line(s) skipped" if bad else ""))
    if a.usage:
        return usage(recs, a)
    corrections(recs, a)
    return 0


if __name__ == "__main__":
    sys.exit(main())
