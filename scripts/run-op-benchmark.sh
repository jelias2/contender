#!/bin/bash
# Run a preset from configs/<test-type>/<preset>.env (no confirmation). Same config names as ./run.sh.
# Usage: ./scripts/run-op-benchmark.sh <config-name> [contender args...]
#   config-name: erc20/medium | stress/high | blobs/default | ... | all
# Example: ./scripts/run-op-benchmark.sh erc20/medium
#          ./scripts/run-op-benchmark.sh erc20/medium -r https://other-rpc.io -d 60

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONTENDER_BIN=""
if [ -x "./target/release/contender" ]; then
    CONTENDER_BIN="./target/release/contender"
elif [ -x "./target/debug/contender" ]; then
    CONTENDER_BIN="./target/debug/contender"
else
    echo -e "${RED}contender binary not found. Run: cargo build --release${NC}" >&2
    exit 1
fi

CONFIG_DIR="configs"
# Configs to run when using "all" (built-in spam only)
ALL_CONFIGS="erc20/low erc20/medium erc20/high stress/high blobs/default transfers/default univ2/default"

usage() {
    echo -e "${GREEN}run-op-benchmark – run a configs/<test-type>/<preset>.env preset (no prompt)${NC}"
    echo ""
    echo "Usage: $0 <config-name> [contender args...]"
    echo ""
    echo "Config names (same as ./run.sh): <test-type>/<preset>"
    echo "  erc20/low  erc20/medium  erc20/high  stress/high  blobs/default  transfers/default"
    echo "  univ2/default  storage/default  l2-mint-send/default  localhost/default"
    echo "  all  – run in sequence: $ALL_CONFIGS"
    echo ""
    echo "Examples:"
    echo "  $0 erc20/medium"
    echo "  $0 erc20/medium -r https://other-rpc.io -d 60"
    echo "  $0 l2-mint-send/default"
    echo "  $0 all"
    exit 0
}

run_config() {
    local config_name="$1"
    shift
    local extra=("$@")
    local env_file="$CONFIG_DIR/$config_name.env"
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Config not found: $env_file${NC}" >&2
        return 1
    fi
    source "$env_file"
    echo -e "${BLUE}[run-op-benchmark] $config_name${NC} RPC=$RPC_URL TPS=$TPS DURATION=$DURATION"

    if [ -n "${SCENARIO_PATH:-}" ]; then
        if [ ! -f "$SCENARIO_PATH" ]; then
            echo -e "${RED}Scenario not found: $SCENARIO_PATH${NC}" >&2
            return 1
        fi
        echo -e "${YELLOW}Running setup...${NC}"
        "$CONTENDER_BIN" setup "$SCENARIO_PATH" "$RPC_URL" -p "$PRIVATE_KEY" --min-balance 0.25
        echo -e "${YELLOW}Running spam...${NC}"
        "$CONTENDER_BIN" spam "$SCENARIO_PATH" "$RPC_URL" -p "$PRIVATE_KEY" \
            -d "$DURATION" --tps "$TPS" --accounts "$ACCOUNTS" --rpc-batch-size "$RPC_BATCH_SIZE" \
            --min-balance 0.05 "${extra[@]}"
    else
        "$CONTENDER_BIN" spam -r "$RPC_URL" -p "$PRIVATE_KEY" -d "$DURATION" \
            --tps "$TPS" --accounts "$ACCOUNTS" --rpc-batch-size "$RPC_BATCH_SIZE" \
            -t "$TX_TYPE" "${extra[@]}" "$TEST_TYPE"
    fi
}

run_all() {
    shift
    local extra=("$@")
    for c in $ALL_CONFIGS; do
        echo -e "\n${GREEN}=== $c ===${NC}\n"
        run_config "$c" "${extra[@]}" || true
    done
    echo -e "\n${GREEN}Done. Run '$0 l2-mint-send/default' for scenario-file config.${NC}"
    exit 0
}

CONFIG="${1:-}"
[ -z "$CONFIG" ] && usage
[ "$CONFIG" = "-h" ] || [ "$CONFIG" = "--help" ] && usage
shift || true

if [ -z "${PRIVATE_KEY:-}" ]; then
    echo -e "${RED}PRIVATE_KEY is not set. Export it or pass -p to contender.${NC}" >&2
    exit 1
fi

if [ "$CONFIG" = "all" ]; then
    run_all "$CONFIG" "$@"
fi

run_config "$CONFIG" "$@"
