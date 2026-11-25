# syntax=docker/dockerfile:1

# ---------- base: shared by every stage ----------
FROM node:22-alpine AS base
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# ---------- deps: install all packages from the lockfile ----------
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund && npm cache clean --force

# ---------- build: compile the Next.js app ----------
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Placeholder only: src/db/index.ts needs DATABASE_URL to exist at build time.
RUN DATABASE_URL=postgresql://build:build@127.0.0.1:5432/build npm run build

# ---------- migrator-deps: keep only what drizzle-kit migrate needs ----------
FROM base AS migrator-deps
COPY package.json package-lock.json ./
RUN npm uninstall --no-audit --no-fund \
      next react react-dom jsonwebtoken @types/jsonwebtoken \
      @tailwindcss/postcss tailwindcss postcss \
      @types/node @types/pg @types/react @types/react-dom \
      eslint eslint-config-next typescript \
    && npm cache clean --force

# ---------- migrator: one-off container that applies migrations ----------
FROM base AS migrator
COPY --from=migrator-deps /app/node_modules ./node_modules
COPY package.json drizzle.config.ts ./
COPY drizzle ./drizzle
USER node
CMD ["node_modules/.bin/drizzle-kit", "migrate"]

# ---------- seed: one-off container that loads demo data (local testing only) ----------
FROM migrator AS seed
COPY tsconfig.json ./
COPY src/db ./src/db
COPY src/lib ./src/lib
COPY src/scripts ./src/scripts
CMD ["node_modules/.bin/tsx", "src/scripts/seed.ts"]

# ---------- runner: final app image (default target) ----------
FROM base AS runner
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
COPY --from=build --chown=node:node /app/.next/standalone ./
COPY --from=build --chown=node:node /app/.next/static ./.next/static
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO /dev/null http://127.0.0.1:3000/api/health || exit 1
CMD ["node", "server.js"]
