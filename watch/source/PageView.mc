import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! One view, three pages (Today / Table / About) — same flat-index pattern
//! as FIWeatherWatch's PageView, so page order is a one-line change and the
//! memory footprint stays flat across the device spread in manifest.xml.
//!
//! Today and Table both scroll, added 2026-09-24 (Nico: "how would I view
//! full list?", then the same gap on Today: "only three games on the
//! first page"): up/down page between Today/Table/About as before, but
//! while ON a scrollable page they scroll its rows instead, using each
//! draw function's real shown-row count rather than a guessed step.
//! Scrolling past either end of the content falls through to the
//! neighbouring page — one gesture vocabulary throughout, no separate
//! "scroll mode" to learn per page.
class PageView extends WatchUi.View {

    const TODAY_PAGE = 0;
    const TABLE_PAGE = 1;

    hidden var _page as Number = 0;
    hidden var _todayScroll as Number = 0;
    hidden var _todayRowsShown as Number = 1; // updated every Today draw
    hidden var _tableScroll as Number = 0;
    hidden var _tableRowsShown as Number = 1; // updated every Table draw

    function initialize() {
        View.initialize();
    }

    function pageCount() as Number { return 3; }

    function next() as Void {
        if (_page == TODAY_PAGE) {
            var nextOffset = _todayScroll + _todayRowsShown;
            if (nextOffset < MockData.displayGames().size()) {
                _todayScroll = nextOffset;
                WatchUi.requestUpdate();
                return;
            }
        } else if (_page == TABLE_PAGE) {
            var nextOffset = _tableScroll + _tableRowsShown;
            if (nextOffset < MockData.standings().size()) {
                _tableScroll = nextOffset;
                WatchUi.requestUpdate();
                return;
            }
        }
        _page = (_page + 1) % pageCount();
        resetScrollOnEntry();
        WatchUi.requestUpdate();
    }

    function prev() as Void {
        if (_page == TODAY_PAGE && _todayScroll > 0) {
            _todayScroll = (_todayScroll - _todayRowsShown > 0) ? _todayScroll - _todayRowsShown : 0;
            WatchUi.requestUpdate();
            return;
        }
        if (_page == TABLE_PAGE && _tableScroll > 0) {
            _tableScroll = (_tableScroll - _tableRowsShown > 0) ? _tableScroll - _tableRowsShown : 0;
            WatchUi.requestUpdate();
            return;
        }
        _page = (_page + pageCount() - 1) % pageCount();
        resetScrollOnEntry();
        WatchUi.requestUpdate();
    }

    //! Entering a scrollable page always starts at the top — Today's
    //! favourite-first reorder and Table's favourite pin both rely on this
    //! being the unscrolled default view every time, not wherever a
    //! previous visit left off.
    function resetScrollOnEntry() as Void {
        if (_page == TODAY_PAGE) { _todayScroll = 0; }
        if (_page == TABLE_PAGE) { _tableScroll = 0; }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Theme.INK, Theme.BG);
        dc.clear();
        if (_page == TODAY_PAGE) { _todayRowsShown = Pages.drawToday(dc, _todayScroll); }
        else if (_page == TABLE_PAGE) { _tableRowsShown = Pages.drawTable(dc, _tableScroll); }
        else { Pages.drawAbout(dc); }
        Pages.drawPager(dc, _page, pageCount());
    }
}

//! Swipe up/down or the physical up/down buttons move between pages (or
//! scroll the Table page — see PageView). Menu button/long-press opens the
//! action menu (MenuDelegate.mc, AppMenu module) — cadence and, for this
//! sim-only build, the mock-scenario switch.
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

    //! Select as a second way into the action menu — onMenu()'s long-press
    //! gesture depends on a per-device key mapping that isn't reliably
    //! reachable in the simulator (Nico, 2026-09-24). Select is always a
    //! clickable on-screen control in the sim, so this guarantees access
    //! regardless of device skin. Once there's a real "refresh now" action
    //! (once the backend exists), reconsider whether Select should do that
    //! instead and move the menu back to onMenu-only.
    function onSelect() as Boolean {
        WatchUi.pushView(AppMenu.buildMenu(), new MenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}
