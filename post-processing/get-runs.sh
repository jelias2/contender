#!/usr/bin/env bash
# List all run IDs (newest first). Use with get-run-results.sh to inspect a specific run.
# Usage: ./post-processing/get-runs.sh [db_path]

set -euo pipefail

CONTENDER_DB="${1:-${CONTENDER_DB:-}}"
if [[ -z "$CONTENDER_DB" ]]; then
  CONTENDER_DB="${HOME:?}/.contender/contender.db"
fi

if ! command -v sqlite3 &>/dev/null; then
  echo "error: sqlite3 not found. Install sqlite3 to run this script." >&2
  exit 1
fi

if [[ ! -f "$CONTENDER_DB" ]]; then
  echo "error: database not found: $CONTENDER_DB" >&2
  exit 1
fi

echo "run_id (newest first):"
sqlite3 -batch "$CONTENDER_DB" "SELECT id FROM runs ORDER BY id DESC;"
