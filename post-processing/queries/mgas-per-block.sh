#!/usr/bin/env bash
# Average MGas per block over the test range.
# Formula (same as L2 node logs): mgas = GasUsed / 1,000,000  →  we report AVG(mgas) per block.
# Usage: ./queries/mgas-per-block.sh [db_path] [run_id]

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

# MGas per block = GasUsed / 1,000,000. We output the average over all blocks in the run.
avg_mgas=$(sqlite3 -batch "$CONTENDER_DB" "
  SELECT ROUND(AVG(block_gas) / 1000000.0, 2) FROM (
    SELECT SUM(gas_used) AS block_gas
    FROM run_txs
    WHERE run_id = $run_id AND block_number IS NOT NULL AND gas_used IS NOT NULL
    GROUP BY block_number
  );
")

if [[ -z "$avg_mgas" || "$avg_mgas" == "" ]]; then
  echo "Average MGas per block (run_id=$run_id): no blocks with gas data"
  exit 0 
fi

echo "Average MGas per block (run_id=$run_id): $avg_mgas"
