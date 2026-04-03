# README

This is a demo for Wroclowe.rb featuring a small SerpApi-powered application for tracking keywords and Kamal configuration for simple VPS deployment.

## Kamal

### Initial setup

To deploy the applications with Kamal, run `kamal setup`:

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

Here's how to restore the database. Start the maintainance mode and stop the application before continuing.

```bash
kamal accessory exec litestream snapshots /rails/storage/production.sqlite3
kamal app maintenance
kamal app exec "rm /rails/storage/production.sqlite3"
kamal accessory exec litestream restore /rails/storage/production.sqlite3
kamal app live
```

To restore with point-in-time, add `-timestamp TIMESTAMP` to `restore`.

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
