# Contender Configuration Presets

This directory contains preset configurations for running Contender spam tests, grouped by **test type**. Each test type has a subdirectory with one or more preset files (e.g. `erc20/low.env`, `erc20/medium.env`).

## Available Configurations

Config names are **`<test-type>/<preset>`**. Run `./run.sh --list-configs` to see the full list.

### erc20
- **low** – TPS 10, 5 accounts. Debugging, basic testing.
- **medium** – TPS 50, 25 accounts. Balanced load testing.
- **high** – TPS 200, 100 accounts. Stress testing.

### stress
- **high** – TPS 500, 200 accounts, 300s. Extreme stress, maximum load.

### blobs
- **default** – EIP-4844 blob transactions. TPS 20, 10 accounts.

### transfers
- **default** – Simple ETH transfers. TPS 100, 50 accounts.

### univ2
- **default** – UniswapV2 swaps. TPS 30, 15 accounts.

### storage
- **default** – Storage operations. TPS 40, 20 accounts.

### l2-mint-send
- **default** – L2 mint + SuperchainTokenBridge (scenario file `scenarios/op-interop/l2MintAndSend.toml`). Setup + spam flow.

### localhost
- **default** – Local development. RPC http://localhost:8545, TPS 25, 10 accounts.

## How to run (unified)

Use the **same config name** with either runner:

| Method | Use when |
|--------|----------|
| **`./run.sh <config-name>`** | Interactive: shows config, prompts to continue, then runs. |
| **`./scripts/run-op-benchmark.sh <config-name>`** | Scripted/CI: no prompt, same config names. Use `all` to run erc20/low through univ2/default in sequence. |

Examples: `./run.sh erc20/medium`, `./scripts/run-op-benchmark.sh erc20/medium`, `./scripts/run-op-benchmark.sh all`.

List all config names: `./run.sh --list-configs`.

## Usage

### Using a Preset Configuration

```bash
./run.sh erc20/medium
```

### Listing All Configurations

```bash
./run.sh --list-configs
```

### Creating Custom Configurations

1. Copy an existing configuration file into the appropriate test-type subdir (or create a new subdir).
2. Modify the parameters.
3. Save with a descriptive preset name (e.g. `custom.env`).
4. Use it with `./run.sh <test-type>/<preset>` (e.g. `./run.sh erc20/custom`).

## Configuration Parameters

Each configuration file can contain:

- **RPC_URL**: The RPC endpoint to target
- **DURATION**: Test duration in seconds
- **TPS**: Transactions per second
- **ACCOUNTS**: Number of accounts per agent
- **RPC_BATCH_SIZE**: Number of transactions per batch request
- **TEST_TYPE**: Type of test (erc20, transfers, blobs, etc.) — omit for scenario-file configs
- **TX_TYPE**: Transaction type (eip1559, legacy, eip4844, eip7702)
- **SCENARIO_PATH**: Path to scenario TOML (for setup + spam configs like `l2-mint-send/default`)

## Overriding Parameters

You can override individual parameters from a preset:

```bash
./run.sh erc20/medium --tps 100 --duration 300
```

## Custom Parameters

Run with completely custom parameters:

```bash
./run.sh --rpc http://localhost:8545 --tps 100 --accounts 50 --test-type transfers
```

## Environment Variables

The `PRIVATE_KEY` environment variable must be set:

```bash
export PRIVATE_KEY=0x...
./run.sh erc20/medium
```

Or pass it directly:

```bash
./run.sh erc20/medium -p 0x...
```
