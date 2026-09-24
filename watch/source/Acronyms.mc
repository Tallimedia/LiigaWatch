import Toybox.Lang;

//! Three-letter club codes — RESEARCH.md §3/§8. No data source for these;
//! they're hardcoded here (as they will be in the backend later) because
//! liiga.fi's API returns full team names only, never a short code.
module Acronyms {
    const CODES = {
        "HIFK" => "HIF",
        "Tappara" => "TAP",
        "Ilves" => "ILV",
        "JYP" => "JYP",
        "Lukko" => "LUK",
        "Kärpät" => "KÄR",
        "TPS" => "TPS",
        "HPK" => "HPK",
        "KalPa" => "KAL",
        "Pelicans" => "PEL",
        "SaiPa" => "SAI",
        "Jukurit" => "JUK",
        "Ässät" => "ÄSS",
        "Sport" => "SPO",
        "KooKoo" => "KOO",
        "K-Espoo" => "K-E",
        "Jokerit" => "JOK",
    };

    function of(teamName as String) as String {
        var code = CODES[teamName];
        return (code != null) ? code : teamName.substring(0, 3);
    }
}
