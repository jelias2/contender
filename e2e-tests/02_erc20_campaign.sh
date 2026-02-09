#!/usr/bin/env bash
# ERC20 campaign test – runs contender in campaign mode with 100% erc20 (replicates op-benchmark erc20-campaign).

set -euo pipefail
: "${CONTENDER_RPC_URL:?CONTENDER_RPC_URL is required}"
: "${CONTENDER_BIN:?CONTENDER_BIN is required}"
# Campaign requires a private key (set PRIVATE_KEY or CONTENDER_PRIVATE_KEY)
PKEY="${PRIVATE_KEY:-${CONTENDER_PRIVATE_KEY:-}}"
: "${PKEY:?PRIVATE_KEY or CONTENDER_PRIVATE_KEY is required for campaign}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAMPAIGN_FILE="${REPO_ROOT}/campaigns/erc20-campaign.toml"

if [[ ! -f "$CAMPAIGN_FILE" ]]; then
  echo "Campaign file not found: $CAMPAIGN_FILE" >&2
  exit 1
fi

"$CONTENDER_BIN" \
  campaign \
  "$CAMPAIGN_FILE" \
  -r "$CONTENDER_RPC_URL" \
  -p "$PKEY"
