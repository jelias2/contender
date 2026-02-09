#!/usr/bin/env bash
# Run metrics: run_id, txs_sent, txs_mined, txs_reverted, min/max block.
# Same query as benchmarking internal/results/contender/results.go GetLatestResults.
# Usage: ./queries/latest-run-metrics.sh [db_path] [run_id]
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
  QUERY="
  SELECT
    $run_id,
    (SELECT COUNT(*) FROM run_txs WHERE run_id = $run_id),
    (SELECT COUNT(*) FROM run_txs WHERE run_id = $run_id AND block_number IS NOT NULL),
    (SELECT COUNT(*) FROM run_txs WHERE run_id = $run_id AND error IS NOT NULL),
    (SELECT MIN(block_number) FROM run_txs WHERE run_id = $run_id AND block_number IS NOT NULL),
    (SELECT MAX(block_number) FROM run_txs WHERE run_id = $run_id AND block_number IS NOT NULL);
  "
else
  QUERY='
  WITH latest_run AS (
    SELECT MAX(id) AS run_id FROM runs
  )
  SELECT
    l.run_id,
    (SELECT COUNT(*) FROM run_txs WHERE run_id = l.run_id) AS num_txs_sent,
    (SELECT COUNT(*) FROM run_txs WHERE run_id = l.run_id AND block_number IS NOT NULL) AS num_txs_mined,
    (SELECT COUNT(*) FROM run_txs WHERE run_id = l.run_id AND error IS NOT NULL) AS num_txs_reverted,
    (SELECT MIN(block_number) FROM run_txs WHERE run_id = l.run_id AND block_number IS NOT NULL) AS min_block_number,
    (SELECT MAX(block_number) FROM run_txs WHERE run_id = l.run_id AND block_number IS NOT NULL) AS max_block_number
  FROM latest_run l;
  '
fi

row=$(sqlite3 -batch "$CONTENDER_DB" "$QUERY")
if [[ -z "$row" ]]; then
  echo "error: no runs found in database" >&2
  exit 1
fi

IFS='|' read -r run_id num_txs_sent num_txs_mined num_txs_reverted min_block max_block <<< "$row"

echo "contender db: $CONTENDER_DB"
echo "run_id:           $run_id"
echo "txs_sent:         $num_txs_sent"
echo "txs_mined:        $num_txs_mined"
echo "txs_reverted:     $num_txs_reverted"
echo "min_block_number: ${min_block:-NULL}"
echo "max_block_number: ${max_block:-NULL}"
