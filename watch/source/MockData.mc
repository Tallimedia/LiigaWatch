import Toybox.Lang;

//! Static fixtures for the sim-only beta — no backend call exists yet
//! (RESEARCH.md §9, Phase 1). Shapes match what the thinned backend
//! response will actually carry (§5): team names, goals, start time,
//! started/ended/currentPeriod/gameTime/finishedType for games; rank,
//! name, games, points, goal difference for standings.
//!
//! `gameTime` is the period-boundary value the real API returns, not a
//! locally-ticking clock — see the live-verification note in RESEARCH.md
//! §1. It is never recalculated here either, on purpose, so this fixture
//! doesn't quietly teach the UI a habit the real data won't support.
//!
//! Three scenarios so every Today-screen state (§8) can be eyeballed in
//! the sim without waiting for a real game day — switch with the action
//! menu's dev-only "Mock scenario" item (MenuDelegate.mc, AppMenu module).
module MockData {

    const SCENARIO_NO_GAMES = 0;
    const SCENARIO_SCHEDULED = 1;
    const SCENARIO_LIVE = 2;

    var scenario = SCENARIO_LIVE;

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
        // SCENARIO_LIVE — one live, one final, one still scheduled later today.
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
}
