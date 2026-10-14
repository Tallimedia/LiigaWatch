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

    //! Draws `full` centred at (cx, y), or `compact` instead if `full`
    //! measures wider than the screen actually has — found 2026-09-24 on
    //! Instinct 2 (176x176px vs. fenix847mm's 454x454): Garmin's system
    //! fonts are roughly the same absolute pixel size on every device, so
    //! a scrolled-range header ("Games today 24.9. 3-3") that fits fine at
    //! 454px genuinely doesn't fit at 176px. No percentage-of-screen
    //! margin can fix that — only measuring the real text width can, via
    //! getTextWidthInPixels, which is the whole reason this exists rather
    //! than more margin tuning.
    function drawFittingHeader(dc as Graphics.Dc, cx as Number, y as Number,
                                full as String, compact as String) as Void {
        var text = (dc.getTextWidthInPixels(full, Graphics.FONT_XTINY) > w(dc) * 0.92)
            ? compact : full;
        dc.drawText(cx, y, Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Centred one-line status message (loading / service unavailable) —
    //! only reachable when MockData.isLiveSource() and Api hasn't got real
    //! data yet, so a mock scenario never shows this.
    function drawCenteredMessage(dc as Graphics.Dc, cx as Number, text as String) as Void {
        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h(dc) * 0.46).toNumber(), Graphics.FONT_SMALL, text,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ---------------------------------------------------------------
    // Today
    // ---------------------------------------------------------------

    //! Draws whichever window of today's games starts at `scrollOffset` and
    //! returns how many it actually fit — same scroll-by-real-shown-count
    //! pattern as drawTable (2026-09-24), added right after Table got it:
    //! a busy day cut off at 3 games with an ellipsis and no way to reach
    //! the rest was the same gap, just not yet fixed here (Nico, same
    //! session). The favourite's game is still floated to index 0 by
    //! orderFavoriteFirst regardless of scroll, so it's always on the
    //! unscrolled first screen without needing its own pin like Table's.
    function drawToday(dc as Graphics.Dc, scrollOffset as Number) as Number {
        var cx = w(dc) / 2;

        if (MockData.isLiveSource()) {
            if (Api.gamesState == Api.STATE_LOADING && Api.displayGames.size() == 0) {
                drawCenteredMessage(dc, cx, res(Rez.Strings.Loading));
                return 0;
            }
            if (Api.gamesState == Api.STATE_ERROR && Api.displayGames.size() == 0) {
                drawCenteredMessage(dc, cx, res(Rez.Strings.NoData));
                return 0;
            }
        }

        var isToday = MockData.activeIsShowingToday();
        var games = orderFavoriteFirst(MockData.activeDisplayGames());

        // "Next games" still needs the actual date, and still uses real
        // rows below — 2026-09-24 fix: this used to be a bare date with no
        // matchups at all, which isn't what the real backend's
        // nextGameDate response would ever look like.
        var headerText = isToday
            ? Lang.format(res(Rez.Strings.TodayHeaderGames), [todayDate()])
            : Lang.format("$1$ $2$", [res(Rez.Strings.TodayHeaderNext),
                MockData.activeNextGameDateLabel()]);
        var compactHeader = headerText;
        // Range indicator only once scrolled, same convention as Table.
        // Compact fallback is the range alone — on a screen too narrow for
        // the full sentence, the range is still legible on its own; the
        // unscrolled first screen (no range) already said what day it is.
        if (scrollOffset > 0) {
            var rangeText = Lang.format("$1$–$2$", [scrollOffset + 1,
                (scrollOffset + 3 < games.size()) ? scrollOffset + 3 : games.size()]);
            headerText = Lang.format("$1$ $2$", [headerText, rangeText]);
            compactHeader = rangeText;
        }
        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        var headerY = (h(dc) * 0.08).toNumber();
        drawFittingHeader(dc, cx, headerY, headerText, compactHeader);

        // Stack rows by real font metrics, not a blind fraction of screen
        // height — that was the bug behind the first sim screenshot
        // (2026-09-24): games ran off the bottom because rowH was computed
        // from height/gameCount without checking it against what the two
        // text lines actually need. Games that don't fit on this screen are
        // reachable by scrolling (PageView), not dropped.
        var statusH = dc.getFontHeight(Graphics.FONT_XTINY);
        var scoreH = dc.getFontHeight(Graphics.FONT_SMALL);
        var withinGap = (h(dc) * 0.01).toNumber();
        var betweenGap = (h(dc) * 0.03).toNumber();
        var blockH = statusH + withinGap + scoreH;

        var top = headerY + statusH + (h(dc) * 0.05).toNumber();
        var bottomLimit = (h(dc) * 0.90).toNumber();

        var shown = 0;
        for (var i = scrollOffset; i < games.size(); i++) {
            if (top + blockH > bottomLimit) { break; }
            drawGameRow(dc, games[i], cx, top, statusH, scoreH, withinGap);
            top += blockH + betweenGap;
            shown += 1;
        }
        if (scrollOffset + shown < games.size()) {
            dc.setColor(Theme.FAINT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, top, Graphics.FONT_XTINY, "…", Graphics.TEXT_JUSTIFY_CENTER);
        }
        return shown;
    }

    //! Favourite's game always visible, same principle as the Table pin
    //! (§8a) — 2026-09-24, prompted by "what if there's a full 8-game
    //! round": without this, a favourite team playing late in the list
    //! could fall past the ellipsis cutoff on a busy day and never be seen
    //! at all, which defeats the point of picking one. Moves that one game
    //! to the front; every other game keeps its original relative order.
    function orderFavoriteFirst(games as Array<Dictionary>) as Array<Dictionary> {
        var fav = AppMenu.favoriteTeam();
        if (fav == null) { return games; }

        var favIdx = -1;
        for (var i = 0; i < games.size(); i++) {
            if (fav.equals(games[i][:home]) || fav.equals(games[i][:away])) {
                favIdx = i;
                break;
            }
        }
        if (favIdx <= 0) { return games; } // not playing today, or already first

        var ordered = [games[favIdx]];
        for (var i = 0; i < games.size(); i++) {
            if (i != favIdx) { ordered.add(games[i]); }
        }
        return ordered;
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

        // A game that hasn't started has no score to show - "0 – 0" reads as
        // a real result, not a placeholder, so it's misleading rather than
        // just uninformative. Score appears once the game has started, and
        // stays for the rest of that game day once it has (FINAL included).
        var showScore = g[:started];

        // Shootout marker, matching liiga.fi's own "(VL)" next to the score
        // (Voittolaukaus - "winning shot"). finishedType only means anything
        // once the game has ended; ignore it otherwise.
        var finishedType = g[:finishedType];
        var isShootout = g[:ended] && finishedType != null
            && (finishedType as String).equals("ENDED_DURING_WINNING_SHOT_COMPETITION");

        var line = showScore
            ? Lang.format(isShootout ? "$1$ $2$ – $3$ $4$ (VL)" : "$1$ $2$ – $3$ $4$",
                [Acronyms.of(g[:home]), g[:homeGoals], g[:awayGoals], Acronyms.of(g[:away])])
            : Lang.format("$1$ – $2$", [Acronyms.of(g[:home]), Acronyms.of(g[:away])]);
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
    //! Row height from the font's real metrics, not height/17 — the second
    //! sim-beta bug (2026-09-24): every row overlapped the next because a
    //! 260px-tall screen divided by 17 gives ~12px rows, well under any
    //! font's actual height. Draws whichever window of the list starts at
    //! `scrollOffset` and returns how many rows it actually fit, so
    //! PageView.next()/prev() can page through the full 17 rows by real
    //! device metrics rather than a hardcoded step count — added
    //! 2026-09-24 after Nico noted an 8-row-visible table has no way to
    //! reach ranks 8–13/15–17 otherwise. Up/down scroll the table while on
    //! this page; scrolling past either end moves to the neighbouring page
    //! (PageView), so the up/down vocabulary stays the same everywhere.
    function drawTable(dc as Graphics.Dc, scrollOffset as Number) as Number {
        var cx = w(dc) / 2;

        if (MockData.isLiveSource()) {
            if (Api.standingsState == Api.STATE_LOADING && Api.standings.size() == 0) {
                drawCenteredMessage(dc, cx, res(Rez.Strings.Loading));
                return 0;
            }
            if (Api.standingsState == Api.STATE_ERROR && Api.standings.size() == 0) {
                drawCenteredMessage(dc, cx, res(Rez.Strings.NoData));
                return 0;
            }
        }

        dc.setColor(Theme.DIM, Graphics.COLOR_TRANSPARENT);
        var headerY = (h(dc) * 0.06).toNumber();
        var rows = MockData.activeStandings();
        // Range indicator only once scrolled — scrollOffset 0 stays a plain
        // "Table" title, matching the original quick-glance view exactly.
        var title = res(Rez.Strings.PageTable);
        var compactTitle = title;
        if (scrollOffset > 0) {
            var rangeText = Lang.format("$1$–$2$", [scrollOffset + 1,
                (scrollOffset + 7 < rows.size()) ? scrollOffset + 7 : rows.size()]);
            title = Lang.format("$1$ $2$", [title, rangeText]);
            compactTitle = rangeText;
        }
        drawFittingHeader(dc, cx, headerY, title, compactTitle);

        var rowH = dc.getFontHeight(Graphics.FONT_XTINY) + (h(dc) * 0.015).toNumber();
        var top = headerY + (h(dc) * 0.10).toNumber();
        // Bottom limit and side margins pulled in further than a naive
        // proportional layout would need, because the round bezel narrows
        // the usable width as rows approach the bottom edge — the last
        // (often pinned-favourite) row was clipping left and right in the
        // sim screenshots (2026-09-24) at the previous 0.88/0.12 values.
        var bottomLimit = (h(dc) * 0.84).toNumber();
        var leftX = (w(dc) * 0.17).toNumber();
        var rightX = (w(dc) * 0.83).toNumber();

        var fav = AppMenu.favoriteTeam();
        var favoriteIdx = -1;
        if (fav != null) {
            for (var i = 0; i < rows.size(); i++) {
                if (fav.equals(rows[i][:name])) { favoriteIdx = i; break; }
            }
        }

        var shown = 0;
        for (var i = scrollOffset; i < rows.size(); i++) {
            var y = top + shown * rowH;
            if (y + rowH > bottomLimit) { break; }
            drawStandingsRow(dc, rows[i], leftX, rightX, y, rowH, i == favoriteIdx);
            shown += 1;
        }

        // Favourite team pinned as the last row when this screen's cut-off
        // left it out — but only on the unscrolled default view
        // (scrollOffset 0). That is the "quick glance, no scrolling
        // needed" guarantee from the original ask; once the user has
        // scrolled at all they can see the favourite in its real position
        // when they reach it, so a second pin on every screen would be
        // redundant clutter rather than useful.
        var lastIdx = scrollOffset + shown;
        if (lastIdx < rows.size()) {
            if (scrollOffset == 0 && favoriteIdx >= shown) {
                drawStandingsRow(dc, rows[favoriteIdx], leftX, rightX, top + shown * rowH,
                                  rowH, true);
            } else {
                dc.setColor(Theme.FAINT, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, top + shown * rowH, Graphics.FONT_XTINY,
                            Lang.format("+$1$", [rows.size() - lastIdx]), Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
        return shown;
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

        // playoffsLines separators — served by the real API, never
        // hardcoded (RESEARCH.md §1).
        if (isPlayoffLine(r[:rank])) {
            dc.setColor(Theme.FAINT, Graphics.COLOR_TRANSPARENT);
            var lineY = y + rowH * 0.85;
            dc.drawLine(leftX, lineY, rightX, lineY);
        }
    }

    function isPlayoffLine(rank as Number) as Boolean {
        var lines = MockData.activePlayoffLines();
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
                    "FILiigaWatch 0.3.0", Graphics.TEXT_JUSTIFY_CENTER);
        // Only ever says "(mock data)" in the dev-only mock scenarios —
        // real production installs never show anything here.
        if (!MockData.isLiveSource()) {
            dc.drawText(cx, (h(dc) * 0.42).toNumber(), Graphics.FONT_TINY,
                        "(mock data)", Graphics.TEXT_JUSTIFY_CENTER);
        }

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
