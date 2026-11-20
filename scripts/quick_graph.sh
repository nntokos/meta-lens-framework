#!/usr/bin/env bash
# Quick look at a single headset session without laps annotations.
# Usage: scripts/quick_graph.sh [dir] [--ovr path/to/ovr_metrics.csv]
#   dir defaults to _logs/ and the newest .log inside it is graphed.
#   OVR CSV defaults to ovr_metrics.csv in dir.
#   OVR start time is read from ovr_metrics_start_time.txt in dir, else the log start is used.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dir="$SCRIPT_DIR/../_logs"
ovr_args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ovr)
            ovr_args=(--ovr_metrics_csv "$2")
            shift 2
            ;;
        *)
            dir="$1"
            shift
            ;;
    esac
done

if [[ ! -d "$dir" ]]; then
    echo "Directory '$dir' does not exist" >&2
    exit 1
fi

log="$(ls -t "$dir"/*.log 2>/dev/null | head -n 1 || true)"
if [[ -z "$log" ]]; then
    echo "No .log file found in '$dir'" >&2
    exit 1
fi

csv="${log%.*}.csv"
python3 "$SCRIPT_DIR/../file_converters/log_to_csv.py" "$log" --csv_file "$csv"
python3 "$SCRIPT_DIR/../analyze/graph.py" "$csv" --output "${log%.*}_graph.html" --show_in_browser ${ovr_args[@]+"${ovr_args[@]}"}
