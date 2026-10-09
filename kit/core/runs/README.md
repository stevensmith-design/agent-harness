# Runs

One directory per run: `YYYY-MM-DD-<procedure>/`.

**Three fields, always:**

- the **procedure** that ran
- the **foundation files** it consumed
- the **commit SHA** of the harness at the time — or, in a workspace substrate, a dated snapshot of the foundations

That third field is what lets a bad output be traced back to the context that caused it. Without it a run record says only that something happened.

Runs are gitignored by default: personalising output is often the point, so this is the likeliest place an individual's details end up. Rename a file `*.public.md` to commit it, and only after a person has confirmed it names nobody. **In a shared folder there is no gitignore to rely on:** `runs/` is exactly as shared as the folder, so identifiable output belongs somewhere private.
