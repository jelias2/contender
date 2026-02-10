# Remote Testing Quick Start

This is a quick reference guide for running remote tests. For complete documentation, see [README.md](README.md).

## Setup (First Time Only)

1. **Navigate to remote-testing directory:**
   ```bash
   cd scripts/remote-testing
   ```

2. **Copy and configure .env:**
   ```bash
   cp .env.example .env
   nano .env
   ```

3. **Fill in your credentials:**
   ```bash
   US_IP="your.us.vm.ip"
   JP_IP="your.jp.vm.ip"
   SSH_KEY_PATH="/path/to/ssh/key"
   SSH_USER="ubuntu"
   PRIVATE_KEY="your_ethereum_private_key"
   ```

4. **Test SSH access:**
   ```bash
   ssh -i /path/to/ssh/key ubuntu@your.us.vm.ip "echo 'Connected!'"
   ```

## Running Tests

### Run Full Test Suite

```bash
./run-all-tests.sh
```

This will:
1. Run tests on US VM
2. Run tests on JP VM
3. Fetch and organize all reports
4. Create matching run IDs for comparison

### Configure Which Tests to Run

Edit the `CONFIGS` array in `run-all-tests.sh`:

```bash
CONFIGS=(
    "low"       # Uses configs/erc20/low.env
    "medium"    # Uses configs/erc20/medium.env
    "high"      # Uses configs/erc20/high.env
)
```

### Fetch Reports Only

If tests are already running or complete on VMs:

```bash
./fetch-reports.sh
```

### Find Matching Test Runs

```bash
./find-matching-runs.sh
```

Output shows which runs have data from both US and JP VMs.

## Results Location

```
scripts/remote-testing/
├── us/erc20/<config>/<run-id>/      # US VM results
└── jp/erc20/<config>/<run-id>/      # JP VM results
```

Each run directory contains:
- `*.csv` - Raw transaction data
- `report-*.html` - HTML reports
- `run-results-*.txt` - Detailed results
- `grafana-url.txt` - Dashboard link (if enabled)
- `run-id.txt` - Run identifier

## Common Issues

### "PRIVATE_KEY not set"
Set it in `.env` file.

### "SSH connection failed"
- Check VM IP addresses
- Verify SSH key path and permissions: `chmod 600 /path/to/key`
- Test SSH access manually first

### "Configuration not found"
The config must exist in `../../configs/erc20/<config>.env`

### "No reports found"
- Check tests completed successfully on VMs
- Verify remote path: `~/.contender/reports/`
- Check SSH user has read permissions

## Quick Reference

| Command | Purpose |
|---------|---------|
| `./run-all-tests.sh` | Run full automated test suite |
| `./fetch-reports.sh` | Download existing reports only |
| `./find-matching-runs.sh` | Find matching US/JP test pairs |
| `nano run-all-tests.sh` | Edit which configs to run |
| `nano .env` | Update VM credentials |

## Next Steps

- Review [README.md](README.md) for complete documentation
- Check [../../configs/README.md](../../configs/README.md) for config options
- See [../../QUICKSTART.md](../../QUICKSTART.md) for local testing

## Getting Help

1. Read the full [README.md](README.md)
2. Check error messages - they include helpful suggestions
3. Verify `.env` configuration
4. Test SSH access manually
