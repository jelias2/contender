# ERC20 Benchmarking Test Guide

> 💡 **What is this?** A system for testing ERC20 token transfer performance on Optimism nodes by running automated load tests on remote servers in different geographic locations.

## What You'll Do

Run automated load tests on two virtual machines (VMs) located in different regions (e.g., US and Japan) to measure how fast ERC20 token transfers perform across different geographic locations.

**Quick Start:** `Configure .env` → `Edit CONFIGS` → `Run ./run-all-tests.sh` → `View results`

---

## What You Need Before Starting

### Required Access & Credentials

- **Two Remote VMs:** Virtual machines (cloud servers) with Contender installed
  - Location: `~/contender` directory on each VM
- **SSH Access:**
  - Private key file (`.pem` or `.key` file)
  - IP addresses for both VMs
  - Username (`ubuntu`)
- **Ethereum Private Key:**
  - Already loaded and provided to you

### Required Knowledge

You should be comfortable with:
- **Linux basics:** Terminal navigation (`cd`, `ls`), SSH, editing files (`nano`, `vim`)
- **Environment variables:** Setting and exporting variables (`export VAR=value`)
- **Git basics:** Cloning repositories, checking out branches

---

## Understanding the Benchmarking System

### What is Contender?

A high-performance transaction spamming tool that:
- ✅ Generates many transactions per second (TPS)
- ✅ Sends them to an Ethereum RPC endpoint
- ✅ Measures success rate, latency, and throughput
- ✅ Stores results in SQLite database (`~/.contender/db/contender.db`)
- ✅ Generates HTML reports with performance metrics

### Key Concepts

> 💡 **TPS (Transactions Per Second)**
> - How many transactions Contender sends every second
> - Higher TPS = more load on the system
> - Tests range from 10 TPS (light) to 5000 TPS (extreme)

> 💡 **ERC20 Token Transfers**
> - Standard format for tokens on Ethereum (like USDC, USDT, etc.)
> - Each test sends ERC20 `transfer()` transactions between accounts
> - Requires: (1) deploying a token contract, (2) funding test accounts

> 💡 **RPC Endpoint**
> - The HTTP URL that connects to the blockchain node
> - Example: `https://demo-ntt-0.optimism.io`
> - Different configs may use different endpoints

> 💡 **Run ID**
> - Unique identifier: `YYYYMMDD_HHMMSS_<config>`
> - Example: `20260209_143022_50-tps`
> - Same ID on both VMs = easy comparison between regions

### How Benchmarking Works

1. **Setup Phase:** Contender deploys ERC20 contract and funds test accounts from your private key
2. **Spam Phase:** Sends transactions at target TPS for configured duration (e.g., 50 TPS for 50 seconds)
3. **Collection:** Records success/failure, latency, and gas used per transaction to SQLite database
4. **Report:** Generates HTML with graphs, tables, and statistics
5. **Analysis:** Compare results across regions or configurations

---

## Architecture

```
┌─────────────┐                    ┌─────────────┐
│   Local     │                    │   Local     │
│  Machine    │ ←── SSH/SCP ────→  │  Machine    │
│(Orchestrator)│                   │ (Results)   │
└──────┬──────┘                    └─────────────┘
       │
       ├─── SSH ───→ US VM (~/contender)
       │              ├─ scripts/run-op-benchmark.sh
       │              └─ ~/.contender/reports/
       │
       └─── SSH ───→ JP VM (~/contender)
                      ├─ scripts/run-op-benchmark.sh
                      └─ ~/.contender/reports/
```

**Flow:** Local triggers → VMs execute → Local fetches → Results organized by region/config/run-id

---

## 🔧 Workflow 1: Test on a Single VM

> ⏰ **When to use:** Running a quick test on one VM, debugging, or trying out a new configuration.

### Step-by-Step

**1. Connect to the VM**
```bash
ssh -i /path/to/your-key.pem ubuntu@<vm-ip-address>
```
Replace `/path/to/your-key.pem` with your SSH key path and `<vm-ip-address>` with the VM's IP.

**2. Navigate to Contender directory**
```bash
cd ~/contender
```

**3. Set your Ethereum private key**
```bash
export PRIVATE_KEY="0xYOUR_PRIVATE_KEY_HERE"
```
> ⚠️ **Security:** Use a dedicated test wallet. This key funds test accounts and sends transactions.

**4. Run a benchmark**
```bash
./scripts/run-op-benchmark.sh erc20/50-tps
```

> ℹ️ **What this does:**
> - Deploys an ERC20 token contract to the chain
> - Funds 25 test accounts from your private key wallet
> - Sends 50 ERC20 transfer transactions per second for 50 seconds
> - Records all results to `~/.contender/db/contender.db`

**5. Generate a report**
```bash
contender report
```

Creates an HTML report from the SQLite database with:
- ✅ Transaction success rate (how many txs confirmed)
- ✅ Latency percentiles (p50, p95, p99 - how fast txs confirmed)
- ✅ Throughput over time (TPS achieved vs. TPS requested)
- ✅ Gas usage statistics

**6. View results**

Reports are saved to `~/.contender/reports/` on the VM.

To download to your local machine:
```bash
# Exit the VM (or open a new terminal)
exit

# Download reports from your local machine
scp -i /path/to/your-key.pem ubuntu@<vm-ip>:~/.contender/reports/* ./local-reports/
```

### Available Test Configurations

| Config | Speed | Intensity | Use Case |
|--------|-------|-----------|----------|
| `erc20/10-tps` | 10 TPS | Very Light | Initial testing, debugging |
| `erc20/50-tps` | 50 TPS | Light | Baseline performance |
| `erc20/800-tps` | 800 TPS | Medium | Normal load testing |
| `erc20/1600-tps` | 1600 TPS | High | Heavy load testing |
| `erc20/3200-tps` | 3200 TPS | Very High | Stress testing |
| `erc20/4000-tps` | 4000 TPS | Extreme | Maximum stress |
| `erc20/5000-tps` | 5000 TPS | Extreme+ | Pushing limits |

> 📁 **Location:** These config files live at `configs/erc20/<config>.env` in the repository.

### Customize a Test

Override default settings:
```bash
./scripts/run-op-benchmark.sh erc20/50-tps -d 120 --tps 75
```
- `-d 120` = Run for 120 seconds instead of default 50
- `--tps 75` = Use 75 TPS instead of default 50

---

## 🌍 Workflow 2: Test on Both VMs (Multi-Region)

> ⏰ **When to use:** Comparing performance between geographic regions (e.g., US vs Japan).

> ⭐ This is the **main workflow** for benchmarking - it automatically runs the same test on both VMs and collects results for easy comparison.

### One-Time Setup

**1. Navigate to the remote testing directory**
```bash
cd scripts/remote-testing
```

**2. Create your configuration file**
```bash
cp .env.example .env
```

**3. Edit the `.env` file**
```bash
nano .env
```
(Or use your preferred text editor: `vim`, `code`, etc.)

Fill in these values:
```bash
US_IP="54.123.45.67"              # Your US VM's IP address
JP_IP="89.234.56.78"              # Your Japan VM's IP address
SSH_KEY_PATH="/path/to/key.pem"   # Path to your SSH private key
SSH_USER="ubuntu"                 # Usually "ubuntu", check with your VM provider
PRIVATE_KEY="0xYOUR_KEY_HERE"     # Your Ethereum test wallet private key
```

**4. Test your SSH connections**
```bash
ssh -i /path/to/key.pem ubuntu@54.123.45.67   # Test US VM
ssh -i /path/to/key.pem ubuntu@89.234.56.78   # Test JP VM
```
> ✅ If both work, you're ready! Type `exit` to disconnect.

### Choose Which Tests to Run

**1. Edit `run-all-tests.sh`**
```bash
nano run-all-tests.sh
```

**2. Find the `CONFIGS` array (around line 59)**
```bash
CONFIGS=(
    "50-tps"      # Uncomment the tests you want
    "800-tps"
    "1600-tps"
)
```
- Uncomment (remove `#`) the tests you want to run
- Comment out (add `#`) the tests you want to skip

> 💡 **Tip:** Start with just one config (e.g., `50-tps`) for your first run to make sure everything works.

### Run the Tests

```bash
./run-all-tests.sh
```

### What Happens (Behind the Scenes)

The script automatically:
1. **Cleans up** old reports on both VMs
2. **For each config:**
   - Runs test on US VM
   - Generates report
   - Fetches results to your local machine
   - Runs same test on JP VM
   - Generates report
   - Fetches results to your local machine
3. **Organizes results** by region, config, and timestamp

> 🆔 Each test gets a unique **Run ID** like `20260209_123456_50-tps` (date + time + config) that matches across both VMs.

### Where Results Are Saved

```
scripts/remote-testing/
├── us/erc20/50-tps/20260209_123456_50-tps/     # US results
│   ├── 1.csv                                    # Raw transaction data
│   ├── report-1-....html                        # HTML report
│   └── run-results-1.txt                        # Detailed results
└── jp/erc20/50-tps/20260209_123456_50-tps/     # JP results (same structure)
```

> ✨ **Same Run ID = easy comparison between regions!**

---

## 📊 Workflow 3: Results Analysis

### Find Matching Runs

```bash
./find-matching-runs.sh
```

**Output structure:**
```
scripts/remote-testing/
├── us/erc20/<config>/<run-id>/
│   ├── *.csv              # Raw transaction data (CSV)
│   ├── report-*.html      # HTML report with graphs
│   ├── run-results-*.txt  # Detailed run statistics
│   └── grafana-url.txt    # Dashboard link (if enabled)
└── jp/erc20/<config>/<run-id>/
    └── (same structure)
```

### Compare Regions

Same run-id → direct comparison between US and JP performance.

**Example:**
- US: `us/erc20/50-tps/20260209_143022_50-tps/report-1-...html`
- JP: `jp/erc20/50-tps/20260209_143022_50-tps/report-1-...html`

Open both HTML reports side-by-side to compare:
- ✅ Transaction success rates
- ✅ Latency (p50, p95, p99)
- ✅ Throughput achieved
- ✅ Gas usage

---

## 📚 Quick Reference

| Task | Command |
|------|---------|
| Single test on VM | `ssh -i <key> ubuntu@<ip>` → `cd ~/contender` → `./scripts/run-op-benchmark.sh erc20/50-tps` |
| Multi-region tests | `cd scripts/remote-testing` → `./run-all-tests.sh` |
| Find matches | `./find-matching-runs.sh` |
| Generate report on VM | `contender report` |
| Customize test | `./scripts/run-op-benchmark.sh erc20/50-tps -d 120 --tps 75` |

---

## ⚙️ Configuration Reference

### Available Configurations

> 📁 Location: `configs/erc20/<config>.env`

| Config | TPS | Accounts | Duration | RPC Endpoint | Use Case |
|--------|-----|----------|----------|--------------|----------|
| 10-tps | 10 | 5 | 50s | demo-ntt-2-0 | Debug, initial testing |
| 50-tps | 50 | 25 | 50s | demo-ntt-0 | Baseline performance |
| 800-tps | 800 | ? | 50s | ? | Medium load |
| 1600-tps | 1600 | ? | 50s | ? | High load |
| 3200-tps | 3200 | ? | 50s | ? | Stress testing |
| 4000-tps | 4000 | ? | 50s | ? | Max stress |
| 5000-tps | 5000 | ? | 50s | ? | Extreme load |

### Creating Custom Configurations

**1. Copy an existing config**
```bash
cd configs/erc20/
cp 10-tps.env my-custom.env
```

**2. Edit the config**
```bash
nano my-custom.env
```

Example customizations:
```bash
RPC_URL="https://demo-ntt-0.optimism.io"
DURATION=120        # Run for 2 minutes instead of 50 seconds
TPS=100             # Send 100 transactions per second
ACCOUNTS=50         # Use 50 test accounts
RPC_BATCH_SIZE=100  # Batch size for RPC calls
TEST_TYPE="erc20"
TX_TYPE="eip1559"
```

**3. Add to test suite**

Edit `scripts/remote-testing/run-all-tests.sh`:
```bash
CONFIGS=(
    "my-custom"    # Add your config name (without .env)
)
```

**4. Run the test**
```bash
cd scripts/remote-testing
./run-all-tests.sh
```

---

## 🚨 Common Issues & Solutions

### "Permission denied (publickey)"

> ❌ **Problem:** Can't connect to VM via SSH.

**Solutions:**
1. Check your SSH key path is correct in `.env`
2. Verify key permissions: `chmod 600 /path/to/key.pem`
3. Confirm you're using the right username (usually `ubuntu`)
4. Test manually: `ssh -i /path/to/key.pem ubuntu@<vm-ip>`

### "No reports found" after running test

> ❌ **Problem:** Results aren't appearing.

**Solutions:**
1. SSH into the VM: `ssh -i <key> ubuntu@<vm-ip>`
2. Check if reports exist: `ls ~/.contender/reports/`
3. If empty, the test may have failed - check for error messages in the terminal output
4. Verify your `PRIVATE_KEY` wallet has enough ETH for test transactions (check balance: `cast balance 0xYOUR_ADDRESS --rpc-url <RPC_URL>`)

### "ulimit: too many open files"

> ❌ **Problem:** System can't handle that many open file connections.

**Solution:**
```bash
# On the VM:
ulimit -n 65536
```

To make this permanent, add to the VM's `~/.bashrc`:
```bash
echo "ulimit -n 65536" >> ~/.bashrc
```

### "Connection timeout" during long tests

> ❌ **Problem:** SSH connection drops during long-running tests.

> ✅ **This is normal** - the script handles it with keep-alive settings (`ServerAliveInterval=60`). The test continues running on the VM even if you see timeout messages in the local terminal.

### "Config not found: configs/erc20/XXX.env"

> ❌ **Problem:** Specified config doesn't exist.

**Solution:**
1. Check available configs: `ls configs/erc20/`
2. Use exact filename without `.env` extension (e.g., `"50-tps"` not `"50-tps.env"`)
3. Create custom config by copying existing one (see [Creating Custom Configurations](#creating-custom-configurations))

### Test runs but results look wrong

> ❌ **Problem:** Numbers seem off or many failed transactions.

**Checklist:**
- Is the RPC endpoint (in config file) reachable from the VM? Test with: `curl -X POST <RPC_URL> -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`
- Does your private key wallet have enough ETH? (Needs ETH to fund accounts and send transactions)
- Is the VM under too much load from other processes? Check with: `top` or `htop`
- Try a lower TPS config first (e.g., `10-tps`) to verify setup works

### "Transaction pool full" or "nonce too low" errors

> ❌ **Problem:** Blockchain node is rejecting transactions.

**Causes:**
- Sending transactions too fast for the node to handle
- Previous test didn't clean up properly

**Solutions:**
1. Use a lower TPS config
2. Wait a few minutes between tests for the mempool to clear
3. Check that your test accounts aren't being used by another test

---

## 🔐 Security & Best Practices

### Critical Security Notes

> ⚠️ **Never commit `.env`** - The `.env` file contains sensitive credentials and should never be committed to git. It's already in `.gitignore`.

> ⚠️ **Use test wallets only** - The `PRIVATE_KEY` in `.env` will send many transactions. Use a dedicated test account with limited funds, never your mainnet wallet.

> ⚠️ **Keep SSH keys secure** - Never commit SSH private keys (`.pem`, `.key` files) to the repository.

### What's Safe to Commit

- ✅ `.env.example` - Template without actual credentials
- ✅ All `.sh` scripts - No hardcoded sensitive data
- ✅ `README.md` - Documentation
- ✅ Config files in `configs/erc20/` - Public RPC endpoints
- ❌ `.env` - Contains your actual credentials
- ❌ SSH private keys
- ❌ Test result directories (`us/`, `jp/`)

### Best Practices

1. ✅ **Start small:** Begin with `10-tps` or `50-tps` to verify your setup
2. ✅ **Monitor resources:** High TPS tests consume significant CPU, network, and file descriptors
3. ✅ **Clean between runs:** Old reports can consume disk space - clean up periodically
4. ✅ **Document custom configs:** Add comments to custom `.env` files explaining what they test
5. ✅ **Version control:** Commit config files (but not `.env`!) so tests are reproducible

---

## 🚀 Advanced Topics

### Grafana Integration (Optional)

To generate Grafana dashboard URLs for each test:

**1. Edit `.env`**
```bash
ENABLE_GRAFANA=true
GRAFANA_BASE_URL="https://your-grafana-instance.com/d/dashboard-id/dashboard-name"
GRAFANA_PARAMS="orgId=1&var-network=your-network"
```

**2. Run tests normally**

Grafana URLs will be saved to `<run-id>/grafana-url.txt` in each result directory.

### Custom Remote Paths

If Contender is installed in a non-standard location on your VMs, update `.env`:

```bash
REMOTE_CONTENDER_PATH="/custom/path/to/contender"
REMOTE_POST_PROCESSING_PATH="/custom/path/to/post-processing"
```

### Interpreting Results

**Key Metrics in Reports:**

> 📊 **Success Rate:** Percentage of transactions that confirmed on-chain
> - 100% = all transactions confirmed
> - <100% = some transactions failed or timed out

> ⏱️ **Latency p50/p95/p99:** Time from submission to confirmation
> - p50 = median (50% of txs confirmed faster than this)
> - p95 = 95th percentile (95% of txs confirmed faster than this)
> - p99 = 99th percentile (1% of txs took longer than this)

> 📈 **Throughput:** Actual TPS achieved vs. requested TPS
> - If achieved < requested, the node may be under load

> ⛽ **Gas Used:** Total gas consumed by transactions
> - ERC20 transfers typically use ~50k-100k gas per transaction

---

## ✅ Troubleshooting Checklist

Before asking for help, verify:

- [ ] SSH connection works: `ssh -i <key> ubuntu@<vm-ip>`
- [ ] Contender is installed on VM: `ssh -i <key> ubuntu@<vm-ip> "ls ~/contender"`
- [ ] `.env` file exists and has correct values
- [ ] SSH key permissions are correct: `chmod 600 /path/to/key.pem`
- [ ] Private key wallet has ETH: Check balance on block explorer
- [ ] Config file exists: `ls configs/erc20/<config>.env`
- [ ] RPC endpoint is reachable: `curl -X POST <RPC_URL> -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`

---

## 📖 Additional Resources

- **Contender Documentation:** See main repository README
- **ERC20 Standard:** https://eips.ethereum.org/EIPS/eip-20
- **Optimism Documentation:** https://docs.optimism.io/
- **Report an Issue:** https://github.com/flashbots/contender/issues

---

## 🤝 Contributing

When adding new test configurations or scripts:
1. Follow existing naming conventions (`<tps>-tps.env`)
2. Add comments explaining the test purpose
3. Test with `.env.example` to ensure no hardcoded credentials
4. Update this README with new configurations
5. Consider edge cases (very high TPS, long durations)

---

**Last Updated:** 2026-02-10
