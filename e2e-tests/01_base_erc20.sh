#!/usr/bin/env bash
# Base ERC20 test – short run, baseline TPS (replicates op-benchmark base-erc20 style).

set -euo pipefail
: "${CONTENDER_RPC_URL:?CONTENDER_RPC_URL is required}"
: "${CONTENDER_BIN:?CONTENDER_BIN is required}"

"$CONTENDER_BIN" \
  spam \
  --rpc-url "$CONTENDER_RPC_URL" \
  --duration 15 \
  --tps 20 \
  --accounts-per-agent 5 \
  erc20
