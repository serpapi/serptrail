# Production

## Environment variables

All secrets are managed via environment variables. In development these live in `.env` (loaded by `dotenv-rails`). In production they must be set in your deployment environment (e.g. Kamal secrets / Docker env).

Here is the list of required environment variables:

| Variable | Description |
|----------|-------------|
| `RAILS_MASTER_KEY` | Contents of `config/master.key` |
| `HTTP_AUTH_USERNAME` | HTTP Basic Auth username |
| `HTTP_AUTH_PASSWORD` | HTTP Basic Auth password |
| `AR_ENCRYPTION_PRIMARY_KEY` | Active Record Encryption — primary key |
| `AR_ENCRYPTION_DETERMINISTIC_KEY` | Active Record Encryption — deterministic key |
| `AR_ENCRYPTION_KEY_DERIVATION_SALT` | Active Record Encryption — key derivation salt |

Note that SerpApi key is added directly in the web interface.

Here is the list of optional environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SOLID_QUEUE_IN_PUMA` | — | Set to `true` to run background jobs inside the Puma process instead of a separate `bin/jobs` worker. |
| `RAILS_MAX_THREADS` | `3` | Puma thread count and database connection pool size. |
| `WEB_CONCURRENCY` | `1` | Number of Puma worker processes. |
| `JOB_CONCURRENCY` | `1` | Number of Solid Queue processes. |
| `RAILS_LOG_LEVEL` | `info` | Log verbosity (`debug`, `info`, `warn`, `error`). |

### Generating Active Record Encryption keys

Run this once to generate a fresh set of encryption keys:

```
bin/rails db:encryption:init
```

The output looks like:

```
active_record_encryption:
  primary_key: <generated>
  deterministic_key: <generated>
  key_derivation_salt: <generated>
```

Copy the three values into your environment:

```
AR_ENCRYPTION_PRIMARY_KEY=<primary_key value>
AR_ENCRYPTION_DETERMINISTIC_KEY=<deterministic_key value>
AR_ENCRYPTION_KEY_DERIVATION_SALT=<key_derivation_salt value>
```

**Important:** generate these keys once and keep them stable. Rotating them means all existing encrypted values in the database (e.g. the SerpApi key stored in the `tenants` table) can no longer be decrypted.

## First-time database setup

After setting all environment variables, run:

```
bin/rails db:prepare
bin/rails db:seed
```

`db:seed` creates the initial Tenant record with a blank SerpApi key. Set the key afterwards in the web interface under Settings.

---

## Running as a Docker image

**Build:**

```bash
docker build -t serptrail .
```

**Run:**

```bash
docker run -d \
  --name serptrail \
  -p 80:80 \
  --env-file .env \
  -v serptrail_storage:/rails/storage \
  serptrail
```

The entrypoint runs `db:prepare` automatically before the server starts, so the database is created and migrated on first boot. 

All SQLite databases are written to `/rails/storage` inside the container. The volume mount at that path persists data across restarts and image updates.

To run background jobs in a separate container, set `SOLID_QUEUE_IN_PUMA=false` in your `.env` and start a jobs container:

## Running with Docker Compose

Create a `docker-compose.yml` in the project root:

```yaml
services:
  web:
    image: serptrail
    build: .
    ports:
      - "80:80"
    env_file: .env
    environment:
      SOLID_QUEUE_IN_PUMA: "false"
    volumes:
      - storage:/rails/storage
    restart: unless-stopped

  jobs:
    image: serptrail
    build: .
    command: ./bin/jobs
    env_file: .env
    volumes:
      - storage:/rails/storage
    depends_on:
      - web
    restart: unless-stopped

volumes:
  storage:
```

Docker Compose automatically reads a `.env` file in the same directory as `docker-compose.yml`. Reference variables in the compose file with `env_file: .env` to pass the whole file to a service, or use `environment:` for values that are not secret and can live in the compose file directly.

**Start:**

```bash
docker compose up -d
```

**Tail logs:**

```bash
docker compose logs -f
```

**Run a Rails console:**

```bash
docker compose exec web bin/rails console
```

**Stop:**

```bash
docker compose down
```

Data in the `storage` volume survives `down`. To remove the volume as well (destroys the database), add `-v`.
