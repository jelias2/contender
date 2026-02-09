#!/bin/bash

# Configuration Comparison Tool
# Displays configurations side-by-side for easy comparison

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo "Usage: ./scripts/compare-configs.sh <config1> <config2> [config3] ..."
    echo
    echo "Example: ./scripts/compare-configs.sh low-tps medium-tps high-tps"
    exit 1
fi

CONFIGS=("$@")
PARAMS=("RPC_URL" "DURATION" "TPS" "ACCOUNTS" "RPC_BATCH_SIZE" "TEST_TYPE" "TX_TYPE")

echo -e "${GREEN}=== Configuration Comparison ===${NC}\n"

# Print header
printf "%-20s" "Parameter"
for config in "${CONFIGS[@]}"; do
    printf "%-25s" "$config"
done
echo
printf "%-20s" "===================="
for config in "${CONFIGS[@]}"; do
    printf "%-25s" "======================="
done
echo

# Print each parameter
for param in "${PARAMS[@]}"; do
    printf "%-20s" "$param"

    for config in "${CONFIGS[@]}"; do
        config_file="$CONFIGS_DIR/$config.env"
        if [ -f "$config_file" ]; then
            # Source config and get value
            value=$(grep "^$param=" "$config_file" | cut -d'=' -f2- | tr -d '"')
            printf "%-25s" "$value"
        else
            printf "%-25s" "N/A"
        fi
    done
    echo
done

echo -e "\n${BLUE}Estimated Load Comparison:${NC}"
printf "%-20s" "Est. Total TXs"
for config in "${CONFIGS[@]}"; do
    config_file="$CONFIGS_DIR/$config.env"
    if [ -f "$config_file" ]; then
        source "$config_file"
        total=$((TPS * DURATION))
        printf "%-25s" "$total txs"
    else
        printf "%-25s" "N/A"
    fi
done
echo

printf "%-20s" "Total Accounts"
for config in "${CONFIGS[@]}"; do
    config_file="$CONFIGS_DIR/$config.env"
    if [ -f "$config_file" ]; then
        source "$config_file"
        printf "%-25s" "$ACCOUNTS"
    else
        printf "%-25s" "N/A"
    fi
done
echo -e "\n"
