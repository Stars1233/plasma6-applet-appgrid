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
