#!/usr/bin/env bash
# Summary stats (min, max, median, mean, std) of transactions per second for the latest run.
# Buckets mined txs by 1-second windows (by end_timestamp), then computes stats over those counts.
# Usage: ./queries/txs-per-second.sh [db_path] [run_id]
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

# Per-second counts: bucket end_timestamp by second (include seconds with 0 txs in range)
timestamps=$(sqlite3 -batch "$CONTENDER_DB" "
  SELECT end_timestamp FROM run_txs
  WHERE run_id = $run_id AND block_number IS NOT NULL AND end_timestamp IS NOT NULL;
")

if [[ -z "$timestamps" ]]; then
  echo "Transactions per second (run_id=$run_id): no mined txs"
  exit 0
fi

# Bucket by second, then output one count per second (min_sec to max_sec)
counts=$(echo "$timestamps" | awk '
  { t = int($1); c[t]++; if (t < min || min == "") min = t; if (t > max || max == "") max = t }
  END { for (s = min; s <= max; s++) print c[s] + 0 }
')

if [[ -z "$counts" ]]; then
  echo "Transactions per second (run_id=$run_id): no data"
  exit 0
fi

echo "Transactions per second (run_id=$run_id):"
echo "$counts" | sort -n | awk -f "$SCRIPT_DIR/stats.awk"
