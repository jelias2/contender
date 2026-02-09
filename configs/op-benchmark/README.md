# OP Benchmark – Bare Bones Contender

This folder replicates **op-benchmark**-style test cases using only Contender (no Kubernetes/Kustomize). Use these configs to run the same scenarios locally or in CI with `contender spam` (and, for scenario files, `contender setup` + `contender spam`).

## Prerequisites

- `PRIVATE_KEY` set (or pass `-p` to the runner).
- Contender built: `cargo build --release` (or `cargo build` for `run.sh` debug binary).

## Test cases (scenarios)

| Case              | Config file       | Description                          | Contender flow              |
|-------------------|-------------------|--------------------------------------|-----------------------------|
| **low**           | `low.env`         | Low TPS, few accounts (debug)        | Built-in `erc20`            |
| **medium**        | `medium.env`      | Medium TPS, balanced                 | Built-in `erc20`            |
| **high**          | `high.env`        | High TPS, stress                     | Built-in `erc20`            |
| **stress**        | `stress.env`      | Extreme TPS, max load                | Built-in `stress`           |
| **blobs**         | `blobs.env`       | EIP-4844 blob txs                    | Built-in `blobs`            |
| **transfers**     | `transfers.env`   | Simple ETH transfers                 | Built-in `transfers`        |
| **univ2**         | `univ2.env`       | UniswapV2 swaps                      | Built-in `uniV2`            |
| **l2-mint-send**  | `l2-mint-send.env`| L2 mint + SuperchainTokenBridge send | Scenario file (see below)   |

## Run with the script (recommended)

From repo root:

```bash
# Run a single case (built-in scenario)
./scripts/run-op-benchmark.sh low
./scripts/run-op-benchmark.sh medium
./scripts/run-op-benchmark.sh high
./scripts/run-op-benchmark.sh stress
./scripts/run-op-benchmark.sh blobs
./scripts/run-op-benchmark.sh transfers
./scripts/run-op-benchmark.sh univ2

# Run the L2 scenario file (mint + send)
./scripts/run-op-benchmark.sh l2-mint-send

# Run all cases (built-in only; l2-mint-send must be run separately if desired)
./scripts/run-op-benchmark.sh all
```

Override RPC or duration:

```bash
./scripts/run-op-benchmark.sh medium --rpc https://your-op-rpc.io --duration 60
```

## Run manually (bare bones)

Source the desired config and call Contender.

### Built-in scenarios (low, medium, high, stress, blobs, transfers, univ2)

```bash
source configs/op-benchmark/medium.env
./target/release/contender spam \
  -r "$RPC_URL" \
  -p "$PRIVATE_KEY" \
  -d "$DURATION" \
  --tps "$TPS" \
  --accounts "$ACCOUNTS" \
  --rpc-batch-size "$RPC_BATCH_SIZE" \
  -t "$TX_TYPE" \
  $TEST_TYPE
```

### L2 mint + send (scenario file)

Uses `scenarios/op-interop/l2MintAndSend.toml`. Setup once, then spam:

```bash
source configs/op-benchmark/l2-mint-send.env
SCENARIO="./scenarios/op-interop/l2MintAndSend.toml"

# One-time setup (deploy/fund if needed)
./target/release/contender setup "$SCENARIO" "$RPC_URL" -p "$PRIVATE_KEY" --min-balance 0.25

# Spam run
./target/release/contender spam "$SCENARIO" "$RPC_URL" \
  --tps "$TPS" -d "$DURATION" -p "$PRIVATE_KEY" \
  --accounts "$ACCOUNTS" --rpc-batch-size "$RPC_BATCH_SIZE" \
  --min-balance 0.05
```

## RPC default

Configs default to `https://demo-ntt-2-0.optimism.io`. Override with `RPC_URL` or `--rpc` when sourcing or via the script.

## Mapping from k8s/kustomize/op-benchmark

If your k8s op-benchmark defines jobs like:

- **erc20-low / erc20-medium / erc20-high** → use `low.env`, `medium.env`, `high.env` with built-in `erc20`.
- **stress** → use `stress.env` with built-in `stress`.
- **blobs** → use `blobs.env` with built-in `blobs`.
- **transfers** → use `transfers.env` with built-in `transfers`.
- **univ2** → use `univ2.env` with built-in `uniV2`.
- **l2-interop / mint-and-send** → use `l2-mint-send.env` and the scenario file above.

Adjust TPS, duration, and accounts in the `.env` files to match your k8s benchmark definitions.
