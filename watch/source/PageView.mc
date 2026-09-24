import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! One view, three pages (Today / Table / About) — same flat-index pattern
//! as FIWeatherWatch's PageView, so page order is a one-line change and the
//! memory footprint stays flat across the device spread in manifest.xml.
class PageView extends WatchUi.View {

    hidden var _page as Number = 0;

    function initialize() {
        View.initialize();
    }

    function pageCount() as Number { return 3; }

    function next() as Void { _page = (_page + 1) % pageCount(); WatchUi.requestUpdate(); }
    function prev() as Void { _page = (_page + pageCount() - 1) % pageCount(); WatchUi.requestUpdate(); }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Theme.INK, Theme.BG);
        dc.clear();
        if (_page == 0) { Pages.drawToday(dc); }
        else if (_page == 1) { Pages.drawTable(dc); }
        else { Pages.drawAbout(dc); }
        Pages.drawPager(dc, _page, pageCount());
    }
}

//! Swipe up/down or the physical up/down buttons move between pages. Menu
//! button/long-press opens the action menu (MenuDelegate.mc, AppMenu module) — cadence and,
//! for this sim-only build, the mock-scenario switch.
class PageDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as PageView;

    function initialize(view as PageView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean { _view.next(); return true; }
    function onPreviousPage() as Boolean { _view.prev(); return true; }

    function onMenu() as Boolean {
        WatchUi.pushView(AppMenu.buildMenu(), new MenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}
