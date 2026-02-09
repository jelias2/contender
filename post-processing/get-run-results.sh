#!/usr/bin/env bash
# Run all query scripts for a specific run_id (metrics, TPS, txs per block).
# Usage: ./post-processing/get-run-results.sh <run_id> [db_path]
#   run_id  – from ./get-runs.sh
#   db_path – optional, defaults to ~/.contender/contender.db
# Requires: sqlite3

set -euo pipefail

if [[ ${1:-} == "" ]]; then
  echo "usage: $0 <run_id> [db_path]" >&2
  echo "  run_id  – from ./post-processing/get-runs.sh" >&2
  echo "  db_path – optional" >&2
  exit 1
fi

RUN_ID="$1"
CONTENDER_DB="${2:-${CONTENDER_DB:-}}"
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

# Ensure run exists
exists=$(sqlite3 -batch "$CONTENDER_DB" "SELECT 1 FROM runs WHERE id = $RUN_ID;")
if [[ -z "$exists" ]]; then
  echo "error: run_id $RUN_ID not found in database" >&2
  exit 1
fi

QUERIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/queries" && pwd)"

"$QUERIES_DIR/latest-run-metrics.sh" "$CONTENDER_DB" "$RUN_ID"
echo ""
"$QUERIES_DIR/txs-per-second.sh" "$CONTENDER_DB" "$RUN_ID"
echo ""
"$QUERIES_DIR/txs-per-block.sh" "$CONTENDER_DB" "$RUN_ID"
echo ""
"$QUERIES_DIR/mgas-per-second.sh" "$CONTENDER_DB" "$RUN_ID"
"$QUERIES_DIR/mgas-per-block.sh" "$CONTENDER_DB" "$RUN_ID"
"$QUERIES_DIR/avg-tps-per-block.sh" "$CONTENDER_DB" "$RUN_ID"
