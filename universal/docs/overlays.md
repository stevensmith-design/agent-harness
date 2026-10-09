# Overlays

An overlay is a named pack of additions for one domain, applied on top of this
harness. `overlays/ai-product/` is the first.

```bash
make overlay-list                     # what exists, what is applied
make overlay-apply NAME=ai-product    # apply one
make overlay-verify                   # sources unchanged, base still compatible
```

## The rule

**An overlay may add files and set config keys. It may never overwrite a base
file.** If it needs the base to behave differently, the base gains a config knob
and the overlay sets it — so the change is named, documented in the base, and
available to everyone, instead of living in a copy nobody else can see.

`scripts/overlay.sh` enforces this: an overlay whose `files/` would land on an
existing path is refused, with that reasoning in the error.

The config patcher enforces the other half: an overlay may only *set* keys the
base already defines. It cannot introduce config that is documented nowhere.

## Why not just fork the harness

Because this project has four recorded examples of what forking produces: two
stale copies of the design skills (434 lines and 9 files behind their source), a
redundant Flutter tree, and root docs that drifted 11 and 19 lines from their
originals. A fork does not stay a variant. It becomes a second place to fix
everything, and then only one of them gets fixed.

The shared machinery here is roughly 100 files — `scripts/`, CI, hooks,
governance, evals, the adapter boundary. A domain pack is five to ten. Copying a
hundred to change ten is the trade a fork makes.

## Anatomy

```
overlays/<name>/
  overlay.yaml         name, version, requires_base, description, gates it adds
  README.md            what it is, who it is for, what it deliberately excludes
  config.patch.yaml    set: <keys the base defines>   append_surfaces: <lanes>
  files/               everything it adds, at the paths it adds them
```

## Gates

An overlay declares its gates in `overlay.yaml`. `make check` runs them via
`check-overlay-gates`, so an overlay never needs to edit the Makefile — which it
could not do anyway.

## Drift

`overlays-lock.json` records the content hash of each applied overlay's source.
`make overlay-verify` fails when that source has changed without being
re-applied, and when the base has moved below what the overlay requires. That is
the check a fork has no way to perform.
