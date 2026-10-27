# Build and development

- `tools/build.sh` — the one build command, runnable from a fresh agent
  session with no arguments. It configures if needed, then builds.
- `tools/check.sh` — the one test/regression check command, and where its
  artifacts (screenshots, logs) land.
- `tools/bootstrap.sh` — one-time repo setup (labels, branch protection).

The workflow in `AGENTS.md` assumes these exist and stand alone, so agents
never reconstruct build steps from memory.
