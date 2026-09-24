import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

//! Action menu. Two items in the sim beta:
//!
//! - Cadence picker (RESEARCH.md §9) — visible every day, but on a day with
//!   no games it shows the game-days-only explainer instead of the picker,
//!   per the 2026-09-24 revision (always-visible, explained-not-hidden).
//! - "Mock scenario" — sim-beta-only, cycles MockData through its three
//!   Today-screen states so all of §8 can be eyeballed without a real game
//!   day. Remove this item once the real backend replaces MockData.
module AppMenu {

    const STORAGE_KEY_CADENCE = "cadenceSeconds";
    const CADENCES = [5, 15, 30, 60];

    function cadenceSeconds() as Number {
        var v = Storage.getValue(STORAGE_KEY_CADENCE);
        return (v != null) ? v : 30;
    }

    function buildMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({});

        if (MockData.hasLiveGame() || MockData.todayGames().size() > 0) {
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

        menu.addItem(new WatchUi.MenuItem("Mock scenario", scenarioLabel(), :scenario, {}));

        return menu;
    }

    function scenarioLabel() as String {
        if (MockData.scenario == MockData.SCENARIO_NO_GAMES) { return "No games"; }
        if (MockData.scenario == MockData.SCENARIO_SCHEDULED) { return "Scheduled"; }
        return "Live";
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
        } else if (id == :scenario) {
            // Dev-only cycle: no games -> scheduled -> live -> no games.
            MockData.scenario = (MockData.scenario + 1) % 3;
            WatchUi.requestUpdate();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function buildCadenceMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Pages.res(Rez.Strings.MenuCadence)});
        var current = AppMenu.cadenceSeconds();
        var labels = [Rez.Strings.Cadence5s, Rez.Strings.Cadence15s,
                       Rez.Strings.Cadence30s, Rez.Strings.Cadence60s];
        for (var i = 0; i < AppMenu.CADENCES.size(); i++) {
            var secs = AppMenu.CADENCES[i];
            menu.addItem(new WatchUi.CheckboxMenuItem(
                Pages.res(labels[i]), null, secs, secs == current, {}));
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
