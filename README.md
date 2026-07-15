# SerpTrail

SerpTrail is a self-hosted SEO and GEO rank tracker built with Ruby on Rails and SQLite. It tracks Google organic positions and AI Overview citations while preserving historical search results for later analysis.

## Features

- Track multiple websites, keywords, and locations
- Check rankings daily, weekly, biweekly, or monthly
- Search up to five pages of Google results
- Preserve historical Google results and ranking positions
- Track whether a website is cited in Google AI Overviews
- Attach multiple websites to the same keyword without repeating the search
- Compare historical performance using saved views
- Ask questions about rankings through the OpenAI-powered chat assistant
- Estimate monthly SerpApi credit usage from your current configuration
- Configure SerpApi and OpenAI keys through Settings

## How SerpTrail works

### Keywords and websites

Keywords and websites are tracked independently.

A keyword defines:

- Search query
- Locations
- Check frequency
- Search depth

One Google search is performed for each keyword, location, and requested results page. The returned results are then checked against every website attached to that keyword.

Attaching another website therefore does not increase SerpApi usage. Increasing the number of keywords, locations, pages, or checks does.

### Multi-page Google results

By default, SerpTrail checks the first page of Google results. Search depth can be configured from one to five pages for each keyword.

Each page contains up to 10 organic results:

| Search depth | Positions checked | SerpApi credits per location |
| --- | --- | --- |
| 1 page | 1–10 | 1 |
| 2 pages | 1–20 | 2 |
| 3 pages | 1–30 | 3 |
| 4 pages | 1–40 | 4 |
| 5 pages | 1–50 | 5 |

Positions from later pages are normalized into one continuous ranking. For example, the first organic result on page two is saved as position 11.

Internally, one `SearchRun` represents a keyword and location check. Each requested Google page is stored separately as a `SearchRunPage`, including its SerpApi search ID, response, offset, and status.

This preserves the original page boundaries in historical results while presenting rankings as positions 1–50.

### SerpApi credit usage

Each requested page consumes one SerpApi credit per keyword and location.

For example, a keyword configured with two locations, three result pages, and daily checking uses approximately:

```text
2 locations × 3 pages × 30 checks = 180 credits per month
```

The Settings page estimates monthly usage across all enabled keywords. The estimate uses a 30-day month and does not include additional manual checks.

Adding more websites to an existing keyword does not increase usage because the search results are shared.

### Historical performance

Every search is stored independently from the websites being tracked. This allows SerpTrail to:

- Display historical organic results
- Track ranking changes for multiple websites
- Attach multiple websites without duplicating searches
- Compare keywords and websites through saved views
- Analyze collected search data through the chat assistant

### GEO and AI Overviews

In addition to traditional organic rankings, SerpTrail records Google AI Overview data and checks whether tracked websites appear among its cited sources.

This helps monitor both conventional SEO visibility and visibility within AI-generated search answers.

### Chat assistant

When an OpenAI API key is configured, the built-in assistant can answer questions using SerpTrail's ranking history and live search tools.

Chat responses support Markdown formatting, and token and cost information is tracked through RubyLLM's native chat interface.

### Scheduling

Keyword checks are scheduled automatically using Solid Queue.

`KeywordCheckDispatchJob` runs every hour and selects keywords whose last check is older than their configured frequency. It then enqueues one `KeywordCheckJob` for every configured location.

Each job requests the configured number of Google result pages and stores them under a single search run. After the check completes, `last_checked_at` is updated and the next check is scheduled according to the keyword's frequency.

## Contributing

Contributions are welcome! Open an issue or a pull request.

Built by [SerpApi](https://serpapi.com).
