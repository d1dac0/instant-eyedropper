# Plan

The plan of record. Phases in order, each with a milestone of tracked
GitHub Issues. Agents pick open `story` issues from the current phase in
order unless a `bug` issue is open first.

## Phase 1: Overlay information density

**Goal:** The overlay shows not just the code of the color under the
cursor but human-readable context about it.

- [ ] #4 Show the nearest named color for the picked color (`{name}`
      template token + default display template)

## On-request audits

Three standing story issues wait in the tracker for the human's explicit
go-ahead — agents never take them as "the next story" in phase order:

- **What are we missing?** — blind-spot review: pre-mortem, hard
  questions, filed as grouped issues.
- **Code review audit** — full static pass; every finding its own issue.
- **Architecture audit** — focus areas derived from this project's own
  risks, findings + `docs/audits/issue-N/REPORT.md`.

Run them whenever the product or the code has grown enough to be worth a
second pair of eyes, out of phase order. Audit issues complete the audit
only — the remediation findings they create join the normal loop.

---

Rules:

- Every story and bug is a GitHub Issue; this file tracks which phase it
  belongs to, not its status. Status lives in the issue labels.
- One issue per PR. Don't bundle unrelated fixes into a story PR.
- New scope discovered mid-phase: file it as a new issue under the current
  phase, or a new phase if the changed direction is big.

## Decisions

Load-bearing decisions (a stack, a data model, a library choice, an
architecture) are written down in `docs/specs/`, one file per decision:
what was decided, the alternatives, and why. The reasoning lives there,
not in a chat session — a session can end, the file stays.

- Write the spec **before** building on the decision, so the build follows
  a written contract.
- If a decision is genuinely overturned, write a new spec and mark the old
  one `Superseded`, pointing at its replacement.
- If you must build before deciding, write the spec as `Assumed`, and
  revisit it before the feature is called done.
