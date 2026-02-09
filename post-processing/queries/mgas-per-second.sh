#!/usr/bin/env bash
# MGas/s (Mega-gas per second) over the test range.
# Formula (same as L2 node logs): mgasps = mgas / total_time_seconds  →  total_MGas / span_secs.
# Usage: ./queries/mgas-per-second.sh [db_path] [run_id]

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
  SELECT
    COALESCE(SUM(gas_used), 0),
    MIN(start_timestamp),
    MAX(end_timestamp)
  FROM run_txs
  WHERE run_id = $run_id AND block_number IS NOT NULL AND gas_used IS NOT NULL AND end_timestamp IS NOT NULL;
")
IFS='|' read -r total_gas min_ts max_ts <<< "$row"

if [[ -z "$total_gas" || -z "$max_ts" || -z "$min_ts" || "$max_ts" -le "$min_ts" ]]; then
  echo "Average MGas/s (run_id=$run_id): no data or zero time span"
  exit 0
fi

span_secs=$((max_ts - min_ts))
# mgasps = mgas / total_time_seconds  (mgas = total_gas / 1,000,000)
mgas_per_sec=$(awk -v gas="$total_gas" -v secs="$span_secs" 'BEGIN { printf "%.2f", (gas / 1000000) / secs }')
echo "Average MGas/s (run_id=$run_id): $mgas_per_sec (total_gas=$total_gas over ${span_secs}s)"
