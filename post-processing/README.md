# Post-processing

Simple scripts that read from contender’s SQLite DB after a run (e.g. to aggregate metrics or feed into other tooling).

## Prerequisites

- **sqlite3** – must be installed (e.g. `brew install sqlite3` on macOS).

## Scripts

### get-runs.sh

Lists all run IDs (newest first). Use with `get-run-results.sh` to inspect a specific run.

```bash
./post-processing/get-runs.sh
./post-processing/get-runs.sh /path/to/contender.db
```

### get-run-results.sh

Runs all query scripts for a **specific run_id** (metrics, TPS, txs per block). Run ID comes from `get-runs.sh`.

```bash
./post-processing/get-run-results.sh 6
./post-processing/get-run-results.sh 6 /path/to/contender.db
```

### get-latest-results.sh

Runs all queries for the **latest** run (same as above but no run_id needed). Each query is implemented under `queries/` so you can run them individually.

```bash
./post-processing/get-latest-results.sh
./post-processing/get-latest-results.sh /path/to/contender.db
```

Run contender at least once (e.g. `contender spam ... erc20`) so the DB exists before calling.

### queries/

Standalone query scripts. Each accepts optional `[db_path]` and, for run-specific output, optional `[run_id]` (if omitted, the latest run is used).

| Script | What it does |
|--------|----------------|
| **latest-run-metrics.sh** | Latest run: `run_id`, `txs_sent`, `txs_mined`, `txs_reverted`, `min_block_number`, `max_block_number` (same as op-benchmark GetLatestResults). |
| **txs-per-second.sh** | Summary stats (min, max, median, mean, std) of **transactions per second** (1-second buckets by `end_timestamp`). |
| **txs-per-block.sh** | Summary stats (min, max, median, mean, std) of **transactions per block**. |
| **mgas-per-second.sh** | **Average MGas/s** over the test range (total gas used by mined txs ÷ time span). |
| **mgas-per-block.sh** | **Average total MGas per block** over the test range (mean of sum(gas_used) per block). |
| **avg-tps-per-block.sh** | **Average TPS per block** (mean transaction count per block). |
| **max-tps-per-block.sh** | **Max TPS per block**: block with the highest tx count; outputs `block_number` and `tx_count`. |

```bash
# From repo root
./post-processing/queries/latest-run-metrics.sh
./post-processing/queries/txs-per-second.sh
./post-processing/queries/txs-per-block.sh
./post-processing/queries/mgas-per-second.sh
./post-processing/queries/mgas-per-block.sh
./post-processing/queries/avg-tps-per-block.sh
./post-processing/queries/max-tps-per-block.sh

# With a specific DB
./post-processing/queries/txs-per-block.sh /path/to/contender.db

# For a specific run (e.g. run_id 6)
./post-processing/queries/latest-run-metrics.sh "" 6
./post-processing/queries/mgas-per-second.sh /path/to/contender.db 6
./post-processing/queries/avg-tps-per-block.sh /path/to/contender.db 6
```
