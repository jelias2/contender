#!/usr/bin/env bash
# Run all latest-run query scripts (metrics, TPS, txs per block).
# Usage: ./post-processing/get-latest-results.sh [db_path]
#   db_path defaults to ~/.contender/contender.db
# Requires: sqlite3

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
  echo "Run contender at least once (e.g. contender spam ... erc20) to create the DB." >&2
  exit 1
fi

QUERIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/queries" && pwd)"

"$QUERIES_DIR/latest-run-metrics.sh" "$CONTENDER_DB"
echo ""
"$QUERIES_DIR/txs-per-second.sh" "$CONTENDER_DB"
echo ""
"$QUERIES_DIR/txs-per-block.sh" "$CONTENDER_DB"
echo ""
"$QUERIES_DIR/mgas-per-second.sh" "$CONTENDER_DB"
"$QUERIES_DIR/mgas-per-block.sh" "$CONTENDER_DB"
"$QUERIES_DIR/avg-tps-per-block.sh" "$CONTENDER_DB"
