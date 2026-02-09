#!/usr/bin/env bash
# Summary stats (min, max, median, mean, std) of transactions per block for the latest run.
# Usage: ./queries/txs-per-block.sh [db_path] [run_id]
#   If run_id is omitted, uses latest run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh" "$1"

if [[ -n "${2:-}" ]]; then
  run_id="$2"
  exists=$(sqlite3 -batch "$CONTENDER_DB" "SELECT 1 FROM runs WHERE id = $run_id;")
  if [[ -z "$exists" ]]; then
    echo "error: run_id $run_id not found in database" >&2
    exit 1
  fi
else
  run_id=$(sqlite3 -batch "$CONTENDER_DB" "SELECT MAX(id) FROM runs;")
  if [[ -z "$run_id" || "$run_id" -eq 0 ]]; then
    echo "error: no runs found in database" >&2
    exit 1
  fi
fi

# One row per block: tx_count
counts=$(sqlite3 -batch "$CONTENDER_DB" "
  SELECT COUNT(*) FROM run_txs
  WHERE run_id = $run_id AND block_number IS NOT NULL
  GROUP BY block_number;
")

if [[ -z "$counts" ]]; then
  echo "Transactions per block (run_id=$run_id): no blocks with txs"
  exit 0
fi

echo "Transactions per block (run_id=$run_id):"
echo "$counts" | sort -n | awk -f "$SCRIPT_DIR/stats.awk"
