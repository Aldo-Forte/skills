# Riferimenti Python

## PEP da conoscere
- PEP 8: stile del codice (indentazione, naming, lunghezza righe)
- PEP 20: The Zen of Python
- PEP 484 / 526: type hints
- PEP 572: walrus operator `:=`
- PEP 634: structural pattern matching (match/case, Python 3.10+)

## Naming convention
- `snake_case` per funzioni e variabili
- `PascalCase` per classi
- `UPPER_CASE` per costanti
- `_privato` per attributi/metodi privati per convenzione
- `__dunder__` per metodi speciali

## Librerie standard comuni — verificare sempre versione su PyPI
- `os`, `pathlib` — filesystem
- `sys` — interprete e argomenti
- `re` — regex
- `json`, `csv` — serializzazione
- `datetime` — date e ore
- `collections` — Counter, defaultdict, deque
- `itertools`, `functools` — programmazione funzionale
- `typing` — annotazioni di tipo
- `logging` — log strutturato (preferibile a `print`)
- `argparse` — CLI arguments
- `dataclasses` — classi dati (Python 3.7+)
- `asyncio` — programmazione asincrona

## Anti-pattern Python da segnalare
- `except:` nudo senza tipo → cattura tutto incluso KeyboardInterrupt
- Mutabile come default argument: `def f(x=[])` → bug classico
- `import *` → inquina il namespace
- Confronto con `==` invece di `is` per None/True/False
- Concatenazione di stringhe in loop → usare `join()`
- Aprire file senza context manager (`with`)

## Checklist type hints
- Funzioni pubbliche dovrebbero avere annotazioni di tipo
- Usare `Optional[X]` o `X | None` (Python 3.10+) per valori nullable
- Preferire `list[str]` a `List[str]` da Python 3.9+
