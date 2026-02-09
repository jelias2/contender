# e2e-tests

This directory contains shell scripts that are executed by the CI. If you set the proper env variables, you can run them directly, provided you have the appropriate RPC backend running.

## ERC20 tests (op-benchmark style)

| Script | Description |
|--------|-------------|
| `00_erc20_smoke.sh` | Smoke test: short erc20 spam (10s, 50 TPS). |
| `01_base_erc20.sh` | Base ERC20: short run, baseline TPS (15s, 20 TPS, 5 accounts). |
| `02_erc20_campaign.sh` | ERC20 campaign: runs `contender campaign` with 100% erc20 (uses `campaigns/erc20-campaign.toml`). Requires `PRIVATE_KEY` or `CONTENDER_PRIVATE_KEY`. |
| `03_erc20_spam.sh` | ERC20 spam: direct `contender spam ... erc20` (15s, 50 TPS, 10 accounts). |

## Required env

- **CONTENDER_RPC_URL** – RPC endpoint (required for all).
- **CONTENDER_BIN** – Path to the contender binary (required for all).
- **PRIVATE_KEY** or **CONTENDER_PRIVATE_KEY** – Required only for `02_erc20_campaign.sh`.
