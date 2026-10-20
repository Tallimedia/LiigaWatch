"""Fetch liiga.fi and thin its responses to what the watch actually draws.

The whole reason this backend exists (RESEARCH.md §5): Connect IQ starts
failing around a 32 kB response, and a busy match day from liiga.fi is
43.7 kB raw, the full standings response 45 kB. Both blow the ceiling by a
wide margin. Thinning here mirrors the exact shape the sim beta's
``MockData.mc`` already established, so the watch app changes to almost
nothing when it switches from fixtures to this.

Also the reason this backend must never call the whole-season endpoint
(``games?tournament=...&season=...``, 3.0 MB) — RESEARCH.md §2 Layer 4: that
is "taking the catalogue" under Finnish *luettelosuoja*, not using individual
items. Only the day and standings endpoints are ever called here.
"""

from __future__ import annotations

from datetime import date, datetime
from typing import Any
from zoneinfo import ZoneInfo

import httpx

from . import config

_HELSINKI = ZoneInfo("Europe/Helsinki")

_client: httpx.AsyncClient | None = None


def _get_client() -> httpx.AsyncClient:
    global _client
    if _client is None:
        _client = httpx.AsyncClient(
            timeout=config.HTTP_TIMEOUT,
            headers={"User-Agent": config.USER_AGENT},
        )
    return _client


async def aclose() -> None:
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None


class LiigaError(Exception):
    """Wraps any upstream failure (network, non-200, bad JSON)."""


#: Three-letter club codes — same table as the watch app's Acronyms.mc, kept
#: here too so the backend can send both the full name and the code and let
#: the watch choose (RESEARCH.md §8a). No data source for these; liiga.fi's
#: API returns full team names only, never a short code.
ACRONYMS: dict[str, str] = {
    "HIFK": "HIF",
    "Tappara": "TAP",
    "Ilves": "ILV",
    "JYP": "JYP",
    "Lukko": "LUK",
    "Kärpät": "KÄR",
    "TPS": "TPS",
    "HPK": "HPK",
    "KalPa": "KAL",
    "Pelicans": "PEL",
    "SaiPa": "SAI",
    "Jukurit": "JUK",
    "Ässät": "ÄSS",
    "Sport": "SPO",
    "KooKoo": "KOO",
    "K-Espoo": "K-E",
    "Jokerit": "JOK",
}


def acronym(team_name: str) -> str:
    return ACRONYMS.get(team_name, team_name[:3])


def current_season(today: date | None = None) -> int:
    """Season number = the *ending* year (RESEARCH.md §1).

    The 2026-27 season is `season=2027`. July onward counts as the season
    that starts that autumn; January through June still belongs to the
    season that started the previous autumn.

    Defaults to Finnish local "today" — games and seasons are scheduled in
    Finnish time, and the server itself likely runs in UTC.
    """
    d = today or datetime.now(_HELSINKI).date()
    return d.year + 1 if d.month >= 7 else d.year


def _thin_team(team: dict[str, Any]) -> dict[str, Any]:
    return {
        "name": team["teamName"],
        "acronym": acronym(team["teamName"]),
        "goals": team["goals"],
    }


def _thin_game(game: dict[str, Any]) -> dict[str, Any]:
    # liiga.fi's `start` is UTC. The watch has no timezone database and
    # should not need one for something this small — the backend does the
    # reshaping (same principle as FIWeatherWatch's Api.mc), so
    # `startTime` arrives pre-formatted in Finnish local time.
    start_utc = datetime.fromisoformat(game["start"])
    start_local = start_utc.astimezone(_HELSINKI)
    return {
        "id": game["id"],
        "start": game["start"],
        "startTime": start_local.strftime("%H:%M"),
        "home": _thin_team(game["homeTeam"]),
        "away": _thin_team(game["awayTeam"]),
        "started": game["started"],
        "ended": game["ended"],
        "finishedType": game["finishedType"],
        # Period-boundary values as liiga.fi reports them, never
        # recalculated here — RESEARCH.md §1's live-verification note:
        # these tick at period boundaries, not continuously, and that is
        # fine for a watch showing score + status.
        "period": game.get("currentPeriod"),
        "gameTime": game.get("gameTime"),
    }


async def games(day: str) -> dict[str, Any]:
    """`day` is YYYY-MM-DD. Raises LiigaError on any upstream failure."""
    try:
        resp = await _get_client().get(
            f"{config.LIIGA_BASE}/games",
            params={"tournament": "runkosarja", "date": day},
        )
        resp.raise_for_status()
        data = resp.json()
    except (httpx.HTTPError, ValueError) as exc:
        raise LiigaError(f"games fetch failed: {exc}") from exc

    return {
        "date": day,
        "games": [_thin_game(g) for g in data.get("games", [])],
        "previousGameDate": data.get("previousGameDate"),
        "nextGameDate": data.get("nextGameDate"),
    }


def _thin_standing(row: dict[str, Any]) -> dict[str, Any]:
    # The settled fields (ranking/games/points/goals), not the live* ones -
    # live* includes provisional results from games still in progress, which
    # inflated the table mid-game (HIFK showed 17pts on the watch while the
    # real/settled standings said 14 - caught by Nico 2026-10-20, confirmed
    # directly against the live API: points=14, livePoints=17 for the same
    # row at the same moment). The Today screen is the right place for
    # live/in-progress state; the table should only ever show official,
    # settled standings.
    return {
        "rank": row["ranking"],
        "name": row["teamName"],
        "acronym": acronym(row["teamName"]),
        "games": row["games"],
        "points": row["points"],
        "goalDiff": row["goals"] - row["goalsAgainst"],
    }


async def standings(season: int | None = None) -> dict[str, Any]:
    """`season` defaults to the current one (RESEARCH.md §1's ending-year
    convention). Raises LiigaError on any upstream failure."""
    season = season or current_season()
    try:
        resp = await _get_client().get(
            f"{config.LIIGA_BASE}/standings/", params={"season": season}
        )
        resp.raise_for_status()
        data = resp.json()
    except (httpx.HTTPError, ValueError) as exc:
        raise LiigaError(f"standings fetch failed: {exc}") from exc

    rows = sorted(data.get("season", []), key=lambda r: r["ranking"])
    return {
        "season": season,
        "standings": [_thin_standing(r) for r in rows],
        # Served by the API, never hardcoded here (RESEARCH.md §1) — Liiga
        # has changed the playoff-cut format repeatedly.
        "playoffsLines": data.get("playoffsLines", []),
    }
