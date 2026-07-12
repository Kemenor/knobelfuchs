# Knobelfuchs — UI Design System

**Inherits the [Fuchsbau design system](https://github.com/Kemenor/fuchsbau/blob/main/DESIGN.md).**
Colours (the tangerine triad), typography (Figtree + the accessibility font picker),
spacing/shape/elevation, and iconography (Material Symbols Rounded) all come from there.
This doc records only what's **knobelfuchs-specific**.

> **Deviations from Fuchsbau:**
> 1. **Tablet-first.** The family is phone-first; knobelfuchs's reference device is an
>    11″ tablet (Xiaomi Pad 5), with phones as the secondary target.
> 2. **No FAB.** The game screen's actions (add · hint · undo) live in a fixed action
>    bar; a floating button over a number grid would cover cells.
> 3. **Font scaling is a hard requirement** (concept §5) — Fuchsbau treats
>    accessibility as a strong should; here OS text scale to 200 % without clipping is
>    a must, and the font picker applies to the board digits themselves.

## 0. Mode → colour

The three modes own the three triad hues — the home screen is the palette:

| Mode | Colour | Accent use |
|---|---|---|
| **Free Form** | fox orange `#EA7A24` / `#F39C4E` | mode card, in-game chrome |
| **Daily Knobel** | indigo `#8559D0` / `#A98CEE` | mode card, in-game chrome |
| **Story** | emerald `#1FA85D` / `#37CE78` | mode card, level path, in-game chrome |

The board itself is mode-neutral (digits stay `onSurface`); only the surrounding
chrome (app bar tint, progress accents) carries the mode hue.

**Semantic colours cut across the mode hue** (they win where they overlap):
- **Indigo = the action forward.** Selection and the current/next thing everywhere —
  selected cell, the in-game action bar (add/hint/undo, **same indigo in every
  mode**), the current story level's Play, Resume buttons. The mode hue lives only in
  passive chrome (mode chip, progress accents) — behaviour that is identical across
  modes looks identical.
- **Emerald = achieved — and returning to the achieved.** Checks, best scores,
  progress fills; a *beaten* story level's Play button is emerald (= replay, beat
  your own best), visually distinct from the indigo "next level" Play.

## 1. Game state → colour

The board maps onto the shared palette; the Fuchsbau **"red is for destruction only"**
law applies — nothing in normal play is ever red.

| State | Colour | Treatment |
|---|---|---|
| Digit (live) | `onSurface` | high contrast, tabular figures |
| Selected cell | indigo `#8559D0` / `#A98CEE` | filled tonal cell + ring (selection/focus = indigo, per Fuchsbau) |
| Hinted pair | fox orange `#EA7A24` / `#F39C4E` | tonal fill + border, **persists until both cells are tapped** — impossible to miss (family feedback) |
| Just matched | emerald `#1FA85D` / `#37CE78` | brief flash, then fades to cleared |
| Cleared cell | faded taupe digit `#A8988C` / `#B6A79B` | ghost of the old digit, struck — keeps the paper feel and makes line-of-sight legible |
| Win celebration | fox orange | the one loud moment |

## 2. The board

- **Cells:** square, adaptive size — the 9-column grid fills the available width up to a
  max cell size of **72 dp** (Pad 5 target ≈ 64–72 dp); floor **48 dp** on phones.
  Radius 8 (chip scale). Hairline `outlineVariant` grid lines — no heavy borders.
- **Digits:** the user's chosen Fuchsbau font, tabular figures, sized to ~55 % of the
  cell.
- **Board scrolls vertically** when longer than the viewport; the action bar and stats
  strip stay fixed.
- **Stillness rule:** nothing on the board moves without player input (concept §7).
  Match/collapse animations ≤ 250 ms, then perfect stillness again.
- **Sound & motion pair up per event** (concept §10, auditioned in
  `examples/ui/07-klang.html`): feedback answers the player's action, never lures —
  no autonomous blinking, no comeback fanfares. Sounds toggleable, silent mode
  respected.

## 3. Layout — orientations (Pad 5)

- **Portrait:** stats strip (matches · rows · deals) on top, board centered, action bar
  at the bottom (thumb reach).
- **Landscape:** board centered-left, stats + actions in a right-side rail — both
  hands hold the tablet, thumbs reach the rail.
- **Phone:** portrait layout at smaller cell sizes; landscape = tablet landscape,
  scaled.

## 4. Action bar

Three quiet `IconButton.filledTonal` actions in **indigo — identical in all modes**
(indigo = action; the mode hue never recolours behaviour), ≥ 56 dp touch targets, each
carrying its **remaining budget** as a neutral count (tabular figures):

| Action | Icon (Material Symbols Rounded) | Budget states |
|---|---|---|
| Add rows | `add_circle` | count `5…0` or `∞`; at **0 → gray** (calm unavailable — never red) |
| Hint | `lightbulb` | count `5…0` or `∞`; at **0 → gray**; pressed with *no pair on the board* → brief gray flash + nudge toward Add, **budget untouched** |
| Undo | `undo` | gray only at the opening position |

**Gray = quietly unavailable.** `onSurface` at ~38 % opacity, no error colour, no
shake. Exhausted budgets are game state, not warnings.

No action ever opens an ad, a shop, or a "watch to continue" — obviously; they just
*work*.

## 5. Mockups

`examples/ui/` will hold the static HTML canon (light/dark toggle, portrait + landscape
frames) before widgets are built — same flow as checkfuchs.
