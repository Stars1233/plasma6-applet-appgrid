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

    Kirigami.FormLayout {
        HeaderActionsConfig {
            Kirigami.FormData.label: i18nd("dev.xarbit.appgrid", "Header actions:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            actions: page.cfg_headerActions
            universalBuild: Plasmoid.isUniversalBuild
            onEdited: newList => page.cfg_headerActions = newList
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18nd("dev.xarbit.appgrid",
                "Bar actions appear directly in the launcher header; Menu actions go behind a single ⋮ button (hidden when empty); Off hides the action.")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: showActionLabels
            Kirigami.FormData.label: i18nd("dev.xarbit.appgrid", "Display:")
            text: i18nd("dev.xarbit.appgrid", "Show labels on header buttons")
        }
    }
}
