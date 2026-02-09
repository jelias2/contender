#!/bin/bash

# Configuration Validator
# Validates configuration files for required parameters

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Required parameters
REQUIRED_PARAMS=("RPC_URL" "DURATION" "TPS" "ACCOUNTS" "RPC_BATCH_SIZE" "TEST_TYPE" "TX_TYPE")

validate_config() {
    local config_file="$1"
    local config_name=$(basename "$config_file" .env)
    local errors=0

    echo -e "\n${BLUE}Validating: $config_name${NC}"

    # Source the config
    source "$config_file"

    # Check required parameters
    for param in "${REQUIRED_PARAMS[@]}"; do
        if [ -z "${!param}" ]; then
            print_error "$param is not set"
            ((errors++))
        else
            print_success "$param = ${!param}"
        fi
    done

    # Validate numeric values
    if ! [[ "$TPS" =~ ^[0-9]+$ ]]; then
        print_error "TPS must be a number"
        ((errors++))
    fi

    if ! [[ "$ACCOUNTS" =~ ^[0-9]+$ ]]; then
        print_error "ACCOUNTS must be a number"
        ((errors++))
    fi

    if ! [[ "$RPC_BATCH_SIZE" =~ ^[0-9]+$ ]]; then
        print_error "RPC_BATCH_SIZE must be a number"
        ((errors++))
    fi

    if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
        print_error "DURATION must be a number"
        ((errors++))
    fi

    # Validate test type
    VALID_TEST_TYPES=("blobs" "contract" "eth-functions" "erc20" "fill-block" "revert" "setCode" "storage" "stress" "transfers" "uniV2")
    if [[ ! " ${VALID_TEST_TYPES[@]} " =~ " ${TEST_TYPE} " ]]; then
        print_warning "TEST_TYPE '$TEST_TYPE' may not be valid. Valid types: ${VALID_TEST_TYPES[*]}"
    fi

    # Validate tx type
    VALID_TX_TYPES=("legacy" "eip1559" "eip4844" "eip7702")
    if [[ ! " ${VALID_TX_TYPES[@]} " =~ " ${TX_TYPE} " ]]; then
        print_error "TX_TYPE must be one of: ${VALID_TX_TYPES[*]}"
        ((errors++))
    fi

    # Check RPC URL format
    if [[ ! "$RPC_URL" =~ ^https?:// ]]; then
        print_warning "RPC_URL should start with http:// or https://"
    fi

    if [ $errors -eq 0 ]; then
        print_success "Configuration is valid!"
        return 0
    else
        print_error "Configuration has $errors error(s)"
        return 1
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    # Validate all configs
    echo -e "${GREEN}=== Validating All Configurations ===${NC}"

    total=0
    failed=0

    for config in "$CONFIGS_DIR"/*.env; do
        if [ -f "$config" ]; then
            ((total++))
            if ! validate_config "$config"; then
                ((failed++))
            fi
        fi
    done

    echo
    echo -e "${BLUE}=== Summary ===${NC}"
    echo "Total configurations: $total"
    echo "Passed: $((total - failed))"
    if [ $failed -gt 0 ]; then
        echo -e "${RED}Failed: $failed${NC}"
        exit 1
    else
        echo -e "${GREEN}All configurations valid!${NC}"
        exit 0
    fi
else
    # Validate specific config
    config_file="$CONFIGS_DIR/$1.env"
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi

    validate_config "$config_file"
fi
