#!/usr/bin/env bash
# extract_requirements_python.sh
# Detects the Python virtual environment and generates requirements_python.txt
# in {report_dir}/requirements_python.txt
#
# Usage: bash extract_requirements_python.sh <project_dir> [report_dir]
#        All informational messages go to stderr.
#        If report_dir is not provided, saves to <project_dir>/code-analyzer/
#
# Exit codes:
#   0 = success
#   1 = fatal error (directory not found, pip freeze failed)
#   2 = venv not found (non-fatal — caller decides how to proceed)
#
# Note: pip warnings are intentionally silenced (2>/dev/null).
#       If the project has warnings, run pip freeze manually to see them.

set -euo pipefail

PROJECT_DIR="${1:-.}"
REPORT_DIR="${2:-}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Directory not found: $PROJECT_DIR" >&2
  exit 1
fi

if [ -n "$REPORT_DIR" ]; then
  OUTPUT_DIR="$REPORT_DIR"
else
  OUTPUT_DIR="$PROJECT_DIR/code-analyzer"
fi
OUTPUT_FILE="$OUTPUT_DIR/requirements_python.txt"

mkdir -p "$OUTPUT_DIR"

echo "🔍 Searching for virtual environment in: $PROJECT_DIR" >&2

VENV_DIRS=(".venv" "venv" "env" ".env" "virtualenv")
FOUND_VENV=""

for d in "${VENV_DIRS[@]}"; do
  CANDIDATE="$PROJECT_DIR/$d"
  if [ -f "$CANDIDATE/bin/pip" ] || [ -f "$CANDIDATE/Scripts/pip.exe" ] || [ -f "$CANDIDATE/Scripts/pip" ]; then
    FOUND_VENV="$CANDIDATE"
    echo "✅ Virtual environment found: $FOUND_VENV" >&2
    break
  fi
done

if [ -z "$FOUND_VENV" ]; then
  echo "⚠️  No virtual environment found in standard locations." >&2
  echo "   Searched: ${VENV_DIRS[*]}" >&2
  echo "   Suggestion: use requirements.txt or pyproject.toml as fallback." >&2
  exit 2
fi

if [ -f "$FOUND_VENV/bin/pip" ]; then
  PIP_CMD="$FOUND_VENV/bin/pip"
elif [ -f "$FOUND_VENV/Scripts/pip.exe" ]; then
  PIP_CMD="$FOUND_VENV/Scripts/pip.exe"
else
  PIP_CMD="$FOUND_VENV/Scripts/pip"
fi

# Verify pip is actually executable (avoids silent failures with set -e)
if [ ! -x "$PIP_CMD" ]; then
  echo "❌ pip found but not executable: $PIP_CMD" >&2
  exit 1
fi

echo "📦 Extracting installed packages with: $PIP_CMD" >&2

# pip freeze: stderr separated to avoid polluting output with pip warnings
FREEZE_OUT=$("$PIP_CMD" freeze 2>/dev/null) || {
  echo "❌ pip freeze failed" >&2
  exit 1
}
{
  echo "# Requirements extracted from virtual environment"
  echo "# Project: $PROJECT_DIR"
  echo "# Venv: $FOUND_VENV"
  echo "# Date: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  printf '%s\n' "$FREEZE_OUT"
} > "$OUTPUT_FILE"

# Count non-comment, non-empty lines
COUNT=$(grep -cE '^[^#[:space:]]' "$OUTPUT_FILE" 2>/dev/null || echo 0)

echo "✅ Requirements extracted: $COUNT packages" >&2
echo "📄 File saved to: $OUTPUT_FILE" >&2
echo "--- Contents (first 20 lines) ---" >&2
head -20 "$OUTPUT_FILE" >&2
