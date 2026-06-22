/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Every menu row in AppGrid uses this instead of PlasmaComponents.MenuItem.

    PlasmaComponents.MenuItem keeps its vertical padding/insets at
    implicitHeight=0, so a row gated with `visible: false` still reserves a
    blank ghost row in the menu (#200). Collapsing the height to 0 when hidden
    fixes it once for all menus, so rows can gate with a plain `visible:` binding
    instead of Instantiator add/remove. Pairs with AppGridMenu (content-sizing).
*/

import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.MenuItem {
    height: visible ? implicitHeight : 0
}
