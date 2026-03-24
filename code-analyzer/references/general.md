# General Reference — Common Patterns and Anti-Patterns

## Performance anti-patterns

- Unnecessary nested loops → suggest algorithmic optimization
- DB queries inside a loop → N+1 problem (solution: eager loading, batch query, or explicit join)
- Synchronous loading of resources that could be lazy (pattern: lazy loading, dynamic `import()` in JS/TS, `importlib.import_module()` in Python, code splitting in bundlers)
- Large objects copied instead of passed by reference

## Maintainability anti-patterns

- Magic numbers or hardcoded strings → suggest constants
- Functions > 50 lines → suggest extraction
- Nesting > 3 levels → suggest early return or extraction
- Duplicate code blocks → suggest DRY refactoring

## Reliability patterns

- Input validation at function boundaries
- Explicit error handling (no silent catch)
- Immutability where possible
- Stateless functions

## Security checklist

- User input never directly in SQL/shell commands
- No secrets hardcoded in source code
- Validation of file paths (no path traversal)
- HTTP responses without sensitive data in headers
