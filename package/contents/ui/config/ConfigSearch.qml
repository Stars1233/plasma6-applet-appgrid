/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    property alias cfg_searchAll: searchAll.checked
    property alias cfg_useExtraRunners: useExtraRunners.checked
    property alias cfg_searchUsesFrecency: searchUsesFrecency.checked
    property alias cfg_searchShowsHidden: searchShowsHidden.checked

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: searchAll
            Kirigami.FormData.label: i18nd("dev.xarbit.appgrid", "Search:")
            text: i18nd("dev.xarbit.appgrid", "Search all apps regardless of active tab")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: useExtraRunners
            Kirigami.FormData.label: i18nd("dev.xarbit.appgrid", "Plugins:")
            text: i18nd("dev.xarbit.appgrid", "Use KDE search plugins (KRunner)")
            QQC2.ToolTip.text: i18nd("dev.xarbit.appgrid", "Includes the calculator, unit conversion, file search, bookmarks, web shortcuts and other KRunner plugins. Use \"Configure Search Plugins\" to choose which are active.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        QQC2.Button {
            text: i18nd("dev.xarbit.appgrid", "Configure Search Plugins…")
            icon.name: "settings-configure"
            enabled: useExtraRunners.checked
            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_plasmasearch")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: searchUsesFrecency
            Kirigami.FormData.label: i18nd("dev.xarbit.appgrid", "Ranking:")
            text: i18nd("dev.xarbit.appgrid", "Prefer frequently-used apps in search results (KActivities)")
            QQC2.ToolTip.text: i18nd("dev.xarbit.appgrid",
                "Uses system-wide KActivities frecency (frequency + recency) data so apps you've launched a lot lately surface above equally-ranked alternatives. Affects only search results — the app grid keeps its own predictable ordering.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: searchShowsHidden
            Kirigami.FormData.label: i18nd("dev.xarbit.appgrid", "Hidden apps:")
            text: i18nd("dev.xarbit.appgrid", "Show hidden applications in search results")
            QQC2.ToolTip.text: i18nd("dev.xarbit.appgrid",
                "Hidden apps stay out of the grid (right-click → Hide Application) and, by default, also out of search results. Turn this on to keep a hidden app findable by name without un-hiding it from the grid.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
