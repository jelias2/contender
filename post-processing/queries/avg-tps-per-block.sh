#!/usr/bin/env bash
# Average TPS per block (mean transaction count per block) over the test range.
# Usage: ./queries/avg-tps-per-block.sh [db_path] [run_id]

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

# SQL: average of (tx count per block)
avg=$(sqlite3 -batch "$CONTENDER_DB" "
  SELECT AVG(cnt) FROM (
    SELECT COUNT(*) AS cnt FROM run_txs
    WHERE run_id = $run_id AND block_number IS NOT NULL
    GROUP BY block_number
  );
")

if [[ -z "$avg" ]]; then
  echo "Average TPS per block (run_id=$run_id): no data"
  exit 0
fi

echo "Average TPS per block (run_id=$run_id): $avg"
