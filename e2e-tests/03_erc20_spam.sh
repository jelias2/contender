#!/usr/bin/env bash
# ERC20 spam test – direct spam subcommand (replicates op-benchmark erc20 spam tests).

set -euo pipefail
: "${CONTENDER_RPC_URL:?CONTENDER_RPC_URL is required}"
: "${CONTENDER_BIN:?CONTENDER_BIN is required}"

"$CONTENDER_BIN" \
  spam \
  --rpc-url "$CONTENDER_RPC_URL" \
  --duration 15 \
  --tps 50 \
  --accounts-per-agent 10 \
  erc20
