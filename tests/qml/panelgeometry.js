/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Centered-overlay panel geometry. The vertical nudge and the panel rect were
    inline in GridWindow, but the rect feeds two consumers — the blur/contrast
    region and the drag-out input rect — so a drift would silently break one of
    them. Pure here (screen + panel sizes in, geometry out) and under test.
*/

.pragma library

// User vertical nudge for the centered panel. percent ∈ [-100, 100] is a
// fraction of the slack between the full panel and the screen edge, so it
// scales across screen sizes and can never push the panel off-screen. Pass the
// full panel height (not the animating height) so the compact-mode height
// animation doesn't drag the panel up or down as it expands.
function verticalOffset(percent, windowHeight, panelHeight) {
    const slack = Math.max(0, (windowHeight - panelHeight) / 2)
    return Math.round(percent / 100 * slack)
}

// Geometry of the centered panel within the overlay window, including the user
// vertical offset and the compact-mode downward shift. Shared by the blur
// region and the drag input rect — keep it the single source.
function panelRect(windowWidth, windowHeight, panelWidth, panelHeight, vOffset, compactShift) {
    const w = Math.round(panelWidth)
    const h = Math.round(panelHeight)
    return {
        x: Math.round((windowWidth - w) / 2),
        y: Math.round((windowHeight - h) / 2) + vOffset + Math.round(compactShift),
        w: w,
        h: h,
    }
}
