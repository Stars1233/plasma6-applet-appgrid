/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: page

    property var cfg_headerActions: Plasmoid.configuration.headerActions
    property alias cfg_showActionLabels: showActionLabels.checked
    property alias cfg_hideMenuButtonLabel: hideMenuButtonLabel.checked

    // Centered, capped-width column; content inside it stays left-aligned.
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, Kirigami.Units.gridUnit * 22)
        spacing: Kirigami.Units.largeSpacing

        HeaderActionsConfig {
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            actions: page.cfg_headerActions
            universalBuild: Plasmoid.isUniversalBuild
            onEdited: newList => page.cfg_headerActions = newList
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18nd("dev.xarbit.appgrid",
                "Bar actions appear directly in the launcher header; Menu actions go behind a single ⋮ button (hidden when empty); Off hides the action.")
        }

        QQC2.CheckBox {
            id: showActionLabels
            text: i18nd("dev.xarbit.appgrid", "Show labels on header buttons")
        }

        QQC2.CheckBox {
            id: hideMenuButtonLabel
            enabled: showActionLabels.checked
            text: i18nd("dev.xarbit.appgrid", "Hide label on the menu button")
        }
    }
}
