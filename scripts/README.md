# Contender Scripts

This directory contains various helper scripts for running and managing Contender tests.

## Directory Structure

### `remote-testing/`
**Automated remote VM testing suite**

Run Contender tests on remote VMs across multiple geographic regions and collect results.

- **`run-all-tests.sh`** - Run automated test suites on US and JP VMs
- **`fetch-reports.sh`** - Fetch existing reports from remote VMs
- **`find-matching-runs.sh`** - Find matching test runs across regions
- **Setup Required** - See [`remote-testing/README.md`](remote-testing/README.md)

**Quick Start:**
```bash
cd remote-testing
cp .env.example .env
# Configure your VMs in .env
./run-all-tests.sh
```

### Root Scripts

#### `run-op-benchmark.sh`
**Non-interactive benchmark runner** - Executes Contender tests without prompts, ideal for automation and remote execution.

```bash
# Run a specific configuration
./scripts/run-op-benchmark.sh erc20/medium

# Run with custom parameters
./scripts/run-op-benchmark.sh erc20/medium -d 120 --tps 75

# Run all built-in configs sequentially
./scripts/run-op-benchmark.sh all
```

**Use cases:**
- **Remote VMs**: After SSH'ing into a VM, run benchmarks with any scenario
- **CI/CD pipelines**: Automated testing without user interaction
- **Scripted testing**: Called by `remote-testing/run-all-tests.sh` for multi-region tests

Available scenarios: `erc20/10-tps`, `erc20/50-tps`, `stress/high`, `blobs/default`, `transfers/default`, `univ2/default`, `l2-mint-send/default`, and more. See `configs/` directory for all options.

#### `batch-test.sh`
Run multiple test configurations sequentially on your local machine.

```bash
./scripts/batch-test.sh low-tps medium-tps high-tps
```

Results are saved to `test-results-<timestamp>/`

#### `validate-config.sh`
Validate configuration files for correctness.

```bash
# Validate all configs
./scripts/validate-config.sh

# Validate specific config
./scripts/validate-config.sh medium-tps
```

#### `compare-configs.sh`
Compare multiple configurations side-by-side.

```bash
./scripts/compare-configs.sh low-tps medium-tps high-tps
```

## Usage Patterns

### Local Development
```bash
# Quick local test
../run.sh localhost

# Batch testing locally
./batch-test.sh low-tps medium-tps high-tps
```

### Remote Benchmarking
```bash
# Multi-region automated testing
cd remote-testing
./run-all-tests.sh

# Find matching runs
./find-matching-runs.sh
```

### Configuration Management
```bash
# Validate before running
./validate-config.sh

# Compare configurations
./compare-configs.sh erc20/low erc20/medium erc20/high
```

## See Also

- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide for local testing
- [configs/README.md](../configs/README.md) - Configuration documentation
- [remote-testing/README.md](remote-testing/README.md) - Remote testing setup
