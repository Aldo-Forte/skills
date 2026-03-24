# Python Reference

## PEP conventions

- PEP 8: 4-space indentation, max 79 chars per line, snake_case
- PEP 257: docstring with triple quotes, first line as summary
- PEP 484: type hints — `def f(x: int) -> str:`
- PEP 526: variable annotations — `x: int = 5`
- PEP 572: walrus operator `:=` (Python 3.8+)
- PEP 634: structural pattern matching `match/case` (Python 3.10+)
- PEP 695: type alias syntax `type Vector = list[float]` (Python 3.12+)

## Common anti-patterns

- Mutable default args: `def f(x=[])` → use `def f(x=None)` with `if x is None: x = []`
- Bare `except:` → always specify the exception type
- `== None` → use `is None`
- String concatenation in loops → use `''.join(list)`
- `type(x) == int` → use `isinstance(x, int)`

## Typing

- `Optional[X]` = `X | None` (Python 3.10+, prefer `X | None`)
- `Union[X, Y]` = `X | Y` (Python 3.10+)
- `Any` from `typing` for unannotated types
- `TypeVar` for generic functions
- `Protocol` for structural subtyping (alternative to ABC)
- `dataclass` for data classes (Python 3.7+)

## Testing

- `pytest` as standard, not `unittest`
- `assert x == y` in tests (pytest rewrites)
- Fixtures with `@pytest.fixture`
- Parametrized tests with `@pytest.mark.parametrize`

## Common libraries to verify

- `requests` → verify vs `httpx` for async
- `datetime.utcnow()` deprecated in Python 3.12 → use `datetime.now(timezone.utc)`
- `os.path` → often replaceable with `pathlib.Path`
