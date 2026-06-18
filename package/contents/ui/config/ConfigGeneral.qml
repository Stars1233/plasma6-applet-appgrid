/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Thin Plasma-dialog wrapper around ConfigGeneralContent: hosts the shared,
    Plasmoid-free body and feeds it directly from Plasmoid. Writes go straight
    to Plasmoid.configuration (live; the cfg_ buffering is gone — acceptable).
*/

import QtQuick

import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

import "../js/constants.js" as Const

KCM.SimpleKCM {
    id: page

    ConfigGeneralContent {
        configuration: Plasmoid.configuration
        isPanel: Plasmoid.pluginName === Const.PLUGIN_ID_PANEL
        formFactor: Plasmoid.formFactor
        location: Plasmoid.location
        availableShells: Plasmoid.availableShells ? Plasmoid.availableShells() : []
        isUniversalBuild: Plasmoid.isUniversalBuild
        defaultIcon: Const.PLUGIN_ID_CENTER
    }
}
