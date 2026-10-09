---
name: ai-boundaries
description: Trust boundaries around model input and output — what may reach a prompt, what a model's output may be allowed to do, and why a model is never an authorisation decision.
paths: ["src/ai/**", "src/llm/**", "src/agents/**", "**/prompts/**", "**/*prompt*.*", "server/ai/**"]
trigger: glob
---

# Model trust boundaries

A model is a **parser of untrusted text that emits untrusted text.** Every rule
here follows from that one sentence.

## Input

- **Everything that is not your own literal string is untrusted.** User messages,
  retrieved documents, tool results, web pages, file contents, database rows
  another user wrote. Retrieval does not launder provenance: a poisoned document
  in your index is a poisoned instruction.
- **Never build a prompt by concatenating trusted and untrusted text with no
  marker.** Put untrusted content in a delimited region and say what it is. The
  delimiter is not a security control — it is a legibility aid that makes the
  boundary reviewable.
- **Do not put a secret in a prompt.** Not the API key, not another user's data,
  not the row you have not yet authorised. Anything in the context window can
  come back out.

## Output

- **A model's output is a proposal, not a command.** Validate it against a schema
  before anything acts on it. An output that fails the schema is an error to
  handle, not a string to coerce.
- **The model does not decide who may do what.** Authorisation happens in your
  code, on the user's identity, before the tool runs — never because the model
  asked nicely. If a model can name a tool, your code decides whether *this
  caller* may use it on *this resource*.
- **Never pass model output into a sink that executes**: a shell, `eval`, a SQL
  string, a template that renders HTML unescaped, a file path. Parameterise or
  reject.

## The one that gets missed

**A tool result is model input.** The output of one call becomes the input of the
next, so a tool that returns attacker-controlled text hands it straight back into
the prompt. Injection through a tool result is the common path in an agent loop,
and it bypasses every check you put on the user's message.

## Non-negotiable

- No model call without a timeout and a failure path. "The API was slow" is a
  state your product has.
- No retry on a non-idempotent tool call. Retrying a charge is not resilience.
- Log the prompt's *shape* and the response's *metadata* — not the content, which
  contains user data.
