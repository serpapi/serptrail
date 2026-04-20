# Kamal is not harder than your PaaS Demo

This is a demo for my talk _Kamal is not harder than your PaaS_ for Wroclowe.rb featuring a small SerpApi-powered application for tracking keywords and Kamal configuration for simple VPS deployment. Just plain Rails, SQLite, Litestream, and Kamal.

## Requirements

This demo requires a small VPS and a couple of ENV variables in `.env` populating `.kamal/secrets`. To get your SerpApi key, [sign up](https://serpapi.com/users/sign_up) for a free account. To set up backups, you'll need S3-compatible storage. You can copy the `.env.example` for a quickstart:

```bash
cp .env.example .env
```

## Kamal

### Initial setup

First, create a VPS server on Digital Ocean with the cloud-init configuration from `config/cloud-init.sh`. Then update `config/deploy.yml` and create `.env` with your environment.

To deploy the application with Kamal, run `kamal setup`:

```bash
kamal setup
```

Something wrong with the accessory? Reboot it:

```bash
kamal lock release
kamal accessory boot [ACCESSORY]
kamal deploy
```

### Flight check

Check snapshots are being written in logs and in S3 bucket:

```bash
kamal accessory logs litestream
kamal accessory exec litestream generations /rails/storage/production.sqlite3
```

### Restores

Here's how to restore the database. Start the maintainance mode and stop Litestream before continuing.

```bash
kamal accessory exec litestream snapshots /rails/storage/production.sqlite3
kamal app maintenance
kamal accessory stop litestream
```

Now let's delete the database so we can put the restore:

```bash
kamal shell
> rm storage/production.sqlite3*
```

(Or delete the files directly from `/var/lib/docker/volumes/serptrail_storage/_data` if the app container is not available.)

Restore the db files, restart litestream, and restart the application:

```bash
kamal app stop
kamal accessory exec litestream restore /rails/storage/production.sqlite3
kamal accessory start litestream
kamal app boot
kamal app live
```

To restore with point-in-time, add `-timestamp TIMESTAMP` to `restore` like this:

```bash
kamal accessory exec litestream "restore -timestamp 2026-04-13T14:50:24Z /rails/storage/production.sqlite3"
```

#### Restores to a new server

If you want to run a copy of the app on a new server with the latest backup, you might need to restore from Litestream before Rails creates an empty database.

```bash
kamal server bootstrap
kamal accessory boot litestream
# Update permissions for /rails/storage
kamal server exec "docker run --rm -v serptrail_storage:/rails/storage alpine chown -R 1000:1000 /rails/storage"
kamal accessory exec litestream restore /rails/storage/production.sqlite3
kamal setup
```

### Audits

See Kamal audit on each host:

```bash
kamal audit
```

See fail2ban audit:

```bash
kamal server exec sudo cat /var/log/fail2ban.log
kamal server exec sudo cat /var/log/auth.log
```

See system log for a service:

```bash
sudo journalctl _SYSTEMD_UNIT=docker.service -n 1000
```
