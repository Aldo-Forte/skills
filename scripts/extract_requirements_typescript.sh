#!/usr/bin/env bash
# extract_requirements_typescript.sh
# Rileva il progetto TypeScript/Node e genera un report delle dipendenze
# in {report_dir}/requirements_typescript.txt
#
# Uso: bash extract_requirements_typescript.sh <project_dir> [report_dir]
#      Se project_dir non è fornito, usa la directory corrente.
#      report_dir: path della report dir (da init_report_dir.sh); se omesso usa <project_dir>/code-analyzer/.
#      I warning npm (peer deps mancanti) vengono silenziati con 2>/dev/null intenzionalmente.

set -euo pipefail

PROJECT_DIR="${1:-.}"
# Secondo argomento opzionale: report dir già creata da init_report_dir.sh
# Se non fornito, salva direttamente in code-analyzer/ (compatibilità)
REPORT_DIR="${2:-}"

# Valida che PROJECT_DIR esista
if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Directory non trovata: $PROJECT_DIR" >&2
  exit 1
fi

if [ -n "$REPORT_DIR" ]; then
  OUTPUT_DIR="$REPORT_DIR"
else
  OUTPUT_DIR="$PROJECT_DIR/code-analyzer"
fi
OUTPUT_FILE="$OUTPUT_DIR/requirements_typescript.txt"

echo "🔍 Ricerca progetto TypeScript/Node in: $PROJECT_DIR" >&2

# --- Verifica package.json (prima di creare directory) ---
PACKAGE_JSON="$PROJECT_DIR/package.json"
if [ ! -f "$PACKAGE_JSON" ]; then
  echo "❌ package.json non trovato in $PROJECT_DIR" >&2
  echo "   Assicurati di puntare alla root del progetto Node/TypeScript." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
echo "✅ package.json trovato" >&2

# --- Verifica node_modules ---
NODE_MODULES="$PROJECT_DIR/node_modules"
HAS_NODE_MODULES=false
if [ -d "$NODE_MODULES" ]; then
  HAS_NODE_MODULES=true
  echo "✅ node_modules trovato" >&2
else
  echo "⚠️  node_modules non trovato — le dipendenze potrebbero non essere installate" >&2
fi

# --- Intestazione output ---
{
  echo "# Requirements TypeScript/Node"
  echo "# Estratto da: $PROJECT_DIR"
  echo "# Data: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
} > "$OUTPUT_FILE"

# --- Sezione 1: dipendenze da package.json ---
{
  echo "# Dipendenze dichiarate (package.json)"
  echo ""
} >> "$OUTPUT_FILE"

# Legge package.json via variabile d'ambiente PKG_PATH (sicuro con path contenenti apostrofi).
if command -v node &>/dev/null; then
  PKG_PATH="$PACKAGE_JSON" node -e "
    const fs = require('fs');
    const pkgPath = process.env.PKG_PATH;
    let pkg;
    try {
      pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    } catch(e) {
      process.stderr.write('Errore lettura package.json: ' + e.message + '\n');
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
    echo "⚠️  node non ha potuto leggere package.json — inclusione raw" >> "$OUTPUT_FILE"
    cat "$PACKAGE_JSON" >> "$OUTPUT_FILE"
  }
else
  echo "⚠️  node non disponibile — inclusione raw di package.json" >> "$OUTPUT_FILE"
  cat "$PACKAGE_JSON" >> "$OUTPUT_FILE"
fi

# --- Sezione 2: versioni effettivamente installate ---
if [ "$HAS_NODE_MODULES" = true ]; then
  {
    echo ""
    echo "# Versioni effettivamente installate (node_modules)"
    echo ""
  } >> "$OUTPUT_FILE"

  if command -v npm &>/dev/null; then
    # npm list esce con codice 1 se ci sono peer deps mancanti (comune):
    # catturiamo l'output in ogni caso e segnaliamo solo se è completamente vuoto.
    NPM_OUT=$(npm --prefix "$PROJECT_DIR" list --depth=0 2>/dev/null || true)
    # Strip whitespace before checking if output is meaningful
    NPM_OUT_TRIMMED=$(echo "$NPM_OUT" | tr -d '[:space:]')
    if [ -n "$NPM_OUT_TRIMMED" ]; then
      printf '%s\n' "$NPM_OUT" >> "$OUTPUT_FILE"
    else
      echo "(npm list non ha prodotto output utile — peer deps potrebbero mancare)" >> "$OUTPUT_FILE"
    fi
  elif command -v yarn &>/dev/null && [ -f "$PROJECT_DIR/yarn.lock" ]; then
    # Rileva versione yarn: v1 usa "list", Berry (v2+) usa "info"
    YARN_VERSION=$(yarn --version 2>/dev/null | cut -d. -f1 || echo "1")
    if [ "$YARN_VERSION" = "1" ]; then
      yarn --cwd "$PROJECT_DIR" list --depth=0 2>/dev/null >> "$OUTPUT_FILE" || \
        echo "(yarn list ha restituito errori)" >> "$OUTPUT_FILE"
    else
      # Yarn Berry: usa workspaces list oppure info
      yarn --cwd "$PROJECT_DIR" workspaces list 2>/dev/null >> "$OUTPUT_FILE" || \
        echo "(yarn workspaces list non disponibile in questa versione)" >> "$OUTPUT_FILE"
    fi
  elif command -v pnpm &>/dev/null && [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then
    # pnpm list senza --depth per compatibilità con versioni diverse
    pnpm --dir "$PROJECT_DIR" list --depth=0 2>/dev/null >> "$OUTPUT_FILE" || \
    pnpm --dir "$PROJECT_DIR" list 2>/dev/null >> "$OUTPUT_FILE" || \
      echo "(pnpm list ha restituito errori)" >> "$OUTPUT_FILE"
  else
    echo "(nessun package manager disponibile per elencare le versioni installate)" >> "$OUTPUT_FILE"
  fi
fi

# --- Sezione 3: info TypeScript ---
TSCONFIG="$PROJECT_DIR/tsconfig.json"
if [ -f "$TSCONFIG" ]; then
  {
    echo ""
    echo "# Configurazione TypeScript (tsconfig.json)"
    echo ""
    cat "$TSCONFIG"
  } >> "$OUTPUT_FILE"
fi

# --- Riepilogo ---
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
echo "✅ Analisi completata: $COUNT_DEPS dipendenze dichiarate" >&2
echo "📄 File salvato in: $OUTPUT_FILE" >&2
