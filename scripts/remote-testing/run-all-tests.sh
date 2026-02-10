#!/bin/bash

# Remote Automated Test Suite
# Runs contender tests on multiple remote VMs and collects results
#
# Prerequisites:
#   1. Copy .env.example to .env and configure your settings
#   2. Ensure SSH access to remote VMs is configured
#   3. Ensure contender is installed on remote VMs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "❌ ERROR: .env file not found"
    echo "Please copy .env.example to .env and configure your settings:"
    echo "  cp $SCRIPT_DIR/.env.example $SCRIPT_DIR/.env"
    echo "  nano $SCRIPT_DIR/.env"
    exit 1
fi

source "$SCRIPT_DIR/.env"

# Validate required variables
REQUIRED_VARS=("US_IP" "JP_IP" "SSH_KEY_PATH" "SSH_USER" "PRIVATE_KEY")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ ERROR: Required variable $var is not set in .env"
        exit 1
    fi
done

# Check SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ ERROR: SSH key not found at: $SSH_KEY_PATH"
    exit 1
fi

# SSH options to prevent timeouts on long-running commands
SSH_OPTS="-o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o ConnectTimeout=10"

# Default values for optional variables
ENABLE_GRAFANA=${ENABLE_GRAFANA:-false}
GRAFANA_BASE_URL=${GRAFANA_BASE_URL:-""}
GRAFANA_PARAMS=${GRAFANA_PARAMS:-""}
REMOTE_CONTENDER_PATH=${REMOTE_CONTENDER_PATH:-"~/contender"}
REMOTE_POST_PROCESSING_PATH=${REMOTE_POST_PROCESSING_PATH:-"~/contender/post-processing"}

# Function to generate Grafana URL
generate_grafana_url() {
    local start_time=$1
    local end_time=$2
    echo "${GRAFANA_BASE_URL}?${GRAFANA_PARAMS}&from=${start_time}&to=${end_time}"
}

# Test configurations (without .env suffix)
CONFIGS=(
    # "10-tps"
    # "50-tps"
    # "400-tps"
    # "800-tps"
    # "1600-tps"
    "3200-tps"
    # "4000-tps"
    # "5000-tps"
)

# Function to fetch and organize reports for a specific config
fetch_reports_for_config() {
    local config=$1

    echo "📥 Fetching reports for erc20/$config..."

    # Create directory structure
    mkdir -p "us/erc20/$config" "jp/erc20/$config"

    # Copy reports from US VM
    echo "  Fetching from US VM..."
    scp $SSH_OPTS -i "$SSH_KEY_PATH" -r "${SSH_USER}@$US_IP:~/.contender/reports/*" "us/erc20/$config/" 2>/dev/null || echo "  No new reports from US VM"

    # Copy reports from JP VM
    echo "  Fetching from JP VM..."
    scp $SSH_OPTS -i "$SSH_KEY_PATH" -r "${SSH_USER}@$JP_IP:~/.contender/reports/*" "jp/erc20/$config/" 2>/dev/null || echo "  No new reports from JP VM"

    # Organize US reports
    organize_reports_for_region "us/erc20/$config" "$US_IP" "US" "$config"

    # Organize JP reports
    organize_reports_for_region "jp/erc20/$config" "$JP_IP" "JP" "$config"

    echo "  ✅ Reports organized in us/erc20/$config/ and jp/erc20/$config/"
}

# Function to organize reports and fetch run results for a specific region
organize_reports_for_region() {
    local region_path=$1
    local vm_ip=$2
    local vm_name=$3
    local config=$4

    cd "$region_path" || return

    # Check if there's a Grafana URL for this test run
    local grafana_url_file="/tmp/grafana_url_${vm_name}_${config}.txt"
    local grafana_url=""
    if [ -f "$grafana_url_file" ]; then
        grafana_url=$(cat "$grafana_url_file")
    fi

    # Check if there's a Run ID for this test run
    local run_id_file="/tmp/run_id_${vm_name}_${config}.txt"
    local run_id=""
    if [ -f "$run_id_file" ]; then
        run_id=$(cat "$run_id_file")
    fi

    # Create directory named by run-id if we have one
    if [ -n "$run_id" ]; then
        mkdir -p "$run_id"

        # Move all report files to the run-id directory
        mv *.csv "$run_id/" 2>/dev/null
        mv report-*.html "$run_id/" 2>/dev/null

        # Find all report numbers and fetch run results for each
        for file in "$run_id"/*.csv; do
            [ -f "$file" ] || continue

            # Extract report number from filename
            if [[ $(basename "$file") =~ ^([0-9]+)\.csv$ ]]; then
                report_num="${BASH_REMATCH[1]}"

                # Fetch run results for this report
                echo "  Fetching run results for report $report_num..."
                ssh $SSH_OPTS -i "$SSH_KEY_PATH" "${SSH_USER}@$vm_ip" "ulimit -n 65536 && ${REMOTE_POST_PROCESSING_PATH}/get-run-results.sh $report_num" > "$run_id/run-results-${report_num}.txt" 2>&1
            fi
        done

        # Save Grafana URL if available
        if [ -n "$grafana_url" ]; then
            echo "$grafana_url" > "$run_id/grafana-url.txt"
        fi

        # Save Run ID
        echo "$run_id" > "$run_id/run-id.txt"
    else
        # Fallback to old behavior if no run-id (for backwards compatibility)
        for file in *.csv report-*.html; do
            [ -f "$file" ] || continue

            # Extract report number from filename
            if [[ $file =~ ^([0-9]+)\.csv$ ]] || [[ $file =~ ^report-([0-9]+) ]]; then
                report_num="${BASH_REMATCH[1]}"
                mkdir -p "$report_num"
                mv "${report_num}.csv" "$report_num/" 2>/dev/null
                mv report-${report_num}-*.html "$report_num/" 2>/dev/null
            fi
        done
    fi

    # Clean up temp files
    rm -f "$grafana_url_file" "$run_id_file"

    cd - > /dev/null
}

# Function to run test on a VM
run_test() {
    local vm_name=$1
    local vm_ip=$2
    local config=$3
    local run_id=$4

    echo ""
    echo "=========================================="
    echo "🚀 RUNNING: erc20/$config on $vm_name VM"
    echo "🆔 Run ID: $run_id"
    echo "=========================================="
    echo ""

    # Clean up old reports on the VM before starting new test
    echo "[$vm_name/$config] Cleaning up old reports on VM..."
    ssh $SSH_OPTS -i "$SSH_KEY_PATH" "${SSH_USER}@$vm_ip" "rm -rf ~/.contender/reports/*" 2>&1 | sed "s/^/[$vm_name\/$config] /"

    # Capture start time (minus 1 minute buffer)
    local start_timestamp=$(date -u -v-1M +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d '1 minute ago' +"%Y-%m-%dT%H:%M:%S.000Z")

    # Run the benchmark with prefixed output
    echo "[$vm_name/$config] Starting benchmark..."
    ssh $SSH_OPTS -i "$SSH_KEY_PATH" "${SSH_USER}@$vm_ip" "ulimit -n 65536 && source ~/.profile && source ~/.bashrc && export PRIVATE_KEY='$PRIVATE_KEY' && ${REMOTE_CONTENDER_PATH}/scripts/run-op-benchmark.sh erc20/$config" 2>&1 | sed "s/^/[$vm_name\/$config] /"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo ""
        echo "❌ ERROR: Test failed on $vm_name VM for $config"
        echo ""
        return 1
    fi

    echo ""
    echo "✅ [$vm_name/$config] Benchmark completed"
    echo ""

    # Generate report
    echo "[$vm_name/$config] Generating report..."
    ssh $SSH_OPTS -i "$SSH_KEY_PATH" "${SSH_USER}@$vm_ip" "ulimit -n 65536 && source ~/.profile && source ~/.bashrc && export PRIVATE_KEY='$PRIVATE_KEY' && export BROWSER=true && contender report" 2>&1 | sed "s/^/[$vm_name\/$config] /"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo ""
        echo "❌ ERROR: Report generation failed on $vm_name VM for $config"
        echo ""
        return 1
    fi

    # Capture end time (plus 1 minute buffer)
    local end_timestamp=$(date -u -v+1M +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d '1 minute' +"%Y-%m-%dT%H:%M:%S.000Z")

    echo ""
    echo "✅ [$vm_name/$config] Report generated successfully"

    # Generate and store Grafana URL only if enabled
    if [ "$ENABLE_GRAFANA" = true ] && [ -n "$GRAFANA_BASE_URL" ]; then
        local grafana_url=$(generate_grafana_url "$start_timestamp" "$end_timestamp")
        echo "📊 Grafana URL: $grafana_url"
        echo "$grafana_url" > "/tmp/grafana_url_${vm_name}_${config}.txt"
    fi

    echo ""

    # Store the Run ID for later use (will be saved to file after fetch)
    echo "$run_id" > "/tmp/run_id_${vm_name}_${config}.txt"

    return 0
}

# Main execution
echo ""
echo "██████████████████████████████████████████"
echo "🚀 STARTING AUTOMATED TEST SUITE"
echo "██████████████████████████████████████████"
echo "Total configurations: ${#CONFIGS[@]}"
echo "VMs: US ($US_IP) and JP ($JP_IP)"
echo "Configurations: ${CONFIGS[*]}"
echo "██████████████████████████████████████████"
echo ""

for config in "${CONFIGS[@]}"; do
    # Generate unique run ID for this test pair
    RUN_ID="$(date +%Y%m%d_%H%M%S)_${config}"

    echo ""
    echo "██████████████████████████████████████████"
    echo "📊 CONFIGURATION: erc20/$config"
    echo "🆔 Run ID: $RUN_ID"
    echo "██████████████████████████████████████████"

    # Run on US VM first
    run_test "US" "$US_IP" "$config" "$RUN_ID"
    if [ $? -ne 0 ]; then
        echo "⚠️  Skipping JP VM test due to US VM failure"
        continue
    fi

    # Run on JP VM
    run_test "JP" "$JP_IP" "$config" "$RUN_ID"

    echo ""
    # Fetch and organize reports with test scenario structure
    fetch_reports_for_config "$config"

    echo ""
    echo "✅ Configuration $config completed on both VMs"
    echo ""
done

echo ""
echo "██████████████████████████████████████████"
echo "🎉 ALL TESTS COMPLETED!"
echo "██████████████████████████████████████████"
echo "📁 Reports are organized by test scenario and run ID:"
echo "   ${SCRIPT_DIR}/us/erc20/<config>/<run-id>/"
echo "   ${SCRIPT_DIR}/jp/erc20/<config>/<run-id>/"
echo ""
echo "Example:"
echo "   ${SCRIPT_DIR}/us/erc20/10-tps/20260210_123456_10-tps/"
echo "   ${SCRIPT_DIR}/jp/erc20/10-tps/20260210_123456_10-tps/"
echo ""
echo "Use the same run-id to find matching US/JP test pairs!"
echo "██████████████████████████████████████████"
echo ""
