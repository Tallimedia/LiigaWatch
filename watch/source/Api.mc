import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

//! Backend client — replaces MockData.mc as the live data source
//! (2026-09-24, once the backend at liigawatch.tallimedia.com existed and
//! was tested). MockData.mc stays in the tree only as the dev-only
//! "Mock scenario" fallback (MenuDelegate.mc), not as production's source.
//!
//! No Application.Storage persistence here, unlike FIWeatherWatch's Api.mc —
//! deliberate scope cut, not an oversight. That backend persists readings
//! because a marine app's phone is routinely out of BLE range for hours;
//! FILiigaWatch has no equivalent case where stale scores from a previous
//! session are worth showing over a clean "loading"/"unavailable" state on
//! a fresh launch. Revisit if that assumption turns out wrong in practice.
//!
//! (:glance) so GlanceView.mc can read the cached games/standings state —
//! Garmin's docs say Glance is allowed to make web requests, but the glance
//! here deliberately never calls fetchGames() etc. itself (see GlanceView.mc).
(:glance)
module Api {

    enum { STATE_IDLE, STATE_LOADING, STATE_OK, STATE_ERROR }

    const BASE_URL = "https://liigawatch.tallimedia.com";

    //! Genuinely today's games — may be empty. Today screen renders
    //! `displayGames`, not this, so it can fall through to the next game
    //! day's fixtures without the caller needing to know that happened.
    var games as Array<Dictionary> = [];
    var displayGames as Array<Dictionary> = [];
    var isShowingToday as Boolean = true;

    var nextGameDateRaw as String? = null;
    //! "dd.mm.", matching MockData.NEXT_GAME_DATE's format.
    var nextGameDateLabel as String = "";

    var standings as Array<Dictionary> = [];
    var playoffsLines as Array<Number> = [];

    var gamesState = STATE_IDLE;
    var standingsState = STATE_IDLE;

    //! liiga.fi's own CDN caches 5s (RESEARCH.md §1) and the backend floors
    //! its own cache the same way — polling the backend faster than this
    //! just re-fetches a value that hasn't changed. Independent of whatever
    //! cadence the user picked in AppMenu; this is the hard floor beneath it.
    var lastRefresh = 0;
    const MIN_REFRESH_SECS = 5;

    function hasLiveGame() as Boolean {
        for (var i = 0; i < games.size(); i++) {
            if (games[i][:started] && !games[i][:ended]) { return true; }
        }
        return false;
    }

    //! True on a real game day — matches the check AppMenu.buildMenu() uses
    //! to gate the cadence picker (§9). Distinct from hasLiveGame(): a day
    //! can have games scheduled later without one live *right now*.
    function isGameDay() as Boolean {
        return games.size() > 0;
    }

    function options() as Dictionary {
        return {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
    }

    function pick(d, key as String) {
        if (d instanceof Dictionary && d.hasKey(key)) { return d[key]; }
        return null;
    }

    //! "YYYY-MM-DD" -> "dd.mm.".
    function formatDateLabel(iso as String?) as String {
        if (iso == null || iso.length() < 10) { return ""; }
        return iso.substring(8, 10) + "." + iso.substring(5, 7) + ".";
    }

    // ------------------------------------------------------------- games

    function thinGame(raw as Dictionary) as Dictionary {
        var home = pick(raw, "home");
        var away = pick(raw, "away");
        return {
            :home => pick(home, "name"),
            :away => pick(away, "name"),
            :homeGoals => pick(home, "goals"),
            :awayGoals => pick(away, "goals"),
            :started => pick(raw, "started"),
            :ended => pick(raw, "ended"),
            :finishedType => pick(raw, "finishedType"),
            :period => pick(raw, "period"),
            :gameTime => pick(raw, "gameTime"),
            :startTime => pick(raw, "startTime"),
        };
    }

    function thinGames(raw) as Array<Dictionary> {
        var out = [] as Array<Dictionary>;
        if (raw instanceof Array) {
            for (var i = 0; i < raw.size(); i++) {
                out.add(thinGame(raw[i]));
            }
        }
        return out;
    }

    function fetchGames() as Void {
        gamesState = STATE_LOADING;
        Communications.makeWebRequest(
            BASE_URL + "/v1/games", {}, options(), new Lang.Method(Api, :onGames));
    }

    function onGames(code as Number,
                      data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (code == 200 && data instanceof Dictionary) {
            games = thinGames(pick(data, "games"));
            nextGameDateRaw = pick(data, "nextGameDate");
            nextGameDateLabel = formatDateLabel(nextGameDateRaw);
            if (games.size() > 0) {
                displayGames = games;
                isShowingToday = true;
                gamesState = STATE_OK;
                WatchUi.requestUpdate();
                fetchStandings();
                return;
            }
            // No games today — fall through to the next game day's real
            // fixtures (RESEARCH.md §8: "Next games needs the data of the
            // next games", not just a bare date).
            isShowingToday = false;
            fetchNextGames();
        } else {
            gamesState = STATE_ERROR;
            WatchUi.requestUpdate();
            fetchStandings();
        }
    }

    function fetchNextGames() as Void {
        if (nextGameDateRaw == null) {
            displayGames = [];
            gamesState = STATE_OK;
            WatchUi.requestUpdate();
            fetchStandings();
            return;
        }
        Communications.makeWebRequest(
            BASE_URL + "/v1/games", { "date" => nextGameDateRaw }, options(),
            new Lang.Method(Api, :onNextGames));
    }

    function onNextGames(code as Number,
                          data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (code == 200 && data instanceof Dictionary) {
            displayGames = thinGames(pick(data, "games"));
            gamesState = STATE_OK;
        } else {
            displayGames = [];
            gamesState = STATE_ERROR;
        }
        WatchUi.requestUpdate();
        fetchStandings();
    }

    // --------------------------------------------------------- standings

    function thinStanding(raw as Dictionary) as Dictionary {
        return {
            :rank => pick(raw, "rank"),
            :name => pick(raw, "name"),
            :games => pick(raw, "games"),
            :points => pick(raw, "points"),
            :goalDiff => pick(raw, "goalDiff"),
        };
    }

    function fetchStandings() as Void {
        standingsState = STATE_LOADING;
        Communications.makeWebRequest(
            BASE_URL + "/v1/standings", {}, options(), new Lang.Method(Api, :onStandings));
    }

    function onStandings(code as Number,
                          data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (code == 200 && data instanceof Dictionary) {
            var rows = pick(data, "standings");
            var out = [] as Array<Dictionary>;
            if (rows instanceof Array) {
                for (var i = 0; i < rows.size(); i++) { out.add(thinStanding(rows[i])); }
            }
            standings = out;
            var lines = pick(data, "playoffsLines");
            playoffsLines = (lines instanceof Array) ? lines : [] as Array<Number>;
            standingsState = STATE_OK;
        } else {
            standingsState = STATE_ERROR;
        }
        WatchUi.requestUpdate();
    }

    // -------------------------------------------------------------- refresh

    //! Floored refresh — periodic polling and view-show calls go through
    //! this, not fetchGames() directly.
    function refreshAll() as Void {
        var now = Time.now().value();
        if (lastRefresh != 0 && now - lastRefresh < MIN_REFRESH_SECS) { return; }
        lastRefresh = now;
        fetchGames();
    }

    //! Bypasses the floor — a manual refresh action, or app launch.
    function refreshNow() as Void {
        lastRefresh = Time.now().value();
        gamesState = STATE_LOADING;
        standingsState = STATE_LOADING;
        fetchGames();
    }
}
