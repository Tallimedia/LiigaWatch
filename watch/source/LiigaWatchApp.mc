import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

//! Sim-only first beta (2026-09-24) — runs entirely on MockData, no backend
//! yet. RESEARCH.md §9 lays out the real Phase 1/2 split; this exists to
//! validate layout, navigation and the three Today-screen states before the
//! backend is built.
class LiigaWatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Sim-beta convenience only, remove before backend integration:
        // defaults the favourite-team picker to HIFK so the highlight is
        // visible on first launch without going through the menu first.
        if (AppMenu.favoriteTeam() == null) {
            Storage.setValue(AppMenu.STORAGE_KEY_FAVORITE, "HIFK");
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new PageView();
        return [view, new PageDelegate(view)];
    }
}
