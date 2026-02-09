#!/bin/bash
# Run OP-benchmark-style test cases with contender only (no k8s).
# Usage: ./scripts/run-op-benchmark.sh <case> [contender args...]
#   case: low | medium | high | stress | blobs | transfers | univ2 | l2-mint-send | all
# Example: ./scripts/run-op-benchmark.sh medium
#          ./scripts/run-op-benchmark.sh medium -r https://other-rpc.io -d 60

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

CONFIG_DIR="configs/op-benchmark"
BUILTIN_CASES="low medium high stress blobs transfers univ2"
SCENARIO_CASES="l2-mint-send"

usage() {
    echo -e "${GREEN}OP Benchmark – Bare Bones Contender${NC}"
    echo ""
    echo "Usage: $0 <case> [contender args...]"
    echo ""
    echo "Cases (built-in): $BUILTIN_CASES"
    echo "Cases (scenario file): $SCENARIO_CASES"
    echo "  all  – run all built-in cases in sequence"
    echo ""
    echo "Examples:"
    echo "  $0 low"
    echo "  $0 medium -r https://demo-ntt-2-0.optimism.io -d 60"
    echo "  $0 l2-mint-send"
    echo "  $0 all"
    exit 0
}

run_builtin() {
    local case="$1"
    shift
    local extra=("$@")
    local env_file="$CONFIG_DIR/$case.env"
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Config not found: $env_file${NC}" >&2
        return 1
    fi
    source "$env_file"
    echo -e "${BLUE}[op-benchmark] $case${NC} RPC=$RPC_URL TPS=$TPS DURATION=$DURATION"
    "$CONTENDER_BIN" spam -r "$RPC_URL" -p "$PRIVATE_KEY" -d "$DURATION" \
        --tps "$TPS" --accounts "$ACCOUNTS" --rpc-batch-size "$RPC_BATCH_SIZE" \
        -t "$TX_TYPE" "${extra[@]}" "$TEST_TYPE"
}

run_l2_mint_send() {
    shift
    local extra=("$@")
    local env_file="$CONFIG_DIR/l2-mint-send.env"
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Config not found: $env_file${NC}" >&2
        exit 1
    fi
    source "$env_file"
    if [ -z "$SCENARIO_PATH" ]; then
        SCENARIO_PATH="./scenarios/op-interop/l2MintAndSend.toml"
    fi
    if [ ! -f "$SCENARIO_PATH" ]; then
        echo -e "${RED}Scenario not found: $SCENARIO_PATH${NC}" >&2
        exit 1
    fi
    echo -e "${BLUE}[op-benchmark] l2-mint-send${NC} RPC=$RPC_URL TPS=$TPS DURATION=$DURATION"
    echo -e "${YELLOW}Running setup...${NC}"
    "$CONTENDER_BIN" setup "$SCENARIO_PATH" "$RPC_URL" -p "$PRIVATE_KEY" --min-balance 0.25
    echo -e "${YELLOW}Running spam...${NC}"
    "$CONTENDER_BIN" spam "$SCENARIO_PATH" "$RPC_URL" \
        --tps "$TPS" -d "$DURATION" -p "$PRIVATE_KEY" \
        --accounts "$ACCOUNTS" --rpc-batch-size "$RPC_BATCH_SIZE" \
        --min-balance 0.05 "${extra[@]}"
}

run_all() {
    shift
    local extra=("$@")
    for c in $BUILTIN_CASES; do
        echo -e "\n${GREEN}=== $c ===${NC}\n"
        run_builtin "$c" "${extra[@]}" || true
    done
    echo -e "\n${GREEN}All built-in cases done. Run '$0 l2-mint-send' for scenario file.${NC}"
    exit 0
}

# Parse case
CASE="${1:-}"
[ -z "$CASE" ] && usage
[ "$CASE" = "-h" ] || [ "$CASE" = "--help" ] && usage
shift || true

if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}PRIVATE_KEY is not set. Export it or pass -p to contender.${NC}" >&2
    exit 1
fi

case "$CASE" in
    low|medium|high|stress|blobs|transfers|univ2)
        run_builtin "$CASE" "$@"
        ;;
    l2-mint-send)
        run_l2_mint_send "$CASE" "$@"
        ;;
    all)
        run_all "$CASE" "$@"
        ;;
    *)
        echo -e "${RED}Unknown case: $CASE${NC}" >&2
        echo "Cases: $BUILTIN_CASES $SCENARIO_CASES all"
        exit 1
        ;;
esac
