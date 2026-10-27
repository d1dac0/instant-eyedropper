# Working on this repo

Instant Eyedropper Reborn (IE-R): a system-wide color picker and daemon
for Linux (Wayland/X11) and Windows, written in Rust. The plan of record
lives in `PLAN.md`, decisions in `docs/specs/`, findings in GitHub
issues. The user verifies work by running the built binary and picking a
color.

Several agent sessions work on the repo at once. Each one takes its own
issue, works on its own branch in its own git worktree, and lands it on
`master` through a pull request (see Git). Never work directly on
`master`.

## The loop: one issue per turn, then stop

1. **Check the checkout and findings first.** On every start and every
   "continue", inspect the current checkout and open pull requests, then
   list the open bugs:
   ```bash
   git status --short --branch
   gh pr list -R d1dac0/instant-eyedropper
   gh issue list -R d1dac0/instant-eyedropper --state open --label bug
   ```
   Open bugs come before stories. Read the whole issue
   (`gh issue view N -R d1dac0/instant-eyedropper --comments`). With no
   bugs, take the next `story` of the current phase's milestone in
   `PLAN.md`.
   **Skip issues another session holds:** those assigned to someone else,
   labelled `in-progress`, or with an open pull request.
   **Never auto-take the three standing audit stories** ("What are we
   missing?", "Code review audit", "Architecture audit"). The human gives
   the go-ahead for those explicitly.
2. **Claim it and branch.** Label the issue so other sessions skip it, then
   work in a worktree on a fresh branch (see Git):
   ```bash
   gh issue edit N -R d1dac0/instant-eyedropper --add-label in-progress
   ```
3. **Plan the change** before writing code. Small tasks: a short list of
   the steps is enough. Larger tasks: write the plan down first and have
   the user approve it before touching code. A load-bearing decision (a
   stack, a data model, an architecture) is written down in `docs/specs/`
   before building on it — see `PLAN.md` and the Decisions rule below.
4. **Write the code** in small, focused commits.
5. **Verify it before closing:** run the build (see Verification), the
   project's test or check command, and any regression check this file
   defines. Inspect the actual output, not just the exit code.
6. **Commit, push and open a pull request** with `Fixes #N`. Describe the
   behavior change and actual validation; include screenshots for visual
   changes and explain configuration or data impacts when applicable.
7. **Review and merge the pull request.** Inspect its diff against the
   issue's acceptance criteria and confirm relevant local validation
   passed. Wait for required checks and reviews; leave failed,
   conflicting, draft, or incomplete pull requests open. Merge only the
   validated PR head as described in Git, without bypassing branch
   protections. If no CI is configured, report the local checks actually
   run and don't claim CI passed. Verify the PR merged.
8. **Stop and hand over.** End the turn with:
   - first line: what changed, the issue, the PR link, the merged commit
     hash;
   - how to try it: the exact command and what to look for;
   - **Next:** the issue you'll take after the user's OK.

   Don't start the next issue in the same turn. Wait for "continue", "go"
   or "looks good". If they report a problem, fix that before anything
   else. A correction to how you fixed something means reverting to the
   smallest fix for what they actually saw. A fix to a merged issue is a
   new branch and pull request from the latest `origin/master`.

## How to work with the user

- **Keep the session chat title current.** At the start of each task, set
  the current session's chat title to a concise description of the work;
  update it if the focus materially changes. Treat title updates as
  nonblocking housekeeping: never pause or delay task work to rename or
  retry. If a title update is unavailable or fails, continue the workflow
  immediately.
- **The user decides; the agent recommends.** Every question carries
  exactly one recommended option with a one-line why, so the user can make
  the call or override. Never a neutral listing, never a silent decision.
- **Suggestions, not gates.** Extended checks, reviews, and docs steps are
  offered for each change; the user picks. `done` is the user's to declare.
  A skipped step is recorded honestly as skipped, not silently dropped or
  hidden as done.
- **Keep state in files, not chat.** Plans live in `PLAN.md`, decisions in
  `docs/specs/`, findings in issues. Anything a next session needs must be
  written down — a session can end at any point.
- **Lead with the action.** Reports start with what changed or what to do;
  detail lives in the linked file or PR. Ask one question at a time.

## Git

One issue, one branch, one worktree:

```bash
git worktree add .worktrees/issue-N -b issue-N-name
```

- The worktree directory is `.worktrees/` at the repo root (older tooling:
  an existing `.worktrees/` or `worktrees/`, else the default). It must be
  ignored by git so its contents can never be staged by accident. If
  `git check-ignore -q .worktrees/probe` fails, add `/.worktrees/` to
  `.git/info/exclude` or `.gitignore`.
- Detect existing isolation first: if `git rev-parse --git-dir` and
  `git rev-parse --git-common-dir` differ, this checkout is already a
  linked worktree — use it, create nothing.
- If the current checkout has unrelated local changes, leave them untouched
  and create a separate worktree for this issue. Never discard or silently
  stash those changes.
- Run the setup command from Verification after creating a worktree
  (none named: say so), and get a clean baseline of the test/check command
  before changing code. A failing baseline is recorded, not chased; judge
  later failures against it.
- Merge `origin/master` into the branch to bring it up to date. **No
  rebase, no force pushes.**
- Read the current PR head SHA and merge with
  `gh pr merge <number> -R d1dac0/instant-eyedropper --squash --match-head-commit <sha> --delete-branch`.
  If the head changes, validate the new revision before retrying. Never
  bypass branch protections, and verify that the PR is merged.
- Commit messages: short, plain-English summaries of the behavior changed.
- Never stage everything blindly. Name explicit file paths; never use
  `git add -A` or `git add .`.
- Never commit generated files, build outputs, or local data/config
  files. Check `.gitignore` covers them before the first commit.

## Verification

- Build: `bash tools/build.sh` (cargo build). Must compile clean.
- Check: `bash tools/check.sh` (cargo test). Inspect the summary counts,
  not just the exit code.
- Manual look for UI/behavior changes: run the binary from `target/`
  (`cargo run --` for CLI subcommands like `coords`; the daemon/overlay
  needs a desktop session) and look at the actual output/screenshot.
- A change is not done until the build, the check, and a manual look at
  the result pass.

## Code style

- Rust, standard `rustfmt` defaults; match nearby code.
- Tests live in sibling `*_tests.rs` files wired in as `#[cfg(test)]
  #[path = "..._tests.rs"] mod tests;` — test mechanics stay out of logic
  files.
- Core logic is organized under `src/core/` (formats, config, overlay,
  capture backends under `src/connectors/`). New features follow that
  layout rather than growing `main.rs`.
- Config is mirrored in `src/core/default_config.toml` — a config change
  updates both the struct defaults in `src/core/config.rs` and that file.

## Data and configuration

Local secrets, extracted data, and build outputs stay out of version
control. Keep local paths out of committed files; if a path must differ
per machine, read it from config or environment.

Before running seed, migration, cleanup, or setup scripts, inspect what data
they change. Use disposable data for destructive operations; do not run them
against live or user data without the user's explicit authorization.

## Decisions

Load-bearing decisions are written in `docs/specs/`, one file per
decision: what was decided, the alternatives, why. Write it before
building on it. Overturning one writes a new spec and marks the old
`Superseded`. Building before deciding writes it as `Assumed` and expects
it revisited before done. The reasoning lives in the file, not the chat.

## GitHub identity

All GitHub work runs under the account **d1dac0**: repo creation, issues,
labels, PRs, and merges. The `gh` CLI and `git` remotes must point at it —
if a command acts as another account, `gh auth switch`. In worktrees,
scripts, and one-off commands carry it explicitly:
`gh issue list -R d1dac0/instant-eyedropper`, `gh pr view N
-R d1dac0/instant-eyedropper` — don't rely on the working directory
deciding which repo answers.

## Shared memory across sessions

This project keeps a local, user-owned Engram graph in `.engram/`
(git-ignored): durable reasoning — decisions, principles, cautions,
problems/resolutions, open intents. Not a code map. It is how sessions
learn what the others found; git/issues say what changed, Engram says why
and what to watch out for. If `.engram/` does not exist yet, this section
doesn't apply until it does — set it up with `engram-alpha serve` in the
repo root.

- **Recall.** Read the project brief at session start (an injected
  "# Engram brief", else call `brief` once). If the brief names a graph
  other than this workspace, rebind: call `brief` with this workspace's
  ABSOLUTE path. In a worktree, always bind with the project's name before
  reading or writing memory — writes made while bound by fallback land in
  the wrong graph. Before any non-trivial work, `search` the graph, read
  each hit's context before concluding it is silent.
- **Capture.** Sparing and durable only: key decisions with their reasons,
  principles, hard-won cautions, problems with their resolutions. Title =
  the claim, body = the why in 1–3 sentences. A dozen good nodes beat
  fifty mirrored doc lines; when in doubt, don't write. Every write reply
  is a verdict: `matched` → update that node; suspects → judge each
  (conflict, replaces, dismiss) and surface genuine contradictions to the
  user. Write silently at natural stopping points, never store secrets.
- **Maintain.** Judge the brief's suspects first; merge duplicates; verify
  stale hits before re-adding. The pane is at `http://127.0.0.1:8787`
  (real port in `.engram/daemon.json`); `engram-alpha serve` in the repo
  root starts the core and exits. If the MCP tools disconnect, don't
  drop captures: `POST /nodes` on that port with `"source": "claude"`,
  or ask the user to reconnect.
