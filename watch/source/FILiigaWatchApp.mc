import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! FILiigaWatch — Liiga (SM-liiga) scores and standings, backed by
//! liigawatch.tallimedia.com (Api.mc). MockData.mc's fixtures remain as a
//! dev-only fallback source, switchable from the action menu, but
//! production reads live from the backend by default.
class FILiigaWatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Api.refreshNow();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new PageView();
        return [view, new PageDelegate(view)];
    }

    //! Card in the glance loop — required on API 4.0.0+ devices for the
    //! widget to have a persistent glance-list entry at all (2026-09-27).
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new GlanceView()];
    }
}
