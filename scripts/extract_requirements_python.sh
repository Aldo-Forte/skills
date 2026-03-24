#!/usr/bin/env bash
# extract_requirements_python.sh
# Rileva il virtual environment Python nel progetto e genera requirements.txt
# in {report_dir}/requirements_python.txt
#
# Uso: bash extract_requirements_python.sh <project_dir> [report_dir]
#      Tutti i messaggi informativi vanno su stderr.
#      Se report_dir non è fornito, salva in <project_dir>/code-analyzer/ (fallback).
#
# Exit codes:
#   0 = successo
#   1 = errore fatale (directory non trovata, pip freeze fallito)
#   2 = venv non trovato (non fatale — caller decide come procedere)

set -euo pipefail

PROJECT_DIR="${1:-.}"
REPORT_DIR="${2:-}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Directory non trovata: $PROJECT_DIR" >&2
  exit 1
fi

if [ -n "$REPORT_DIR" ]; then
  OUTPUT_DIR="$REPORT_DIR"
else
  OUTPUT_DIR="$PROJECT_DIR/code-analyzer"
fi
OUTPUT_FILE="$OUTPUT_DIR/requirements_python.txt"

mkdir -p "$OUTPUT_DIR"

echo "🔍 Ricerca virtual environment in: $PROJECT_DIR" >&2

VENV_DIRS=(".venv" "venv" "env" ".env" "virtualenv")
FOUND_VENV=""

for d in "${VENV_DIRS[@]}"; do
  CANDIDATE="$PROJECT_DIR/$d"
  if [ -f "$CANDIDATE/bin/pip" ] || [ -f "$CANDIDATE/Scripts/pip.exe" ] || [ -f "$CANDIDATE/Scripts/pip" ]; then
    FOUND_VENV="$CANDIDATE"
    echo "✅ Virtual environment trovato: $FOUND_VENV" >&2
    break
  fi
done

if [ -z "$FOUND_VENV" ]; then
  echo "⚠️  Nessun virtual environment trovato nelle posizioni standard." >&2
  echo "   Posizioni cercate: ${VENV_DIRS[*]}" >&2
  echo "   Suggerimento: usa requirements.txt o pyproject.toml come fonte alternativa." >&2
  exit 2
fi

if [ -f "$FOUND_VENV/bin/pip" ]; then
  PIP_CMD="$FOUND_VENV/bin/pip"
elif [ -f "$FOUND_VENV/Scripts/pip.exe" ]; then
  PIP_CMD="$FOUND_VENV/Scripts/pip.exe"
else
  PIP_CMD="$FOUND_VENV/Scripts/pip"
fi

# Verifica che pip sia effettivamente eseguibile (evita errori silenziosi con set -e)
if [ ! -x "$PIP_CMD" ]; then
  echo "❌ pip trovato ma non eseguibile: $PIP_CMD" >&2
  exit 1
fi

echo "📦 Estrazione pacchetti installati con: $PIP_CMD" >&2

# pip freeze: stderr separato per non inquinare l'output con warning di pip
# (es. pacchetti obsoleti, corrotti). Se il progetto ha warning, eseguire
# pip freeze manualmente per vederli.
FREEZE_OUT=$("$PIP_CMD" freeze 2>/dev/null) || {
  echo "❌ pip freeze ha fallito (exit code: $?)" >&2
  exit 1
}
{
  echo "# Requirements estratti dal virtual environment"
  echo "# Progetto: $PROJECT_DIR"
  echo "# Venv: $FOUND_VENV"
  echo "# Data: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  printf '%s\n' "$FREEZE_OUT"
} > "$OUTPUT_FILE"

# Se il venv è vuoto, requirements_python.txt conterrà solo l'intestazione: comportamento corretto.

# Conta righe non-commento e non-vuote ('^[^#[:space:]]' gestisce anche nomi da 1 carattere)
COUNT=$(grep -cE '^[^#[:space:]]' "$OUTPUT_FILE" 2>/dev/null || echo 0)

echo "✅ Requirements estratti: $COUNT pacchetti" >&2
echo "📄 File salvato in: $OUTPUT_FILE" >&2
echo "--- Contenuto (prime 20 righe) ---" >&2
head -20 "$OUTPUT_FILE" >&2
