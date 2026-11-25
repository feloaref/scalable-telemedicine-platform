# Docker and Ansible

How to run the platform in containers, how to deploy it with Ansible, and what the other parts of the project (Jenkins, Kubernetes, Nginx) need to know.

## What is in this part

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build on `node:22-alpine` |
| `.dockerignore` | Keeps secrets, docs and build output out of the image |
| `docker-compose.yml` | `db`, `migrate`, `app`, and an optional `seed` service |
| `.env.example` | Template for the local `.env` |
| `ansible/` | Playbook, inventory, variables and a fake vault example |

Dockerfile targets:

| Target | What it does | Local image |
|---|---|---|
| `runner` (default) | Runs the app as a non-root user on port 3000 | `telemedicine-app` (about 80 MB compressed) |
| `migrator` | Runs `drizzle-kit migrate` once, then exits | `telemedicine-migrator` (about 79 MB compressed) |
| `seed` | Loads demo data once, then exits. Local testing only | `telemedicine-seed` |

## Run with Docker Compose

You need Docker with the compose plugin. Node.js and PostgreSQL are not required.

```bash
cp .env.example .env            # then replace every "change-this" value
docker compose up --build -d
curl http://localhost:3000/api/health    # {"ok":true}
```

The start order is automatic: `db` becomes healthy, `migrate` finishes successfully, then `app` starts. If a migration fails, the app does not start.

### Demo data

```bash
docker compose run --rm --build seed
```

Creates `patient@example.com`, `cardio@example.com`, `derma@example.com` and `neuro@example.com`, all with the password `password123`.

- Run it once on an empty database. A second run stops with a duplicate key error.
- Never run it in production: the passwords are public.
- Do not mix it with `POST /api/seed`. That route works only in development mode, creates `@test.com` accounts, and renames existing `@example.com` ones. It returns 404 in the containers.

### Useful commands

```bash
docker compose ps -a             # status
docker compose logs -f app       # logs
docker compose down              # stop, keep the database
docker compose down -v           # stop and DELETE the database
docker builder prune -af         # free disk space used by the build cache
```

## Environment variables

| Variable | Used by | Notes |
|---|---|---|
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | Compose | Required. Letters and digits only in the password, because it becomes part of a URL |
| `DATABASE_URL` | app, migrations, seed | Compose builds it from `POSTGRES_*` with the host `db`. The value in `.env` is used only outside Docker |
| `JWT_SECRET` | app | Required. Use a long random value, for example `openssl rand -hex 32` |
| `NODE_ENV` | app | Compose always sets `production` |
| `SEED_SECRET` | `POST /api/seed` | Development mode only |
| `IMAGE_TAG` | Compose | Optional image tag, default `latest` |
| `COMPOSE_PROJECT_NAME` | Compose | Optional, default `telemedicine` |

PostgreSQL reads `POSTGRES_PASSWORD` only when its volume is first created. Changing it later in `.env` does not change the password inside an existing database.

`.env`, `ansible/.vault_pass` and `ansible/group_vars/all/vault.yml` are ignored by Git. Never commit them.

## Deploy with Ansible

The playbook targets Ubuntu. It installs Docker and the compose plugin if they are missing, copies the **committed** files of the project to `/opt/telemedicine`, writes `.env`, starts the stack, and waits until `/api/health` returns ok.

### 1. Prepare the control machine

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### 2. Create the secrets

```bash
cp vault.example.yml group_vars/all/vault.yml     # then put real values in it
(umask 077; openssl rand -hex 24 > .vault_pass)
ansible-vault encrypt --vault-password-file .vault_pass group_vars/all/vault.yml
```

The playbook rejects the fake values, database passwords shorter than 16 characters, and JWT secrets shorter than 32. Keep a safe copy of `.vault_pass`: the vault cannot be opened without it.

### 3. Choose the server

Edit `inventory.ini`. It contains localhost for testing and a commented EC2 example. The localhost line sets `ansible_become_exe=/usr/bin/sudo.ws` because Ubuntu 26.04 uses sudo-rs, whose prompt Ansible does not recognise. Remove that setting on machines without `sudo.ws`.

### 4. Run

```bash
# localhost (asks for your sudo password)
ansible-playbook playbook.yml --ask-become-pass --vault-password-file .vault_pass

# EC2 Ubuntu images use passwordless sudo
ansible-playbook playbook.yml --vault-password-file .vault_pass
```

Port 3000 must be free on the server. To deploy something other than the current commit, add `-e telemedicine_git_ref=<branch, tag or commit>`. Running the playbook again is safe: it rebuilds only when the commit changes.

The deployment uses the project name `telemedicine-deploy` and the image tag `deploy`, so it never shares a database volume or images with a local stack.

### Remove a deployment

```bash
sudo docker compose --project-directory /opt/telemedicine down -v   # DELETES its database
docker rmi telemedicine-app:deploy telemedicine-migrator:deploy
sudo rm -rf /opt/telemedicine
```

Tested on localhost (Ubuntu 26.04). Installing the Docker packages was also tested on a clean Ubuntu 24.04 container. It has not been run on a real EC2 server yet.

## What teammates need

### Jenkins (Hisham)

Build the images from the repository root. No database and no secrets are needed at build time.

```bash
docker build --target runner   -t <registry>/telemedicine-app:<commit> .
docker build --target migrator -t <registry>/telemedicine-migrator:<commit> .
```

- Push both images with the same tag. Do not push `seed`.
- The agent needs Docker with BuildKit (buildx).
- `npm run lint` currently fails with 7 errors in `src/app`, so a strict lint stage will stop the pipeline until they are fixed. `npm audit` also reports vulnerabilities, so expect findings from image scans.

### Kubernetes (Felopateer)

- Use the `telemedicine-app` and `telemedicine-migrator` images from the registry.
- Run the migrator as a Job that finishes before the new app version starts. Run one at a time, not once per replica.
- The app needs `DATABASE_URL` and `JWT_SECRET` from a Secret. All replicas must share the same `JWT_SECRET`.
- The container listens on port 3000 as uid 1000. With `runAsNonRoot: true`, also set `runAsUser: 1000`, because the image uses a user name instead of a number.
- Kubernetes ignores the Docker `HEALTHCHECK`. Use `/api/health` for the readiness probe. It also checks the database, so use a TCP probe on port 3000 for liveness; otherwise a database outage restarts every pod.

### Nginx (Felopateer)

HTTPS is required. In production the login cookie is `Secure`, so browsers drop it over plain HTTP on a server IP or domain. Login then returns 200, but the next API calls return 401. It works on `http://localhost` because browsers such as Chrome and Firefox treat localhost as secure.

Terminate TLS in Nginx and proxy to the app. No app change is needed. Example (not tested here):

```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

- When Nginx runs on the same host, change the Compose port to `"127.0.0.1:3000:3000"` so nobody can bypass HTTPS. Ports published by Docker can also bypass `ufw` rules.
- Do not "fix" login by setting `NODE_ENV=development`.
- To test a remote server before HTTPS exists: `ssh -L 3000:localhost:3000 user@server`, then open `http://localhost:3000`.

### Everyone: containers use UTC

The containers run in UTC and the database stores timestamps without a time zone. The seeded 09:00–17:00 slots are therefore UTC, and appear as 11:00–19:00 in Egypt in winter or 12:00–20:00 in summer. Keep every environment on UTC; mixing time zones shifts existing appointments.
