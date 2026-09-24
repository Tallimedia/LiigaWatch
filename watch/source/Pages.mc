import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Page rendering. Proportional to screen size, not pixel-positioned — the
//! manifest spreads across round/semi-round screens at several resolutions
//! (fenix847mm, fenix7s, venu3s, instinct2; see manifest.xml's note on why
//! that spread and not the final device list).
module Pages {

    function res(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    function w(dc as Graphics.Dc) as Number { return dc.getWidth(); }
    function h(dc as Graphics.Dc) as Number { return dc.getHeight(); }

    // ---------------------------------------------------------------
    // Today
    // ---------------------------------------------------------------

    function drawToday(dc as Graphics.Dc) as Void {
        var cx = w(dc) / 2;
        var games = MockData.todayGames();

        var headerText;
        if (games.size() == 0) {
            headerText = Lang.format(res(Rez.Strings.TodayHeaderNext), []);
            // No games today — header alone, then the next scheduled date.
            dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h(dc) * 0.10).toNumber(), Graphics.FONT_SMALL, headerText,
                        Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Theme.INK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h(dc) * 0.30).toNumber(), Graphics.FONT_MEDIUM,
                        MockData.NEXT_GAME_DATE, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        headerText = Lang.format(res(Rez.Strings.TodayHeaderGames), [todayDate()]);
        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        var headerY = (h(dc) * 0.08).toNumber();
        dc.drawText(cx, headerY, Graphics.FONT_XTINY, headerText, Graphics.TEXT_JUSTIFY_CENTER);

        // Stack rows by real font metrics, not a blind fraction of screen
        // height — that was the bug behind the first sim screenshot
        // (2026-09-24): games ran off the bottom because rowH was computed
        // from height/gameCount without checking it against what the two
        // text lines actually need. Games that don't fit are dropped in
        // favour of an ellipsis rather than drawn cramped/overlapping.
        var statusH = dc.getFontHeight(Graphics.FONT_XTINY);
        var scoreH = dc.getFontHeight(Graphics.FONT_SMALL);
        var withinGap = (h(dc) * 0.01).toNumber();
        var betweenGap = (h(dc) * 0.03).toNumber();
        var blockH = statusH + withinGap + scoreH;

        var top = headerY + statusH + (h(dc) * 0.05).toNumber();
        var bottomLimit = (h(dc) * 0.90).toNumber();

        var shown = 0;
        for (var i = 0; i < games.size(); i++) {
            if (top + blockH > bottomLimit) { break; }
            drawGameRow(dc, games[i], cx, top, statusH, scoreH, withinGap);
            top += blockH + betweenGap;
            shown += 1;
        }
        if (shown < games.size()) {
            dc.setColor(Theme.FAINT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, top, Graphics.FONT_XTINY, "…", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    //! One game: a status line (kickoff time / live period+clock / FINAL),
    //! then the score line. `gameTime` here is always the period-boundary
    //! value the real API returns (never a locally-ticked clock) — carried
    //! straight through from MockData, per RESEARCH.md §1.
    //!
    //! The score line uses Theme.FAVORITE instead of INK when either side
    //! is the user's chosen team (AppMenu.favoriteTeam(), 2026-09-24
    //! addition) — one accent colour for "your team", not a per-team
    //! colour table, so this doesn't reopen the "no team colours" v1 call.
    //! The status line keeps its own colour (LIVE/DIM) either way, so a
    //! favourite team's live game still reads as live.
    function drawGameRow(dc as Graphics.Dc, g as Dictionary, cx as Number, top as Number,
                          statusH as Number, scoreH as Number, withinGap as Number) as Void {
        var status;
        var statusColor = Theme.DIM;
        if (g[:ended]) {
            status = "FINAL";
        } else if (g[:started]) {
            status = Lang.format("P$1$ — $2$", [g[:period], clock(g[:gameTime])]);
            statusColor = Theme.LIVE;
        } else {
            status = g[:startTime];
        }

        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, top, Graphics.FONT_XTINY, status, Graphics.TEXT_JUSTIFY_CENTER);

        var fav = AppMenu.favoriteTeam();
        var isFavorite = (fav != null) && (fav.equals(g[:home]) || fav.equals(g[:away]));

        var line = Lang.format("$1$ $2$ – $3$ $4$",
            [Acronyms.of(g[:home]), g[:homeGoals], g[:awayGoals], Acronyms.of(g[:away])]);
        dc.setColor(isFavorite ? Theme.FAVORITE : Theme.INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, top + statusH + withinGap, Graphics.FONT_SMALL, line,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Seconds since period start -> "MM:SS". Only ever fed a value straight
    //! from the API/fixture, never a locally-advanced counter.
    function clock(seconds as Number) as String {
        var m = seconds / 60;
        var s = seconds % 60;
        return Lang.format("$1$:$2$", [m, s < 10 ? "0" + s : s.toString()]);
    }

    function todayDate() as String {
        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return Lang.format("$1$.$2$.", [now.day, now.month]);
    }

    // ---------------------------------------------------------------
    // Table
    // ---------------------------------------------------------------

    //! All 17 rows drawn, no independent scroll yet — acceptable for the
    //! sim-only beta; RESEARCH.md §8 already flags the real scroll strategy
    //! as a Phase 2 requirement once real device metrics are in hand.
    //! Row height from the font's real metrics, not height/17 — the second
    //! sim-beta bug (2026-09-24): every row overlapped the next because a
    //! 260px-tall screen divided by 17 gives ~12px rows, well under any
    //! font's actual height. Draws only as many rows as legibly fit and
    //! shows a "+N" tail instead of cramming the rest in illegibly.
    //! RESEARCH.md §8 already flags a real scroll strategy as Phase 2 work
    //! once device metrics are in hand — this is the sim-beta placeholder
    //! for that, not the final answer.
    function drawTable(dc as Graphics.Dc) as Void {
        var cx = w(dc) / 2;
        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        var headerY = (h(dc) * 0.06).toNumber();
        dc.drawText(cx, headerY, Graphics.FONT_XTINY, res(Rez.Strings.PageTable),
                    Graphics.TEXT_JUSTIFY_CENTER);

        var rows = MockData.standings();
        var rowH = dc.getFontHeight(Graphics.FONT_XTINY) + (h(dc) * 0.015).toNumber();
        var top = headerY + (h(dc) * 0.10).toNumber();
        var bottomLimit = (h(dc) * 0.88).toNumber();
        var leftX = (w(dc) * 0.12).toNumber();
        var rightX = (w(dc) * 0.88).toNumber();

        var fav = AppMenu.favoriteTeam();
        var favoriteIdx = -1;
        if (fav != null) {
            for (var i = 0; i < rows.size(); i++) {
                if (fav.equals(rows[i][:name])) { favoriteIdx = i; break; }
            }
        }

        var shown = 0;
        for (var i = 0; i < rows.size(); i++) {
            var y = top + shown * rowH;
            if (y + rowH > bottomLimit) { break; }
            drawStandingsRow(dc, rows[i], leftX, rightX, y, rowH, i == favoriteIdx);
            shown += 1;
        }

        // Favourite team pinned as the last row when the cut-off left it
        // out — 2026-09-24 addition: "always shown, highlighted, even if
        // not in the visible range". Replaces the generic "+N" overflow
        // line so it costs no extra vertical space; if the favourite is
        // already visible above, the ordinary "+N" still runs as before.
        if (shown < rows.size()) {
            if (favoriteIdx >= shown) {
                drawStandingsRow(dc, rows[favoriteIdx], leftX, rightX, top + shown * rowH,
                                  rowH, true);
            } else {
                dc.setColor(Theme.FAINT, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, top + shown * rowH, Graphics.FONT_XTINY,
                            Lang.format("+$1$", [rows.size() - shown]), Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    //! One standings row. `highlight` is Theme.FAVORITE for the user's
    //! chosen team (a single accent for "your team", distinct from any
    //! per-team colour table — see the note on drawGameRow).
    function drawStandingsRow(dc as Graphics.Dc, r as Dictionary, leftX as Number,
                               rightX as Number, y as Number, rowH as Number,
                               highlight as Boolean) as Void {
        dc.setColor(highlight ? Theme.FAVORITE : Theme.INK, Graphics.COLOR_TRANSPARENT);
        var label = Lang.format("$1$ $2$", [r[:rank], r[:name]]);
        dc.drawText(leftX, y, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);
        var pts = Lang.format("$1$p", [r[:points]]);
        dc.drawText(rightX, y, Graphics.FONT_XTINY, pts, Graphics.TEXT_JUSTIFY_RIGHT);

        // playoffsLines separators (MockData.PLAYOFF_LINES) — never
        // hardcoded once the real backend exists (RESEARCH.md §1).
        if (isPlayoffLine(r[:rank])) {
            dc.setColor(Theme.FAINT, Graphics.COLOR_TRANSPARENT);
            var lineY = y + rowH * 0.85;
            dc.drawLine(leftX, lineY, rightX, lineY);
        }
    }

    function isPlayoffLine(rank as Number) as Boolean {
        var lines = MockData.PLAYOFF_LINES;
        for (var i = 0; i < lines.size(); i++) {
            if (lines[i] == rank) { return true; }
        }
        return false;
    }

    // ---------------------------------------------------------------
    // About
    // ---------------------------------------------------------------

    function drawAbout(dc as Graphics.Dc) as Void {
        var cx = w(dc) / 2;
        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h(dc) * 0.10).toNumber(), Graphics.FONT_XTINY,
                    res(Rez.Strings.PageAbout), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h(dc) * 0.30).toNumber(), Graphics.FONT_TINY,
                    "LiigaWatch 0.1.0", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, (h(dc) * 0.42).toNumber(), Graphics.FONT_TINY,
                    "(sim beta — mock data)", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h(dc) * 0.58).toNumber(), Graphics.FONT_XTINY,
                    res(Rez.Strings.Attribution), Graphics.TEXT_JUSTIFY_CENTER);
        // Split across two lines, not one — a single-line disclaimer got
        // clipped by the round bezel at this width in the first sim screenshot
        // (2026-09-24). DisclaimerL1/L2 are pre-wrapped per language rather
        // than measured/wrapped at runtime, since the strings are fixed.
        dc.drawText(cx, (h(dc) * 0.68).toNumber(), Graphics.FONT_XTINY,
                    res(Rez.Strings.DisclaimerL1), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, (h(dc) * 0.76).toNumber(), Graphics.FONT_XTINY,
                    res(Rez.Strings.DisclaimerL2), Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ---------------------------------------------------------------
    // Shared
    // ---------------------------------------------------------------

    function drawPager(dc as Graphics.Dc, index as Number, count as Number) as Void {
        var cx = w(dc) / 2;
        var y = h(dc) * 0.955;
        var gap = 10;
        var startX = cx - ((count - 1) * gap) / 2;
        for (var i = 0; i < count; i += 1) {
            dc.setColor(i == index ? Theme.INK : Theme.FAINT, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle((startX + i * gap).toNumber(), y.toNumber(), i == index ? 3 : 2);
        }
    }
}
