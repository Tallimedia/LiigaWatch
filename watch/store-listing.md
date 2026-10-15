# Connect IQ Store listing copy — v1.0.0 / v1.1.0

Paste-ready text for <https://apps-developer.garmin.com>. v1.0.0 (device list, the
monochrome Instinct fix, "Liiga Watch" branding) was uploaded for review 2026-10-14,
before the round-screen text-clipping fix (`fitsScreen()`) existed. v1.1.0 ships that
fix. There's no separate "what's new" text for 1.1.0 below — nobody saw 1.0.0 publicly,
so the listing just describes what's actually shipping as the first public release.

The beta branch (`kavaleff/FILiigaWatch`'s `beta`, app id
`3be2f502eeff40c7b0e859bfbb271279`) is unlisted and needs no copy — same split as
FIWeatherWatch/VolvoWatch.

---

## Listing language

The Connect IQ store takes a separate description per language, and the app declares
`eng`, `fin` and `swe`. **All three get real copy here, unlike FIWeatherWatch's
listing** (fin/eng only) — RESEARCH.md §6 already made the case for Swedish
specifically: HIFK, Sport and Ässät have real Swedish-speaking followings, and the
league itself is "FM-ligan" in Swedish, not a transliteration.

The dashboard offers a name and a description per language, nothing else — no short
description, no bullets, no subtitle field. Everything the listing says has to live in
those two boxes.

---

## App name

**50-character limit** (same as FIWeatherWatch's dashboard).

**Finnish:**
```
Liigan tulokset ja sarjataulukko ajantasaisena
```
(46 chars)

**English:**
```
Liiga hockey scores and standings on your wrist
```
(48 chars)

**Swedish:**
```
FM-ligans resultat och tabell på handleden
```
(43 chars)

**Why these.** Same reasoning as FIWeatherWatch's name field: it's the whole short
pitch and what store search matches on, so a bare product name would waste it. All
three lead with *live/current* ("ajantasaisena" / "on your wrist" implying real-time,
not a static score lookup) — matching RESEARCH.md §7's actual differentiator over the
one paid US-league competitor: a 5-second upstream cache makes this genuinely live,
where the incumbent updates hourly.

**The launcher name on the watch is `AppName` = "Liiga Watch" in all three language
packs** (`watch/resources*/strings/strings.xml`) — same device/store name split
rationale as FIWeatherWatch, though here the two happen to be closer to each other.

---

## Description — Finnish

```
Liigan (SM-liiga) ottelut ja sarjataulukko ranteessa — niin ajantasaisena kuin Liiga.fi itse näyttää.

OTTELUT
Päivän ottelut yhdellä silmäyksellä: aloitusaika ennen ottelun alkua, sitten erä ja peliaika livenä, lopuksi loppulukema. Voittolaukauksilla ratkenneet ottelut on merkitty (VL). Jos tänään ei pelata, sovellus näyttää seuraavan pelipäivän ottelut valmiiksi.

SARJATAULUKKO
Koko sarjataulukko sijoituksineen ja pisteineen.

OMA SUOSIKKI
Valitse suosikkijoukkue: sen ottelu nousee aina päivän listan kärkeen, ja se korostuu sekä otteluissa että taulukossa — taulukossa se pysyy näkyvissä omalla rivillään, vaikka olisi sijalla 14.

PÄIVITYSTAHTI
Pelipäivinä voit valita, kuinka usein lukemat päivittyvät — 5, 15, 30 tai 60 sekunnin välein.

VILKAISU
Ottelutilanne näkyy myös widget-karusellissa ilman, että sovellusta tarvitsee avata.

Suomi, ruotsi ja englanti kellon omien kieliasetusten mukaan.

KATTAVUUS
Vain Liiga (SM-liiga) — runkosarja ja pudotuspelit. Ei tilastoja, ei maalintekijöitä, ei muita sarjoja.

Vaatii puhelinyhteyden tai WiFin. Ei tiliä eikä kirjautumista.

Tulokset ja sarjataulukko: Liiga.fi. Liiga Watch on itsenäinen projekti, ei Liigan eikä Garminin tukema.
```

---

## Description — English

```
Live Liiga (SM-liiga) scores and the full league table on your wrist.

GAMES
Today's games at a glance: kickoff time before a game starts, period and game clock live, final score once it's over — games decided by a shootout are marked (VL). No games today? The app shows the next game day's fixtures instead.

TABLE
The full league table, with every team's rank and points.

YOUR TEAM
Pick a favourite team: their game always sits at the top of today's list, and they're highlighted both there and in the table — in the table they stay visible on their own row even sitting in 14th.

UPDATE SPEED
On game days, choose how often scores refresh — 5, 15, 30 or 60 seconds.

GLANCE
Check the score from the glance carousel without opening the app.

Finnish, Swedish and English, following your watch's language.

COVERAGE
Liiga (SM-liiga) only — regular season and playoffs. No player stats, no goal scorers, no other leagues.

Needs a phone connection or WiFi. No account, no sign-in.

Scores and standings: Liiga.fi. Liiga Watch is an independent project, not affiliated with or endorsed by Liiga or Garmin.
```

---

## Description — Swedish

```
FM-ligans (SM-liiga) resultat och tabell direkt på handleden.

MATCHER
Dagens matcher på en gång: avsparkstid innan matchen börjar, period och matchklocka live, slutresultat när matchen är slut — matcher som avgjorts på straffar är märkta (VL). Inga matcher idag? Appen visar nästa matchdags program istället.

TABELL
Hela serietabellen, med varje lags placering och poäng.

DITT LAG
Välj ett favoritlag: deras match hamnar alltid överst i dagens lista, och laget är markerat både där och i tabellen — i tabellen syns det på sin egen rad även på plats 14.

UPPDATERINGSTAKT
På matchdagar väljer du själv hur ofta resultaten uppdateras — 5, 15, 30 eller 60 sekunder.

GLANCE
Se matchläget direkt i glance-karusellen utan att öppna appen.

Finska, svenska och engelska, enligt klockans eget språkval.

TÄCKNING
Endast FM-ligan (SM-liiga) — grundserie och slutspel. Ingen spelarstatistik, inga målskyttar, inga andra serier.

Kräver telefonanslutning eller WiFi. Inget konto, ingen inloggning.

Resultat och tabell: Liiga.fi. Liiga Watch är ett oberoende projekt, inte anslutet till eller stött av Liiga eller Garmin.
```

---

## What's new — first public release

**Finnish:**
```
Ensimmäinen julkinen versio.

• Päivän ottelut livenä, erä ja peliaika näkyvissä
• Koko sarjataulukko
• Oma suosikkijoukkue — korostus ja kiinnitys taulukossa
• Valittava päivitystahti pelipäivinä
• Widget-karuselli ilman sovelluksen avaamista
• Suomi, ruotsi ja englanti
```

**English:**
```
First public release.

• Today's games live, with period and game clock
• Full league table
• Favourite team — highlighted and pinned in the table
• Configurable update speed on game days
• Glance carousel card, no need to open the app
• Finnish, Swedish and English
```

**Swedish:**
```
Första publika versionen.

• Dagens matcher live, med period och matchklocka
• Hela serietabellen
• Favoritlag — markerat och fäst i tabellen
• Valbar uppdateringstakt på matchdagar
• Glance-kort utan att öppna appen
• Finska, svenska och engelska
```

---

## Availability

**Recommendation: don't geo-restrict, unlike FIWeatherWatch.** FIWeatherWatch's
9-country list exists because its *data* is location-bound — a German buyer only
benefits from it in Germany or on the Baltic. Liiga scores aren't location-bound the
same way: a Finn (or Liiga fan) anywhere in the world gets identical value from the
app, matching RESEARCH.md §7's framing of the whole proposition as "on a wrist,"
not "near Finland." Worth confirming with Nico rather than assuming, but there's no
FIWeatherWatch-style coverage-mismatch risk to defend against here.

## Artwork

`watch/store/make_store_art.py` renders both images from a real capture
(`Screenshots/pg1.png`) composited into the SDK's own `fenix847mm` skin — same
mechanism as FIWeatherWatch/VolvoWatch, so the artwork can't drift from the product.
Title updated 2026-10-15 to say "Liiga Watch", matching the in-app name.

- `watch/store/hero-1440x720.png`
- `watch/store/cover-500x500.png`

Regenerated 2026-10-15 from a fresh v1.1.0 capture (live game, a shootout-decided
FINAL with the (VL) marker, an upcoming unscored game, favourite team HIFK
highlighted) — the previous capture predated the VL feature, the no-score-before-
kickoff change, and the "Liiga Watch" rename.

## Screenshots

From `Screenshots/framed/` (bezel-composited, `Screenshots/frame.py`), all well under
the store's 300 kB cap:

| File | Shows |
|---|---|
| `pg1.png` | Today — live game, FINAL with (VL) shootout marker, upcoming game, favourite highlighted |
| `pg1-2.png` | Today, scrolled — more of the same day's round |
| `pg1-3.png` | Today, scrolled — rest of the round |
| `pg2-1.png` | Table — top of the standings |
| `pg2-2.png` | Table, scrolled — favourite team (HIFK) pinned on its own row outside the top group |
| `pg-about.png` | About page (reference only — shows "(mock data)" since it was captured in the mock full-round scenario for variety; **retake from live data before using it in the actual gallery**, or drop it per FIWeatherWatch's precedent that About is lowest-priority and optional) |

Priority order if the dashboard caps the count (same reasoning as FIWeatherWatch —
colour first, gallery preview is image one): `pg1.png`, `pg2-2.png` (shows the
favourite-pin feature, a real differentiator), `pg2-1.png`, `pg1-2.png`, `pg1-3.png`.
Drop `pg-about.png` first if anything has to give.

**Not yet done:** a monochrome capture (Instinct). Same reasoning as
FIWeatherWatch's "monochrome slot" — a buyer on one of the now-shipping mono Instinct
devices deserves to see before installing what their screen will actually look like
(plain white highlight instead of orange/yellow, see `Theme.mc`). Take one before
final submission if time allows; not a blocker for getting v1.0.0/1.1.0 uploaded.
