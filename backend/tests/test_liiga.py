from datetime import date

from app.liiga import acronym, current_season


def test_season_is_the_ending_year():
    # 2026-27 season = season 2027 (RESEARCH.md §1). Verified live 2026-09-24:
    # querying the API with the current date returned season 2027.
    assert current_season(date(2026, 9, 24)) == 2027
    assert current_season(date(2026, 7, 1)) == 2027
    assert current_season(date(2027, 4, 15)) == 2027
    assert current_season(date(2027, 6, 30)) == 2027
    assert current_season(date(2027, 7, 1)) == 2028


def test_acronym_uses_the_hardcoded_table():
    assert acronym("HIFK") == "HIF"
    assert acronym("Kärpät") == "KÄR"
    assert acronym("K-Espoo") == "K-E"


def test_acronym_falls_back_to_first_three_chars_for_an_unknown_team():
    # Defensive only — every current club is in the table, but Jokerit's
    # 2026 return already showed this table can go stale (RESEARCH.md §1).
    assert acronym("SomeNewClub") == "Som"
