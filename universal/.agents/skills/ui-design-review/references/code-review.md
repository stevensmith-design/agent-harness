# Code review procedure

## Scanner

Run `scripts/scan.sh` on the requested files/diff. It detects known risky patterns including
interactive gradients, oversized untokenized radii, ghost cards, warm/gradient canvases, generic
display fonts, bounce easing, layout-animation risk, glow/coloured shadows, translucent/glass
content surfaces, high literal z-index, inaccessible click targets, missing icon labels, emoji
chrome, placeholder images, and invalid override citations.

Treat scanner output by its emitted tier. A hit is evidence to adjudicate, not automatic proof that
the UI is bad. Read the corresponding section in `rules.md` when contested.

## Override citations — check pre-dating, not just resolution

A green scan can be bought with paperwork. An `scan-exceptions.conf` id that resolves to a DESIGN.md
override entry only clears the gate if that decision **pre-dates** the use it authorizes. When the
diff under review *adds* both the gated pattern (e.g. an interactive gradient) and the override
entry that authorizes it in the *same* change, the authorization is self-authored — the author wrote
the "purpose" for their own change — and it does not clear the gate (gate question 6). Report the
pattern as an unresolved finding: recommend the flat/solid default and surface the exception as a
proposal for a separate human to ratify, whose entry then pre-dates any future use. The scanner
passing on a same-change override is a false clear, not a sign-off. (This never waives a Tier-1
accessibility/correctness failure regardless of pre-dating.)

## Manual consistency sweep — required

After the scanner:

- inventory unique font sizes/weights, colours, spacing, radii, shadows, and button geometry;
- flag off-scale or near-duplicate values and repeated literals that should be semantic tokens;
- inspect dynamic/template-built styles and inline JSX style objects the scanner may miss;
- compare each shared state across representative tabs, tiles, rows, and controls;
- verify absolute claims in DESIGN.md against implementation;
- separate visible component geometry from the hit area;
- inspect representative rendered siblings before recommending a shared change.

Do not call a missing explicit height a target failure without measuring the rendered hit box. Do
not change one state instance when the shared token/component is the true source.

## Output

Report Layers 1–3. For every finding include file:line, evidence/basis, affected instances, the
canonical rule or project contract, and smallest compatible fix. State scanner and validator
results separately; neither is equivalent to visual sign-off.
