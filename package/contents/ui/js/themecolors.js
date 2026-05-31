/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Theme-color helpers. Saves the noisy
        Qt.rgba(Kirigami.Theme.XColor.r,
                Kirigami.Theme.XColor.g,
                Kirigami.Theme.XColor.b, alpha)
    spread that appeared at every tinted-background site.
*/

.pragma library

// Returns the given Kirigami.Theme.*Color with @p alpha applied,
// preserving the theme's RGB so dark/light/high-contrast themes
// still tint correctly.
function tint(color, alpha) {
    return Qt.rgba(color.r, color.g, color.b, alpha)
}
