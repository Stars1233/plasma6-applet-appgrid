/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Bold, dimmed section header label shown above grid groupings (recents,
    favorites/all, category names). The search-results list uses
    Kirigami.ListSectionHeader instead — this is for the plain grid sections.
*/

import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.Label {
    font.bold: true
    opacity: 0.7
}
