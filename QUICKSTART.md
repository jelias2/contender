# Contender Local Run - Quick Start Guide

This guide will help you quickly start running Contender spam tests with various configurations.

## Prerequisites

1. Set your private key environment variable:
   ```bash
   export PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
   ```

2. Build Contender (if not already built):
   ```bash
   cargo build --release
   ```

## Basic Usage

### Using Preset Configurations

Run with a preset configuration:
```bash
./run.sh medium-tps
```

Available presets:
- `low-tps` - 10 TPS, 5 accounts (debugging)
- `medium-tps` - 50 TPS, 25 accounts (balanced)
- `high-tps` - 200 TPS, 100 accounts (stress test)
- `stress-test` - 500 TPS, 200 accounts (extreme)
- `blob-test` - Blob transactions (EIP-4844)
- `transfers-test` - ETH transfers
- `univ2-test` - UniswapV2 swaps
- `storage-test` - Storage operations
- `localhost` - Local node testing

### Custom Parameters

Override specific parameters:
```bash
./run.sh medium-tps --tps 100 --duration 300
```

Run with completely custom settings:
```bash
./run.sh --rpc http://localhost:8545 --tps 50 --accounts 20 --test-type transfers
```

### Getting Help

Show all available options:
```bash
./run.sh --help
```

List all configurations:
```bash
./run.sh --list-configs
```

List all test types:
```bash
./run.sh --list-test-types
```

## Advanced Usage

### Validate Configurations

Validate all configuration files:
```bash
./scripts/validate-config.sh
```

Validate a specific configuration:
```bash
./scripts/validate-config.sh medium-tps
```

### Compare Configurations

Compare multiple configurations side-by-side:
```bash
./scripts/compare-configs.sh low-tps medium-tps high-tps
```

### Batch Testing

Run multiple configurations sequentially:
```bash
./scripts/batch-test.sh low-tps medium-tps high-tps
```

Results will be saved to `test-results-<timestamp>/`

## Configuration Files

All preset configurations are stored in `configs/` directory as `.env` files.

Example configuration file (`configs/medium-tps.env`):
```bash
RPC_URL="https://demo-ntt-0.optimism.io"
DURATION=120
TPS=50
ACCOUNTS=25
RPC_BATCH_SIZE=50
TEST_TYPE="erc20"
TX_TYPE="eip1559"
```

### Creating Custom Configurations

1. Copy an existing config:
   ```bash
   cp configs/medium-tps.env configs/my-custom.env
   ```

2. Edit the parameters:
   ```bash
   nano configs/my-custom.env
   ```

3. Use it:
   ```bash
   ./run.sh my-custom
   ```

## Common Scenarios

### Local Development
```bash
./run.sh localhost
```

### Quick Test
```bash
./run.sh low-tps
```

### Performance Benchmarking
```bash
./run.sh high-tps --duration 300
```

### Stress Testing
```bash
./run.sh stress-test
```

### Testing Specific Transaction Types

Blob transactions:
```bash
./run.sh blob-test
```

Simple transfers:
```bash
./run.sh transfers-test
```

DeFi interactions:
```bash
./run.sh univ2-test
```

## Parameters Reference

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--rpc` | RPC endpoint URL | `http://localhost:8545` |
| `--tps` | Transactions per second | `50` |
| `--accounts` | Number of accounts | `25` |
| `--batch-size` | RPC batch size | `50` |
| `--duration` | Duration in seconds | `120` |
| `--test-type` | Type of test | `erc20`, `transfers`, `blobs` |
| `--tx-type` | Transaction type | `eip1559`, `legacy`, `eip4844` |

## Test Types

- **erc20** - ERC20 token transfers
- **transfers** - Simple ETH transfers
- **blobs** - EIP-4844 blob transactions
- **uniV2** - UniswapV2 swaps
- **storage** - Storage slot filling
- **stress** - Comprehensive stress test
- **fill-block** - Fill blocks with gas-consuming txs
- **revert** - Reverting transactions
- **setCode** - EIP-7702 setCode transactions
- **contract** - Custom contract interactions
- **eth-functions** - Opcode & precompile testing

## Transaction Types

- **eip1559** - Modern transactions with priority fees (default)
- **legacy** - Legacy transaction format (type 0x0)
- **eip4844** - Blob transactions (type 0x3)
- **eip7702** - EOA set code transactions (type 0x4)

## Tips

1. **Start Small**: Begin with `low-tps` to ensure everything works
2. **Monitor Resources**: Watch CPU/memory when running high TPS tests
3. **Check Logs**: Output is colored and shows progress clearly
4. **Batch Testing**: Use `batch-test.sh` to run multiple configs and compare results
5. **Validate First**: Run `validate-config.sh` before using new configurations

## Troubleshooting

### "PRIVATE_KEY not set"
```bash
export PRIVATE_KEY=0xYOUR_KEY
```

### "Configuration file not found"
```bash
# List available configs
./run.sh --list-configs
```

### Command not found
```bash
# Make sure scripts are executable
chmod +x run.sh scripts/*.sh
```

### RPC connection issues
Check your RPC URL and network connectivity. Try with localhost first:
```bash
./run.sh localhost
```

## Examples

### Example 1: Quick Local Test
```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./run.sh localhost
```

### Example 2: Medium Load Test
```bash
./run.sh medium-tps --duration 600
```

### Example 3: Compare Different TPS Levels
```bash
./scripts/compare-configs.sh low-tps medium-tps high-tps
./scripts/batch-test.sh low-tps medium-tps high-tps
```

### Example 4: Custom Blob Test
```bash
./run.sh --tps 10 --accounts 5 --test-type blobs --tx-type eip4844 --duration 60
```

## Next Steps

- Explore `configs/README.md` for detailed configuration documentation
- Check `scripts/` directory for additional helper tools
- Create custom configurations for your specific testing needs
- Run batch tests to compare different scenarios
