import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Small card in the glance loop — a count, not a specific matchup: "4
//! games today" / "No games today" / "3 games tomorrow" / "Next game
//! 29.9." (2026-09-27, replacing an earlier version that picked one game
//! to show a score for — with a full round of games, that arbitrary pick
//! was less useful than just the count, and it also dodges having to fit a
//! score line + a "+N more" indicator in 32KB of glance canvas).
//!
//! Renders only whatever `Api` already has — no network call from here,
//! deliberately. This file didn't exist before 2026-09-27: without an
//! overridden getGlanceView(), Connect IQ has no persistent glance-list
//! entry to show on API 4.0.0+ devices (quatix 8 runs API 9.2.0), which is
//! what made the app vanish from the carousel and widget list on real
//! hardware despite Garmin Connect Mobile still reporting it installed.
//! Don't add a fetch call to onShow() here — that reopens a different,
//! real failure mode (a request landing after the OS has already torn the
//! glance back down triggers Connect IQ's crash-loop protection, which
//! pulls the app from the glance list the same way).
(:glance)
class GlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        var h = dc.getHeight();
        var vc = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h * 0.28, Graphics.FONT_GLANCE, res(Rez.Strings.GlanceHeadline), vc);

        dc.setColor(Theme.INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h * 0.72, Graphics.FONT_GLANCE, line(), vc);
    }

    function line() as String {
        if (Api.gamesState == Api.STATE_IDLE) {
            return res(Rez.Strings.Loading);
        }

        var count = Api.displayGames.size();

        if (Api.isShowingToday) {
            if (count == 0) { return res(Rez.Strings.GlanceNoGamesToday); }
            return count == 1
                ? res(Rez.Strings.GlanceGameToday)
                : Lang.format(res(Rez.Strings.GlanceGamesToday), [count]);
        }

        if (count == 0) {
            return Lang.format(res(Rez.Strings.GlanceNextGame), [Api.nextGameDateLabel]);
        }
        if (isTomorrow(Api.nextGameDateRaw)) {
            return count == 1
                ? res(Rez.Strings.GlanceGameTomorrow)
                : Lang.format(res(Rez.Strings.GlanceGamesTomorrow), [count]);
        }
        return count == 1
            ? Lang.format(res(Rez.Strings.GlanceGameOn), [Api.nextGameDateLabel])
            : Lang.format(res(Rez.Strings.GlanceGamesOn), [count, Api.nextGameDateLabel]);
    }

    //! `iso` is "YYYY-MM-DD" (Api.nextGameDateRaw) — compares day/month only,
    //! which is safe here since "next game" is never more than a few days
    //! out and the Liiga season doesn't sit on a Dec 31/Jan 1 boundary for
    //! more than one turn of this check at a time.
    function isTomorrow(iso as String?) as Boolean {
        if (iso == null || iso.length() < 10) { return false; }
        var day = iso.substring(8, 10).toNumber();
        var month = iso.substring(5, 7).toNumber();
        var tomorrow = Gregorian.info(
            Time.now().add(new Time.Duration(86400)), Time.FORMAT_SHORT);
        return day == tomorrow.day && month == tomorrow.month;
    }

    function res(id) as String {
        return WatchUi.loadResource(id) as String;
    }
}
