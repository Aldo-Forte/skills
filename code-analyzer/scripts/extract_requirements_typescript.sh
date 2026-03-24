#!/usr/bin/env bash
# extract_requirements_typescript.sh
# Detects the TypeScript/Node project and generates requirements_typescript.txt
# in {report_dir}/requirements_typescript.txt
#
# Usage: bash extract_requirements_typescript.sh <project_dir> [report_dir]
#        If project_dir is not provided, uses the current directory.
#        report_dir: path of the report dir (from init_report_dir.sh);
#                    if omitted, saves to <project_dir>/code-analyzer/
#        npm warnings (missing peer deps) are intentionally silenced with 2>/dev/null.

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
OUTPUT_FILE="$OUTPUT_DIR/requirements_typescript.txt"

echo "🔍 Searching for TypeScript/Node project in: $PROJECT_DIR" >&2

# --- Check package.json (before creating output directory) ---
PACKAGE_JSON="$PROJECT_DIR/package.json"
if [ ! -f "$PACKAGE_JSON" ]; then
  echo "❌ package.json not found in $PROJECT_DIR" >&2
  echo "   Make sure you are pointing to the root of the Node/TypeScript project." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
echo "✅ package.json found" >&2

# --- Check node_modules ---
NODE_MODULES="$PROJECT_DIR/node_modules"
HAS_NODE_MODULES=false
if [ -d "$NODE_MODULES" ]; then
  HAS_NODE_MODULES=true
  echo "✅ node_modules found" >&2
else
  echo "⚠️  node_modules not found — dependencies may not be installed" >&2
fi

# --- Output header ---
{
  echo "# TypeScript/Node Requirements"
  echo "# Extracted from: $PROJECT_DIR"
  echo "# Date: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
} > "$OUTPUT_FILE"

# --- Section 1: dependencies from package.json ---
{
  echo "# Declared dependencies (package.json)"
  echo ""
} >> "$OUTPUT_FILE"

if command -v node &>/dev/null; then
  PKG_PATH="$PACKAGE_JSON" node -e "
    const fs = require('fs');
    const pkgPath = process.env.PKG_PATH;
    let pkg;
    try {
      pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    } catch(e) {
      process.stderr.write('Error reading package.json: ' + e.message + '\n');
      process.exit(1);
    }
    const sections = [
      ['dependencies', pkg.dependencies || {}],
      ['devDependencies', pkg.devDependencies || {}],
      ['peerDependencies', pkg.peerDependencies || {}],
      ['optionalDependencies', pkg.optionalDependencies || {}],
    ];
    for (const [section, deps] of sections) {
      const entries = Object.entries(deps);
      if (entries.length === 0) continue;
      process.stdout.write('# ' + section + '\n');
      for (const [name, version] of entries) {
        process.stdout.write(name + '@' + version + '\n');
      }
      process.stdout.write('\n');
    }
  " >> "$OUTPUT_FILE" || {
    echo "⚠️  node could not read package.json — including raw file" >> "$OUTPUT_FILE"
    cat "$PACKAGE_JSON" >> "$OUTPUT_FILE"
  }
else
  echo "⚠️  node not available — including raw package.json" >> "$OUTPUT_FILE"
  cat "$PACKAGE_JSON" >> "$OUTPUT_FILE"
fi

# --- Section 2: actually installed versions ---
if [ "$HAS_NODE_MODULES" = true ]; then
  {
    echo ""
    echo "# Actually installed versions (node_modules)"
    echo ""
  } >> "$OUTPUT_FILE"

  if command -v npm &>/dev/null; then
    NPM_OUT=$(npm --prefix "$PROJECT_DIR" list --depth=0 2>/dev/null || true)
    NPM_OUT_TRIMMED=$(echo "$NPM_OUT" | tr -d '[:space:]')
    if [ -n "$NPM_OUT_TRIMMED" ]; then
      printf '%s\n' "$NPM_OUT" >> "$OUTPUT_FILE"
    else
      echo "(npm list produced no useful output — peer deps may be missing)" >> "$OUTPUT_FILE"
    fi
  elif command -v yarn &>/dev/null && [ -f "$PROJECT_DIR/yarn.lock" ]; then
    YARN_VERSION=$(yarn --version 2>/dev/null | cut -d. -f1 || echo "1")
    if [ "$YARN_VERSION" = "1" ]; then
      yarn --cwd "$PROJECT_DIR" list --depth=0 2>/dev/null >> "$OUTPUT_FILE" || \
        echo "(yarn list returned errors)" >> "$OUTPUT_FILE"
    else
      yarn --cwd "$PROJECT_DIR" workspaces list 2>/dev/null >> "$OUTPUT_FILE" || \
        echo "(yarn workspaces list not available in this version)" >> "$OUTPUT_FILE"
    fi
  elif command -v pnpm &>/dev/null && [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then
    pnpm --dir "$PROJECT_DIR" list --depth=0 2>/dev/null >> "$OUTPUT_FILE" || \
    pnpm --dir "$PROJECT_DIR" list 2>/dev/null >> "$OUTPUT_FILE" || \
      echo "(pnpm list returned errors)" >> "$OUTPUT_FILE"
  else
    echo "(no package manager available to list installed versions)" >> "$OUTPUT_FILE"
  fi
fi

# --- Section 3: TypeScript config ---
TSCONFIG="$PROJECT_DIR/tsconfig.json"
if [ -f "$TSCONFIG" ]; then
  {
    echo ""
    echo "# TypeScript configuration (tsconfig.json)"
    echo ""
    cat "$TSCONFIG"
  } >> "$OUTPUT_FILE"
fi

# --- Summary ---
COUNT_DEPS=0
if command -v node &>/dev/null; then
  COUNT_DEPS=$(PKG_PATH="$PACKAGE_JSON" node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync(process.env.PKG_PATH, 'utf8'));
    const all = [
      ...Object.keys(pkg.dependencies || {}),
      ...Object.keys(pkg.devDependencies || {}),
      ...Object.keys(pkg.peerDependencies || {}),
      ...Object.keys(pkg.optionalDependencies || {}),
    ];
    console.log(all.length);
  " 2>/dev/null || echo 0)
fi

echo "" >&2
echo "✅ Analysis complete: $COUNT_DEPS declared dependencies" >&2
echo "📄 File saved to: $OUTPUT_FILE" >&2
