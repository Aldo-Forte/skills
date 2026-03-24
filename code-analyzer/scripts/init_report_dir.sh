#!/usr/bin/env bash
# init_report_dir.sh
# Creates the timestamped subdirectory for the current analysis run
# and prints the absolute path to stdout.
#
# Usage: bash init_report_dir.sh <project_dir>
#        Prints the absolute path of the created report dir to stdout.
#        All informational messages go to stderr to keep stdout clean.
#
# Directory format: YYYY-MM-DDTHH:MM:SS-Report
# Collision (same second): YYYY-MM-DDTHH:MM:SS-Report-N

set -euo pipefail

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Directory not found: $PROJECT_DIR" >&2
  exit 1
fi

# Resolve absolute path for consistent output
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
BASE_DIR="$PROJECT_DIR/code-analyzer"
mkdir -p "$BASE_DIR"

# Generate full timestamp with seconds: YYYY-MM-DDTHH:MM:SS
TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')
REPORT_DIR="$BASE_DIR/${TIMESTAMP}-Report"

# Collision (started in the same second): add counter
COUNTER=1
while [ -d "$REPORT_DIR" ]; do
  REPORT_DIR="$BASE_DIR/${TIMESTAMP}-Report-${COUNTER}"
  COUNTER=$((COUNTER + 1))
done

mkdir -p "$REPORT_DIR"

echo "📁 Report dir created: $REPORT_DIR" >&2

# Print only the absolute path to stdout (used by the caller)
echo "$REPORT_DIR"
