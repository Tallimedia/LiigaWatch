"""Runtime configuration, all overridable by environment variable."""
import os


def _flag(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


# liiga.fi's own undocumented API. No key exists or is required
# (RESEARCH.md §1) — this is the wide-open `/api/v2` base, not `/api/v1`,
# which is dead and returns the SPA's HTML shell instead of JSON.
LIIGA_BASE = os.getenv("LIIGA_BASE", "https://liiga.fi/api/v2")

HTTP_TIMEOUT = float(os.getenv("HTTP_TIMEOUT", "20"))

# liiga.fi publishes no rate limits and asks for no key (RESEARCH.md §2
# Layer 1 — no terms of use exist at all), so identifying the client is the
# only courtesy available, same reasoning as FIWeatherWatch's User-Agent.
USER_AGENT = os.getenv(
    "USER_AGENT", "LiigaWatch/0.1 (+https://liigawatch.tallimedia.com)"
)

# Cache TTLs in seconds. RESEARCH.md §9: 5s matches liiga.fi's own CDN
# cache-control (`max-age=5, s-maxage=5`) exactly — going faster than the
# upstream's own freshness buys nothing and just re-fetches a cached value.
# 5 minutes otherwise, since a day with no live game does not need
# second-by-second polling — the schedule does not change mid-day.
TTL_LIVE = int(os.getenv("TTL_LIVE", "5"))
TTL_IDLE = int(os.getenv("TTL_IDLE", "300"))

# The public live-scores page: what the watch shows, live, for people
# arriving from the Connect IQ store listing. Default off so a bare deploy
# exposes nothing but the API — same convention as FIWeatherWatch's
# ENABLE_PUBLIC (RESEARCH.md §5, backend architecture).
ENABLE_PUBLIC = _flag("ENABLE_PUBLIC", False)

# Connect IQ store URL. Unset until the app is published — the public page
# then says "coming to the store" rather than a link that goes nowhere.
STORE_URL = os.getenv("STORE_URL", "")

# The app's own hostname, for the public page's self-links and og:url.
APP_URL = os.getenv("APP_URL", "https://liigawatch.tallimedia.com")
