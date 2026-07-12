# Knobelfuchs — UI Design System

**Inherits the [Fuchsbau design system](https://github.com/Kemenor/fuchsbau/blob/main/DESIGN.md).**
Colours (the tangerine triad), typography (Figtree + the accessibility font picker),
spacing/shape/elevation, and iconography (Material Symbols Rounded) all come from there.
This doc records only what's **knobelfuchs-specific**.

> **Deviations from Fuchsbau:**
> 1. **Tablet-first.** The family is phone-first; knobelfuchs's reference device is an
>    11″ tablet (Xiaomi Pad 5), with phones as the secondary target.
> 2. **No FAB.** The game screen's actions (deal · hint · undo) live in a fixed action
>    bar; a floating button over a number grid would cover cells.

## 1. Game state → colour

The board maps onto the shared palette; the Fuchsbau **"red is for destruction only"**
law applies — nothing in normal play is ever red.

| State | Colour | Treatment |
|---|---|---|
| Digit (live) | `onSurface` | high contrast, tabular figures |
| Selected cell | indigo `#8559D0` / `#A98CEE` | filled tonal cell + ring (selection/focus = indigo, per Fuchsbau) |
| Hinted pair | amber `#E0A33B` / `#EDB45A` | soft tonal fill — *information, not command* |
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

## 3. Layout — orientations (Pad 5)

- **Portrait:** stats strip (matches · rows · deals) on top, board centered, action bar
  at the bottom (thumb reach).
- **Landscape:** board centered-left, stats + actions in a right-side rail — both
  hands hold the tablet, thumbs reach the rail.
- **Phone:** portrait layout at smaller cell sizes; landscape = tablet landscape,
  scaled.

## 4. Action bar

Three quiet `IconButton.filledTonal` actions, ≥ 56 dp touch targets:

| Action | Icon (Material Symbols Rounded) | Note |
|---|---|---|
| Deal | `add_circle` | badge shows deal count — neutral grey, informational |
| Hint | `lightbulb` | amber highlight on the board |
| Undo | `undo` | disabled-look only at the opening position |

No action ever opens an ad, a shop, or a "watch to continue" — obviously; they just
*work*.

## 5. Mockups

`examples/ui/` will hold the static HTML canon (light/dark toggle, portrait + landscape
frames) before widgets are built — same flow as checkfuchs.
