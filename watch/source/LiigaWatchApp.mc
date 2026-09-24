import Toybox.Application;
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
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new PageView();
        return [view, new PageDelegate(view)];
    }
}
