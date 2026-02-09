#!/bin/bash

# Configurable Contender Spam Runner
# Usage:
#   ./run.sh [config_name]                    # Use a preset config
#   ./run.sh --rpc URL --tps 100 ...          # Custom parameters
#   ./run.sh --help                           # Show help

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_RPC_URL="https://demo-ntt-2-0.optimism.io"
DEFAULT_DURATION=120
DEFAULT_TPS=50
DEFAULT_ACCOUNTS=25
DEFAULT_RPC_BATCH_SIZE=50
DEFAULT_TEST_TYPE="erc20"
DEFAULT_TX_TYPE="eip1559"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show help
show_help() {
    cat << EOF
${GREEN}Contender Spam Runner${NC}

Usage:
  ./run.sh [CONFIG_NAME]              Load preset configuration
  ./run.sh [OPTIONS]                  Run with custom parameters
  ./run.sh --help                     Show this help

${BLUE}Available Preset Configurations:${NC}
  <test-type>/<preset>  e.g. erc20/low, erc20/medium, erc20/high
  stress/high           - Extreme (500 TPS, 200 accounts)
  blobs/default         - Blob transactions (EIP-4844)
  transfers/default    - Simple ETH transfers
  univ2/default        - UniswapV2 swaps
  storage/default      - Storage operations
  l2-mint-send/default  - L2 mint + SuperchainTokenBridge (scenario file)
  localhost/default    - Local development setup
  Run ./run.sh --list-configs to see all.

${BLUE}Custom Options:${NC}
  -r, --rpc URL              RPC endpoint URL
  --tps NUM                  Transactions per second
  -a, --accounts NUM         Number of accounts per agent
  -b, --batch-size NUM       RPC batch size
  -d, --duration NUM         Duration in seconds
  -t, --test-type TYPE       Test type (erc20, transfers, blobs, etc.)
  --tx-type TYPE             Transaction type (eip1559, legacy, eip4844, eip7702)
  -p, --private-key KEY      Private key (or set PRIVATE_KEY env var)
  --list-configs             List all available configurations
  --list-test-types          List all available test types

${BLUE}Examples:${NC}
  ./run.sh erc20/medium                         # Use erc20 medium preset
  ./run.sh --tps 100 --accounts 50              # Custom TPS and accounts
  ./run.sh -r http://localhost:8545 --tps 25   # Custom RPC and TPS
  ./run.sh stress/high --duration 600           # Override duration in preset

${YELLOW}Note:${NC} PRIVATE_KEY environment variable must be set or provided via -p flag
EOF
    exit 0
}

# Function to list configurations
list_configs() {
    echo -e "${GREEN}Available Configurations:${NC}\n"
    for config in configs/*/*.env; do
        if [ -f "$config" ]; then
            name="${config#configs/}"
            name="${name%.env}"
            echo -e "${BLUE}$name${NC}"
            grep "^#" "$config" | head -n 2 | sed 's/^# /  /'
            echo
        fi
    done
    exit 0
}

# Function to list test types
list_test_types() {
    cat << EOF
${GREEN}Available Test Types:${NC}

  blobs          - Send EIP-4844 blob transactions
  contract       - Deploy and spam a custom contract
  eth-functions  - Spam specific opcodes & precompiles
  erc20          - Transfer ERC20 tokens
  fill-block     - Fill blocks with simple gas-consuming transactions
  revert         - Send reverting transactions
  setCode        - Send EIP-7702 setCode transactions
  storage        - Fill storage slots with random data
  stress         - Comprehensive stress test
  transfers      - Simple ETH transfers
  uniV2          - UniswapV2 swaps with custom tokens

EOF
    exit 0
}

# Load configuration from file
load_config() {
    local config_file="configs/$1.env"
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        echo "Run './run.sh --list-configs' to see available configurations"
        exit 1
    fi

    print_info "Loading configuration: $1"
    source "$config_file"
    print_success "Loaded $config_file"
}

# Parse arguments
CONFIG_LOADED=false

if [ $# -eq 0 ]; then
    print_warning "No configuration specified, using defaults"
    RPC_URL="$DEFAULT_RPC_URL"
    DURATION="$DEFAULT_DURATION"
    TPS="$DEFAULT_TPS"
    ACCOUNTS="$DEFAULT_ACCOUNTS"
    RPC_BATCH_SIZE="$DEFAULT_RPC_BATCH_SIZE"
    TEST_TYPE="$DEFAULT_TEST_TYPE"
    TX_TYPE="$DEFAULT_TX_TYPE"
elif [ $# -eq 1 ] && [[ ! "$1" =~ ^- ]]; then
    # Single argument without dash - treat as config name
    case "$1" in
        --help|-h)
            show_help
            ;;
        --list-configs)
            list_configs
            ;;
        --list-test-types)
            list_test_types
            ;;
        *)
            load_config "$1"
            CONFIG_LOADED=true
            ;;
    esac
else
    # Parse command line arguments
    RPC_URL="$DEFAULT_RPC_URL"
    DURATION="$DEFAULT_DURATION"
    TPS="$DEFAULT_TPS"
    ACCOUNTS="$DEFAULT_ACCOUNTS"
    RPC_BATCH_SIZE="$DEFAULT_RPC_BATCH_SIZE"
    TEST_TYPE="$DEFAULT_TEST_TYPE"
    TX_TYPE="$DEFAULT_TX_TYPE"

    # Check if first arg is a config name
    if [[ ! "$1" =~ ^- ]] && [ -f "configs/$1.env" ]; then
        load_config "$1"
        CONFIG_LOADED=true
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            --list-configs)
                list_configs
                ;;
            --list-test-types)
                list_test_types
                ;;
            -r|--rpc)
                RPC_URL="$2"
                shift 2
                ;;
            --tps)
                TPS="$2"
                shift 2
                ;;
            -a|--accounts)
                ACCOUNTS="$2"
                shift 2
                ;;
            -b|--batch-size)
                RPC_BATCH_SIZE="$2"
                shift 2
                ;;
            -d|--duration)
                DURATION="$2"
                shift 2
                ;;
            -t|--test-type)
                TEST_TYPE="$2"
                shift 2
                ;;
            --tx-type)
                TX_TYPE="$2"
                shift 2
                ;;
            -p|--private-key)
                PRIVATE_KEY="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
fi

# Check for private key
if [ -z "$PRIVATE_KEY" ]; then
    print_error "PRIVATE_KEY environment variable is not set"
    echo "Set it with: export PRIVATE_KEY=your_key_here"
    echo "Or pass it with: ./run.sh -p your_key_here"
    exit 1
fi

# Scenario-file flow (e.g. l2-mint-send): setup then spam
if [ -n "${SCENARIO_PATH:-}" ]; then
    echo -e "\n${GREEN}=== Contender Scenario (setup + spam) ===${NC}"
    echo -e "${BLUE}RPC URL:${NC}      $RPC_URL"
    echo -e "${BLUE}Scenario:${NC}     $SCENARIO_PATH"
    echo -e "${BLUE}Duration:${NC}    ${DURATION}s"
    echo -e "${BLUE}TPS:${NC}          $TPS"
    echo -e "${BLUE}Accounts:${NC}     $ACCOUNTS"
    echo -e "${GREEN}=========================================${NC}\n"
    read -p "$(echo -e ${YELLOW}Continue? [Y/n]:${NC} )" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        print_warning "Aborted by user"
        exit 0
    fi
    CONTENDER_BIN="./target/debug/contender"
    [ -x "./target/release/contender" ] && CONTENDER_BIN="./target/release/contender"
    print_info "Running setup..."
    $CONTENDER_BIN setup "$SCENARIO_PATH" "$RPC_URL" -p "$PRIVATE_KEY" --min-balance 0.25
    print_info "Running spam..."
    $CONTENDER_BIN spam "$SCENARIO_PATH" "$RPC_URL" -p "$PRIVATE_KEY" \
        -d "$DURATION" --tps "$TPS" --accounts "$ACCOUNTS" --rpc-batch-size "$RPC_BATCH_SIZE" \
        --min-balance 0.05
    print_success "Scenario run completed!"
    exit 0
fi

# Display configuration (built-in spam)
echo -e "\n${GREEN}=== Contender Spam Configuration ===${NC}"
echo -e "${BLUE}RPC URL:${NC}         $RPC_URL"
echo -e "${BLUE}Duration:${NC}        ${DURATION}s"
echo -e "${BLUE}TPS:${NC}             $TPS"
echo -e "${BLUE}Accounts:${NC}        $ACCOUNTS"
echo -e "${BLUE}Batch Size:${NC}      $RPC_BATCH_SIZE"
echo -e "${BLUE}Test Type:${NC}       $TEST_TYPE"
echo -e "${BLUE}TX Type:${NC}         $TX_TYPE"
echo -e "${GREEN}====================================${NC}\n"

# Confirmation prompt
read -p "$(echo -e ${YELLOW}Continue with this configuration? [Y/n]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
    print_warning "Aborted by user"
    exit 0
fi

# Build the command
CMD="./target/debug/contender spam \
    -r $RPC_URL \
    -p $PRIVATE_KEY \
    -d $DURATION \
    --tps $TPS \
    --accounts $ACCOUNTS \
    --rpc-batch-size $RPC_BATCH_SIZE \
    -t $TX_TYPE \
    $TEST_TYPE"

print_info "Running command:"
echo -e "${BLUE}$CMD${NC}\n"

# Execute the command
eval $CMD

print_success "Spam run completed!"
