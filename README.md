# SerpTrail

Monitor your SEO efforts. Built on top of Rails and SQLite for easy self-hosting.

## Features

- Monitor multiple sites
- Monitor multiple keywords per site
- Daily/Weekly/Monthly monitoring
- See history for keyword positions

## How scheduling works

Keyword checks are scheduled automatically using Solid Queue.

`KeywordCheckDispatchJob` runs every hour and picks up all keywords that are due — those whose `last_checked_at` is either unset or older than their check frequency (daily = 1 day, weekly = 1 week, etc.). For each due keyword it enqueues a `KeywordCheckJob` per location, which calls the SerpApi and records the result.

After a successful check, `last_checked_at` is updated on the keyword, which resets the clock for the next cycle.

## Contributing

Contributions are welcome! Open an issue or a Pull Request.

Built by [SerpApi](https://serpapi.com).
