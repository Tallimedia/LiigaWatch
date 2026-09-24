import Toybox.Lang;

//! Static fixtures — dev-only test data, **not the production data source**
//! since 2026-09-24 (Api.mc, backed by the real liigawatch.tallimedia.com
//! backend, took over that role). Kept because these fixtures exercise
//! Today-screen edge cases (no games, a full 8-game round) that a given
//! real game day may not happen to show — useful to keep testable without
//! waiting for the right day. Shapes match what Api.mc's thinning produces,
//! so Pages.mc draws either source identically.
//!
//! `gameTime` is the period-boundary value the real API returns, not a
//! locally-ticking clock — see the live-verification note in RESEARCH.md
//! §1. It is never recalculated here either, on purpose, so this fixture
//! doesn't quietly teach the UI a habit the real data won't support.
//!
//! `scenario` selects the active source, cycled from the action menu's
//! "Data source" item (MenuDelegate.mc, AppMenu module) — SOURCE_LIVE (the
//! default) reads from Api.mc; every other value reads one of these fixed
//! fixtures instead. All call sites elsewhere in the app go through the
//! `active*` functions below, never `MockData.todayGames()` etc directly,
//! so they don't need to know which source is active.
module MockData {

    const SOURCE_LIVE = 0;
    const SCENARIO_NO_GAMES = 1;
    const SCENARIO_SCHEDULED = 2;
    const SCENARIO_LIVE_MOCK = 3;
    const SCENARIO_FULL_ROUND = 4;
    const SCENARIO_COUNT = 5;

    var scenario = SOURCE_LIVE;

    function isLiveSource() as Boolean { return scenario == SOURCE_LIVE; }

    const NEXT_GAME_DATE = "27.09.";

    function todayGames() as Array<Dictionary> {
        if (scenario == SCENARIO_NO_GAMES) {
            return [];
        }
        if (scenario == SCENARIO_SCHEDULED) {
            return [
                { :home => "Lukko", :away => "Tappara", :homeGoals => 0, :awayGoals => 0,
                  :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 0, :gameTime => 0, :startTime => "18:30" },
                { :home => "HIFK", :away => "Kärpät", :homeGoals => 0, :awayGoals => 0,
                  :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 0, :gameTime => 0, :startTime => "18:30" },
            ];
        }
        if (scenario == SCENARIO_FULL_ROUND) {
            // 8 games, 16 of the 17 clubs (JYP has the bye) — a full round
            // day, mixing live/final/scheduled so the cutoff logic is
            // exercised realistically rather than with 8 identical rows.
            return [
                { :home => "HIFK", :away => "Kärpät", :homeGoals => 2, :awayGoals => 1,
                  :started => true, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 2, :gameTime => 1745, :startTime => "18:30" },
                { :home => "Tappara", :away => "Ilves", :homeGoals => 4, :awayGoals => 0,
                  :started => true, :ended => true, :finishedType => "ENDED_DURING_REGULAR_GAME_TIME",
                  :period => 3, :gameTime => 3600, :startTime => "15:30" },
                { :home => "Jukurit", :away => "SaiPa", :homeGoals => 0, :awayGoals => 0,
                  :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 0, :gameTime => 0, :startTime => "20:30" },
                { :home => "Lukko", :away => "TPS", :homeGoals => 1, :awayGoals => 1,
                  :started => true, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 1, :gameTime => 640, :startTime => "18:30" },
                { :home => "HPK", :away => "KalPa", :homeGoals => 0, :awayGoals => 0,
                  :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 0, :gameTime => 0, :startTime => "18:30" },
                { :home => "Pelicans", :away => "Ässät", :homeGoals => 2, :awayGoals => 3,
                  :started => true, :ended => true, :finishedType => "ENDED_DURING_EXTENDED_GAME_TIME",
                  :period => 4, :gameTime => 3900, :startTime => "15:30" },
                { :home => "Sport", :away => "KooKoo", :homeGoals => 5, :awayGoals => 2,
                  :started => true, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 3, :gameTime => 2810, :startTime => "15:30" },
                { :home => "K-Espoo", :away => "Jokerit", :homeGoals => 0, :awayGoals => 0,
                  :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
                  :period => 0, :gameTime => 0, :startTime => "18:30" },
            ];
        }
        // SCENARIO_LIVE_MOCK — one live, one final, one still scheduled later today.
        return [
            { :home => "HIFK", :away => "Kärpät", :homeGoals => 2, :awayGoals => 1,
              :started => true, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
              :period => 2, :gameTime => 1745, :startTime => "18:30" },
            { :home => "Tappara", :away => "Ilves", :homeGoals => 4, :awayGoals => 0,
              :started => true, :ended => true, :finishedType => "ENDED_DURING_REGULAR_GAME_TIME",
              :period => 3, :gameTime => 3600, :startTime => "15:30" },
            { :home => "Jukurit", :away => "SaiPa", :homeGoals => 0, :awayGoals => 0,
              :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
              :period => 0, :gameTime => 0, :startTime => "20:30" },
        ];
    }

    //! Fixture for `nextGameDate`'s actual fixtures — added 2026-09-24
    //! (Nico: "Next games needs the data of the next games"). Before this,
    //! the no-games-today state showed only a bare date with no matchups,
    //! which isn't what the real `/v1/games` response for that date would
    //! give you — the real backend's nextGameDate point is a full day of
    //! games, same shape as today's, just not started yet.
    function nextGames() as Array<Dictionary> {
        return [
            { :home => "Ilves", :away => "JYP", :homeGoals => 0, :awayGoals => 0,
              :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
              :period => 0, :gameTime => 0, :startTime => "18:30" },
            { :home => "KooKoo", :away => "HPK", :homeGoals => 0, :awayGoals => 0,
              :started => false, :ended => false, :finishedType => "ACTIVE_OR_NOT_STARTED",
              :period => 0, :gameTime => 0, :startTime => "18:30" },
        ];
    }

    //! What the Today screen should actually render: today's games, or —
    //! when there are none — the next game day's fixtures instead, so
    //! "Next games" is never just a bare date. Both Pages.mc and
    //! PageView.mc's scroll-boundary check read this, not todayGames()
    //! directly, so they can't disagree about which list is on screen.
    function displayGames() as Array<Dictionary> {
        var today = todayGames();
        return (today.size() > 0) ? today : nextGames();
    }

    function standings() as Array<Dictionary> {
        return [
            { :rank => 1, :name => "JYP", :games => 5, :points => 15, :goalDiff => 12 },
            { :rank => 2, :name => "Jukurit", :games => 7, :points => 15, :goalDiff => 7 },
            { :rank => 3, :name => "Ässät", :games => 6, :points => 14, :goalDiff => 9 },
            { :rank => 4, :name => "Ilves", :games => 5, :points => 11, :goalDiff => 4 },
            { :rank => 5, :name => "SaiPa", :games => 5, :points => 11, :goalDiff => 7 },
            { :rank => 6, :name => "KalPa", :games => 6, :points => 9, :goalDiff => 5 },
            { :rank => 7, :name => "Tappara", :games => 5, :points => 9, :goalDiff => 5 },
            { :rank => 8, :name => "TPS", :games => 6, :points => 9, :goalDiff => 4 },
            { :rank => 9, :name => "Pelicans", :games => 7, :points => 9, :goalDiff => -2 },
            { :rank => 10, :name => "K-Espoo", :games => 6, :points => 9, :goalDiff => 6 },
            { :rank => 11, :name => "Sport", :games => 8, :points => 9, :goalDiff => -10 },
            { :rank => 12, :name => "Lukko", :games => 6, :points => 8, :goalDiff => 0 },
            { :rank => 13, :name => "Kärpät", :games => 6, :points => 7, :goalDiff => -5 },
            { :rank => 14, :name => "HIFK", :games => 6, :points => 7, :goalDiff => -6 },
            { :rank => 15, :name => "HPK", :games => 6, :points => 6, :goalDiff => -10 },
            { :rank => 16, :name => "Jokerit", :games => 6, :points => 4, :goalDiff => -12 },
            { :rank => 17, :name => "KooKoo", :games => 6, :points => 1, :goalDiff => -14 },
        ];
    }

    // playoffsLines — RESEARCH.md §1: served by the API, never hardcoded once
    // the real backend exists. Fixed here only because this is a fixture.
    const PLAYOFF_LINES = [4, 12, 14];

    function hasLiveGame() as Boolean {
        var games = todayGames();
        for (var i = 0; i < games.size(); i++) {
            if (games[i][:started] && !games[i][:ended]) {
                return true;
            }
        }
        return false;
    }

    // ---------------------------------------------------------------
    // Active-source dispatch — every other file reads through these,
    // never the fixture functions above directly, so nothing else in the
    // app needs to know whether SOURCE_LIVE (Api.mc) or a mock scenario
    // is currently selected.
    // ---------------------------------------------------------------

    function activeDisplayGames() as Array<Dictionary> {
        return isLiveSource() ? Api.displayGames : displayGames();
    }

    function activeIsShowingToday() as Boolean {
        return isLiveSource() ? Api.isShowingToday : (todayGames().size() > 0);
    }

    function activeNextGameDateLabel() as String {
        return isLiveSource() ? Api.nextGameDateLabel : NEXT_GAME_DATE;
    }

    function activeStandings() as Array<Dictionary> {
        return isLiveSource() ? Api.standings : standings();
    }

    function activePlayoffLines() as Array<Number> {
        return isLiveSource() ? Api.playoffsLines : PLAYOFF_LINES;
    }

    function activeIsGameDay() as Boolean {
        return isLiveSource() ? Api.isGameDay() : (todayGames().size() > 0);
    }
}
