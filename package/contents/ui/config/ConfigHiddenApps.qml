/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Thin Plasma-dialog wrapper around ConfigHiddenAppsContent. The body manages
    its own scrollable list, so an AbstractKCM (no built-in flickable) hosts it
    and lets it fill the page. Writes go straight to Plasmoid.configuration
    (live; the cfg_ buffering is gone — acceptable), so the launcher's
    right-click "Unhide" (which mutates the same Plasmoid.configuration.hiddenApps)
    updates the list reactively without the page's former Connections re-pull (#162).
*/

import QtQuick

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.AbstractKCM {
    id: page

    framedView: false

    ConfigHiddenAppsContent {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        configuration: Plasmoid.configuration
        appsModel: Plasmoid.appsModel
    }
}
