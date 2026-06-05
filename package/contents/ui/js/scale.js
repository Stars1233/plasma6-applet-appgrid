/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Scale policy for size-aware content. The Size preset (Small=0, Medium=1,
    Large=2) maps to a multiplier applied on top of each consumer's own
    intrinsic factor (e.g. the category bar's 1.1). Large is anchored at 1.0 so
    existing-user appearance is preserved; smaller presets scale content down.
    A future XL preset is one row in the table below, not a slope change.

    Two scales share the one curve:
      - iconScale: always follows the preset.
      - textScale: follows the preset unless the user pinned text size
        independently of it (#167), where it holds at 1.0 so the preset moves
        only the app icons, not text and spacing.
*/

.pragma library

// Multiplier per Size preset; array index is the cfg.iconSize enum value.
const ICON_SCALE = [0.80, 0.90, 1.00]   // Small, Medium, Large

// Multiplier for the given preset, clamped into the table's range so an
// out-of-range value lands on the nearest defined preset rather than NaN.
function iconScale(preset) {
    const i = Math.max(0, Math.min(ICON_SCALE.length - 1, Math.round(preset)))
    return ICON_SCALE[i]
}

// Text/spacing scale: the icon-size curve, unless text size is pinned
// independently of the preset (#167), in which case it holds at 1.0.
function textScale(preset, independentText) {
    return independentText ? 1.0 : iconScale(preset)
}
