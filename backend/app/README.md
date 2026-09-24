# FILiigaWatch — backend

Serves liiga.fi's public API, reshaped for the FILiigaWatch Garmin watch app.
Unofficial — not affiliated with Jääkiekon SM-liiga Oy.

Planning and research live in `RESEARCH.md`, which is owned by the
`claude-docs` repo rather than this one (see that repo's `CLAUDE.md`).
Section references below (§1, §5, …) point there.

## Why a backend at all

Connect IQ starts failing around a 32 kB response. A busy match day from
liiga.fi is 43.7 kB raw; the full standings response is 45 kB. Both blow the
ceiling by a wide margin. This service thins both down to about 1 kB.

It also never calls the whole-season endpoint (`games?season=...`, 3.0 MB)
— under Finnish *luettelosuoja*, that is taking the catalogue, not using
individual items (§2 Layer 4). Only the day and standings endpoints are ever
called here, one caller regardless of how many watches are connected.

## Endpoints

| Endpoint | Returns | Size |
|---|---|---|
| `GET /healthz` | liveness | — |
| `GET /v1/games?date=` | one day's games + `previousGameDate`/`nextGameDate` | ~1 kB |
| `GET /v1/standings?season=` | league table + `playoffsLines` | ~1.4 kB |

`date` defaults to today (Finnish local time — see `_today_helsinki()` in
`main.py`); `season` defaults to the current one (§1: the *ending* year,
e.g. `2027` for the 2026-27 season).

## Running it

```bash
python3.12 -m venv .venv && .venv/bin/pip install -e ".[dev]"
.venv/bin/uvicorn app.main:app --reload --port 8792
.venv/bin/pytest -q
```

With Docker: `cp .env.example .env && docker compose up -d --build`

## Deployment

Production is `liigawatch.tallimedia.com`, on **public-vm** under
`~/public-services/liigawatch/`, behind the shared Traefik and Cloudflare
tunnel — same pattern as `weatherapp` and `volvowatch`. Not a git checkout —
copy the tree up and rebuild:

```bash
tar --exclude='__pycache__' --exclude='.DS_Store' -czf - app Dockerfile pyproject.toml \
  | ssh public-vm-auto 'cd ~/public-services/liigawatch && tar -xzf -'
ssh public-vm-auto 'cd ~/public-services/liigawatch && docker compose build && docker compose up -d'
```

There is no `rsync` on that host. Tag `liigawatch-backend:rollback` before
building so a revert is one command. `.env` there sets `ENABLE_PUBLIC=true`.

## Cache behaviour

5 s while any game today is live — matches liiga.fi's own CDN
`cache-control` exactly, so going faster buys nothing. 5 minutes otherwise,
since a quiet day's schedule does not change hour to hour (§9).

## Gotchas this code exists to handle

- **`season` is the *ending* year, not the year it starts.** Getting this
  wrong returns last season silently, with no error.
- **`/api/v1/` is dead** — it returns the SPA's HTML shell, not JSON. Only
  `/api/v2/games` and `/api/v2/standings/` are open; `teams`, `players`,
  `livescore`, `tournaments` all 403.
- **`gameTime`/`currentPeriod` update at period boundaries, not
  continuously** — verified live 2026-09-23. Never recalculate them
  client-side; pass them through exactly as received.
- **Games are scheduled in Finnish local time**, and the server likely runs
  in UTC — a naive `date.today()` is wrong for part of every evening.
- **No published terms of use exist at all** (§2 Layer 1) — verified by
  slug-echo testing every plausible route. Never assume permission beyond
  what §2's five-layer analysis actually supports: today's games and the
  current table, never the season archive.

## Licence and attribution

No open-data licence exists for liiga.fi's data (§2). Every response
carries `"attribution": "Liiga.fi"`, and the app and its store listing must
show it too, alongside "Unofficial app — not affiliated with Liiga."
