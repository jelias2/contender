#!/bin/bash

# Fetch Reports from Remote VMs
# Downloads reports from remote VMs and organizes them locally
#
# Prerequisites:
#   1. .env file must be configured (see .env.example)
#   2. SSH access to remote VMs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "❌ ERROR: .env file not found"
    echo "Please copy .env.example to .env and configure your settings"
    exit 1
fi

source "$SCRIPT_DIR/.env"

# Validate required variables
REQUIRED_VARS=("US_IP" "JP_IP" "SSH_KEY_PATH" "SSH_USER")
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

# SSH options to prevent timeouts
SSH_OPTS="-o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o ConnectTimeout=10"

# Default values for optional variables
REMOTE_POST_PROCESSING_PATH=${REMOTE_POST_PROCESSING_PATH:-"~/contender/post-processing"}

# Function to organize reports into directories
organize_reports() {
    local region=$1
    cd "$region" || return

    # Find all report files and extract report numbers
    for file in *.csv report-*.html; do
        [ -f "$file" ] || continue

        # Extract report number from filename
        if [[ $file =~ ^([0-9]+)\.csv$ ]] || [[ $file =~ ^report-([0-9]+) ]]; then
            report_num="${BASH_REMATCH[1]}"

            # Create directory for this report if it doesn't exist
            mkdir -p "$report_num"

            # Move matching files to the report directory
            mv "${report_num}.csv" "$report_num/" 2>/dev/null
            mv report-${report_num}-*.html "$report_num/" 2>/dev/null
        fi
    done

    cd ..
}

# Function to fetch run results for all reports in a region
fetch_run_results() {
    local region=$1
    local vm_ip=$2

    echo "Fetching run results from $region VM..."
    cd "$region" || return

    # Iterate through all report directories
    for dir in */; do
        [ -d "$dir" ] || continue
        report_num="${dir%/}"  # Remove trailing slash

        # Check if this is a numeric directory (report number)
        if [[ $report_num =~ ^[0-9]+$ ]]; then
            echo "  Getting results for report $report_num..."
            ssh $SSH_OPTS -i "$SSH_KEY_PATH" "${SSH_USER}@$vm_ip" "ulimit -n 65536 && ${REMOTE_POST_PROCESSING_PATH}/get-run-results.sh $report_num" > "$report_num/run-results.txt" 2>&1
        fi
    done

    cd ..
}

# Create local directories if they don't exist
mkdir -p us jp

# Copy reports from US VM
echo "Fetching reports from US VM..."
scp $SSH_OPTS -i "$SSH_KEY_PATH" -r "${SSH_USER}@$US_IP:~/.contender/reports/*" us/ 2>/dev/null || echo "No reports found on US VM or connection failed"
organize_reports us
fetch_run_results us "$US_IP"

# Copy reports from JP VM
echo "Fetching reports from JP VM..."
scp $SSH_OPTS -i "$SSH_KEY_PATH" -r "${SSH_USER}@$JP_IP:~/.contender/reports/*" jp/ 2>/dev/null || echo "No reports found on JP VM or connection failed"
organize_reports jp
fetch_run_results jp "$JP_IP"

echo "Done! Reports saved to:"
echo "  US: $(pwd)/us/"
echo "  JP: $(pwd)/jp/"
