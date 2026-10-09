#!/bin/bash
# ui-design-review — code scan script
# Checks frontend files for banned UI patterns.
# Usage:
#   scan.sh <file-or-dir>       Scan a specific file or directory
#   scan.sh --staged            Scan git staged files
#   scan.sh --diff <branch>     Scan diff against a branch (e.g. main)
#   (add --tiered to gate on ERROR/REVIEW only; RISK becomes advisory)
#
# Exit codes: 0 = pass, 1 = violations found

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

VIOLATIONS=0
ERRORS=0        # Tier-1 quality/a11y defects (F8)
REVIEWS=0       # Tier-2 gate-able patterns needing a documented rationale
RISKS=0         # Tier-3 co-occurrence risk indicators (advisory)
PRINTED=0
MAX_PRINT=100   # display-only cap: every match is still COUNTED; only printed detail is capped
TIERED=0        # --tiered: only ERROR/REVIEW fail CI; RISK is advisory
FILES=()

# Extract --tiered from anywhere in the args (leave positional target intact).
_args=()
for a in "$@"; do
  if [ "$a" = "--tiered" ]; then TIERED=1; else _args+=("$a"); fi
done
set -- ${_args[@]+"${_args[@]}"}

# ── Collect files to scan ──────────────────────────────────────────────────────

collect_files() {
  local target="$1"
  if [ -f "$target" ]; then
    FILES+=("$target")
  elif [ -d "$target" ]; then
    while IFS= read -r f; do
      FILES+=("$f")
    done < <(find "$target" -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.vue" \
      -o -name "*.css" -o -name "*.scss" -o -name "*.html" -o -name "*.jsx" -o -name "*.js" \) \
      ! -path "*/node_modules/*" ! -path "*/.git/*")
  fi
}

if [ $# -eq 0 ]; then
  echo "Usage: scan.sh <file-or-dir> | --staged | --diff <branch>"
  exit 1
fi

case "$1" in
  --staged)
    while IFS= read -r f; do
      [[ "$f" =~ \.(tsx|ts|vue|css|scss|html|jsx|js)$ ]] && FILES+=("$f")
    done < <(git diff --cached --name-only --diff-filter=ACM)
    ;;
  --diff)
    BRANCH="${2:-main}"
    while IFS= read -r f; do
      [[ "$f" =~ \.(tsx|ts|vue|css|scss|html|jsx|js)$ ]] && [ -f "$f" ] && FILES+=("$f")
    done < <(git diff --name-only "$BRANCH"...HEAD --diff-filter=ACM)
    ;;
  *)
    collect_files "$1"
    ;;
esac

if [ ${#FILES[@]} -eq 0 ]; then
  echo -e "${GREEN}✔ No frontend files to scan.${RESET}"
  exit 0
fi

# ── Project exceptions (portable) ──────────────────────────────────────────────
# Optional per-project file: scan-exceptions.conf at the git root (or cwd).
# One extended-regex per line; '#' starts a comment. A flagged line matching any
# pattern is skipped. Every entry must correspond to a DESIGN.md override-log
# entry — this file is the scanner-side mirror of documented overrides.
EXCEPTIONS=()
EXC_IDS=()   # parallel to EXCEPTIONS: the "# id: <slug>" governing each pattern ("" if none)
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
pending_id=""
if [ -f "$ROOT/scan-exceptions.conf" ]; then
  while IFS= read -r raw; do
    # A standalone "# id: slug" comment governs the next pattern line.
    if printf '%s' "$raw" | grep -qE '^[[:space:]]*#[[:space:]]*id:[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*$'; then
      pending_id=$(printf '%s' "$raw" | sed -E 's/^[[:space:]]*#[[:space:]]*id:[[:space:]]*([A-Za-z0-9_-]+).*/\1/')
      continue
    fi
    inline_id=""
    if printf '%s' "$raw" | grep -qE '#[[:space:]]*id:[[:space:]]*[A-Za-z0-9_-]+'; then
      inline_id=$(printf '%s' "$raw" | sed -E 's/.*#[[:space:]]*id:[[:space:]]*([A-Za-z0-9_-]+).*/\1/')
    fi
    pat="${raw%%#*}"
    pat="$(printf '%s' "$pat" | sed -e 's/[[:space:]]*$//')"
    if [ -n "$pat" ]; then
      EXCEPTIONS+=("$pat")
      if [ -n "$inline_id" ]; then EXC_IDS+=("$inline_id"); else EXC_IDS+=("$pending_id"); fi
      pending_id=""
    fi
  done < "$ROOT/scan-exceptions.conf"
fi

# ── Exception governance (F7) ──────────────────────────────────────────────────
# Every active scan-exception must carry a "# id: <slug>" that mirrors a DESIGN.md override-log
# entry. An undocumented or orphaned exception silently suppresses findings, so it is itself a
# violation (counted below, before the file loop). Verified only when a DESIGN.md exists.
DESIGN_MD=""
for cand in "$ROOT/DESIGN.md" "$ROOT/design-system.md" "$ROOT/DESIGN_SYSTEM.md"; do
  [ -f "$cand" ] && { DESIGN_MD="$cand"; break; }
done

is_excepted() {
  local line="$1" pat
  for pat in ${EXCEPTIONS[@]+"${EXCEPTIONS[@]}"}; do
    if printf '%s' "$line" | grep -qE "$pat"; then
      return 0
    fi
  done
  return 1
}

echo -e "${BOLD}UI Design Review — Code Scan${RESET}"
echo -e "Scanning ${#FILES[@]} file(s)...\n"

if [ ${#EXCEPTIONS[@]} -gt 0 ] && [ -z "$DESIGN_MD" ]; then
  # Ungoverned exceptions: a scan-exceptions.conf with no DESIGN.md can silently suppress
  # findings with nothing to audit it against. That is itself an ERROR (F7/#3).
  VIOLATIONS=$((VIOLATIONS + 1)); ERRORS=$((ERRORS + 1))
  echo -e "  ${RED}✘${RESET} ${BOLD}scan-exceptions.conf${RESET}  [ERROR]"
  echo -e "    Rule:  Ungoverned scan-exceptions (no DESIGN.md)"
  echo -e "    Found: ${YELLOW}${#EXCEPTIONS[@]} exception pattern(s) with no DESIGN.md override log${RESET}"
  echo -e "    Fix:   add a DESIGN.md with an override log so every '# id: <slug>' can be verified\n"
fi
if [ ${#EXCEPTIONS[@]} -gt 0 ] && [ -n "$DESIGN_MD" ]; then
  gi=0
  for pat in "${EXCEPTIONS[@]}"; do
    id="${EXC_IDS[$gi]}"; gi=$((gi+1))
    if [ -z "$id" ]; then
      VIOLATIONS=$((VIOLATIONS + 1)); ERRORS=$((ERRORS + 1))
      echo -e "  ${RED}✘${RESET} ${BOLD}scan-exceptions.conf${RESET}"
      echo -e "    Rule:  Undocumented scan-exception (no id)"
      echo -e "    Found: ${YELLOW}${pat}${RESET}"
      echo -e "    Fix:   add '# id: <slug>' and a matching ${DESIGN_MD##*/} override-log entry\n"
    elif ! grep -qF "$id" "$DESIGN_MD"; then
      VIOLATIONS=$((VIOLATIONS + 1)); ERRORS=$((ERRORS + 1))
      echo -e "  ${RED}✘${RESET} ${BOLD}scan-exceptions.conf${RESET}"
      echo -e "    Rule:  Orphaned scan-exception id"
      echo -e "    Found: ${YELLOW}id: ${id}${RESET}  (pattern: ${pat})"
      echo -e "    Fix:   document override '${id}' in ${DESIGN_MD##*/} override log, or remove the exception\n"
    fi
  done
fi

# ── Pattern checks ─────────────────────────────────────────────────────────────

# F8: map a rule to its decision tier. ERROR = objective correctness/a11y (never overridable);
# REVIEW = context-dependent design or performance pattern; RISK = Tier-3 advisory tell.
rule_tier() {
  case "$1" in
    *"Clickable div"*|*"aria-label"*|*"Broken/placeholder image"*|*"Semantic-palette leak"*) echo ERROR;;
    *"Numbered section markers"*|*"Em-dash overuse"*|*"Decorative accent border (advisory)"*) echo RISK;;
    *) echo REVIEW;;
  esac
}

flag() {
  local file="$1" line="$2" rule="$3" match="$4" fix="$5"
  # Classify FIRST, then apply exceptions. Tier-1 ERRORs (correctness/a11y) are never
  # overridable — a scan-exception may suppress only REVIEW/RISK, never an ERROR (F8 fix).
  local tier; tier="$(rule_tier "$rule")"
  if [ "$tier" != "ERROR" ] && is_excepted "$match"; then
    return 0
  fi
  # Count every violation. Printing is display-only and capped at MAX_PRINT so a
  # noisy file can't flood the terminal — but the count (and exit code) is complete.
  case "$tier" in
    ERROR)  ERRORS=$((ERRORS + 1));;
    RISK)   RISKS=$((RISKS + 1));;
    *)      REVIEWS=$((REVIEWS + 1));;
  esac
  VIOLATIONS=$((VIOLATIONS + 1))
  if [ "$PRINTED" -lt "$MAX_PRINT" ]; then
    echo -e "  ${RED}✘${RESET} ${BOLD}${file}:${line}${RESET}  [${tier}]"
    echo -e "    Rule:  ${rule}"
    echo -e "    Found: ${YELLOW}${match}${RESET}"
    echo -e "    Fix:   ${fix}\n"
    PRINTED=$((PRINTED + 1))
    if [ "$PRINTED" -eq "$MAX_PRINT" ]; then
      echo -e "  ${YELLOW}… detail cap reached (${MAX_PRINT} shown). Remaining violations are still counted in the total.${RESET}\n"
    fi
  fi
}

for FILE in "${FILES[@]}"; do
  [ -f "$FILE" ] || continue

  # ── 1. Gradient on interactive elements ────────────────────────────────────
  # Floor-fades, scrims, and scroll masks (gradients ending in transparent /
  # zero-alpha) are skill-taught craft, not button gradients — exempt them.
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE 'transparent|rgba\([0-9, .]*[, ]0(\.0*)?\)|\bmask|scrim|floor-?fade|fade-?out'; then
      continue
    fi
    context=$(sed -n "$((lineno > 5 ? lineno - 5 : 1)),${lineno}p" "$FILE" | grep -iE 'button|\.btn|cta|\[role="button"\]|submit' || true)
    if [ -n "$context" ]; then
      flag "$FILE" "$lineno" "No gradient on interactive elements" "$match" "Replace with flat solid color: background: var(--color-primary)"
    fi
  done < <(grep -n "linear-gradient\|radial-gradient" "$FILE" 2>/dev/null || true)

  # ── 2. Oversized border radius on card/container elements (> 16px) ─────────
  # Parse the border-radius value itself — not the first Npx on the line
  # (which may be padding or margin).
  while IFS=: read -r lineno match; do
    px=$(echo "$match" | sed -nE 's/.*[bB]order-?[rR]adius[^:]*:[[:space:]]*['"'"'"]?([0-9]+)px.*/\1/p' | head -1 || true)
    if [ -n "$px" ] && [ "$px" -gt 16 ] 2>/dev/null; then
      context=$(sed -n "$((lineno > 3 ? lineno - 3 : 1)),${lineno}p" "$FILE" | grep -iE 'card|modal|sheet|panel|container|\.box|section' || true)
      if [ -n "$context" ]; then
        flag "$FILE" "$lineno" "Border radius > 16px on card/container" "$match" "Use --radius-md (12px) or --radius-lg (16px) max for cards"
      fi
    fi
  done < <(grep -n "border-radius" "$FILE" 2>/dev/null || true)

  # ── 3. Colored side-stripe borders (border-left/right > 1px with color) ────
  while IFS=: read -r lineno match; do
    px=$(echo "$match" | grep -oE '[0-9]+px' | head -1 | tr -d 'px' || true)
    if [ -n "$px" ] && [ "$px" -gt 1 ] 2>/dev/null; then
      flag "$FILE" "$lineno" "Colored side-stripe border" "$match" "Use background tint, full border, or leading icon instead"
    fi
  done < <(grep -n "border-left\|border-right" "$FILE" 2>/dev/null | grep -v "none\|0px\|0 " || true)

  # ── 4. Ghost-card pattern — border + wide box-shadow on nearby lines ────────
  while IFS=: read -r lineno match; do
    start=$((lineno > 5 ? lineno - 5 : 1))
    end=$((lineno + 10))
    block=$(sed -n "${start},${end}p" "$FILE" 2>/dev/null || true)
    has_border=$(echo "$block" | grep -E '^[^/]*border\s*:' || true)
    has_shadow=$(echo "$block" | grep -oE 'box-shadow[^;]+' | grep -oE '[0-9]+px' | sort -n | tail -1 || true)
    if [ -n "$has_border" ] && [ -n "$has_shadow" ]; then
      blur_px=$(echo "$has_shadow" | tr -d 'px')
      if [ -n "$blur_px" ] && [ "$blur_px" -ge 16 ] 2>/dev/null; then
        flag "$FILE" "$lineno" "Ghost-card pattern (border + wide shadow)" "$match" "Pick one: solid border OR shadow ≤ 8px blur"
      fi
    fi
  done < <(grep -n "box-shadow" "$FILE" 2>/dev/null || true)

  # ── 5. Gradient text ────────────────────────────────────────────────────────
  while IFS=: read -r lineno match; do
    flag "$FILE" "$lineno" "Gradient text (absolute ban)" "$match" "Use solid color. Emphasize with font-weight or size."
  done < <(grep -n "background-clip.*text\|webkit-background-clip.*text" "$FILE" 2>/dev/null || true)

  # ── 6. Warm/cream background tokens by name ─────────────────────────────────
  while IFS=: read -r lineno match; do
    flag "$FILE" "$lineno" "Warm/cream background token" "$match" "Use a true off-white or brand-tinted neutral instead"
  done < <(grep -in "\-\-paper\|\-\-cream\|\-\-sand\|\-\-bone\|\-\-linen\|\-\-parchment\|\-\-ivory\|\-\-warm-white" "$FILE" 2>/dev/null || true)

  # ── 7. Generic font as sole primary font ────────────────────────────────────
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE "font-family\s*:\s*['\"]?(Inter|Roboto|Arial|Geist)['\"]?\s*;"; then
      flag "$FILE" "$lineno" "Generic font as primary design choice" "$match" "Add a distinctive display font. Inter/Roboto/Arial/Geist are fallbacks, not a design decision."
    fi
  done < <(grep -in "font-family" "$FILE" 2>/dev/null || true)

  # ── 7b. Saturated display/mono font (AI training-data default) ──────────────
  # These are the fonts an unguided model reaches for by reflex. See
  # impeccable/reference/brand.md "reflex-reject list". Flagged only when set as
  # an actual font-family (not merely a fallback further down the stack).
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE "font-family\s*:\s*['\"]?(Space Grotesk|JetBrains Mono|Space Mono|Sora)['\"]?"; then
      flag "$FILE" "$lineno" "Saturated AI-default font (Space Grotesk / JetBrains Mono family)" "$match" "Training-data default that reads as 'AI made this'. Pick a distinctive face for the brand's voice; see impeccable brand.md reflex-reject list."
    fi
  done < <(grep -in "font-family" "$FILE" 2>/dev/null || true)

  # ── 7c. Acid accent on near-black (dev-tool-brutalist AI lane) ──────────────
  # The single most common unguided-model shape: near-black surface + one acid
  # accent (chartreuse/lime, electric-cyan, hot-magenta). Heuristic: flag the
  # common acid-accent hexes; near-black grounds are the usual companion.
  while IFS=: read -r lineno match; do
    flag "$FILE" "$lineno" "Acid accent (dev-tool-brutalist AI lane)" "$match" "Chartreuse/lime/electric-cyan neon on near-black is a saturated AI default. If the brand isn't a literal terminal/CI tool, choose an accent from its own voice."
  done < <(grep -inE "#c6f24e|#ccff00|#c1ff00|#d4ff00|#adff2f|#00ff[0-9a-f]{2}|#39ff14|#0aff|#ff00ff|#e5ff[0-9a-f]{2}" "$FILE" 2>/dev/null || true)

  # ── 8. Bounce / elastic easing ──────────────────────────────────────────────
  while IFS=: read -r lineno match; do
    flag "$FILE" "$lineno" "Bounce/elastic easing (absolute ban)" "$match" "Use ease-out-quart/quint/expo. No spring physics on UI elements."
  done < <(grep -in "bounce\|elastic\|spring\|wiggle\|wobble" "$FILE" 2>/dev/null | grep -iE "animation|transition|timing-function|keyframe" || true)

  # Also catch cubic-bezier overshoot (4th value > 1 or < 0)
  while IFS=: read -r lineno match; do
    # Extract the 4th parameter of cubic-bezier
    fourth=$(echo "$match" | grep -oE 'cubic-bezier\s*\([^)]+\)' | grep -oE '[-0-9.]+\s*\)' | grep -oE '[-0-9.]+' || true)
    if [ -n "$fourth" ]; then
      # Check if it's outside 0-1 range (overshoot = bounce)
      if echo "$fourth" | awk '{exit ($1 >= 0 && $1 <= 1) ? 0 : 1}' 2>/dev/null; then
        : # within range, ok
      else
        flag "$FILE" "$lineno" "Bounce easing via cubic-bezier overshoot" "$match" "Use ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1)"
      fi
    fi
  done < <(grep -n "cubic-bezier" "$FILE" 2>/dev/null || true)

  # ── 9. Layout property animation ────────────────────────────────────────────
  while IFS=: read -r lineno match; do
    # Flag if transition is animating layout properties
    if echo "$match" | grep -qiE "transition\s*:[^;]*(width|height|padding|margin|top|left|right|bottom)"; then
      flag "$FILE" "$lineno" "Layout property animation" "$match" "Animate transform/opacity instead. For height: grid-template-rows: 0fr → 1fr"
    fi
  done < <(grep -in "transition" "$FILE" 2>/dev/null || true)

  # Also catch @keyframes animating layout props
  while IFS=: read -r lineno match; do
    flag "$FILE" "$lineno" "Layout property animation in @keyframes" "$match" "Animate transform/opacity instead to avoid layout thrash"
  done < <(grep -n "from\|to\|[0-9]\+%" "$FILE" 2>/dev/null | grep -iE "^\s*(width|height|padding|margin)\s*:" || true)

  # ── 10. Image hover scale/rotate ────────────────────────────────────────────
  # Scope: images under :hover only. :active press-states (scale on tap) and
  # SVG geometry transforms (progress rings, chart rotation) are legitimate.
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE ':active|active:|<svg|<path|<circle|<rect|<g |stroke-|viewBox'; then
      continue
    fi
    context=$(sed -n "$((lineno > 5 ? lineno - 5 : 1)),${lineno}p" "$FILE" || true)
    if echo "$context" | grep -qiE ':active|<svg|<path|<circle|viewBox'; then
      continue
    fi
    hoverctx=$(echo "$context" | grep -iE ':hover|hover:' || true)
    imgctx=$(echo "$context" | grep -iE '\bimg\b|image|photo|thumb|picture|background-image' || true)
    if [ -n "$hoverctx" ] && [ -n "$imgctx" ]; then
      flag "$FILE" "$lineno" "Image scale/rotate on hover" "$match" "Let imagery sit still. Use a color overlay or caption reveal instead."
    fi
  done < <(grep -n "transform.*scale\|transform.*rotate\|scale(\|rotate(" "$FILE" 2>/dev/null || true)

  # ── 11. Numbered section markers (01/02/03 pattern) ─────────────────────────
  # Date/day/calendar numerals ("08", "09" in a check-in strip) are data,
  # not editorial scaffold — exempt them by context.
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE 'date|day|time|calendar|month|week|clock'; then
      continue
    fi
    context=$(sed -n "$((lineno > 3 ? lineno - 3 : 1)),${lineno}p" "$FILE" | grep -iE 'date|day|calendar|month|week' || true)
    if [ -n "$context" ]; then
      continue
    fi
    flag "$FILE" "$lineno" "Numbered section markers (AI tell)" "$match" "Remove unless content is a true sequence. Use structural hierarchy instead."
  done < <(grep -nE '>\s*0[1-9]\.?\s*<|content:\s*["'"'"']0[1-9]' "$FILE" 2>/dev/null || true)

  # ── 12. All-caps on long text blocks ────────────────────────────────────────
  while IFS=: read -r lineno match; do
    # Only flag on elements that typically contain body text, not labels
    context=$(sed -n "$((lineno > 2 ? lineno - 2 : 1)),${lineno}p" "$FILE" | grep -iE 'p\s*{|\.body|\.text|\.content|\.description|\.prose' || true)
    if [ -n "$context" ]; then
      flag "$FILE" "$lineno" "All-caps on body text" "$match" "Reserve text-transform: uppercase for short labels (4-6 words max)."
    fi
  done < <(grep -n "text-transform\s*:\s*uppercase" "$FILE" 2>/dev/null || true)

  # ── 13. Marketing buzzwords in UI copy ──────────────────────────────────────
  BUZZWORDS="supercharge\|supercharges\|supercharging\|streamline\|streamlines\|streamlining\|enterprise-grade\|world-class\|next-generation\|game-changing\|cutting-edge\|state-of-the-art\|revolutionary\|empower\|empowers"
  while IFS=: read -r lineno match; do
    # Only flag in JSX/HTML string content, not in comments or class names
    if echo "$match" | grep -qvE '^\s*//' && echo "$match" | grep -qvE 'className|class='; then
      flag "$FILE" "$lineno" "Marketing buzzword in UI copy" "$match" "Replace with specific, literal description of what the product does."
    fi
  done < <(grep -in "$BUZZWORDS" "$FILE" 2>/dev/null || true)

  # ── 14. Em-dash overuse (more than 2 per line) ──────────────────────────────
  while IFS=: read -r lineno match; do
    # Count em-dashes in the line
    count=$(echo "$match" | grep -o "—\|&mdash;\|&#8212;" | wc -l || true)
    if [ "$count" -ge 3 ] 2>/dev/null; then
      flag "$FILE" "$lineno" "Em-dash overuse (AI copy tell)" "$match" "Use commas, colons, periods, or parentheses instead. Max 2 em-dashes per text block."
    fi
  done < <(grep -n "—\|&mdash;\|&#8212;" "$FILE" 2>/dev/null || true)

  # ── 15. Translucent content-surface fills ───────────────────────────────────
  # Content cards/panels/rows must be opaque. Native chrome (tab bar, sheet,
  # overlay/scrim/backdrop) is exempt. Project-specific exemptions go in
  # scan-exceptions.conf.
  while IFS=: read -r lineno match; do
    # Exempt native chrome by context on the same line.
    if echo "$match" | grep -qiE 'tab-?bar|nav|sheet|overlay|scrim|backdrop'; then
      continue
    fi
    # Require a content-surface context (card/panel/row/box) on the line.
    if echo "$match" | grep -qiE 'card|panel|\.row|surface|\bbox\b|container'; then
      flag "$FILE" "$lineno" "Translucent content-surface fill" "$match" "Content surfaces are opaque #FFFFFF. Native chrome (tab bar/sheet) is exempt."
    fi
  done < <(grep -niE 'background[^;]*(rgba\(255, ?255, ?255, ?0?\.[0-9]|hsla\([^)]*, ?0?\.[0-9])' "$FILE" 2>/dev/null || true)

  # ── 16. Gradient / glow page background ─────────────────────────────────────
  # Page canvas must be one flat solid colour. Flag gradient/glow behind content
  # and glow/ambient/body-gradient tokens. Committed immersive-screen gradients
  # (documented in DESIGN.md) are registered in scan-exceptions.conf, not here.
  while IFS=: read -r lineno match; do
    # Skip comment-only lines (JS //, /* * , CSS /* */) — they name tokens in prose.
    if echo "$match" | grep -qE '^\s*(//|/?\*)'; then
      continue
    fi
    if echo "$match" | grep -qiE '(body|#root|\.app|\.screen|\.page|canvas)[^;{]*(linear|radial)-gradient'; then
      flag "$FILE" "$lineno" "Gradient/glow page background" "$match" "The canvas is one flat solid colour — use the project's canvas/surface token."
    elif echo "$match" | grep -qiE '\-\-[a-z-]*glow-|gradient-body|gradient-app|gradient-ambient|\.ambient'; then
      flag "$FILE" "$lineno" "Glow/ambient/body-gradient background token" "$match" "Glows and body/app gradients are banned as canvas. Use the flat canvas token, or register a documented exception in scan-exceptions.conf."
    fi
  done < <(grep -niE 'gradient|glow|\.ambient' "$FILE" 2>/dev/null || true)

  # ── 16b. Gradient canvas via CSS custom property (Gap B) ────────────────────
  # A gradient hidden in a var (--x: linear-gradient(...)) then applied with
  # background: var(--x) on a page/screen element must also be caught.
  GRADIENT_VARS=$(grep -oE '\-\-[a-zA-Z0-9_-]+[[:space:]]*:[[:space:]]*(linear|radial)-gradient' "$FILE" 2>/dev/null | grep -oE '^\-\-[a-zA-Z0-9_-]+' | sort -u || true)
  for gv in $GRADIENT_VARS; do
    while IFS=: read -r lineno match; do
      context=$(sed -n "$((lineno > 6 ? lineno - 6 : 1)),${lineno}p" "$FILE" | grep -iE 'body|#root|\.app\b|\.screen|\.page|canvas' || true)
      if [ -n "$context" ]; then
        flag "$FILE" "$lineno" "Gradient canvas via custom property (${gv})" "$match" "${gv} resolves to a gradient. The canvas is one flat solid colour."
      fi
    done < <(grep -nE "background[^;]*var\(${gv}\)" "$FILE" 2>/dev/null || true)
  done

  # ── 17. Coloured / glow elevation ───────────────────────────────────────────
  # Elevation shadows are neutral (near-grey channels). Flag brand-tinted
  # shadows (RGB channel spread > 40 = a hue, not a grey) and glow-as-lift.
  # Documented exceptions (e.g. a committed warm selected-state lift) go in
  # scan-exceptions.conf.
  while IFS=: read -r lineno match; do
    # Only consider lines that actually declare a shadow.
    echo "$match" | grep -qiE 'box-?shadow' || continue
    if echo "$match" | grep -qiE 'box-?shadow[^;]*\-\-[a-z-]*glow-'; then
      flag "$FILE" "$lineno" "Glow used as elevation" "$match" "Elevation is a neutral shadow from the elevation ramp, never a glow."
      continue
    fi
    # Neutrality test: near-equal RGB channels. Spread > 40 = brand-tinted.
    rgb=$(echo "$match" | grep -oE 'box-?shadow[^;]*' | grep -oE 'rgba?\([0-9]+, ?[0-9]+, ?[0-9]+' | head -1 | grep -oE '[0-9]+' | tr '\n' ' ' || true)
    if [ -n "$rgb" ]; then
      set -- $rgb
      r=$1; g=$2; b=$3
      max=$r; min=$r
      for v in "$g" "$b"; do
        if [ "$v" -gt "$max" ]; then max=$v; fi
        if [ "$v" -lt "$min" ]; then min=$v; fi
      done
      if [ $((max - min)) -gt 40 ]; then
        flag "$FILE" "$lineno" "Brand-tinted elevation shadow" "$match" "Elevation shadows are neutral (near-grey rgba). Use the neutral elevation ramp, or register a documented exception in scan-exceptions.conf."
      fi
    fi
  done < <(grep -niE 'box-?shadow' "$FILE" 2>/dev/null || true)

  # ── 18. Offsetless glow shadows (0 0 blur) ──────────────────────────────────
  # A shadow needs a vertical offset (light from above). box-shadow: 0 0 Npx is
  # a glow, banned as elevation. Focus rings (0 0 0 Npx spread-only) are exempt.
  while IFS=: read -r lineno match; do
    # Exempt focus rings: 0 0 0 Npx (zero blur, spread-only)
    if echo "$match" | grep -qE 'box-shadow[^;]*:\s*(inset\s+)?0(px)? 0(px)? 0(px)? [0-9]'; then
      continue
    fi
    # Exempt focus/ring context
    if echo "$match" | grep -qiE 'focus|ring|outline'; then
      continue
    fi
    if echo "$match" | grep -qE 'box-shadow[^;]*:\s*(inset\s+)?0(px)? 0(px)? [1-9][0-9]*px'; then
      flag "$FILE" "$lineno" "Offsetless glow shadow" "$match" "Shadows need a vertical offset (y ≥ blur ÷ 2). Use the --elev ramp, e.g. 0 4px 12px."
    fi
  done < <(grep -niE 'box-?shadow' "$FILE" 2>/dev/null || true)

  # ── 19. Glassmorphism on content surfaces ───────────────────────────────────
  # backdrop-filter blur belongs on native chrome overlaying scroll (nav/tab
  # bar, sheet) — never on content cards/panels/rows.
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE 'tab-?bar|nav|sheet|toast|snackbar|scrim|backdrop-color'; then
      continue
    fi
    context=$(sed -n "$((lineno > 5 ? lineno - 5 : 1)),${lineno}p" "$FILE" | grep -iE 'card|panel|\.row|list|container|\bbox\b' || true)
    if [ -n "$context" ]; then
      flag "$FILE" "$lineno" "Glassmorphism on content surface" "$match" "Blur+translucency only on chrome overlaying scroll (nav/tab bar, sheet). Content cards are opaque."
    fi
  done < <(grep -niE 'backdrop-filter' "$FILE" 2>/dev/null || true)

  # ── 20. Literal high z-index ────────────────────────────────────────────────
  while IFS=: read -r lineno match; do
    zvals=$(echo "$match" | grep -oiE 'z-?index[^0-9-]*[0-9]+' | grep -oE '[0-9]+' || true)
    for zval in $zvals; do
      if [ "$zval" -ge 999 ] 2>/dev/null; then
        flag "$FILE" "$lineno" "Literal high z-index" "$match" "Use the z-index token ramp (content < chrome < dropdown < modal < toast). No 999+ literals."
        break
      fi
    done
  done < <(grep -niE 'z-?index' "$FILE" 2>/dev/null || true)

  # ── 21. Clickable div/span ──────────────────────────────────────────────────
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE 'role=["'"'"']?(button|link)|<button|<a[ >]|tabIndex'; then
      continue
    fi
    if echo "$match" | grep -qE '<(div|span)[^>]*onClick'; then
      flag "$FILE" "$lineno" "Clickable div/span" "$match" "Use a real <button>/<a> — focus, keyboard activation, and semantics come free."
    fi
  done < <(grep -nE '<(div|span)[^>]*onClick' "$FILE" 2>/dev/null || true)

  # ── 22. Icon-only button without aria-label (heuristic, same-line only) ─────
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qiE 'aria-label|aria-labelledby'; then
      continue
    fi
    # Only flag when the button visibly contains just an icon on this line.
    if echo "$match" | grep -qE '<button[^>]*>[[:space:]]*<(svg|img|[A-Z][A-Za-z]*Icon)'; then
      flag "$FILE" "$lineno" "Icon-only button without aria-label" "$match" "Add aria-label — an unlabelled icon button doesn't exist for screen readers."
    fi
  done < <(grep -nE '<button' "$FILE" 2>/dev/null || true)

  # ── 23. Emoji as chrome icons ───────────────────────────────────────────────
  # Emoji is banned in chrome (buttons, nav/tab bar, toolbars, notification
  # icons). Content emoji (mood categories, posts, labels) is a legitimate,
  # documented JP consumer convention and is NOT flagged — detection requires a
  # chrome context on the line. Limited to 4-byte emoji (U+1F000+, the 😀🔔👥
  # class); ✓/→-class symbols are ignored to avoid false positives.
  EMOJI_BYTES=$'\xf0\x9f'
  while IFS=: read -r lineno match; do
    if echo "$match" | LC_ALL=C grep -qE "<[A-Za-z]*[Bb]utton[^>]*>[^<]*${EMOJI_BYTES}"; then
      flag "$FILE" "$lineno" "Emoji as chrome icon (button label)" "$match" "Chrome uses the SVG icon set; emoji stays in content (rules.md → Emoji as system/chrome icons)."
      continue
    fi
    if echo "$match" | grep -qiE 'tab-?bar|<nav\b|navbar|toolbar|menu-?item|notif[a-z-]*-?icon|role=["'"'"']?(button|tab|menuitem)'; then
      flag "$FILE" "$lineno" "Emoji as chrome icon" "$match" "Chrome uses the SVG icon set; emoji stays in content (rules.md → Emoji as system/chrome icons)."
    fi
  done < <(LC_ALL=C grep -n "$EMOJI_BYTES" "$FILE" 2>/dev/null || true)

  # ── 24. Broken / placeholder image src ──────────────────────────────────────
  # An <img> with an empty or placeholder src ships as a broken-image box.
  # Only same-line empty/placeholder values are flagged (multi-line tags and
  # dynamic src={expr} are left alone — no false positives on JSX).
  while IFS=: read -r lineno match; do
    if echo "$match" | grep -qE 'src=["'"'"'][[:space:]]*["'"'"']|src=["'"'"']#["'"'"']|src=["'"'"'](placeholder|TODO|FIXME|about:blank)'; then
      flag "$FILE" "$lineno" "Broken/placeholder image src" "$match" "Use a real image, a generated asset, or remove the tag — empty src ships a broken-image box."
    fi
  done < <(grep -n '<img' "$FILE" 2>/dev/null || true)

  # ── 25. Override-citation integrity ─────────────────────────────────────────
  # A code comment that cites a DESIGN.md override ("per DESIGN.md override
  # 2026-07-11", "override: gradient-cta", "id: gradient-cta") must resolve to a
  # real entry in the DESIGN.md override log. A bogus citation launders a Tier-2
  # pattern past review — the impeccable pass found a gradient CTA citing a
  # non-existent 2026-07-11 override. Mechanises the scan-exceptions↔override-log
  # governance for inline code citations. Verified only when a DESIGN.md exists
  # (nothing to resolve against otherwise).
  if [ -n "$DESIGN_MD" ]; then
    while IFS=: read -r lineno match; do
      # comment context only
      echo "$match" | grep -qE '(//|/\*|\*/|[[:space:]]\*[[:space:]]|#|<!--)' || continue
      # a citation references the design doc or uses the id:/override: convention
      echo "$match" | grep -qiE 'design[-_]?system|design\.md|\bid:[[:space:]]*[a-z0-9-]|override:' || continue
      cite=""
      if echo "$match" | grep -qiE '\bid:[[:space:]]*[a-z0-9-]{3,}'; then
        cite=$(echo "$match" | sed -nE 's/.*[iI][dD]:[[:space:]]*([a-zA-Z0-9-]{3,}).*/\1/p' | head -1)
      elif echo "$match" | grep -qiE 'override[s]?:?[[:space:]]+[a-z][a-z0-9-]{2,}'; then
        cite=$(echo "$match" | sed -nE 's/.*[oO]verride[s]?:?[[:space:]]+([a-zA-Z][a-zA-Z0-9-]{2,}).*/\1/p' | head -1)
      fi
      dcite=$(echo "$match" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
      if [ -n "$cite" ] && ! grep -qiF "$cite" "$DESIGN_MD"; then
        flag "$FILE" "$lineno" "Override citation not in DESIGN.md override log" "$match" "Cited override '$cite' has no matching entry in ${DESIGN_MD##*/} override log. Add the entry, fix the citation, or remove the pattern."
      elif [ -n "$dcite" ] && ! grep -qF "$dcite" "$DESIGN_MD"; then
        flag "$FILE" "$lineno" "Override citation not in DESIGN.md override log" "$match" "Cited override date '$dcite' has no matching entry in ${DESIGN_MD##*/} override log. Add the entry, fix the citation, or remove the pattern."
      fi
    done < <(grep -niE 'override' "$FILE" 2>/dev/null || true)
  fi

  # ── 26. Semantic-palette leak — meaning-carrying ramp used for decoration ────
  # The semantic/index ramp (--index-*, --status-*, --semantic-*, --category-*, or
  # a project-declared ramp) exists to *mean* something. Using it in a border /
  # accent stripe / box-shadow — a decorative slot that encodes nothing — corrupts
  # the signalling layer. This is a Tier-1 correctness failure (ERROR), not a
  # waivable Tier-2 gate, so scan-exceptions cannot suppress it.
  # A project may extend the ramp-name pattern via a "# semantic-ramp: <regex>"
  # line in scan-exceptions.conf (read below as SEMANTIC_RAMP_RE).
  SEMANTIC_RAMP_RE='\-\-(index|status|semantic|category|meaning)-'
  if [ -f "$ROOT/scan-exceptions.conf" ]; then
    _extra=$(grep -iE '^[[:space:]]*#[[:space:]]*semantic-ramp:' "$ROOT/scan-exceptions.conf" 2>/dev/null \
      | sed -E 's/^[[:space:]]*#[[:space:]]*semantic-ramp:[[:space:]]*//' | head -1 || true)
    [ -n "$_extra" ] && SEMANTIC_RAMP_RE="${SEMANTIC_RAMP_RE}|${_extra}"
  fi
  while IFS=: read -r lineno match; do
    # Only decorative slots: a border / accent stripe / shadow declaration.
    echo "$match" | grep -qiE 'border(-top|-right|-bottom|-left)?[[:space:]]*:|box-?shadow[[:space:]]*:|outline[[:space:]]*:' || continue
    # …carrying a semantic-ramp token.
    echo "$match" | grep -qiE "var\([[:space:]]*(${SEMANTIC_RAMP_RE})" || continue
    # Chips/badges/pills legitimately carry a status colour — but as a *fill*, not
    # a border; a bordered chip drawing its ring from the ramp is still a leak, so
    # only exempt when the same line is clearly a fill context, handled by grep of
    # 'background'. Here we are already on a border/shadow line, so no fill exempt.
    flag "$FILE" "$lineno" "Semantic-palette leak (meaning ramp used as decoration)" "$match" "The semantic/index ramp must carry real encoded meaning, never decoration. Use the neutral ramp, surface, or weight for borders/accents; reserve the semantic ramp for status/category fills. Tier-1 — not overridable."
  done < <(grep -niE "var\([[:space:]]*(${SEMANTIC_RAMP_RE})" "$FILE" 2>/dev/null || true)

  # ── 27. Decorative accent border/stripe (advisory, RISK) ────────────────────
  # Lower-confidence: a saturated coloured border-top/left stripe (2–4px) on a
  # card/section, regardless of token source. Surfaces for sign-off; not a hard
  # fail on its own (a real bordered callout may be legitimate).
  while IFS=: read -r lineno match; do
    px=$(echo "$match" | grep -oE '[0-9]+px' | head -1 | tr -d 'px' || true)
    [ -n "$px" ] || continue
    if [ "$px" -ge 2 ] && [ "$px" -le 4 ] 2>/dev/null; then
      # Skip neutral hairline tokens / greys (not an accent) and focus contexts.
      echo "$match" | grep -qiE 'var\([[:space:]]*\-\-border|#(fff|000|[0-9a-f]{3}\b)|transparent|currentcolor|focus|ring' && continue
      context=$(sed -n "$((lineno > 3 ? lineno - 3 : 1)),${lineno}p" "$FILE" | grep -iE 'card|panel|section|\.box|container|phase|roadmap' || true)
      if [ -n "$context" ]; then
        flag "$FILE" "$lineno" "Decorative accent border (advisory) — encodes no data?" "$match" "A coloured top/side accent stripe reads as decoration unless it maps to real status. Carry order/hierarchy with structure/weight/surface, or map + document it."
      fi
    fi
  done < <(grep -niE 'border-(top|left)[[:space:]]*:' "$FILE" 2>/dev/null || true)

done

# ── Summary ────────────────────────────────────────────────────────────────────

echo "────────────────────────────────────────"
if [ "$VIOLATIONS" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}✔ Static scan passed — no detectable prohibited patterns.${RESET}"
  echo -e "  ${BOLD}This is not visual or accessibility approval.${RESET} The scanner is regex-only: it"
  echo -e "  cannot judge contrast, coherence, hierarchy, or context. Run @skills/ui-design-review"
  echo -e "  (visual review) before sign-off."
  exit 0
fi

echo -e "  ${BOLD}Tiers:${RESET} ${RED}ERROR ${ERRORS}${RESET} (Tier-1 defects) · ${YELLOW}REVIEW ${REVIEWS}${RESET} (Tier-2, need a documented rationale) · RISK ${RISKS} (Tier-3, advisory)"
if [ "$TIERED" -eq 1 ]; then
  if [ "$ERRORS" -gt 0 ] || [ "$REVIEWS" -gt 0 ]; then
    echo -e "${RED}${BOLD}✘ NEEDS FIXES (--tiered) — ${ERRORS} ERROR + ${REVIEWS} REVIEW.${RESET}"
    echo -e "  ERROR = correctness/a11y; REVIEW = a Tier-2 pattern with no documented override. Run @skills/ui-design-review."
    exit 1
  else
    echo -e "${YELLOW}${BOLD}~ RISK-only (${RISKS}) — passes --tiered; advisory, review recommended.${RESET}"
    echo -e "  Tier-3 co-occurrence tells are not a hard failure alone. Run @skills/ui-design-review to weigh them."
    exit 0
  fi
else
  echo -e "${RED}${BOLD}✘ NEEDS FIXES — ${VIOLATIONS} violation(s) found.${RESET}"
  echo -e "  Resolve before merging (or pass --tiered to gate on ERROR/REVIEW only). Run @skills/ui-design-review for full visual review."
  exit 1
fi
