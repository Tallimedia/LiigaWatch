"""FILiigaWatch backend.

Serves reshaped liiga.fi data to the Garmin watch app. Every response is kept
small deliberately: Connect IQ starts failing somewhere around 32 kB
(RESEARCH.md §5) — a busy match day is 43.7 kB raw, thinned here to ~1 kB.
"""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles

from . import config, legal, liiga
from .cache import cache

_HERE = Path(__file__).resolve().parent

# No per-request query params worth redacting here — unlike FIWeatherWatch's
# coordinate-scrubbing filter (that backend's real lesson, carried forward
# as a habit rather than copied verbatim: check what a new backend actually
# logs before assuming it needs the same filter). `date=` and `season=` are
# not personal data, so Uvicorn's default access log is left alone.


@asynccontextmanager
async def _lifespan(_: FastAPI) -> AsyncIterator[None]:
    yield
    await liiga.aclose()


app = FastAPI(
    lifespan=_lifespan,
    title="FILiigaWatch backend",
    version="0.1.0",
    description="liiga.fi data, reshaped for a Garmin watch. Unofficial — "
    "not affiliated with Jääkiekon SM-liiga Oy. Data: Liiga.fi.",
)

ATTRIBUTION = "Liiga.fi"

_HELSINKI = ZoneInfo("Europe/Helsinki")


def _today_helsinki() -> str:
    """Games are scheduled in Finnish local time. The server itself likely
    runs in UTC, and naive UTC "today" is wrong for part of every evening
    (Helsinki is UTC+2/+3) — near midnight Helsinki time it would ask
    liiga.fi for tomorrow's empty schedule instead of tonight's live games."""
    return datetime.now(_HELSINKI).date().isoformat()


def _ttl() -> int:
    """5s during a live game, matching liiga.fi's own CDN cache-control —
    going faster buys nothing (RESEARCH.md §9). 5 minutes otherwise, since
    a quiet day's schedule does not change hour to hour."""
    hit = cache.get("games:today")
    if hit and any(g["started"] and not g["ended"] for g in hit.get("games", [])):
        return config.TTL_LIVE
    return config.TTL_IDLE


@app.get("/healthz")
async def healthz() -> dict:
    return {"ok": True, "version": app.version}


@app.get("/v1/games")
async def v1_games(
    date: str | None = Query(None, description="YYYY-MM-DD, defaults to today")
) -> dict:
    today = _today_helsinki()
    day = date or today
    try:
        data = await cache.aget_or_set(
            f"games:{day}", _ttl(), lambda: liiga.games(day)
        )
    except liiga.LiigaError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    if day == today:
        cache.set("games:today", data, _ttl())
    return {**data, "attribution": ATTRIBUTION}


@app.get("/v1/standings")
async def v1_standings(
    season: int | None = Query(None, description="Ending year, e.g. 2027 for 2026-27")
) -> dict:
    try:
        data = await cache.aget_or_set(
            f"standings:{season or liiga.current_season()}",
            _ttl(),
            lambda: liiga.standings(season),
        )
    except liiga.LiigaError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    return {**data, "attribution": ATTRIBUTION}


# --- Legal pages — same pattern as FIWeatherWatch's main.py: rendered from
# the repo's own PRIVACY.md/TERMS.md, so the published page and the
# committed document can never drift apart. ---

_LEGAL_CSS = (
    "max-width:44rem;margin:0 auto;padding:56px 24px 96px;"
    "font:16px/1.65 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;"
    "color:#1d1f20;background:#f2f2f3"
)


def _legal_page(name: str) -> HTMLResponse:
    try:
        title, body = legal.document(name)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="not found")
    return HTMLResponse(
        f"<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
        f"<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
        f"<title>{title}</title>"
        f"<style>body{{{_LEGAL_CSS}}}h1{{font-size:28px;margin:0 0 4px}}"
        f"h2{{font-size:18px;margin:32px 0 8px}}a{{color:#416180}}"
        f"em{{color:#6b6e70}}li{{margin:4px 0}}"
        f".back{{display:inline-block;margin-bottom:28px;color:#416180;"
        f"text-decoration:none;font-size:14px}}</style></head><body>"
        f"<a class=\"back\" href=\"/\">&larr; FILiigaWatch</a>{body}</body></html>",
        headers={"Cache-Control": "no-cache, must-revalidate"},
    )


@app.get("/privacy", response_class=HTMLResponse)
async def privacy() -> HTMLResponse:
    return _legal_page("PRIVACY")


@app.get("/terms", response_class=HTMLResponse)
async def terms() -> HTMLResponse:
    return _legal_page("TERMS")


# --- Public live-scores page — what the watch shows, live, for people
# arriving from the Connect IQ store listing. Off by default so a bare
# deploy exposes nothing but the API (RESEARCH.md §5, same ENABLE_PUBLIC
# convention as FIWeatherWatch). ---

if config.ENABLE_PUBLIC:

    @app.get("/")
    async def public_index() -> HTMLResponse:
        html = (_HERE / "public" / "index.html").read_text(encoding="utf-8")
        return HTMLResponse(html, headers={"Cache-Control": "no-cache, must-revalidate"})

    app.mount("/public", StaticFiles(directory=_HERE / "public"), name="public")
