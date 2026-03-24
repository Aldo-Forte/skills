# Riferimenti JavaScript / TypeScript

## Versioni ES da riconoscere
- ES2023/TS 4.9+: `satisfies` operator (valida tipo senza widening), `using` keyword (Explicit Resource Management)
- ES2024/TS 5.x: variadic tuple types migliorati, `Object.groupBy()`
- ES6/ES2015: arrow functions, let/const, classes, template literals, destructuring, modules
- ES2017: async/await
- ES2020: optional chaining `?.`, nullish coalescing `??`, BigInt
- ES2022: top-level await, class fields, `at()`
- TypeScript: verificare versione in `tsconfig.json` o `package.json`

## Naming convention
- `camelCase` per variabili e funzioni
- `PascalCase` per classi e componenti React
- `UPPER_SNAKE_CASE` per costanti
- `_privato` per convenzione (non enforcement reale in JS)
- Prefisso `I` o suffisso `Type`/`Interface` per tipi TypeScript (dipende dal progetto)
- `satisfies` preferito a cast `as` quando si vuole validare il tipo senza perdere inferenza

## Librerie/framework comuni — verificare sempre su npm
- `react`, `vue`, `angular`, `svelte` — UI framework
- `express`, `fastify`, `koa` — server HTTP
- `axios`, `node-fetch`, `ky` — HTTP client
- `lodash`, `ramda` — utility funzionali
- `date-fns`, `dayjs`, `luxon` — date (preferiti a `moment.js` che è deprecated)
- `zod`, `joi`, `yup` — validazione schema
- `prisma`, `typeorm`, `knex` — ORM/query builder
- `jest`, `vitest`, `mocha` — testing
- `eslint`, `prettier` — linting e formatting

## Anti-pattern JS/TS da segnalare
- `var` invece di `let`/`const` → scope problematico
- Callback hell invece di Promise/async-await
- `==` invece di `===` → coercizione di tipo
- `any` in TypeScript → annulla i benefici del type system
- `console.log` lasciato in produzione
- Promise non gestite (`.then()` senza `.catch()`)
- Mutazione diretta dello stato (in React/Redux)
- `moment.js` — deprecato, suggerisci alternativa

## Checklist async
- Ogni `await` dovrebbe essere in una funzione `async`
- Usare `try/catch` per gestire errori nelle funzioni async
- `Promise.all()` per operazioni parallele indipendenti
- Evitare `await` dentro `.forEach()` → usare `for...of` o `Promise.all()`
