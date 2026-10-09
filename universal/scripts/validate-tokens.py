#!/usr/bin/env python3
"""
validate-tokens.py — token-graph coherence validator (project-agnostic).

The engine behind ui-design-system. Reads a project's tokens.json (and, if present,
DESIGN.md) and computes the *relationships between* tokens that regex-over-components can
never see: contrast pairs (incl. small-text badge/count labels on an accent fill),
semantic-colour distinctness, selection-vs-action distance,
neutral-ramp derivation, support-accent permission, tint-to-ground value steps, scale ratios,
elevation coherence. Math lives here,
not in a prompt — zero effective-load cost, deterministic, CI-gradeable.

It is intentionally schema-tolerant: it flattens whatever nesting a project's tokens.json
uses, resolves {dotted.path} references, and classifies colours into roles by key-name
heuristics. It does not require the template schema. When it cannot determine a role it
reports SKIP rather than guessing — a missing input is a finding, not a crash.

Usage:
  validate-tokens.py [PROJECT_DIR]         # defaults to cwd; finds tokens.json + DESIGN.md
  validate-tokens.py --tokens PATH [--design PATH]
  validate-tokens.py [PROJECT_DIR] --json  # machine-readable report on stdout
  validate-tokens.py [PROJECT_DIR] --strict # require full coverage of the core relationships
                                            # (unresolved required role = FAIL, not SKIP)

Exit codes (for CI / gates):
  0  no FAILs (WARN/INFO allowed)
  1  at least one FAIL (a broken relationship — e.g. sub-threshold contrast)
  2  usage / parse / missing-input error
"""

import sys, os, json, re, math

# ─────────────────────────────────────────────────────────────────────────────
# Colour parsing + math
# ─────────────────────────────────────────────────────────────────────────────

HEX_RE = re.compile(r'#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b')
RGB_RE = re.compile(r'rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)', re.I)

def _hex_to_rgb(h):
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(c * 2 for c in h)
    r = int(h[0:2], 16) / 255.0
    g = int(h[2:4], 16) / 255.0
    b = int(h[4:6], 16) / 255.0
    return (r, g, b)

def extract_colors(s):
    """Return a list of (r,g,b) tuples found in a string. Gradients yield all stops."""
    if not isinstance(s, str):
        return []
    out = []
    for m in HEX_RE.finditer(s):
        out.append(_hex_to_rgb(m.group(0)))
    for m in RGB_RE.finditer(s):
        out.append((float(m.group(1)) / 255.0, float(m.group(2)) / 255.0, float(m.group(3)) / 255.0))
    return out

def is_gradient(s):
    return isinstance(s, str) and 'gradient' in s.lower()

def _lin(c):
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

def rel_lum(rgb):
    r, g, b = (_lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(c1, c2):
    l1, l2 = rel_lum(c1), rel_lum(c2)
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)

def _rgb_to_xyz(rgb):
    r, g, b = (_lin(c) for c in rgb)
    x = r * 0.4124 + g * 0.3576 + b * 0.1805
    y = r * 0.2126 + g * 0.7152 + b * 0.0722
    z = r * 0.0193 + g * 0.1192 + b * 0.9505
    return (x, y, z)

def _f(t):
    return t ** (1 / 3) if t > 0.008856 else (7.787 * t + 16 / 116)

def rgb_to_lab(rgb):
    x, y, z = _rgb_to_xyz(rgb)
    xn, yn, zn = 0.95047, 1.0, 1.08883
    fx, fy, fz = _f(x / xn), _f(y / yn), _f(z / zn)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))

def deltaE(c1, c2):
    """CIE76 ΔE — perceptual distance. ~2.3 = JND; >15 = clearly different."""
    l1 = rgb_to_lab(c1); l2 = rgb_to_lab(c2)
    return math.sqrt(sum((a - b) ** 2 for a, b in zip(l1, l2)))

def rgb_to_hsl(rgb):
    r, g, b = rgb
    mx, mn = max(rgb), min(rgb)
    l = (mx + mn) / 2
    if mx == mn:
        return (0.0, 0.0, l)
    d = mx - mn
    s = d / (2 - mx - mn) if l > 0.5 else d / (mx + mn)
    if mx == r:
        h = (g - b) / d + (6 if g < b else 0)
    elif mx == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    return (h * 60, s, l)

def hue_dist(h1, h2):
    d = abs(h1 - h2) % 360
    return min(d, 360 - d)

def lab_chroma(rgb):
    """Perceptual chroma (Lab a,b magnitude). Robust neutrality test — unlike HSL
    saturation, it does not spike on very pale or very dark tints."""
    _, a, b = rgb_to_lab(rgb)
    return math.sqrt(a * a + b * b)

def lab_hue(rgb):
    _, a, b = rgb_to_lab(rgb)
    return math.degrees(math.atan2(b, a)) % 360

def avg_rgb(colors):
    n = len(colors)
    return tuple(sum(c[i] for c in colors) / n for i in range(3))

# ─────────────────────────────────────────────────────────────────────────────
# Token flattening + reference resolution
# ─────────────────────────────────────────────────────────────────────────────

def flatten(obj, prefix=''):
    """Flatten nested dict/list into {dotted.path: leaf}. Leaves are str/num/bool."""
    out = {}
    if isinstance(obj, dict):
        for k, v in obj.items():
            out.update(flatten(v, f'{prefix}.{k}' if prefix else str(k)))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            out.update(flatten(v, f'{prefix}.{i}'))
    else:
        out[prefix] = obj
    return out

REF_RE = re.compile(r'\{([^}]+)\}')

def resolve_refs(flat):
    """Resolve {a.b.c} references against the flattened map (best-effort, 5 passes)."""
    resolved = dict(flat)
    for _ in range(5):
        changed = False
        for path, val in list(resolved.items()):
            if not isinstance(val, str) or '{' not in val:
                continue
            def sub(m):
                key = m.group(1).strip()
                for cand in (key, key + '.value', key.replace('.value', '')):
                    if cand in resolved and isinstance(resolved[cand], (str, int, float)):
                        return str(resolved[cand])
                return m.group(0)
            new = REF_RE.sub(sub, val)
            if new != val:
                resolved[path] = new
                changed = True
        if not changed:
            break
    return resolved

def color_entries(resolved):
    """List of {path, raw, colors, gradient} for every leaf that parses as colour(s)."""
    entries = []
    DESC = {'note', 'notes', 'description', 'desc', 'comment', 'doc', 'example', 'status', 'purpose'}
    for path, val in resolved.items():
        last = path.split('.')[-1]
        # Skip descriptive fields — prose notes often quote example hex values that must
        # NOT be treated as tokens (e.g. a "#1E9385 = 3.77:1" note beside a #2EB7A3 value).
        if last.startswith('_') or last.lower() in DESC:
            continue
        cols = extract_colors(val)
        if cols:
            entries.append({
                'path': path,
                'lpath': path.lower(),
                'raw': val,
                'colors': cols,
                'gradient': is_gradient(val),
            })
    return entries

def pick(entries, patterns, exclude=()):
    """Priority pick: for each pattern in order, return the shortest-path match not excluded."""
    excl = [re.compile(x, re.I) for x in exclude]
    for pat in patterns:
        p = re.compile(pat, re.I)
        matches = [e for e in entries
                   if p.search(e['lpath']) and not any(x.search(e['lpath']) for x in excl)]
        if matches:
            return sorted(matches, key=lambda e: len(e['path']))[0]
    return None

def pick_all(entries, patterns, exclude=()):
    excl = [re.compile(x, re.I) for x in exclude]
    pats = [re.compile(pat, re.I) for pat in patterns]
    seen, out = set(), []
    for e in entries:
        if e['path'] in seen:
            continue
        if any(x.search(e['lpath']) for x in excl):
            continue
        if any(pat.search(e['lpath']) for pat in pats):
            out.append(e); seen.add(e['path'])
    return out

# ─────────────────────────────────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────────────────────────────────

class Report:
    LEVELS = {'PASS': 0, 'INFO': 0, 'SKIP': 0, 'WARN': 1, 'FAIL': 2}
    COLORS = {'PASS': '\033[0;32m', 'FAIL': '\033[0;31m', 'WARN': '\033[1;33m',
              'INFO': '\033[0;36m', 'SKIP': '\033[0;90m'}
    RESET = '\033[0m'; BOLD = '\033[1m'

    def __init__(self):
        self.items = []

    def add(self, level, check, msg):
        self.items.append((level, check, msg))

    def worst(self):
        return max((self.LEVELS[l] for l, _, _ in self.items), default=0)

    def counts(self):
        c = {}
        for l, _, _ in self.items:
            c[l] = c.get(l, 0) + 1
        return c

    def render(self, use_color=True):
        lines = []
        for level, check, msg in self.items:
            tag = f'[{level}]'
            if use_color:
                tag = f'{self.COLORS.get(level, "")}{tag}{self.RESET}'
            lines.append(f'  {tag:<7} {check}: {msg}')
        return '\n'.join(lines)

# ─────────────────────────────────────────────────────────────────────────────
# Checks
# ─────────────────────────────────────────────────────────────────────────────

def canvas_repr(entry):
    """Representative colour for a (possibly gradient) canvas: the average of its stops."""
    return avg_rgb(entry['colors'])

def min_contrast_over(entry_bg, fg):
    """Worst-case contrast of fg over every stop of a background (gradient-safe)."""
    return min(contrast(fg, stop) for stop in entry_bg['colors'])

def run_checks(tokens, design_text, theme_text='', theme_label='', strict=False):
    R = Report()
    flat_raw = flatten(tokens)
    flat = resolve_refs(flatten(tokens))
    entries = color_entries(flat)

    # ── role resolution ──────────────────────────────────────────────────────
    canvas = pick(entries,
                  [r'\bcanvas\b', r'surface[-_.]?page', r'\bpage\b', r'\bbg\b',
                   r'background(?!.*(card|button|btn))', r'neutral.*\.1(\b|\.)'],
                  exclude=[r'card', r'button', r'btn', r'sheet', r'overlay', r'hover', r'dark'])
    surface = pick(entries,
                   [r'tile[-_.]?resting', r'\bsurface\b(?!.*page)', r'\bcard\b(?!.*hairline)',
                    r'\bpanel\b', r'neutral.*\.0(\b|\.)'],
                   exclude=[r'page', r'canvas', r'hairline', r'\bborder\b', r'alt', r'selected',
                            r'overlay', r'floating', r'dark', r'sheet', r'tab'])
    primary = pick(entries,
                   [r'brand.*primary(?!soft|dark|hover)', r'\bprimary\b', r'\bcta\b',
                    r'\baction\b', r'\baccent\b'],
                   exclude=[r'hover', r'soft', r'\bdark\b', r'\blight\b', r'text', r'on[-_]?',
                            r'inverse', r'muted', r'disabled'])
    on_brand = pick(entries,
                    [r'on[-_]?brand', r'on[-_]?primary', r'text[-_.]?inverse', r'\binverse\b',
                     r'label.*on', r'text.*on'],
                    exclude=[r'dark'])
    ink = pick(entries,
               [r'text[-_.]?primary', r'\bink\b', r'\bforeground\b', r'text\.primary',
                r'neutral.*\.9(\b|\.)', r'\bbody\b'],
               exclude=[r'muted', r'secondary', r'tertiary', r'inverse', r'on[-_]?brand',
                        r'disabled', r'placeholder', r'\bdark\b'])
    muted = pick_all(entries,
                     [r'\bmuted\b', r'text.*muted', r'text.*secondary', r'text.*tertiary'],
                     exclude=[r'\bborder\b', r'button', r'\bbrand\b', r'\bdark\b', r'\baction\b'])
    disabled = pick(entries, [r'disabled'], exclude=[r'\bdark\b'])
    selected = pick_all(entries, [r'\bselected\b', r'\bselection\b'], exclude=[r'\bdark\b'])
    err = pick(entries, [r'\berror\b', r'destructive', r'\bdanger\b'],
               exclude=[r'\bdark\b', r'note', r'text'])
    succ = pick(entries, [r'\bsuccess\b', r'\bpositive\b'], exclude=[r'\bdark\b', r'note'])
    warn = pick(entries, [r'\bwarning\b', r'\bcaution\b'], exclude=[r'\bdark\b', r'note'])
    info = pick(entries, [r'\binfo\b(?!.*note)', r'informational'], exclude=[r'\bdark\b'])

    # A second saturated accent is not wrong merely because it is distant from the brand hue,
    # but it needs a declared job/harmony. Tokenization alone is not palette permission. Keep
    # this advisory: colour harmony remains contextual, while the presence/absence of a reason
    # is deterministic. Semantic and data/category palettes are checked in their own roles.
    support_accents = pick_all(
        entries,
        [r'brand.*secondary', r'\bsecondary\b', r'\bsupport(?:ing)?\b', r'\baccent\b'],
        exclude=[r'text', r'muted', r'tertiary', r'neutral', r'canvas', r'surface', r'background',
                 r'border', r'selected', r'selection', r'error', r'danger', r'destructive',
                 r'success', r'warning', r'caution', r'\binfo\b', r'data', r'chart', r'category',
                 r'disabled', r'hover', r'\bdark\b', r'note'])
    support_accents = [e for e in support_accents
                       if (not primary or e['path'] != primary['path'])
                       and lab_chroma(avg_rgb(e['colors'])) >= 18]
    # Badge / count chip: a small-text-on-accent component. Only assessed when a badge
    # FILL role is explicitly declared (badges are optional; no badge role -> silent, no
    # SKIP noise). The label is picked separately; when absent we assume a white numeral
    # (the common failing pattern) but only WARN, since a tint-fill badge could legitimately
    # carry an undeclared ink label.
    badge_fill = pick(entries,
                      [r'badge[-_.]?(fill|bg|background|surface|chip)',
                       r'(count|notification)[-_.]?(fill|bg|badge|chip|dot)',
                       r'\bbadge\b'],
                      exclude=[r'text', r'label', r'\bfg\b', r'ink', r'numeral',
                               r'\bborder\b', r'\bdark\b', r'note', r'count(er|ry|ing)'])
    badge_label = pick(entries,
                       [r'badge[-_.]?(text|label|fg|ink|numeral)',
                        r'(count|notification)[-_.]?(text|label|numeral|ink)'],
                       exclude=[r'\bdark\b', r'note', r'count(er|ry|ing)'])

    if tokens is None:
        R.add('FAIL', 'input', 'no tokens.json found')
        return R

    # ── 1. Computed contrast pairs ──────────────────────────────────────────
    if ink and canvas:
        c = min_contrast_over(canvas, avg_rgb(ink['colors']))
        lvl = 'PASS' if c >= 4.5 else 'FAIL'
        note = ' (worst gradient stop)' if canvas['gradient'] else ''
        R.add(lvl, 'contrast/body-on-canvas', f'{c:.2f}:1{note} — need >=4.5:1  [{ink["path"]} on {canvas["path"]}]')
    else:
        R.add('SKIP', 'contrast/body-on-canvas', 'body text or canvas role not resolvable from token names')

    if ink and surface:
        c = min_contrast_over(surface, avg_rgb(ink['colors']))
        lvl = 'PASS' if c >= 4.5 else 'FAIL'
        R.add(lvl, 'contrast/body-on-card', f'{c:.2f}:1 — need >=4.5:1  [{ink["path"]} on {surface["path"]}]')

    for m in muted:
        relaxed = bool(re.search(r'tertiary|placeholder|disabled|hint', m['lpath']))
        bg = canvas or surface
        if not bg:
            break
        c = min_contrast_over(bg, avg_rgb(m['colors']))
        if c >= 4.5:
            R.add('PASS', 'contrast/muted-on-canvas', f'{c:.2f}:1  [{m["path"]}]')
        elif relaxed and c >= 3.0:
            R.add('WARN', 'contrast/muted-on-canvas',
                  f'{c:.2f}:1 — below 4.5:1 but reads as placeholder/disabled (WCAG-exempt); confirm it is never body copy  [{m["path"]}]')
        else:
            R.add('FAIL', 'contrast/muted-on-canvas', f'{c:.2f}:1 — need >=4.5:1  [{m["path"]}]')

    if on_brand and primary:
        c = contrast(avg_rgb(on_brand['colors']), avg_rgb(primary['colors']))
        # Token files normally do not prove rendered label size/weight. Default to the
        # ordinary-text requirement; 3:1 is valid only when the actual rendered label is
        # WCAG-large (>=24px regular or about >=18.5px bold), which belongs in visual review.
        lvl = 'PASS' if c >= 4.5 else 'FAIL'
        R.add(lvl, 'contrast/cta-label', f'{c:.2f}:1 — need >=4.5:1 unless rendered metadata proves WCAG-large text  [{on_brand["path"]} on {primary["path"]}]')
    elif primary and not on_brand:
        c = contrast((1, 1, 1), avg_rgb(primary['colors']))
        lvl = 'PASS' if c >= 4.5 else 'FAIL'
        R.add(lvl, 'contrast/cta-label', f'{c:.2f}:1 (assumed #FFFFFF label — no on-brand token found) — need >=4.5:1 unless rendered metadata proves WCAG-large text  [on {primary["path"]}]')

    # ── 1b. Badge / count label contrast ─────────────────────────────────────
    # A count badge label is SMALL text — needs the full 4.5:1, not the 3:1 CTA-label
    # allowance. White-on-accent (~2.5:1) fails and can't be darkened into range within
    # a brand; the on-system fix is a tint fill + ink numeral. Silent when no badge fill
    # role is declared (the JT case — badges are inline, caught by the render/inline sweep).
    if badge_fill:
        bg = badge_fill['colors'][0] if not badge_fill['gradient'] else avg_rgb(badge_fill['colors'])
        if badge_label:
            c = min_contrast_over(badge_fill, avg_rgb(badge_label['colors']))
            lvl = 'PASS' if c >= 4.5 else 'FAIL'
            R.add(lvl, 'contrast/badge-label',
                  f'{c:.2f}:1 — badge/count label is small text, needs >=4.5:1 (not the 3:1 CTA allowance)  [{badge_label["path"]} on {badge_fill["path"]}]')
        else:
            c = contrast((1, 1, 1), bg)
            lvl = 'PASS' if c >= 4.5 else 'WARN'
            R.add(lvl, 'contrast/badge-label',
                  f'{c:.2f}:1 (assumed #FFFFFF numeral — no badge label token) — small text needs >=4.5:1; if white-on-accent, use a tint fill + ink numeral  [on {badge_fill["path"]}]')

    # ── 2. primary <-> disabled distance ─────────────────────────────────────
    if primary and disabled:
        d = deltaE(avg_rgb(primary['colors']), avg_rgb(disabled['colors']))
        lvl = 'PASS' if d >= 12 else 'WARN'
        R.add(lvl, 'distinct/primary-vs-disabled',
              f'deltaE {d:.1f} — a disabled action must not read as enabled (want >=12)')
    elif primary:
        # No explicit disabled token — derive it. Most builds fade the enabled
        # colour (opacity ~0.4), which is invisible to token-only comparison and
        # is exactly how the 2026-07 "CTA reads as disabled" bug shipped: the
        # ghost derives from the enabled colour, so darkening the CTA cannot fix
        # confusability (JT: enabled vs ghost 1.92:1 at #27A390; still only
        # 2.18:1 at the much darker #1E9385).
        flat_all = resolve_refs(flatten(tokens))
        alpha = None
        for k, v in flat_all.items():
            if re.search(r'disabled[^.]*opacity|opacity[^.]*disabled', k, re.I):
                try:
                    alpha = float(str(v).rstrip('%'))
                    if alpha > 1: alpha /= 100.0
                except ValueError:
                    pass
                break
        if alpha and canvas:
            en = avg_rgb(primary['colors']); bg = canvas_repr(canvas)
            ghost = tuple(en[i] * alpha + bg[i] * (1 - alpha) for i in range(3))
            c = contrast(en, ghost)
            # 2:1 is a project heuristic for perceptual separation, not a WCAG
            # requirement. Keep it visible without turning an unadopted house
            # threshold into a CI correctness failure.
            lvl = 'PASS' if c >= 2.0 else 'WARN'
            R.add(lvl, 'distinct/primary-vs-disabled',
                  f'derived: enabled vs its {alpha:.0%}-opacity ghost over the canvas = {c:.2f}:1 — '
                  f'below the 2:1 project heuristic; verify the rendered enabled/disabled pair. '
                  f'If users could confuse them, define a distinct disabled token or add another '
                  f'state channel. Do not treat this heuristic alone as WCAG failure.')
        else:
            R.add('SKIP', 'distinct/primary-vs-disabled', 'no explicit disabled-action token and no disabled-opacity to derive one from')
    else:
        R.add('SKIP', 'distinct/primary-vs-disabled', 'no explicit disabled-action token to compare')

    # ── 3. semantic-colour mutual distinctness ───────────────────────────────
    sem = [(n, e) for n, e in (('primary', primary), ('error', err), ('success', succ),
                               ('warning', warn), ('info', info)) if e]
    if len(sem) >= 2:
        worst = None
        for i in range(len(sem)):
            for j in range(i + 1, len(sem)):
                d = deltaE(avg_rgb(sem[i][1]['colors']), avg_rgb(sem[j][1]['colors']))
                if worst is None or d < worst[0]:
                    worst = (d, sem[i][0], sem[j][0])
        d, a, b = worst
        lvl = 'PASS' if d >= 15 else 'WARN'
        R.add(lvl, 'distinct/semantic-colours',
              f'closest pair {a}<->{b} deltaE {d:.1f} — state colours must be tellable apart without a legend (want >=15)')
    else:
        R.add('SKIP', 'distinct/semantic-colours', f'fewer than two semantic roles resolved ({[n for n,_ in sem]})')

    # ── 3b. brand/support accent permission + relationship metrics ───────────
    if primary and support_accents:
        brand_rgb = avg_rgb(primary['colors'])
        brand_hue = lab_hue(brand_rgb)
        brand_chroma = max(lab_chroma(brand_rgb), 0.01)

        def _temperature(rgb):
            h = rgb_to_hsl(rgb)[0]
            return 'warm' if h >= 330 or h <= 90 else 'cool'

        def _permission_for(entry):
            leaf = entry['lpath'].rsplit('.', 1)[-1]
            parent = entry['lpath'].rsplit('.', 1)[0] if '.' in entry['lpath'] else entry['lpath']
            permission_words = re.compile(
                r'brand[-_ ]?(?:derived|support)|support(?:ing)?(?: palette| harmony| accent)?|'
                r'analogous|complement(?:ary)?|triad|split[-_ ]?complement|semantic|data|category', re.I)
            for key, value in flat_raw.items():
                lk = key.lower()
                if not re.search(r'permission|harmony|purpose|palette[-_.]?role|colour[-_.]?role|color[-_.]?role', lk):
                    continue
                related = leaf in lk or parent in lk or 'palette' in lk
                if related and permission_words.search(str(value)):
                    return f'token metadata {key}'
            if re.search(r'palette\s+permission|support(?:ing)?\s+(?:palette|harmony|accent)|'
                         r'analogous|complement(?:ary)?|triad|split[- ]?complement',
                         design_text or '', re.I):
                return 'DESIGN.md palette rationale'
            return None

        for accent in support_accents:
            rgb = avg_rgb(accent['colors'])
            hd = hue_dist(brand_hue, lab_hue(rgb))
            cr = lab_chroma(rgb) / brand_chroma
            temperatures = f'{_temperature(brand_rgb)}→{_temperature(rgb)}'
            permission = _permission_for(accent)
            metrics = f'hue distance {hd:.0f}°, chroma ratio {cr:.2f}×, temperature {temperatures}'
            if permission:
                R.add('PASS', 'palette/support-permission',
                      f'{metrics}; role/harmony declared by {permission}  [{accent["path"]}]')
            else:
                R.add('WARN', 'palette/support-permission',
                      f'{metrics} — saturated support accent has no declared palette job or harmony. '
                      f'Document brand-derived support, semantic, or data/category permission and verify '
                      f'usage proportions in context; do not reject the hue solely because it is distant. '
                      f'[{accent["path"]}]')
    elif primary:
        R.add('SKIP', 'palette/support-permission', 'no separate saturated support accent resolved')
    else:
        R.add('SKIP', 'palette/support-permission', 'no brand/primary hue to compare')

    # ── 4. selection != action distance ──────────────────────────────────────
    if selected and primary:
        pr = avg_rgb(primary['colors'])
        worst = min((deltaE(avg_rgb(s['colors']), pr), s['path']) for s in selected)
        d, path = worst
        # deltaE 20 is a house heuristic, not a formal accessibility threshold.
        # The actual requirement is that action and selection remain distinguishable
        # in context, potentially through non-colour channels.
        lvl = 'PASS' if d >= 20 else 'WARN'
        R.add(lvl, 'distinct/selection-vs-action',
              f'closest selection token deltaE {d:.1f} from primary — "chosen" must not look "pressable" (want >=20)  [{path}]')
    else:
        R.add('SKIP', 'distinct/selection-vs-action', 'no selection token resolved')

    # ── 4b. selection fill vs the surface(s) it sits on (second-signal dependency) ─
    # A faint selection fill is legitimate ONLY if a non-colour signal (ink check /
    # scale-lift / real border) carries the state — "colour is never the only signal".
    # Report the fill against BOTH plausible grounds — the page canvas AND a white
    # content card — because a tile on a card only needs to separate from the card
    # (JT: 1.033 on the canvas but 1.126 on the card it actually sits on; canvas-only
    # over-warns and names the wrong surface). Thresholds track the surface value-step
    # band (1.05-1.12, see surface/value-step): >=1.10 clears the top of the band so
    # the fill stands on its own; <1.03 is below the "invisible" floor; between, it
    # depends on a second signal. The validator can't see the render, so it asserts
    # the dependency and reminds the reviewer to verify it. (Promoted 2026-07-13 from a
    # JT review: a mockup dropped the scale-lift and the selected tile read as blending.)
    sel_entries = [e for e in entries if 'select' in e['lpath']]
    sel_fills = [e for e in sel_entries if re.search(r'fill|background|\bbg\b|tint', e['lpath'])]
    _sel_pool = sel_fills or [e for e in sel_entries if not re.search(r'check|border', e['lpath'])] or sel_entries
    sel_fill = max(_sel_pool, key=lambda s: rel_lum(avg_rgb(s['colors'])), default=None)
    _grounds = [('canvas', canvas)] + ([('card', surface)] if surface else [])
    if sel_fill and canvas:
        _f = avg_rgb(sel_fill['colors'])
        _steps = [(nm, contrast(_f, canvas_repr(g) if g is canvas else avg_rgb(g['colors']))) for nm, g in _grounds]
        _pairs = ', '.join(f'{nm} {s:.3f}:1' for nm, s in _steps)
        _lo = min(s for _, s in _steps); _hi = max(s for _, s in _steps)
        _fa = resolve_refs(flatten(tokens))
        def _num(x):
            try: return float(str(x).strip().rstrip('%'))
            except (TypeError, ValueError): return None
        def _real(x): return str(x).strip().lower() not in ('', 'transparent', 'none', 'null', '0')
        # Only VALUE fields count as signals — never metadata. A `.note`/`.description`
        # leaf like "Retired: the old warm border (#EFB94A)…" is a real non-empty string
        # but describes a signal that no longer exists; counting it re-introduces exactly
        # the fragile config this check guards. (JT-2026-07: a retired-border NOTE made
        # has_border read True and the faint selection passed instead of warning.)
        _META = ('note', 'description', 'comment', 'desc', 'doc', 'rationale', '_note', '$description')
        def _is_signal(k):
            return k.rsplit('.', 1)[-1].lower() not in _META
        has_check  = any(_is_signal(k) and 'select' in k.lower() and 'check' in k.lower() and _real(v) for k, v in _fa.items())
        # A lift only counts as a real second signal if it is PERCEPTIBLE. A scale(1.04)
        # is below the just-noticeable floor and cannot carry state on its own — this was
        # the JT-2026-07 config (12% tint + 1.04 lift + ink check, border retired) that
        # shipped as a near-invisible selected state. Require |scale-1| >= 0.06.
        def _lift_ok(v):
            n = _num(v)
            return n is not None and abs(n - 1) >= 0.06
        has_lift   = any(_is_signal(k) and 'select' in k.lower() and re.search(r'scale|lift', k, re.I)
                         and _lift_ok(v) for k, v in _fa.items())
        has_border = any(_is_signal(k) and 'select' in k.lower() and 'border' in k.lower() and _real(v) for k, v in _fa.items())
        second = has_check or has_lift or has_border
        # "strong" second signal = one that survives on its own over a faint fill: a
        # committed border, OR an ink check BACKED by a perceptible lift. A lone check, a
        # lone sub-1.06 lift, or a retired (transparent) border is NOT enough — that is the
        # fragile config, so it WARNs instead of passing silently.
        strong_second = has_border or (has_check and has_lift)
        sig = ', '.join(n for n, ok in (('ink-check', has_check), ('lift', has_lift), ('border', has_border)) if ok) or 'none'
        chk = 'selection/fill-vs-canvas-second-signal'
        if _lo >= 1.10:
            R.add('PASS', chk, f'{_pairs} — selection fill separates from every ground it can sit on; still pair it with the ink check (colour is never the only signal)  [{sel_fill["path"]}]')
        elif strong_second:
            R.add('PASS', chk, f'{_pairs} — faint on the lighter ground but a committed non-colour signal carries it ({sig}); VERIFY the check + lift render wherever a selected tile sits on the fainter surface  [{sel_fill["path"]}]')
        elif second:
            R.add('WARN', chk, f'{_pairs} — faint fill leaning on one declared signal ({sig}). Verify the rendered item remains independently identifiable through an established non-colour channel (border, weight, shape, indicator, label, position, or mark). Strengthen the existing channel or deepen the fill only if the render is ambiguous; do not add a checkmark by default  [{sel_fill["path"]}]')
        elif _hi >= 1.10:
            R.add('INFO', chk, f'{_pairs} — separates from the card but is faint on the canvas, and no non-colour signal is defined; add an ink check + scale-lift for tiles placed directly on the canvas  [{sel_fill["path"]}]')
        elif _hi < 1.03:
            R.add('FAIL', chk, f'{_pairs} — selection fill is invisible against every known ground AND no non-colour signal is defined; selection relies on colour alone. Add the smallest system-compatible persistent channel (border, weight, shape, indicator, label, position, or mark) and verify it in the render  [{sel_fill["path"]}]')
        else:
            R.add('INFO', chk, f'{_pairs} — faint against every known ground and no non-colour signal is defined; add an ink check + scale-lift so "chosen" survives without colour  [{sel_fill["path"]}]')
    else:
        R.add('SKIP', 'selection/fill-vs-canvas-second-signal', 'no selection fill or canvas resolvable')


    # ── 5. neutral ramp derived from brand hue ───────────────────────────────
    if primary:
        bhue = lab_hue(avg_rgb(primary['colors']))
        neutrals = pick_all(entries,
                            [r'\bcanvas\b', r'\bborder\b', r'hairline', r'divider',
                             r'\bmuted\b', r'\bink\b', r'text[-_.]?primary', r'neutral'],
                            exclude=[r'button', r'\bbrand\b', r'\bcta\b', r'selected', r'\bdark\b'])
        offenders, dead = [], []
        for e in neutrals:
            rgb = avg_rgb(e['colors'])
            chroma = lab_chroma(rgb)
            if chroma > 18:
                offenders.append(f'{e["path"]} chroma {chroma:.0f} (>18 — too saturated for a neutral)')
            elif chroma < 1.2:
                dead.append(e['path'])
            elif hue_dist(lab_hue(rgb), bhue) > 55:
                offenders.append(f'{e["path"]} hue {lab_hue(rgb):.0f} vs brand {bhue:.0f} (delta {hue_dist(lab_hue(rgb),bhue):.0f})')
        if offenders:
            R.add('WARN', 'ramp/brand-tinted-neutrals',
                  'neutrals should carry the brand hue at low chroma: ' + '; '.join(offenders[:4]))
        elif dead and len(dead) >= max(2, len(neutrals) // 2):
            R.add('WARN', 'ramp/brand-tinted-neutrals',
                  f'{len(dead)} neutrals are dead-gray (chroma ~0) under a colourful brand — tint the ramp toward hue {bhue:.0f}')
        elif neutrals:
            R.add('PASS', 'ramp/brand-tinted-neutrals',
                  f'{len(neutrals)} neutrals sit at low chroma near brand hue {bhue:.0f}')
        else:
            R.add('SKIP', 'ramp/brand-tinted-neutrals', 'no neutral tokens resolved')
    else:
        R.add('SKIP', 'ramp/brand-tinted-neutrals', 'no brand/primary hue to derive from')

    # ── 6. background <-> card value step (1.05-1.12) ────────────────────────
    if canvas and surface:
        step = contrast(canvas_repr(canvas), avg_rgb(surface['colors']))
        if step < 1.03:
            R.add('FAIL', 'surface/value-step', f'{step:.3f}:1 — card is invisible against canvas (<1.03)')
        elif 1.05 <= step <= 1.12:
            R.add('PASS', 'surface/value-step', f'{step:.3f}:1 — in the 1.05-1.12 band')
        elif step < 1.05:
            R.add('WARN', 'surface/value-step', f'{step:.3f}:1 — separation is faint (want 1.05-1.12)')
        else:
            R.add('WARN', 'surface/value-step', f'{step:.3f}:1 — step is heavier than 1.12; check it does not read as two tones')
    else:
        R.add('SKIP', 'surface/value-step', 'canvas or card surface not resolvable')

    # ── 6b. tinted decorative/component surfaces vs plausible grounds ───────
    # The validator cannot know layout placement, so an undeclared faint pair is advisory rather
    # than an automatic failure. It still names the exact ground that would collapse, ensuring the
    # reviewer checks the rendered placement. Explicit interactive boundaries remain governed by
    # the stronger contrast/accessibility checks.
    tint_surfaces = pick_all(
        entries,
        [r'tint', r'\bsoft\b', r'subtle', r'\btile\b', r'\bwell\b', r'callout', r'\bbanner\b',
         r'chip[-_.]?(?:fill|bg|background|surface)'],
        exclude=[r'text', r'label', r'ink', r'foreground', r'icon', r'border', r'hairline',
                 r'shadow', r'gradient', r'selected', r'selection', r'hover', r'disabled',
                 r'\bdark\b', r'note', r'description', r'(?:^|\.)(?:on|ground)$'])
    tint_surfaces = [e for e in tint_surfaces
                     if e['path'] not in {x['path'] for x in (canvas, surface, primary) if x}]
    grounds = [('canvas', canvas)] + ([('card', surface)] if surface else [])
    if tint_surfaces and canvas:
        for tint in tint_surfaces:
            rgb = avg_rgb(tint['colors'])
            steps = [(name, contrast(rgb, canvas_repr(g) if g is canvas else avg_rgb(g['colors'])))
                     for name, g in grounds if g]
            faint = [(name, step) for name, step in steps if step < 1.03]
            pairs = ', '.join(f'{name} {step:.3f}:1' for name, step in steps)
            if faint:
                names = ', '.join(name for name, _ in faint)
                R.add('WARN', 'surface/tint-vs-grounds',
                      f'{pairs} — tint collapses against plausible {names} placement (<1.03). '
                      f'Confirm its actual ground; if adjacent, separate with whitespace, a value step, '
                      f'or a hairline before adding hue, saturation, shadow, or glow. [{tint["path"]}]')
            else:
                R.add('PASS', 'surface/tint-vs-grounds',
                      f'{pairs} — tint remains perceptibly distinct from known grounds [{tint["path"]}]')
    elif canvas:
        R.add('SKIP', 'surface/tint-vs-grounds', 'no separate tinted tile/well/chip/callout surface resolved')
    else:
        R.add('SKIP', 'surface/tint-vs-grounds', 'no canvas ground resolvable')

    # ── 7. type-scale ratios ────────────────────────────────────────────────
    # The validator floors at 1.15x as a hard "distinct level" minimum (below it two steps read
    # as one); rules.md's 1.25x is the display-tier *target*, deliberately above this floor.
    # Only *heading tiers* are assessed: comparing a full xs->5xl ramp adjacent-pairwise would
    # misclassify a 16:14 body step as a failed heading ratio, so when no heading-named tiers
    # exist the check SKIPs rather than flagging body-scale tokens (F5).
    type_sizes = collect_type_sizes(tokens)
    headings = [(n, s) for n, s in type_sizes
                if re.search(r'hero|title|h[1-6]|display|heading|headline|subtitle', n, re.I)]
    if len(headings) >= 2:
        pool = sorted(headings, key=lambda x: -x[1])
        bad = []
        hard = False
        for i in range(len(pool) - 1):
            ratio = pool[i][1] / pool[i + 1][1]
            if ratio < 1.15:
                bad.append(f'{pool[i][0]}({pool[i][1]:g}):{pool[i+1][0]}({pool[i+1][1]:g})={ratio:.2f}x')
                if ratio < 1.1:
                    hard = True
        if bad:
            R.add('FAIL' if hard else 'WARN', 'type/scale-ratios',
                  'adjacent heading steps too close (<1.15x floor = same level; 1.25x is the target): ' + '; '.join(bad))
        else:
            R.add('PASS', 'type/scale-ratios', f'{len(pool)} heading-tier steps all >=1.15x apart')
    elif len(type_sizes) >= 2:
        R.add('SKIP', 'type/scale-ratios',
              'no heading-named tiers (h1/title/display/hero/subtitle) to isolate — body-scale steps '
              'are not heading ratios; name the display tiers to enable this check')
    else:
        R.add('SKIP', 'type/scale-ratios', 'no type size scale found')

    # ── 8. radius monotonicity + concentric ─────────────────────────────────
    radii = collect_scale_px(tokens, r'radius')
    radii = [(n, v) for n, v in radii if v < 400]  # drop pill/999
    if radii:
        vals = sorted(v for _, v in radii)
        dupes = [f'{vals[i]:g}/{vals[i+1]:g}px' for i in range(len(vals) - 1)
                 if 0 < vals[i + 1] - vals[i] < 2]
        if len(set(vals)) > 6:
            R.add('WARN', 'radius/scale', f'{len(set(vals))} distinct card/control radii — looks eye-tuned, not a scale')
        elif dupes:
            R.add('WARN', 'radius/scale', 'near-duplicate radii (probably one value): ' + ', '.join(dupes))
        else:
            R.add('PASS', 'radius/scale', f'{len(set(vals))} clean radius steps: {", ".join(f"{v:g}" for v in sorted(set(vals)))}px')
        R.add('INFO', 'radius/concentric',
              'concentric nesting (inner = outer - gap) cannot be verified from tokens alone — check by eye where cards nest')
    else:
        R.add('SKIP', 'radius/scale', 'no radius scale found')

    # ── 9. elevation ramp coherence + opacity-fall hint ─────────────────────
    elevs = collect_elevation(tokens)
    if len(elevs) >= 2:
        blur_ok = all(elevs[i][2] <= elevs[i + 1][2] for i in range(len(elevs) - 1))
        off_ok = all(elevs[i][1] <= elevs[i + 1][1] for i in range(len(elevs) - 1))
        if blur_ok and off_ok:
            R.add('PASS', 'elevation/ramp', f'{len(elevs)} steps rise monotonically in offset & blur')
        else:
            R.add('FAIL', 'elevation/ramp', 'blur/offset do not rise monotonically with the ramp level — the ramp is not generative')
        alphas = [e[3] for e in elevs if e[3] is not None]
        if len(alphas) >= 2:
            if all(alphas[i] >= alphas[i + 1] for i in range(len(alphas) - 1)):
                R.add('INFO', 'elevation/opacity', 'opacity falls as shadows diffuse — matches the physical model')
            else:
                R.add('INFO', 'elevation/opacity',
                      f'opacity rises with elevation ({", ".join(f"{a:.2f}" for a in alphas)}); the template model is that diffuse shadows lighten — informational, not a fault')
    else:
        R.add('SKIP', 'elevation/ramp', 'no multi-step elevation ramp found')

    # ── 10. 60/30/10 budget hint ────────────────────────────────────────────
    accents = [e for e in (primary, err, succ, warn, info, *selected) if e]
    hues = set()
    for e in accents:
        h, s, l = rgb_to_hsl(avg_rgb(e['colors']))
        if s > 0.15:
            hues.add(round(h / 30) * 30)
    if hues:
        lvl = 'WARN' if len(hues) > 5 else 'INFO'
        R.add(lvl, 'palette/60-30-10',
              f'~{len(hues)} distinct saturated accent hue families — the 10% budget wants a small set; confirm the canvas/neutrals carry 60/30')

    # ── 11. dark-mode relationship preservation ─────────────────────────────
    # Only a real dark *scheme* counts — a segment named 'dark' (theme.dark, scheme.dark,
    # mode.dark, colorDark). An immersive 'night' gradient is not a dark-mode token set.
    dark_entries = [e for e in entries
                    if re.search(r'(^|\.)dark(\.|$)|(scheme|mode|theme)[-_.]?dark|dark[-_.]?(mode|theme|scheme)',
                                 e['lpath'])]
    dark_in_design = bool(re.search(r'dark\s*mode|dark\s*theme|prefers-color-scheme', design_text or '', re.I))
    light_only_declared = bool(re.search(r'light[- ]only|single light scheme|no (dark|second|night[- ]?time) (mode|scheme|theme)', design_text or '', re.I))
    if dark_entries:
        dink = pick(dark_entries, [r'text[-_.]?primary', r'\bink\b', r'\bbody\b'], exclude=[r'muted', r'inverse'])
        dbg = pick(dark_entries, [r'\bcanvas\b', r'\bbg\b', r'background', r'surface'], exclude=[r'card'])
        if dink and dbg:
            c = min_contrast_over(dbg, avg_rgb(dink['colors']))
            lvl = 'PASS' if c >= 4.5 else 'FAIL'
            R.add(lvl, 'dark/body-contrast', f'{c:.2f}:1 — dark-mode body must also clear 4.5:1  [{dink["path"]} on {dbg["path"]}]')
        else:
            R.add('WARN', 'dark/relationships', f'{len(dark_entries)} dark tokens found but body/bg pair not resolvable — verify the same relationships hold')
    elif dark_in_design and light_only_declared:
        R.add('SKIP', 'dark/relationships', 'light-only declared as a Layer-1 decision — no dark tokens expected')
    elif dark_in_design:
        R.add('WARN', 'dark/relationships', 'DESIGN.md mentions dark mode but no dark tokens found — the relationships are undefined')
    else:
        R.add('SKIP', 'dark/relationships', 'no dark-mode tokens or spec — single scheme')

    # ── 12. Implementation CSS vs tokens.json drift ─────────────────────────
    # The 2026-07-11 external reviews both hit the same failure class: the
    # validator passed on tokens.json while the shipped theme CSS carried the
    # opposite values ("green as false comfort"). This check diffs the theme's
    # custom properties against the mappable token roles.
    if theme_text:
        css = re.sub(r'/\*.*?\*/', '', theme_text, flags=re.S)
        props = dict(re.findall(r'(--[A-Za-z0-9_-]+)\s*:\s*([^;]+);', css))
        for _ in range(3):
            changed = False
            for k, v in list(props.items()):
                m = re.search(r'var\((--[A-Za-z0-9_-]+)\)', v)
                if m and m.group(1) in props:
                    props[k] = v.replace(m.group(0), props[m.group(1)].strip()); changed = True
            if not changed:
                break
        def theme_pick(pats, exclude=()):
            for k, v in props.items():
                kl = k.lower()
                if any(re.search(pt, kl) for pt in pats) and not any(re.search(e, kl) for e in exclude):
                    return k, v.strip()
            return None, None
        drift = []
        checked = 0
        def cmp_color(role, tok_entry, pats, exclude=()):
            nonlocal checked
            if not tok_entry:
                return
            k, v = theme_pick(pats, exclude)
            if not v:
                return
            # Resolve simple color-mix(in srgb, C1 P%, C2) statically.
            mm = re.match(r'\s*color-mix\(\s*in\s+srgb\s*,\s*(#[0-9A-Fa-f]{6})\s+([\d.]+)%\s*,\s*(#[0-9A-Fa-f]{6})\s*\)\s*$', v)
            if mm:
                c1 = _hex_to_rgb(mm.group(1)); pct = float(mm.group(2)) / 100.0; c2 = _hex_to_rgb(mm.group(3))
                cols = [tuple(c1[j] * pct + c2[j] * (1 - pct) for j in range(3))]
            else:
                cols = extract_colors(v)
            if not cols:
                if 'color-mix' in v or 'var(' in v:
                    R.add('INFO', 'drift/theme-vs-tokens', f'{role}: theme value not statically resolvable ({k}) — verify by eye')
                return
            checked += 1
            d = min(deltaE(c, t) for c in cols for t in tok_entry['colors'])
            if d > 4:
                drift.append(f'{role}: theme {k}: {v[:48]} vs tokens {tok_entry["path"]} (deltaE {d:.0f})')
        cmp_color('primary', primary, [r'brand-primary$', r'color-primary$', r'primary$'], [r'dark', r'soft', r'text', r'on'])
        cmp_color('canvas', canvas, [r'bg-app$', r'surface-page$', r'canvas$', r'bg-page$'], [r'dark'])
        sel_fill = next((e for e in selected if re.search(r'fill', e['path'], re.I)), None)
        cmp_color('selected-fill', sel_fill, [r'selected-fill$', r'selection-fill$'])
        body_px = next((px for role, px in collect_type_sizes(tokens) if re.search(r'^body$', role, re.I)), None)
        k, v = theme_pick([r'text-body$', r'font-size-body$', r'body-size$'])
        if body_px and v:
            tv = _to_px(v)
            checked += 1
            if tv and abs(tv - body_px) > 0.5:
                drift.append(f'body-size: theme {k}: {v} vs tokens {body_px:.0f}px')
        src = f' [{theme_label}]' if theme_label else ''
        if drift:
            for d in drift:
                R.add('FAIL', 'drift/theme-vs-tokens', d + f' — implementation CSS diverges from tokens.json (unlogged drift){src}')
        elif checked:
            R.add('PASS', 'drift/theme-vs-tokens', f'{checked} mappable roles match the implementation CSS{src}')
        else:
            R.add('SKIP', 'drift/theme-vs-tokens', f'theme CSS found but no mappable role names{src}')
    else:
        R.add('SKIP', 'drift/theme-vs-tokens', 'no theme/implementation CSS found — token-level checks only')

    # ── coverage floor (F4) ─────────────────────────────────────────────────
    # SKIP means "role not resolvable," which in default mode still permits exit 0 — so a blank
    # or badly-key-named token file could "pass" while almost nothing was assessed. --strict
    # closes that: the universal relationships below MUST be assessed; an unresolved one FAILs.
    # A coverage ratio is always reported so the exit code is never mistaken for full coverage.
    REQUIRED = ('contrast/body-on-canvas', 'contrast/cta-label',
                'surface/value-step', 'ramp/brand-tinted-neutrals')
    assessed = {c for (l, c, _) in R.items if l in ('PASS', 'WARN', 'FAIL')}
    req_hit = [c for c in REQUIRED if c in assessed]
    missing = [c for c in REQUIRED if c not in assessed]
    if strict:
        for c in missing:
            R.add('FAIL', 'coverage/required',
                  f'{c} not assessed — a required relationship is unresolvable from the token '
                  f'names (--strict requires full coverage)')
        R.add('INFO', 'coverage/summary',
              f'{len(req_hit)}/{len(REQUIRED)} required relationships assessed'
              + (f'; missing: {", ".join(missing)}' if missing else ''))
    else:
        R.add('INFO', 'coverage/summary',
              f'{len(req_hit)}/{len(REQUIRED)} required relationships assessed'
              + ' (run --strict to require full coverage before PASS)')

    return R


def collect_type_sizes(tokens):
    """Return [(role_name, px)] for a typography scale, tolerant of schema shape."""
    out = []
    flat = flatten(tokens)
    for path, val in flat.items():
        lp = path.lower()
        if not re.search(r'(type|font|text|size|heading|scale)', lp):
            continue
        if re.search(r'weight|line|leading|track|letter|family|note', lp):
            continue
        px = _to_px(val)
        if px and 6 <= px <= 200:
            parts = path.split('.')
            role = parts[-1]
            if role in ('size', 'value', 'fontSize'):
                role = parts[-2] if len(parts) >= 2 else role
            out.append((role, px))
    seen, uniq = set(), []
    for r, v in out:
        if r not in seen:
            uniq.append((r, v)); seen.add(r)
    return uniq


def collect_scale_px(tokens, key_re):
    out = []
    flat = flatten(tokens)
    for path, val in flat.items():
        if not re.search(key_re, path, re.I):
            continue
        if path.split('.')[-1].startswith('_') or path.endswith('.note'):
            continue
        px = _to_px(val)
        if px is not None:
            parts = path.split('.')
            role = parts[-1]
            if role == 'value':
                role = parts[-2] if len(parts) >= 2 else role
            out.append((role, px))
    return out


def collect_elevation(tokens):
    """Return [(name, max_offset, blur, alpha)] for the numbered elevation *ramp* only.
    Semantic one-off shadows (selected-tile lift, component shadows) are deliberately
    excluded — the ramp check is about whether the generative scale is monotonic, not
    about documented exceptions that reference it."""
    flat = flatten(tokens)
    rows = {}
    for path, val in flat.items():
        # Ramp members are numbered: elevation.1, elev-2, boxShadow.3, shadow.md ...
        if not re.search(r'(^|\.)(elev(ation)?|box[-_]?shadow|shadow)[-_.]?(\d|sm|md|lg|xl)\b', path, re.I):
            continue
        if not isinstance(val, str) or 'gradient' in val.lower() or 'none' in val.lower():
            continue
        nums = re.findall(r'-?\d*\.?\d+', re.sub(r'rgba?\([^)]*\)', '', val))
        m = re.search(r'rgba?\([^)]*?,\s*([\d.]+)\s*\)', val)
        alpha = float(m.group(1)) if m else None
        px = [float(n) for n in nums[:3]]
        if len(px) >= 2:
            parts = path.split('.')
            name = parts[-2] if path.endswith('.value') else parts[-1]
            order = {'sm': 1, 'md': 2, 'lg': 3, 'xl': 4}
            key = re.sub(r'\D', '', name)
            level = int(key) if key else order.get(name.lower(), 99)
            offset = abs(px[1]) if len(px) > 1 else 0
            blur = abs(px[2]) if len(px) > 2 else offset
            rows[path] = (name, offset, blur, alpha, level)
    ordered = sorted(rows.values(), key=lambda r: (r[4], r[0]))
    return [(r[0], r[1], r[2], r[3]) for r in ordered]


def _num_or(s):
    m = re.search(r'\d+', str(s))
    return int(m.group(0)) if m else 0


def _to_px(val):
    if isinstance(val, bool):
        return None
    if isinstance(val, (int, float)):
        return float(val)
    if isinstance(val, str):
        m = re.match(r'\s*(\d*\.?\d+)\s*px', val)
        if m:
            return float(m.group(1))
        m = re.match(r'\s*(\d*\.?\d+)\s*$', val)
        if m:
            return float(m.group(1))
    return None


# ─────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────

def find_file(root, names):
    for n in names:
        p = os.path.join(root, n)
        if os.path.isfile(p):
            return p
    return None

def main(argv):
    tokens_path = design_path = theme_path = None
    root = '.'
    root_explicit = False
    as_json = False
    strict = False
    args = argv[1:]
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--tokens':
            tokens_path = args[i + 1]; i += 2
        elif a == '--design':
            design_path = args[i + 1]; i += 2
        elif a == '--theme':
            theme_path = args[i + 1]; i += 2
        elif a == '--json':
            as_json = True; i += 1
        elif a == '--strict':
            strict = True; i += 1
        elif a in ('-h', '--help'):
            print(__doc__); return 0
        else:
            root = a; root_explicit = True; i += 1

    if tokens_path is None:
        tokens_path = find_file(root, ['tokens.json', 'design-tokens.json', 'src/tokens.json'])
    if design_path is None:
        design_path = find_file(root, ['DESIGN.md', 'design-system.md', 'DESIGN_SYSTEM.md'])

    if not tokens_path or not os.path.isfile(tokens_path):
        sys.stderr.write('validate-tokens: no tokens.json found (looked in %s). '
                         'Pass --tokens PATH.\n' % os.path.abspath(root))
        return 2
    try:
        with open(tokens_path, encoding='utf-8') as f:
            tokens = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        sys.stderr.write(f'validate-tokens: cannot parse {tokens_path}: {e}\n')
        return 2

    design_text = ''
    if design_path and os.path.isfile(design_path):
        with open(design_path, encoding='utf-8') as f:
            design_text = f.read()

    if theme_path is None and root_explicit and os.path.isdir(root):
        import glob as _glob
        cands = []
        for pat in ('theme.css', os.path.join('src*', 'theme.css'),
                    os.path.join('styles', 'theme.css'), os.path.join('src', 'styles', 'theme.css'),
                    os.path.join('css', 'theme.css')):
            cands += sorted(_glob.glob(os.path.join(root, pat)))
        # Multiple candidates (e.g. a legacy src-v3 next to the active src-v4):
        # the most recently modified file is the one under active development.
        theme_path = max(cands, key=os.path.getmtime) if cands else None
    theme_text = ''
    if theme_path and os.path.isfile(theme_path):
        with open(theme_path, encoding='utf-8') as f:
            theme_text = f.read()

    R = run_checks(tokens, design_text, theme_text, os.path.relpath(theme_path, root) if theme_path else '', strict=strict)

    if as_json:
        # Additive per-relationship coverage (does not alter items/counts/exit or the headline
        # ratio, which also remains as the coverage/summary item). 'assessed' = the check produced
        # a real verdict (PASS/WARN/FAIL); 'skipped' = role unresolvable (SKIP).
        _REQUIRED = ('contrast/body-on-canvas', 'contrast/cta-label',
                     'surface/value-step', 'ramp/brand-tinted-neutrals')
        _assessed = {c for (l, c, _) in R.items if l in ('PASS', 'WARN', 'FAIL')}
        _req = [{'relationship': c, 'assessed': c in _assessed} for c in _REQUIRED]
        _hit = sum(1 for r in _req if r['assessed'])
        print(json.dumps({
            'tokens': tokens_path,
            'design': design_path,
            'counts': R.counts(),
            'items': [{'level': l, 'check': c, 'message': m} for l, c, m in R.items],
            'coverage': {
                'required_assessed': _hit,
                'required_total': len(_REQUIRED),
                'ratio': f'{_hit}/{len(_REQUIRED)}',
                'per_relationship': _req,
            },
            'exit': 1 if R.worst() >= 2 else 0,
        }, indent=2))
        return 1 if R.worst() >= 2 else 0

    use_color = sys.stdout.isatty()
    B = Report.BOLD if use_color else ''; RS = Report.RESET if use_color else ''
    print(f'{B}token-graph validation{RS}  ·  {os.path.relpath(tokens_path)}'
          + (f' + {os.path.relpath(design_path)}' if design_path else ' (no DESIGN.md)'))
    print(R.render(use_color))
    c = R.counts()
    summary = '  '.join(f'{k}:{v}' for k, v in sorted(c.items()))
    print('  ' + '-' * 40)
    if R.worst() >= 2:
        print(f'  {Report.COLORS["FAIL"] if use_color else ""}FAIL{RS} — {summary}. '
              'A relationship is broken; fix before this system ships.')
        return 1
    elif R.worst() == 1:
        print(f'  {Report.COLORS["WARN"] if use_color else ""}PASS with warnings{RS} — {summary}. '
              'No broken relationships; review warnings.')
        return 0
    else:
        print(f'  {Report.COLORS["PASS"] if use_color else ""}PASS{RS} — {summary}. '
              'Token relationships cohere. Not a substitute for visual review.')
        return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
