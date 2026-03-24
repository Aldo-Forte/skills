# JavaScript / TypeScript Reference

## ES versions to recognize

- ES2023/TS 4.9+: `satisfies` operator (validates type without widening), `using` keyword (Explicit Resource Management)
- ES2024/TS 5.x: improved variadic tuple types, `Object.groupBy()`
- ES2022: `at()`, `Object.hasOwn()`, top-level `await`
- ES2021: `??=`, `||=`, `&&=`, `Promise.any()`
- ES2020: `??`, optional chaining `?.`, `BigInt`, `Promise.allSettled()`
- ES2019: `flat()`, `flatMap()`, `Object.fromEntries()`

## TypeScript — things to check

- `any` → prefer `unknown` with type narrowing
- `as` cast → prefer type predicates or `satisfies`
- `satisfies` preferred over `as` cast when you want to validate type without losing inference
- `!` non-null assertion → add null check
- `interface` vs `type`: `interface` for extensible objects, `type` for unions/intersections
- Prefix `I` or suffix `Type`/`Interface` for TypeScript types (project-dependent)

## Async patterns

- Always `.catch()` or `try/catch` for Promises
- `async/await` preferred over `.then()` chains
- `Promise.all()` for parallel independent operations
- Never `await` inside a `for` loop unless sequential order is needed

## npm / package.json

- `^x.y.z` = compatible with major version (allows minor/patch updates)
- `~x.y.z` = allows only patch updates
- `devDependencies` = build/test tools only
- `peerDependencies` = dependencies the consumer must install

## Common anti-patterns

- `var` → use `const`/`let`
- `==` → use `===`
- `console.log` left in production code
- Callbacks instead of Promises for new code
- Mutating function arguments directly
