#!/usr/bin/env python3
"""Apply an overlay's config patch to harness.config.yaml.

Deliberately a line-level patcher, not a YAML round-trip. harness.config.yaml is
a document people read: its comments carry the reasoning, and every YAML library
either drops them or reflows the file into something unrecognisable. A config
whose comments are gone is a config nobody can maintain.

So: set a scalar key in place, append a list item under a block key, and refuse
anything it cannot do safely rather than guessing.

  overlay-config.py <config.yaml> <patch.yaml>

Patch format:
  set:
    evals.enabled: true          # replaces the value, keeps the comment above it
  append_surfaces:               # adds a surface entry if its id is not present
    - id: ai
      paths: ["src/ai/**"]
      risk: high
      level: L3
"""
import re, sys, io

def load_patch(path):
    """Minimal reader for the two shapes above. No dependency on PyYAML."""
    sets, surfaces, mode, cur = {}, [], None, None
    for raw in open(path):
        line = raw.rstrip('\n')
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if re.match(r'^set:\s*$', line):
            mode = 'set'; continue
        if re.match(r'^append_surfaces:\s*$', line):
            mode = 'surfaces'; continue
        if mode == 'set' and re.match(r'^\s+\S+:', line):
            k, v = line.strip().split(':', 1)
            sets[k.strip()] = v.strip()
        elif mode == 'surfaces':
            if re.match(r'^\s*-\s', line):
                cur = {}; surfaces.append(cur)
                rest = re.sub(r'^\s*-\s*', '', line)
                if ':' in rest:
                    k, v = rest.split(':', 1); cur[k.strip()] = v.strip()
            elif cur is not None and ':' in line:
                k, v = line.strip().split(':', 1); cur[k.strip()] = v.strip()
    return sets, surfaces

def set_key(text, dotted, value):
    """section.key -> replace that key's scalar inside that top-level block."""
    if '.' in dotted:
        section, key = dotted.split('.', 1)
    else:
        section, key = None, dotted
    lines = text.split('\n')
    out, in_section, done = [], section is None, False
    for line in lines:
        if section and re.match(r'^%s:\s*$' % re.escape(section), line):
            in_section = True; out.append(line); continue
        if section and re.match(r'^[^\s#]', line) and not line.startswith(section + ':'):
            in_section = False
        if in_section and not done and re.match(r'^(\s+)%s:' % re.escape(key), line):
            indent = re.match(r'^(\s*)', line).group(1)
            trailing = ''
            m = re.search(r'(\s+#.*)$', line)
            if m: trailing = m.group(1)
            out.append('%s%s: %s%s' % (indent, key, value, trailing)); done = True; continue
        out.append(line)
    if not done:
        raise SystemExit("overlay-config: key '%s' not found in the config — "
                         "an overlay may only set keys the base already defines, so that "
                         "every knob it touches is documented in the base." % dotted)
    return '\n'.join(out)

def append_surface(text, entry):
    sid = entry.get('id', '').strip('"\'')
    if re.search(r'^\s*-\s*id:\s*["\']?%s["\']?\s*$' % re.escape(sid), text, re.M):
        return text, False
    lines = text.split('\n')
    out, inserted, in_surf = [], False, False
    for i, line in enumerate(lines):
        if re.match(r'^surfaces:\s*$', line):
            in_surf = True; out.append(line); continue
        if in_surf and re.match(r'^[^\s#]', line):
            block = ['  - id: %s' % sid]
            for k in ('paths', 'risk', 'level'):
                if k in entry: block.append('    %s: %s' % (k, entry[k]))
            if 'why' in entry: block[-1] += '          # %s' % entry['why'].strip('"\'')
            out.extend(block); out.append('')
            inserted = True; in_surf = False
        out.append(line)
    if not inserted:
        raise SystemExit("overlay-config: no `surfaces:` block to append to")
    return '\n'.join(out), True

def main(argv):
    cfg_path, patch_path = argv[1], argv[2]
    text = open(cfg_path).read()
    sets, surfaces = load_patch(patch_path)
    changed = []
    for k, v in sets.items():
        text = set_key(text, k, v); changed.append('set %s = %s' % (k, v))
    for entry in surfaces:
        text, did = append_surface(text, entry)
        if did: changed.append('added surface %s' % entry.get('id'))
    open(cfg_path, 'w').write(text)
    for c in changed: print('  config: %s' % c)
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv))
