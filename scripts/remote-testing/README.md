# Remote Testing Scripts

This directory contains scripts for running Contender tests on remote VMs and collecting results.

## Overview

These scripts enable you to:
- Run automated test suites on multiple remote VMs simultaneously
- Fetch and organize test reports from remote VMs
- Match test runs across different geographic regions (e.g., US and JP VMs)

## Architecture

The remote testing setup is designed for multi-region benchmarking:

### Repository Deployment
- **The Contender repository is cloned on two remote machines** (typically in different geographic regions, e.g., US and Japan)
- Each VM has the full repository at `~/contender` with all scripts, configurations, and the compiled binary
- The same repository structure exists on both machines, ensuring consistent test execution

### Automated Testing Flow
- Tests are executed **back-to-back** on both VMs using `run-all-tests.sh`
- Each test run is assigned a unique Run ID (timestamp + config name) that matches across both regions
- After tests complete, results are automatically fetched from both VMs and organized locally
- This allows for easy comparison of performance across geographic regions

### Manual Testing on VMs
You can also SSH into any VM and manually run tests:

1. **SSH into a VM:**
   ```bash
   ssh -i /path/to/your/key ubuntu@your.vm.ip
   ```

2. **Run a benchmark with any scenario:**
   ```bash
   # Navigate to the contender directory
   cd ~/contender

   # Export your private key
   export PRIVATE_KEY="0x..."

   # Run with the erc20 scenario
   ./scripts/run-op-benchmark.sh erc20/10-tps

   # Or run with other scenarios
   ./scripts/run-op-benchmark.sh erc20/50-tps
   ./scripts/run-op-benchmark.sh stress/high
   ./scripts/run-op-benchmark.sh l2-mint-send/default

   # Run with custom parameters
   ./scripts/run-op-benchmark.sh erc20/medium -d 120 --tps 75
   ```

3. **Available scenarios:**
   - `erc20/*` - ERC20 token transfer tests (10-tps, 50-tps, 400-tps, 800-tps, 1600-tps, 3200-tps, 4000-tps, 5000-tps)
   - `stress/high` - High-stress testing (500 TPS, 200 accounts)
   - `blobs/default` - EIP-4844 blob transactions
   - `transfers/default` - Simple ETH transfers
   - `univ2/default` - UniswapV2 swap operations
   - `l2-mint-send/default` - L2 mint + SuperchainTokenBridge scenario
   - See `configs/` directory for all available scenarios

4. **Generate reports:**
   ```bash
   # After a test completes, generate an HTML report
   contender report

   # Reports are saved to ~/.contender/reports/
   ```

See the [Creating Custom Configurations](#creating-custom-configurations) section below for details on adding new test scenarios.

## Prerequisites

Before using these scripts, ensure:

1. **Remote VMs are set up** with Contender installed
2. **SSH access** is configured to your VMs
3. **Config files exist** in `configs/erc20/` for the tests you want to run

## Setup

### 1. Configure Environment Variables

From the repository root:

```bash
cd scripts/remote-testing
cp .env.example .env
nano .env  # or use your preferred editor
```

Required configuration:
- `US_IP` - IP address of your US VM
- `JP_IP` - IP address of your JP VM
- `SSH_KEY_PATH` - Path to your SSH private key
- `SSH_USER` - SSH username (typically "ubuntu")
- `PRIVATE_KEY` - Ethereum private key for funding transactions

Optional configuration:
- `ENABLE_GRAFANA` - Set to `true` to generate Grafana dashboard URLs
- `GRAFANA_BASE_URL` - Your Grafana dashboard URL
- `GRAFANA_PARAMS` - Grafana query parameters

### 2. Ensure SSH Access

Make sure you can SSH into your VMs:

```bash
ssh -i /path/to/your/key ubuntu@your.vm.ip
```

### 3. Prepare Remote VMs

Ensure each remote VM has:
- Contender installed at `~/contender`
- Post-processing scripts at `~/contender/post-processing`
- Proper ulimit settings for file descriptors

## Scripts

### `run-all-tests.sh`

Main script for running automated test suites on multiple VMs.

**Features:**
- Runs tests on US and JP VMs in sequence
- Cleans up old reports before each test
- Fetches and organizes results by test type and run ID
- Optionally generates Grafana dashboard URLs
- Creates matching run IDs for US/JP test pairs

**Usage:**

```bash
# From repository root
cd scripts/remote-testing
./run-all-tests.sh
```

**Configuration:**

Edit the `CONFIGS` array in the script to specify which test configurations to run. These should match config files in `../../configs/erc20/`:

```bash
CONFIGS=(
    "10-tps"      # Uses configs/erc20/10-tps.env
    "50-tps"      # Uses configs/erc20/50-tps.env
    "400-tps"     # Uses configs/erc20/400-tps.env
    # Add more configurations as needed
)
```

**Note:** The configurations must exist as `.env` files in the `configs/erc20/` directory at the repository root.

**Output Structure:**

Results are saved in the `scripts/remote-testing/` directory:

```
scripts/remote-testing/
├── us/                           # US VM results
│   └── erc20/
│       └── <config>/            # e.g., 10-tps, 50-tps
│           └── <run-id>/        # e.g., 20260209_204224_10-tps
│               ├── *.csv                   # Raw CSV data
│               ├── report-*.html           # HTML reports
│               ├── run-results-*.txt       # Detailed run results
│               ├── grafana-url.txt         # Grafana dashboard link
│               └── run-id.txt              # Run identifier
└── jp/                           # JP VM results
    └── erc20/
        └── <config>/
            └── <run-id>/
                └── (same structure as US)
```

The `<run-id>` format is `YYYYMMDD_HHMMSS_<config>` to easily match US and JP test pairs.

### `fetch-reports.sh`

Standalone script to fetch reports from remote VMs without running new tests.

**Features:**
- Downloads existing reports from remote VMs
- Organizes reports by report number
- Fetches run results for each report

**Usage:**

```bash
./fetch-reports.sh
```

**Output:**
```
us/
├── <report-num>/
│   ├── <report-num>.csv
│   ├── report-<report-num>-*.html
│   └── run-results.txt
jp/
└── (same structure)
```

### `find-matching-runs.sh`

Utility script to find test runs that have results from both US and JP VMs.

**Features:**
- Identifies matching test runs by Run ID
- Shows matched and unmatched runs
- Displays full paths for easy navigation

**Usage:**

```bash
./find-matching-runs.sh
```

**Example Output:**

```
═══════════════════════════════════════════════════════════════
MATCHED TEST RUNS (US ↔ JP)
═══════════════════════════════════════════════════════════════

🆔 Run ID: 20260209_204224_1600-tps
   🇺🇸 US: us/erc20/1600-tps/20260209_204224_1600-tps/
   🇯🇵 JP: jp/erc20/1600-tps/20260209_204224_1600-tps/

───────────────────────────────────────────────────────────────
UNMATCHED RUNS
───────────────────────────────────────────────────────────────

⚠️  US only - 20260209_213325_4000-tps
   us/erc20/4000-tps/20260209_213325_4000-tps/
```

## Security

### Important Notes

1. **Never commit `.env`** - The `.env` file contains sensitive credentials and should never be committed to git
2. **`.gitignore`** - The `.env` file is already added to `.gitignore` to prevent accidental commits
3. **SSH Keys** - Keep your SSH private keys secure and never commit them to the repository
4. **Private Keys** - The `PRIVATE_KEY` in `.env` is for funding test transactions - use a dedicated test account

### What's Safe to Commit

- ✅ `.env.example` - Template without actual credentials
- ✅ All `.sh` scripts - No hardcoded sensitive data
- ✅ `README.md` - Documentation
- ❌ `.env` - Contains your actual credentials
- ❌ SSH private keys
- ❌ Test result directories (`us/`, `jp/`)

## Test Configuration Reference

### Test Configurations

The scripts use configuration files from the main repository at `../../configs/erc20/`. Common configurations:

- `low.env` - Low TPS (10 TPS, 5 accounts) - Debugging
- `medium.env` - Medium TPS (50 TPS, 25 accounts) - Balanced testing
- `high.env` - High TPS (200 TPS, 100 accounts) - Stress testing
- Custom configs for specific TPS levels (400, 800, 1600, 3200, 4000, 5000)

**Note:** The config names in the `CONFIGS` array must match the filename (without `.env`) in `configs/erc20/`.

For example:
- `CONFIGS=("medium")` → uses `configs/erc20/medium.env`
- `CONFIGS=("1600-tps")` → uses `configs/erc20/1600-tps.env`

### Creating Custom Configurations

1. Create a new config file in the main repo:
   ```bash
   cd ../../configs/erc20/
   cp low.env my-custom.env
   nano my-custom.env
   ```

2. Add it to the `CONFIGS` array:
   ```bash
   CONFIGS=(
       "my-custom"
   )
   ```

3. Run the test suite:
   ```bash
   cd ../../scripts/remote-testing
   ./run-all-tests.sh
   ```

## Workflow

### Running a Complete Test Suite

1. Configure your VMs in `.env`
2. Edit `CONFIGS` array in `run-all-tests.sh`
3. Run the test suite:
   ```bash
   ./run-all-tests.sh
   ```
4. Find matching runs:
   ```bash
   ./find-matching-runs.sh
   ```
5. Analyze results in the organized directories

### Fetching Existing Reports

If you just want to download existing reports without running new tests:

```bash
./fetch-reports.sh
```

### Adding New Test Configurations

1. Create a new config file in `configs/erc20/your-config.env`
2. Add `"your-config"` to the `CONFIGS` array in `run-all-tests.sh`
3. Run the test suite

## Troubleshooting

### "SSH connection failed"

- Verify your VM IP addresses are correct
- Check SSH key path and permissions (`chmod 600 /path/to/key`)
- Ensure security groups allow SSH access

### "No reports found"

- Check that tests ran successfully on remote VMs
- Verify the remote report path: `~/.contender/reports/`
- Check SSH user has proper permissions

### "ulimit: too many files"

- Increase file descriptor limit on remote VMs:
  ```bash
  ulimit -n 65536
  ```
- Add to `/etc/security/limits.conf` for persistence

### Date command issues

The scripts use `date -v` (macOS) with fallback to `date -d` (Linux). If you encounter date-related errors:

- On macOS: Should work out of the box
- On Linux: Uses GNU date format automatically

## Advanced Usage

### Custom Remote Paths

If contender is installed in a non-standard location on your VMs, update `.env`:

```bash
REMOTE_CONTENDER_PATH="/custom/path/to/contender"
REMOTE_POST_PROCESSING_PATH="/custom/path/to/post-processing"
```

### Parallel Execution

The current implementation runs tests sequentially (US first, then JP). To run in parallel:

```bash
# Run in background
./run-all-tests.sh &
```

Or modify the script to use background jobs.

### Custom Report Organization

The scripts organize reports by:
1. Region (us/jp)
2. Test type (erc20)
3. Configuration (10-tps, etc.)
4. Run ID (timestamp + config)

Modify the `organize_reports_for_region()` function to customize this structure.

## Contributing

When adding new scripts:
1. Follow the existing pattern for environment variable usage
2. Add validation for required variables
3. Include helpful error messages
4. Update this README with documentation
5. Test with `.env.example` to ensure no hardcoded credentials

## License

Same as the main Contender repository.
