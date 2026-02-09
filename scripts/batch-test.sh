#!/bin/bash

# Batch Test Runner - Run multiple configurations sequentially
# Usage: ./scripts/batch-test.sh [config1] [config2] ...

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage:${NC} ./scripts/batch-test.sh [config1] [config2] ..."
    echo
    echo "Example: ./scripts/batch-test.sh low-tps medium-tps high-tps"
    echo
    echo "This will run each configuration sequentially and generate reports."
    exit 1
fi

# Check for private key
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${YELLOW}[WARNING]${NC} PRIVATE_KEY not set. Export it before running:"
    echo "export PRIVATE_KEY=your_key_here"
    exit 1
fi

CONFIGS=("$@")
TOTAL=${#CONFIGS[@]}
RESULTS_DIR="$ROOT_DIR/test-results-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$RESULTS_DIR"

print_info "Running batch test with $TOTAL configurations"
print_info "Results will be saved to: $RESULTS_DIR"
echo

for i in "${!CONFIGS[@]}"; do
    CONFIG="${CONFIGS[$i]}"
    NUM=$((i + 1))

    echo -e "\n${GREEN}=== Test $NUM/$TOTAL: $CONFIG ===${NC}\n"

    # Create output file for this test
    OUTPUT_FILE="$RESULTS_DIR/${CONFIG}-output.log"

    # Run the test and capture output
    if "$ROOT_DIR/run.sh" "$CONFIG" 2>&1 | tee "$OUTPUT_FILE"; then
        print_success "Test $NUM/$TOTAL completed: $CONFIG"
    else
        echo -e "${YELLOW}[WARNING]${NC} Test $NUM/$TOTAL had errors: $CONFIG"
    fi

    # Wait between tests
    if [ $NUM -lt $TOTAL ]; then
        print_info "Waiting 10 seconds before next test..."
        sleep 10
    fi
done

echo
print_success "All batch tests completed!"
print_info "Results saved to: $RESULTS_DIR"
echo

# Generate summary
echo -e "\n${GREEN}=== Test Summary ===${NC}" | tee "$RESULTS_DIR/SUMMARY.txt"
for CONFIG in "${CONFIGS[@]}"; do
    echo "- $CONFIG" | tee -a "$RESULTS_DIR/SUMMARY.txt"
done
echo | tee -a "$RESULTS_DIR/SUMMARY.txt"
