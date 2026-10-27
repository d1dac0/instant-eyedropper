#!/usr/bin/env bash
# The one test/check command: runs the full test suite.
# Artifacts: cargo writes nothing outside target/; failing output is on stdout.
set -euo pipefail
cargo test "$@"
