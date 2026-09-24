import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

//! Action menu.
//!
//! - Cadence picker (RESEARCH.md §9) — visible every day, but on a day with
//!   no games it shows the game-days-only explainer instead of the picker,
//!   per the 2026-09-24 revision (always-visible, explained-not-hidden).
//! - Favourite team.
//! - Refresh now — added once the real backend existed; bypasses Api's
//!   MIN_REFRESH_SECS floor, same "force a refresh" role as
//!   FIWeatherWatch's Select-triggered Api.refreshNow().
//! - Data source — dev-only, cycles MockData between SOURCE_LIVE (the real
//!   backend, the default) and its fixed test scenarios. Useful for
//!   exercising Today-screen edge cases (no games, a full 8-game round)
//!   that today's actual game day may not happen to show.
module AppMenu {

    const STORAGE_KEY_CADENCE = "cadenceSeconds";
    const CADENCES = [5, 15, 30, 60];

    const STORAGE_KEY_FAVORITE = "favoriteTeam";

    function cadenceSeconds() as Number {
        var v = Storage.getValue(STORAGE_KEY_CADENCE);
        return (v != null) ? v : 30;
    }

    //! Full team name (matches MockData's :name/:home/:away strings
    //! directly, no acronym translation needed), or null for "no favourite".
    function favoriteTeam() as String? {
        return Storage.getValue(STORAGE_KEY_FAVORITE);
    }

    function buildMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({});

        if (MockData.activeIsGameDay()) {
            menu.addItem(new WatchUi.MenuItem(
                Pages.res(Rez.Strings.MenuCadence),
                cadenceSeconds().toString() + "s",
                :cadence, {}));
        } else {
            menu.addItem(new WatchUi.MenuItem(
                Pages.res(Rez.Strings.MenuCadence),
                Pages.res(Rez.Strings.CadenceGameDaysOnly),
                :cadenceDisabled, {}));
        }

        var fav = favoriteTeam();
        menu.addItem(new WatchUi.MenuItem(
            Pages.res(Rez.Strings.MenuFavoriteTeam),
            (fav != null) ? fav : Pages.res(Rez.Strings.FavoriteTeamNone),
            :favoriteTeam, {}));

        if (MockData.isLiveSource()) {
            menu.addItem(new WatchUi.MenuItem("Refresh now", null, :refresh, {}));
        }

        menu.addItem(new WatchUi.MenuItem("Data source", scenarioLabel(), :scenario, {}));

        return menu;
    }

    function scenarioLabel() as String {
        if (MockData.scenario == MockData.SOURCE_LIVE) { return "Live"; }
        if (MockData.scenario == MockData.SCENARIO_NO_GAMES) { return "Mock: No games"; }
        if (MockData.scenario == MockData.SCENARIO_SCHEDULED) { return "Mock: Scheduled"; }
        if (MockData.scenario == MockData.SCENARIO_FULL_ROUND) { return "Mock: Full round (8)"; }
        return "Mock: Live game";
    }
}

class MenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :cadence) {
            WatchUi.pushView(buildCadenceMenu(), new CadenceMenuDelegate(), WatchUi.SLIDE_UP);
        } else if (id == :favoriteTeam) {
            WatchUi.pushView(buildFavoriteTeamMenu(), new FavoriteTeamMenuDelegate(), WatchUi.SLIDE_UP);
        } else if (id == :refresh) {
            Api.refreshNow();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :scenario) {
            // Cycle: Live -> No games -> Scheduled -> Live game -> Full
            // round -> back to Live.
            MockData.scenario = (MockData.scenario + 1) % MockData.SCENARIO_COUNT;
            WatchUi.requestUpdate();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    //! Plain MenuItem, not CheckboxMenuItem — CheckboxMenuItem can only be
    //! added to a WatchUi.CheckboxMenu container, not a Menu2 (crashed the
    //! sim, 2026-09-24: "CheckboxMenuItem can only be added to
    //! CheckboxMenu"). This is a single-choice list, not a multi-toggle
    //! one, so a "> " prefix on the current pick is enough — same
    //! MenuItem-only pattern VolvoWatch's own action menu uses. Plain ASCII
    //! deliberately, not a ✓ glyph: the watch font doesn't have one and
    //! rendered a missing-glyph placeholder instead (same sim session).
    function buildCadenceMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Pages.res(Rez.Strings.MenuCadence)});
        var current = AppMenu.cadenceSeconds();
        var labels = [Rez.Strings.Cadence5s, Rez.Strings.Cadence15s,
                       Rez.Strings.Cadence30s, Rez.Strings.Cadence60s];
        for (var i = 0; i < AppMenu.CADENCES.size(); i++) {
            var secs = AppMenu.CADENCES[i];
            var label = Pages.res(labels[i]);
            if (secs == current) { label = "> " + label; }
            menu.addItem(new WatchUi.MenuItem(label, null, secs, {}));
        }
        return menu;
    }

    //! Built from the standings order (already rank-sorted) rather than a
    //! separate hardcoded list, so it can't drift from Acronyms.CODES.
    //! Falls back to Acronyms.CODES' own team list when standings haven't
    //! loaded yet (live source, before the first successful fetch) — the
    //! picker should never be empty just because Api hasn't responded yet.
    function buildFavoriteTeamMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Pages.res(Rez.Strings.MenuFavoriteTeam)});
        var current = AppMenu.favoriteTeam();
        var noneLabel = Pages.res(Rez.Strings.FavoriteTeamNone);
        if (current == null) { noneLabel = "> " + noneLabel; }
        menu.addItem(new WatchUi.MenuItem(noneLabel, null, "", {}));

        var names = [] as Array<String>;
        var rows = MockData.activeStandings();
        if (rows.size() > 0) {
            for (var i = 0; i < rows.size(); i++) { names.add(rows[i][:name]); }
        } else {
            names = Acronyms.CODES.keys();
        }
        for (var i = 0; i < names.size(); i++) {
            var name = names[i];
            var label = ((current != null) && current.equals(name)) ? "> " + name : name;
            menu.addItem(new WatchUi.MenuItem(label, null, name, {}));
        }
        return menu;
    }
}

class CadenceMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        Storage.setValue(AppMenu.STORAGE_KEY_CADENCE, item.getId());
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class FavoriteTeamMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var name = item.getId() as String;
        if (name.equals("")) {
            Storage.deleteValue(AppMenu.STORAGE_KEY_FAVORITE);
        } else {
            Storage.setValue(AppMenu.STORAGE_KEY_FAVORITE, name);
        }
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
