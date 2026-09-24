import Toybox.Graphics;

module Theme {
    const INK = Graphics.COLOR_WHITE;
    const DIM = Graphics.COLOR_LT_GRAY;
    const FAINT = Graphics.COLOR_DK_GRAY;
    const BG = Graphics.COLOR_BLACK;
    const LIVE = Graphics.COLOR_ORANGE;

    //! Single accent for "this is your team" — a user preference, not a
    //! club brand colour. Distinct from LIVE (orange) so a favourite
    //! team's live game still reads as live on its status line.
    const FAVORITE = Graphics.COLOR_YELLOW;
}
