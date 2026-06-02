/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Themed horizontal separator line. Callers set width/visibility/opacity
    for their context; the line element itself is fixed here.
*/

import org.kde.ksvg as KSvg

KSvg.SvgItem {
    imagePath: "widgets/line"
    elementId: "horizontal-line"
    // Sub-pixel implicit height renders the line at half-alpha across a
    // single screen pixel. Softer than a full 1px line in any theme, and
    // consistent across separators regardless of each slot's fractional Y.
    implicitHeight: 0.5
}
