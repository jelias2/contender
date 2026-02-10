#!/bin/bash

# Find Matching US and JP Test Runs
# Identifies test runs that have results from both US and JP VMs
# Based on Run ID matching

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Finding matching US and JP test runs..."
echo ""

# Find all run-id directories and group them
declare -A run_ids

for region in us jp; do
    region_path="$SCRIPT_DIR/$region"
    if [ ! -d "$region_path" ]; then
        continue
    fi

    # Find all directories that match run-id pattern (YYYYMMDD_HHMMSS_config)
    for config_dir in "$region_path"/erc20/*/; do
        [ -d "$config_dir" ] || continue

        for run_dir in "$config_dir"*/; do
            [ -d "$run_dir" ] || continue

            dir_name=$(basename "$run_dir")

            # Check if this looks like a run-id (starts with date pattern)
            if [[ $dir_name =~ ^[0-9]{8}_[0-9]{6}_ ]]; then
                run_id="$dir_name"

                # Store the mapping: run_id -> region:path
                if [ -n "${run_ids[$run_id]}" ]; then
                    run_ids[$run_id]="${run_ids[$run_id]}|$region:$run_dir"
                else
                    run_ids[$run_id]="$region:$run_dir"
                fi
            fi
        done
    done
done

# Display the results
echo "═══════════════════════════════════════════════════════════════"
echo "MATCHED TEST RUNS (US ↔ JP)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

for run_id in "${!run_ids[@]}"; do
    paths="${run_ids[$run_id]}"

    # Check if we have both US and JP
    if [[ $paths == *"us:"* ]] && [[ $paths == *"jp:"* ]]; then
        echo "🆔 Run ID: $run_id"

        # Extract and display US path
        us_path=$(echo "$paths" | grep -o "us:[^|]*" | cut -d: -f2-)
        echo "   🇺🇸 US: $us_path"

        # Extract and display JP path
        jp_path=$(echo "$paths" | grep -o "jp:[^|]*" | cut -d: -f2-)
        echo "   🇯🇵 JP: $jp_path"

        echo ""
    fi
done

# Also show unmatched runs
echo "───────────────────────────────────────────────────────────────"
echo "UNMATCHED RUNS"
echo "───────────────────────────────────────────────────────────────"
echo ""

for run_id in "${!run_ids[@]}"; do
    paths="${run_ids[$run_id]}"

    # Show runs that only have US or only JP
    if [[ $paths == *"us:"* ]] && [[ ! $paths == *"jp:"* ]]; then
        us_path=$(echo "$paths" | grep -o "us:[^|]*" | cut -d: -f2-)
        echo "⚠️  US only - $run_id"
        echo "   $us_path"
        echo ""
    elif [[ $paths == *"jp:"* ]] && [[ ! $paths == *"us:"* ]]; then
        jp_path=$(echo "$paths" | grep -o "jp:[^|]*" | cut -d: -f2-)
        echo "⚠️  JP only - $run_id"
        echo "   $jp_path"
        echo ""
    fi
done

echo "═══════════════════════════════════════════════════════════════"
