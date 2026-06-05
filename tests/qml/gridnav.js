/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Shared keyboard-navigation helpers for AppGridView and
    CategoryGridView. Pure functions; state stays on the grid.
*/

.pragma library

// Arrow-key move that extends the multi-selection from the anchor
// when one is active, and falls back to a plain move otherwise.
// Caller passes its `selection` object, the live `multiSelectActive`
// flag, the original `event`, the move callback, and a getter that
// returns the current index after the move.
function arrowMoveWithSelection(selection, multiSelectActive, event, moveFn, currentIndexFn) {
    if (multiSelectActive)
        selection.extendOrMove(event, moveFn, currentIndexFn)
    else
        moveFn()
}

// Recents-row landing index when moving UP out of the grid's top row.
// Keeps the column and drops onto the last (possibly ragged) recents row,
// clamped so a short last row lands on its final cell rather than a gap.
// Shared verbatim by both grids — the lastRow arithmetic is the off-by-one
// surface, so it lives here under test.
function recentsLandingFromGrid(currentIndex, recentCount, columns) {
    const lastRow = Math.floor((recentCount - 1) / columns)
    return Math.min(currentIndex + lastRow * columns, recentCount - 1)
}

// Grid landing index when moving DOWN out of the recents row into the grid.
// Mirrors the recents column onto the grid's first row, clamped to the grid
// so a wider recents row than grid still lands on a real cell.
function gridLandingFromRecents(recentIndex, columns, gridCount) {
    return Math.min(recentIndex % columns, gridCount - 1)
}
