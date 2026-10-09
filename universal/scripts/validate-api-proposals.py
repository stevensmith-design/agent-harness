#!/usr/bin/env python3
"""Validate the API proposals in docs/api-proposal/.

Two modes, called by two gates:

  --mode status   every operation carries an x-status and a unique operationId
  --mode drift    an operation the consumer has already agreed to has not moved
                  without a matching row in the sign-off ledger

Why Python and not awk, like the rest of the harness: these checks need to know
which keys belong to which operation, through $refs, multi-line descriptions and
anchors. A line-oriented approximation of that is not a fragile gate, it is a
wrong one, and a gate you cannot trust to be exact should not exist. yaml is
declared in harness.config.yaml under tooling.python_modules and checked by
`make doctor`; if it is absent this exits non-zero rather than degrading.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

try:
    import yaml
except ImportError:
    sys.stderr.write(
        "✗ python module 'yaml' is missing — the API contract gate cannot run.\n"
        "    install: pip3 install pyyaml\n"
        "    Declared in harness.config.yaml under tooling.python_modules.\n"
        "    Refusing to skip: a contract check that silently does not run is\n"
        "    worse than no contract check, because it reads as one.\n")
    sys.exit(1)

METHODS = ("get", "put", "post", "delete", "options", "head", "patch", "trace")
REQ_RE = re.compile(r"^REQ-[0-9]+$")
# A requirement at or past this point is being built, so if it needs an API the
# contract should exist by now. Earlier than that, silence is legitimate.
BUILDING = ("specced", "in-progress", "shipped")
STATUSES = ("proposed", "agreed", "frozen", "changed", "superseded")
# The statuses that mean "someone is building against this shape".
COMMITTED = ("agreed", "frozen")
# Keys that describe the agreement ABOUT an operation rather than its shape.
# Excluded from the hash, so bumping a status is not itself a shape change.
META_KEYS = ("x-status", "x-changed", "x-agreed", "x-ledger", "x-req")

def requirement_rows(root):
    """(id, status) for every row of the requirement register.

    The register is the harness's existing spine — one register, read by two
    gates. Re-deriving the list of requirements anywhere else would be the
    second-tracker problem the harness forbids.
    """
    reg = os.path.join(root, "docs", "product", "requirements.md")
    rows = []
    if not os.path.isfile(reg):
        return rows
    with open(reg, encoding="utf-8") as fh:
        for line in fh:
            if not line.startswith("| REQ-"):
                continue
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) >= 4:
                rows.append((cells[0], cells[3].lower()))
    return rows


def no_api_ids(root):
    """REQ ids explicitly recorded as having no API surface.

    A list, not a per-requirement flag: the register belongs to the product lane
    and must not grow a column that only the API lane reads.
    """
    doc = os.path.join(root, "docs", "api-proposal", "README.md")
    if not os.path.isfile(doc):
        return set()
    with open(doc, encoding="utf-8") as fh:
        text = fh.read()
    # Comments are examples, not exemptions.
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    # Every such section, not the first: a second heading appended later is a
    # perfectly ordinary way for this list to grow, and reading only the first
    # would drop real exemptions on the floor.
    ids = set()
    for m in re.finditer(r"^##+[ \t]*No API surface[ \t]*$(.*?)(?=^##[ \t]|\Z)",
                         text, re.M | re.S):
        ids.update(re.findall(r"\bREQ-[0-9]+\b", m.group(1)))
    return ids


problems = []


def note(msg):
    problems.append(msg)


def operations(doc, where):
    """Yield (operationId-or-None, method, path, op-dict) for a parsed document."""
    paths = (doc or {}).get("paths")
    if not isinstance(paths, dict):
        return
    for path, item in paths.items():
        if not isinstance(item, dict):
            note("%s: path '%s' is not a mapping" % (where, path))
            continue
        for method, op in item.items():
            if method.lower() not in METHODS:
                continue
            if not isinstance(op, dict):
                note("%s: %s %s is not a mapping" % (where, method.upper(), path))
                continue
            yield (op.get("operationId"), method.lower(), path, op,
                   item.get("parameters") or [])


def load(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        note("%s: not valid YAML — %s" % (os.path.basename(path), str(exc).split("\n")[0]))
        return None


def proposal_files(root):
    d = os.path.join(root, "docs", "api-proposal")
    if not os.path.isdir(d):
        return []
    return sorted(
        os.path.join(d, f) for f in os.listdir(d)
        if f.endswith((".yaml", ".yml"))
    )


def _deref(node, doc, loader, trail):
    """Inline every $ref reachable from node, so the hash covers the real shape.

    Without this the hash saw the literal string "#/components/schemas/Entry"
    and nothing else: adding a required field to a shared schema changed every
    agreed response and the gate reported no change at all. That is the single
    most common way a contract actually breaks.

    `trail` carries the refs already being expanded on this branch of the walk,
    so a self-referential schema terminates instead of recursing forever.
    """
    if isinstance(node, dict):
        ref = node.get("$ref")
        if isinstance(ref, str):
            if ref in trail:
                return {"$circular-ref": ref}
            filepart, _, pointer = ref.partition("#")
            target_doc = doc
            if filepart:
                target_doc = loader(filepart)
                if target_doc is None:
                    # An unresolvable ref is not "no change" — it is a shape we
                    # cannot read, and it must hash differently from one we can.
                    return {"$unresolved-ref": ref}
            cur = target_doc
            for token in [t for t in pointer.split("/") if t != ""]:
                token = token.replace("~1", "/").replace("~0", "~")
                if isinstance(cur, dict) and token in cur:
                    cur = cur[token]
                elif isinstance(cur, list) and token.isdigit() and int(token) < len(cur):
                    cur = cur[int(token)]
                else:
                    return {"$unresolved-ref": ref}
            merged = _deref(cur, target_doc, loader, trail | {ref})
            # Sibling keys alongside a $ref are legal in OpenAPI 3.1.
            rest = {k: v for k, v in node.items() if k != "$ref"}
            if rest and isinstance(merged, dict):
                merged = dict(merged)
                merged.update(_deref(rest, doc, loader, trail | {ref}))
            return merged
        return {k: _deref(v, doc, loader, trail) for k, v in node.items()}
    if isinstance(node, list):
        return [_deref(v, doc, loader, trail) for v in node]
    return node


def op_hash(op, method=None, path=None, doc=None, loader=None, shared=None):
    """A canonical hash of an operation's SHAPE, ignoring agreement metadata.

    Covers, deliberately:
      - the operation body, with every $ref resolved
      - the METHOD and PATH, which are the operation's identity to a caller.
        Hashing the body alone meant moving GET /entries to POST /v2/entries
        under the same operationId was "no change" while every consumer 404s.
      - path-level `parameters`, which are siblings of the operation and apply
        to it. A required header added there rejects every existing caller.
    """
    loader = loader or (lambda _f: None)
    body = {k: v for k, v in op.items() if k not in META_KEYS}
    body = _deref(body, doc if doc is not None else {}, loader, frozenset())
    envelope = {
        "method": (method or "").lower(),
        "path": path or "",
        "op": body,
        "path_level_parameters": _deref(
            shared or [], doc if doc is not None else {}, loader, frozenset()),
    }
    return hashlib.sha256(
        json.dumps(envelope, sort_keys=True, default=str).encode("utf-8")
    ).hexdigest()


# --- mode: status -------------------------------------------------------------

def check_status(root):
    files = proposal_files(root)
    # NOT an early return. "There are no proposals" is precisely the state in
    # which a requirement being built has no contract written down, so returning
    # here would skip the only check that notices — the same silent-skip the
    # harness abolished everywhere else.
    seen = {}
    count = 0
    reg = requirement_rows(root)
    reg_ids = {r for r, _ in reg}
    covered = set()
    for path in files:
        name = os.path.basename(path)
        doc = load(path)
        if doc is None:
            continue
        # The retired mechanic. One file-level status cannot describe a document
        # whose operations were agreed on five different days.
        if isinstance(doc, dict) and "status" in doc:
            note("%s: has a file-level 'status:' — status is per-operation now. "
                 "Move it to 'x-status' on each operation." % name)
        found = False
        for op_id, method, p, op, _shared in operations(doc, name):
            found = True
            count += 1
            label = "%s: %s %s" % (name, method.upper(), p)
            if not op_id or not isinstance(op_id, str):
                note("%s has no operationId — the ledger and every status check "
                     "address operations by that name" % label)
            elif op_id in seen:
                note("duplicate operationId '%s' (%s and %s) — an ID that names "
                     "two operations makes every ledger row ambiguous"
                     % (op_id, seen[op_id], label))
            else:
                seen[op_id] = label
            # x-req is the join key. Without it the three registers — proposals,
            # ledger, invariants — are keyed three different ways and none of
            # them answers the question a consumer actually asks: "I am building
            # this. What do I need to know?"
            req = op.get("x-req")
            if req is None:
                note("%s has no x-req — name the requirement it serves, so the "
                     "contract can be looked up by the unit of work rather than "
                     "by resource" % label)
            elif not isinstance(req, str) or not REQ_RE.match(req.strip()):
                note("%s has x-req '%s' — expected a single REQ-NNN from "
                     "docs/product/requirements.md" % (label, req))
            else:
                req = req.strip()
                if reg_ids and req not in reg_ids:
                    note("%s names %s, which has no row in "
                         "docs/product/requirements.md. A contract pointing at a "
                         "requirement nobody wrote is not traceable to anything."
                         % (label, req))
                covered.add(req)
            st = op.get("x-status")
            if st is None:
                note("%s has no x-status — one of: %s" % (label, ", ".join(STATUSES)))
            elif st not in STATUSES:
                note("%s has x-status '%s' — expected one of: %s"
                     % (label, st, ", ".join(STATUSES)))
        if not found:
            note("%s: no operations found under 'paths:' — an OpenAPI document "
                 "with nothing in it passes every other check" % name)
    # The other direction, and the one nobody can eyeball: a requirement being
    # built whose API surface was never written down. "The spec did not cover
    # every screen" is an incompleteness complaint, and incompleteness is
    # exactly what a gate is good at. `x-no-api` is the explicit opt-out — a
    # requirement with genuinely no API surface says so, once, on the record.
    no_api = no_api_ids(root)
    missing = [r for r, st in reg
               if st in BUILDING and r not in covered and r not in no_api]
    if missing:
        note("these requirements are being built and no proposed operation "
             "names them, and none is marked as having no API surface: %s.\n"
             "    Either add x-req to the operations that serve them, or record "
             "the exemption in docs/api-proposal/README.md under 'No API "
             "surface' — a spec that is silent about an endpoint is the gap "
             "that gets discovered during integration."
             % ", ".join(sorted(missing)))

    if not problems:
        if not files:
            print("no proposals yet, and no requirement in build needs one")
        else:
            print("%d operation(s) across %d file(s), every one with a status "
                  "and a requirement; %d requirement(s) in build covered"
                  % (count, len(files), len(covered)))


# --- mode: drift --------------------------------------------------------------

ROW = re.compile(r"^\|(?!\s*[-:]+\s*\|)(.+)\|\s*$")


def ledger_rows(text):
    """Every table row in the ledger, as raw cell lists."""
    rows = []
    fenced = False
    for line in (text or "").splitlines():
        if line.strip().startswith("```"):
            fenced = not fenced
            continue
        # A worked example in a code fence is documentation, not a sign-off.
        # Without this, the example rows in a newly added ledger count as rows
        # added by the change, and an example naming a real operation would
        # excuse a real drift.
        if fenced:
            continue
        m = ROW.match(line.strip())
        if not m:
            continue
        cells = [c.strip() for c in m.group(1).split("|")]
        if len(cells) >= 3 and cells[0].lower() not in ("date",):
            rows.append(cells)
    return rows


def git_show(root, ref, relpath):
    try:
        return subprocess.check_output(
            ["git", "-C", root, "show", "%s:%s" % (ref, relpath)],
            stderr=subprocess.DEVNULL).decode("utf-8")
    except subprocess.CalledProcessError:
        return None


def base_proposal_files(root, base):
    """Proposal files as they existed at the base commit.

    Listing only the working tree meant deleting a whole proposal file reported
    'no proposals yet' and passed — the loudest possible withdrawal of an agreed
    contract, invisible to the check meant to catch withdrawals.
    """
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "ls-tree", "-r", "--name-only", base,
             "docs/api-proposal/"], stderr=subprocess.DEVNULL).decode("utf-8")
    except (subprocess.CalledProcessError, OSError):
        return []
    return [f for f in out.splitlines() if f.endswith((".yaml", ".yml"))]


def check_drift(root, main_branch):
    try:
        subprocess.check_output(["git", "-C", root, "rev-parse", "HEAD"],
                                stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, OSError):
        print("no git history to compare against — skipped")
        return
    # Falling back to "HEAD" here made the gate compare HEAD against itself, so
    # every committed change was invisible and the gate could not fail — on a
    # fork, in a shallow clone, and in any repo whose default branch is not the
    # configured one. That is the harness's own first rule broken by its newest
    # gate: a check may report "clean", or "I could not look", never the second
    # as the first.
    try:
        base = subprocess.check_output(
            ["git", "-C", root, "merge-base", main_branch, "HEAD"],
            stderr=subprocess.DEVNULL).decode().strip()
    except subprocess.CalledProcessError:
        base = ""
    if not base:
        note("cannot resolve a merge base between '%s' and HEAD, so there is "
             "nothing to compare an agreed shape against. Fetch the base branch "
             "(a shallow clone has no merge base), or set git.main_branch in "
             "harness.config.yaml to the branch this repo actually uses."
             % main_branch)
        return

    rels = sorted(set(
        [os.path.relpath(f, root) for f in proposal_files(root)]
        + base_proposal_files(root, base)))
    if not rels:
        print("no proposals yet")
        return

    ledger_rel = "docs/api-proposal/AGREEMENTS.md"
    ledger_path = os.path.join(root, ledger_rel)
    now = ledger_rows(open(ledger_path, encoding="utf-8").read()
                      if os.path.isfile(ledger_path) else "")
    before = ledger_rows(git_show(root, base, ledger_rel) or "")
    before_keys = [tuple(r) for r in before]
    # Rows added since the base. Deliberately not "rows dated today": a clock is
    # not evidence, and a branch may legitimately span days.
    # Novelty, not multiset delta. Counting the second copy of an identical row
    # as "added" meant pasting a row that was already there excused a shape
    # change — a one-line bypass, and a plausible accident when resolving a
    # rebase conflict in this file.
    seen_before = set(before_keys)
    added = [r for r in now if tuple(r) not in seen_before]
    named_in_new_rows = " ".join(" ".join(r) for r in added)

    moved = 0
    for rel in rels:
        path = os.path.join(root, rel)
        name = os.path.basename(rel)
        # A file deleted in this change: no live operations, so every committed
        # operation it held counts as removed.
        doc = load(path) if os.path.isfile(path) else {}
        if doc is None:
            continue
        old_text = git_show(root, base, rel)
        if old_text is None:
            continue  # new file: nothing was ever agreed in it
        try:
            old_doc = yaml.safe_load(old_text)
        except yaml.YAMLError:
            note("%s: the version at %s is not valid YAML, so nothing can be "
                 "compared against it. Refusing to report this file unchanged."
                 % (name, base[:8]))
            continue
        # A $ref may point into a sibling file. Resolve it on the correct side
        # of the comparison: the working tree for "now", the base commit for
        # "then". Using the live file for both would hide a change made only in
        # the shared schema, which is the commonest break of all.
        def now_loader(fp, _rel=rel):
            t = os.path.join(root, os.path.dirname(_rel), fp)
            return load(t) if os.path.isfile(t) else None

        def base_loader(fp, _rel=rel):
            r = os.path.normpath(os.path.join(os.path.dirname(_rel), fp))
            txt = git_show(root, base, r)
            if txt is None:
                return None
            try:
                return yaml.safe_load(txt)
            except yaml.YAMLError:
                return None

        old_ops = {}
        for op_id, method, p, op, shared in operations(old_doc, name):
            old_ops[op_id or "%s %s" % (method, p)] = (
                op.get("x-status"),
                op_hash(op, method, p, old_doc, base_loader, shared))
        live = set()
        for op_id, method, p, op, shared in operations(doc, name):
            key = op_id or "%s %s" % (method, p)
            live.add(key)
            if key not in old_ops:
                continue
            was_status, was_hash = old_ops[key]
            if was_status not in COMMITTED:
                continue
            if op_hash(op, method, p, doc, now_loader, shared) == was_hash:
                continue
            moved += 1
            if key and re.search(r"(?<![\w-])%s(?![\w-])" % re.escape(key),
                                 named_in_new_rows):
                continue
            note("%s (%s %s) was '%s' and its shape changed, with no new row in "
                 "%s naming it. The consumer is building against the old shape "
                 "and has not been told."
                 % (key, method.upper(), p, was_status, ledger_rel))
        # Removing an agreed operation is a louder version of changing it, and
        # the loop above cannot see it — it only walks operations that still
        # exist. Withdrawing a shape someone is building against needs a row for
        # the same reason amending one does.
        for key, (was_status, _h) in old_ops.items():
            if key in live or was_status not in COMMITTED:
                continue
            moved += 1
            if key and re.search(r"(?<![\w-])%s(?![\w-])" % re.escape(key),
                                 named_in_new_rows):
                continue
            note("%s was '%s' in %s and has been removed, with no new row in %s "
                 "naming it. Withdrawing an agreed operation still needs a "
                 "'reopened' row." % (key, was_status, name, ledger_rel))
    if not problems:
        if moved:
            print("%d agreed operation(s) changed, each recorded in the ledger" % moved)
        else:
            print("no agreed operation changed shape since %s" % base[:8])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=("status", "drift"), required=True)
    ap.add_argument("--root", default=".")
    ap.add_argument("--main-branch", default="main")
    args = ap.parse_args()
    root = os.path.abspath(args.root)
    if args.mode == "status":
        check_status(root)
    else:
        check_drift(root, args.main_branch)
    if problems:
        for p in problems:
            sys.stderr.write("    %s\n" % p)
        sys.exit(1)


if __name__ == "__main__":
    main()
