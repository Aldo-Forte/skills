#!/usr/bin/env bash
# init_report_dir.sh
# Crea la sottodirectory timestampata per l'analisi corrente e stampa il path assoluto.
#
# Uso: bash init_report_dir.sh <project_dir>
#      Stampa su stdout il path assoluto della report dir creata.
#      Tutti i messaggi informativi vanno su stderr per non inquinare lo stdout.
#
# Formato directory: YYYY-MM-DDTHH:MM:SS-Report
# Collisione (stesso secondo): YYYY-MM-DDTHH:MM:SS-Report-N

set -euo pipefail

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Directory non trovata: $PROJECT_DIR" >&2
  exit 1
fi

# Risolvi il path assoluto per garantire output consistente
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
BASE_DIR="$PROJECT_DIR/code-analyzer"
mkdir -p "$BASE_DIR"

# Genera il timestamp completo con secondi: YYYY-MM-DDTHH:MM:SS
TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')
REPORT_DIR="$BASE_DIR/${TIMESTAMP}-Report"

# Collisione (avvio nello stesso secondo): aggiungi contatore
COUNTER=1
while [ -d "$REPORT_DIR" ]; do
  REPORT_DIR="$BASE_DIR/${TIMESTAMP}-Report-${COUNTER}"
  COUNTER=$((COUNTER + 1))
done

mkdir -p "$REPORT_DIR"

echo "📁 Report dir creata: $REPORT_DIR" >&2

# Stampa solo il path assoluto su stdout (usato da chi chiama lo script)
echo "$REPORT_DIR"
