#!/usr/bin/env bash
# The one build command. Builds the workspace.
set -euo pipefail
cargo build "$@"
