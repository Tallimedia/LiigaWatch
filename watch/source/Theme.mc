import Toybox.Graphics;
import Toybox.Lang;

(:glance)
module Theme {
    const INK = Graphics.COLOR_WHITE;
    const DIM = Graphics.COLOR_LT_GRAY;
    const FAINT = Graphics.COLOR_DK_GRAY;
    const BG = Graphics.COLOR_BLACK;

    //! True 2-colour devices (Instinct's MIP/transflective line: palette is
    //! literally [000000, FFFFFF], confirmed via the SDK's compiler.json)
    //! don't render COLOR_ORANGE/COLOR_YELLOW at all - not dimmed, not
    //! snapped to the nearest in-palette colour, just invisible. There's no
    //! runtime API to detect this (no Graphics.getColorDepth() in this SDK -
    //! an earlier, never-actually-compiled assumption that it existed was
    //! wrong), so this is resolved per device at *build* time instead, via
    //! monkey.jungle's excludeAnnotations: the :colorTheme variant below
    //! ships to every product except the mono Instinct ids, which get
    //! :monoTheme instead. That's a real loss on those devices (no colour
    //! cue for "this game is live" or "this is your team"), but not a
    //! silent one: the status line already says "FINAL"/"P3 — 12:34"/
    //! kickoff time regardless of colour, and orderFavoriteFirst() + the
    //! Table pin (Pages.mc) already surface the favourite positionally, not
    //! just by colour. Diagnosed 2026-09-24, fixed 2026-10-14.
    (:colorTheme)
    function live() as Graphics.ColorValue {
        return Graphics.COLOR_ORANGE;
    }

    (:monoTheme)
    function live() as Graphics.ColorValue {
        return INK;
    }

    //! Single accent for "this is your team" — a user preference, not a
    //! club brand colour. Distinct from live() (orange) so a favourite
    //! team's live game still reads as live on its status line.
    (:colorTheme)
    function favorite() as Graphics.ColorValue {
        return Graphics.COLOR_YELLOW;
    }

    (:monoTheme)
    function favorite() as Graphics.ColorValue {
        return INK;
    }
}
