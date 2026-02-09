# Contender Configuration Presets

This directory contains preset configurations for running Contender spam tests with various parameters.

## Available Configurations

### `low-tps.env`
- **TPS**: 10
- **Accounts**: 5
- **Batch Size**: 10
- **Use Case**: Debugging, basic testing, development

### `medium-tps.env`
- **TPS**: 50
- **Accounts**: 25
- **Batch Size**: 50
- **Use Case**: Balanced load testing, default configuration

### `high-tps.env`
- **TPS**: 200
- **Accounts**: 100
- **Batch Size**: 100
- **Use Case**: Stress testing, performance benchmarking

### `stress-test.env`
- **TPS**: 500
- **Accounts**: 200
- **Batch Size**: 200
- **Duration**: 300s
- **Use Case**: Extreme stress testing, finding limits

### `blob-test.env`
- **TPS**: 20
- **Accounts**: 10
- **Batch Size**: 20
- **Test Type**: blobs (EIP-4844)
- **Use Case**: Testing blob transaction handling

### `transfers-test.env`
- **TPS**: 100
- **Accounts**: 50
- **Batch Size**: 75
- **Test Type**: transfers
- **Use Case**: Simple ETH transfer testing

### `univ2-test.env`
- **TPS**: 30
- **Accounts**: 15
- **Batch Size**: 30
- **Test Type**: uniV2
- **Use Case**: DeFi interaction testing (UniswapV2)

### `storage-test.env`
- **TPS**: 40
- **Accounts**: 20
- **Batch Size**: 40
- **Test Type**: storage
- **Use Case**: Storage operation testing

### `localhost.env`
- **TPS**: 25
- **Accounts**: 10
- **Batch Size**: 25
- **RPC**: http://localhost:8545
- **Use Case**: Local development, testing against local node

### OP Benchmark (bare bones)

The **`op-benchmark/`** directory holds configs that replicate k8s/kustomize op-benchmark–style test cases using only Contender (no Kubernetes). Use the script from repo root:

```bash
./scripts/run-op-benchmark.sh <case>   # case: low, medium, high, stress, blobs, transfers, univ2, l2-mint-send, all
```

See **`op-benchmark/README.md`** for the full list of cases and manual commands.

## Usage

### Using a Preset Configuration

```bash
./run.sh medium-tps
```

### Listing All Configurations

```bash
./run.sh --list-configs
```

### Creating Custom Configurations

1. Copy an existing configuration file
2. Modify the parameters
3. Save with a descriptive name
4. Use it with `./run.sh your-config-name`

## Configuration Parameters

Each configuration file can contain:

- **RPC_URL**: The RPC endpoint to target
- **DURATION**: Test duration in seconds
- **TPS**: Transactions per second
- **ACCOUNTS**: Number of accounts per agent
- **RPC_BATCH_SIZE**: Number of transactions per batch request
- **TEST_TYPE**: Type of test (erc20, transfers, blobs, etc.)
- **TX_TYPE**: Transaction type (eip1559, legacy, eip4844, eip7702)

## Overriding Parameters

You can override individual parameters from a preset:

```bash
./run.sh medium-tps --tps 100 --duration 300
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
./run.sh medium-tps
```

Or pass it directly:

```bash
./run.sh medium-tps -p 0x...
```
