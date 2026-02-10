#!/usr/bin/env bash
# Block with the maximum TPS (tx count) in the run. Outputs block_number and tx_count.
# Usage: ./queries/max-tps-per-block.sh [db_path] [run_id]

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

row=$(sqlite3 -batch "$CONTENDER_DB" "
  SELECT block_number, cnt FROM (
    SELECT block_number, COUNT(*) AS cnt
    FROM run_txs
    WHERE run_id = $run_id AND block_number IS NOT NULL
    GROUP BY block_number
    ORDER BY cnt DESC
    LIMIT 1
  );
")

if [[ -z "$row" ]]; then
  echo "Max TPS per block (run_id=$run_id): no blocks with txs"
  exit 0
fi

IFS='|' read -r block_number tx_count <<< "$row"
echo "Max TPS per block (run_id=$run_id): block_number=$block_number tx_count=$tx_count"
