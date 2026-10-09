# Corpus — judged examples

**The organ that makes a soft standard harnessable.** Also the one most often missing.

```
corpus/
├── accepted/   what good looks like
└── rejected/   what wrong looks like — usually the more useful half
```

**Every example carries its reason.** An example without one is decoration; the reason is the reusable part. Concrete examples calibrate faster than adjectives, and rejections calibrate faster than acceptances, because what to avoid is easier to state than what to achieve.

## Two jobs

**Now** — this is what an agent reads before generating, and what a reviewer reads before judging.

**Later** — this is the *prerequisite for automating the standard*. You cannot write a deterministic check for "on-brand" or "well-argued" until enough judged examples exist to know what you actually mean. Writing the check first encodes today's guesses as permanent rules. See `../../LADDER.md`.

## Filing

`{accepted|rejected}/YYYY-MM-DD-<slug>.md`, containing the output, who judged it, and **why** — in the judge's own words, not a category.

File it at the moment of judgement. Skipping it means every future run starts from zero, and the spec never changes after contact with real output — which looks like stability and is actually disuse.
