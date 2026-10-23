# Commands

Spliit is a Next.js app (React UI and Node server in one) with a PostgreSQL database through Prisma.
Needs Node >= 24 and a running PostgreSQL. Install with **pnpm** (`pnpm i`) or **npm** (`npm ci`, npm >= 11): both lockfiles are
kept in sync.

## Setup

```
cp .env.example .env
# in .env, point both URLs at your database, e.g.
#   POSTGRES_PRISMA_URL=postgresql://postgres:1234@localhost:5432/spliit
#   POSTGRES_URL_NON_POOLING=postgresql://postgres:1234@localhost:5432/spliit
pnpm i                     # or: npm ci — installs, then applies the database migrations and generates the Prisma client
```

If PostgreSQL is installed but not running: `pg_ctl -D <data dir> start` (or `sudo service postgresql start`), then
`createdb spliit` (or `psql -c "create database spliit"`).

The packages that need install scripts (Prisma, esbuild, SWC…) are pre-approved for pnpm in `package.json` (`pnpm.onlyBuiltDependencies`).
With pnpm, run the scripts below as `pnpm <script>` (e.g. `pnpm dev`, `pnpm test`).

## Run the app

```
npm run dev                # http://localhost:3000 (another port: npm run dev -- -p 3100, and set BASE_URL in .env)
npm run build && npm start # production build
```

## Checks and tests

```
npm run lint               # oxlint
npm run check-types        # tsc --noEmit
npm run check-formatting   # prettier --check (npm run prettier to fix)
npm test                   # jest unit tests (src/**/*.test.ts)
npx jest src/lib/balances.test.ts   # one test file
```

## End-to-end tests (Playwright, against a running app)

```
npx playwright install chromium     # once
npm run e2e                         # tests http://localhost:3000; another URL: E2E_BASE_URL=http://localhost:3100 npm run e2e
npx playwright test e2e/core.spec.ts
npm run e2e:report                  # open the HTML report
```

The PWA tests (`e2e/pwa.spec.ts`) need the production build (`npm run build && npm start`): the service worker is not
served by `npm run dev`.

## Database

```
npx prisma migrate deploy  # apply migrations
npx prisma migrate dev --name <change>   # after editing prisma/schema.prisma
npx prisma studio          # browse the data
```
