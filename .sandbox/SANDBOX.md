# Sandbox upload (Spliit) — not uploaded

Branch `sandbox-base` = upstream `spliit-app/spliit` at `73478ed` ("Support more currencies via the Frankfurter v2 API"), minus
what the code doesn't need:

- repo tooling and deploy: `.github/`, `.devcontainer/`, `Dockerfile`, `compose.yaml`, `compose.e2e.yaml`, `compose.perf.yaml`,
  `.dockerignore`, `container.env.example`, `vercel.json`, `scripts/` (Docker build / e2e / perf / local-db scripts), `perf/`
- `README.md` (replaced by a short `COMMANDS.md`: setup, run, checks, tests, e2e, database)

Small changes so it runs without Docker:

- `package.json`: the Docker-only scripts (`build-image`, `start-container`, `e2e:*`, `perf*`) removed; `e2e` is now
  `playwright test` (against `E2E_BASE_URL`, default http://localhost:3000); `check-formatting` / `prettier` no longer list `perf`
- `next.config.mjs`: `agentRules: false`, so `next dev` doesn't write `AGENTS.md` / `CLAUDE.md` into the project

## Make the zip
```
bash .sandbox/make-sandbox-zip.sh            # -> ../spliit-sandbox.zip (~1 MB), checks every rule
bash .sandbox/make-sandbox-zip.sh <branch>   # same, from another branch
```
Upload with "Mount files", extraction path `/workspace`.

Checked on 2026-10-23 (Node 24.15, Postgres 16): `npm ci` (27 migrations), lint, check-types, check-formatting, `npm test`
**498 passed**; e2e against `npm run dev`: 45 passed, the 3 PWA tests need `npm run build && npm start` (then 3 passed).

## In the sandbox (Node >= 24, npm >= 11, PostgreSQL) — also in COMMANDS.md
```
cd /workspace/spliit
cp .env.example .env            # set POSTGRES_PRISMA_URL / POSTGRES_URL_NON_POOLING to the local database
npm ci                          # also runs the database migrations
npm run dev                     # http://localhost:3000
npm run lint && npm run check-types && npm run check-formatting && npm test
npx playwright install chromium && npm run e2e   # with the app running
```
