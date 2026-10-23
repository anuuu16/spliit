# Sandbox upload (Spliit) — not uploaded

Branch `sandbox-base` = upstream `spliit-app/spliit` at `73478ed` ("Support more currencies via the Frankfurter v2 API"), minus
what the code doesn't need:

- repo tooling and deploy: `.github/`, `.devcontainer/`, `Dockerfile`, `compose.yaml`, `compose.e2e.yaml`, `compose.perf.yaml`,
  `.dockerignore`, `container.env.example`, `vercel.json`, `scripts/` (Docker build / e2e / perf / local-db scripts), `perf/`
- `README.md` (replaced by a short `COMMANDS.md`: setup, run, checks, tests, e2e, database)

Small changes so it runs without Docker:

- `package.json`: the Docker-only scripts (`build-image`, `start-container`, `e2e:*`, `perf*`) removed; `e2e` is now
  `playwright test` (against `E2E_BASE_URL`, default http://localhost:3000); `check-formatting` / `prettier` no longer list `perf`
- `package.json`: declares `deepmerge` and `decimal.js` (imported by the app but only present through other packages, so pnpm
  couldn't find them); `pnpm.onlyBuiltDependencies` approves the install scripts pnpm 10 blocks (`@parcel/watcher`,
  `@prisma/engines`, `@swc/core`, `esbuild`, `fsevents`, `prisma`, `unrs-resolver`); `package-lock.json` updated to match;
  `pnpm-lock.yaml` added (made with `pnpm import`, same versions); `.npmrc` pins the public npm registry
- `next.config.mjs`: `agentRules: false`, so `next dev` doesn't write `AGENTS.md` / `CLAUDE.md` into the project

## Make the zip

```
bash .sandbox/make-sandbox-zip.sh            # -> ../spliit-sandbox.zip (~1 MB), checks every rule
bash .sandbox/make-sandbox-zip.sh <branch>   # same, from another branch
```

Upload with "Mount files", extraction path `/workspace`.

Checked on 2026-10-23 (Node 24.15, Postgres 16): `npm ci` (27 migrations), lint, check-types, check-formatting, `npm test`
**498 passed**; e2e against `npm run dev`: 45 passed, the 3 PWA tests need `npm run build && npm start` (then 3 passed).

Also checked with pnpm 10.10: one `pnpm i --frozen-lockfile` from clean (no blocked builds, 27 migrations), lint, check-types,
check-formatting, `pnpm test` 498 passed, `pnpm build`, e2e 45 passed against `pnpm dev`.

## In the sandbox (Node >= 24, npm >= 11, PostgreSQL) — also in COMMANDS.md

```
cd /workspace/spliit
cp .env.example .env            # set POSTGRES_PRISMA_URL / POSTGRES_URL_NON_POOLING to the local database
pnpm i                          # or npm ci; also runs the database migrations
npm run dev                     # http://localhost:3000
npm run lint && npm run check-types && npm run check-formatting && npm test
npx playwright install chromium && npm run e2e   # with the app running
```
