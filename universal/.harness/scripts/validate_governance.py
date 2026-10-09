#!/usr/bin/env python3
"""Validate governance records: JSON Schema, plus the semantic rules schema cannot express.

Schema catches shape. It cannot catch "the reviewer is the same actor as the
producer" — that is a relationship between two fields, and it is the only rule
here that actually matters. Hence two passes.

Usage:
  validate_governance.py --file <path> --kind <Kind>
  validate_governance.py --all          # every fixture: valid must pass, invalid must fail
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCHEMAS = ROOT / ".harness" / "schemas"
FIXTURES = ROOT / ".harness" / "fixtures"

SCHEMA_FOR = {
    "WorkItem": "work-item.schema.json",
    "EvidenceRecord": "evidence-record.schema.json",
    "Finding": "finding.schema.json",
    "Approval": "approval.schema.json",
    "Rejection": "rejection.schema.json",
    "ClosureRecord": "closure-record.schema.json",
}


class SemanticError(Exception):
    pass


def schema_validate(doc: dict, kind: str) -> None:
    name = SCHEMA_FOR.get(kind)
    if not name:
        raise SemanticError(f"unknown record kind: {kind}")
    schema = json.loads((SCHEMAS / name).read_text())
    try:
        import jsonschema
    except ImportError:
        # Degrade honestly rather than silently passing: required keys + const kind.
        for key in schema.get("required", []):
            if key not in doc:
                raise SemanticError(f"missing required field '{key}' (jsonschema not installed; shallow check only)")
        print("  ! jsonschema not installed — shallow validation only (pip install jsonschema)", file=sys.stderr)
        return
    jsonschema.validate(doc, schema)


# --- Semantic rules: the anti-self-certification core -------------------------

def rule_independent_review(doc: dict) -> None:
    """A governed review must come from a different actor, in a clean context, read-only."""
    if doc.get("evidenceType") != "governed_review":
        return
    action = doc.get("actorAction", {})
    producer = doc.get("producerActorId")
    if action.get("actorId") == producer:
        raise SemanticError(
            f"producer_cannot_self_certify: reviewer '{producer}' is the actor that produced the work"
        )
    prov = action.get("provenance") or {}
    if not prov:
        raise SemanticError("governed_review requires actorAction.provenance")
    if prov.get("cleanContext") is not True:
        raise SemanticError("governed_review requires provenance.cleanContext = true")
    if prov.get("inputAccess") != "read_only":
        raise SemanticError("governed_review requires provenance.inputAccess = read_only")
    if prov.get("resultEmission") != "governed_output_only":
        raise SemanticError("governed_review requires provenance.resultEmission = governed_output_only")


def rule_human_approval(doc: dict) -> None:
    """An agent may not stand in for a human approver — and neither may a claim.

    Two separate checks, because they catch two different lies.

    principalKind guards the first: a record that says an *agent* approved
    cannot be an approvalClass=human approval. That one was already here.

    trust guards the second, and it is the one that mattered. Any actor able to
    run repository scripts can write a file naming a person, set
    principalKind=human, and satisfy every check a schema can express.
    scripts/declare-intent.sh does exactly that, by design — it proves a
    DECLARATION was made, not that a human made it. So the declaration is
    labelled self_reported, and an approvalClass=human record must carry
    authenticated_human, which only a channel that issues identity can honestly
    supply (a GitHub required review, a protected environment).

    Be clear about what this is: a labelling discipline, not authentication.
    Nothing stops the same actor writing trust=authenticated_human in the file.
    What the rule buys is that the harness stops CALLING a self-reported
    declaration a human approval — which is the overclaim, not the file format.
    """
    if doc.get("approvalClass") != "human":
        return
    if doc.get("approverAction", {}).get("principalKind") != "human":
        raise SemanticError("approvalClass=human requires approverAction.principalKind = human")
    if doc.get("trust") != "authenticated_human":
        raise SemanticError(
            f"approvalClass=human requires trust=authenticated_human, got "
            f"{doc.get('trust')!r} — a self-reported declaration is not a human approval"
        )


def rule_closure(doc: dict) -> None:
    """Closure needs independent review, an approval, no open blocking findings, and a human closer."""
    producer = doc.get("producerActorId")
    action = doc.get("closureAction", {})
    if action.get("actorId") == producer:
        raise SemanticError(
            f"producer_cannot_self_certify: closing actor '{producer}' produced the work"
        )
    if action.get("principalKind") != "human":
        raise SemanticError("closure requires a human principal")
    if not doc.get("reviewEvidenceIds"):
        raise SemanticError("closure requires at least one independent review evidence id")
    if not doc.get("approvalIds"):
        raise SemanticError("closure requires at least one approval")
    if doc.get("openBlockingFindings", 0) != 0:
        raise SemanticError("closure requires zero open blocking findings")


SEMANTIC = {
    "EvidenceRecord": [rule_independent_review],
    "Approval": [rule_human_approval],
    "ClosureRecord": [rule_closure],
}


def validate(path: Path, kind: str | None = None) -> None:
    doc = json.loads(path.read_text())
    kind = kind or doc.get("kind")
    if not kind:
        raise SemanticError(f"{path.name}: no 'kind' field and none supplied")
    schema_validate(doc, kind)
    for rule in SEMANTIC.get(kind, []):
        rule(doc)


def run_all() -> int:
    failures = 0
    for path in sorted((FIXTURES / "valid").glob("*.json")):
        try:
            validate(path)
            print(f"  ✓ valid/{path.name}")
        except Exception as exc:                      # noqa: BLE001 - report, don't crash the suite
            print(f"  ✗ valid/{path.name} should have passed: {exc}")
            failures += 1
    for path in sorted((FIXTURES / "invalid").glob("*.json")):
        try:
            validate(path)
            print(f"  ✗ invalid/{path.name} should have been rejected but passed")
            failures += 1
        except Exception as exc:                      # noqa: BLE001
            reason = str(exc).split("\n")[0][:90]
            print(f"  ✓ invalid/{path.name} rejected: {reason}")
    print()
    if failures:
        print(f"✗ {failures} fixture(s) behaved incorrectly")
        return 1
    print("✓ governance fixtures behave correctly")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--file")
    ap.add_argument("--kind")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    if args.all:
        return run_all()
    if not args.file:
        ap.error("--file or --all required")
    try:
        validate(Path(args.file), args.kind)
    except Exception as exc:                          # noqa: BLE001
        print(f"✗ {args.file}: {exc}", file=sys.stderr)
        return 1
    print(f"✓ {args.file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
