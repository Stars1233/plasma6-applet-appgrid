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

    property var cfg_hiddenApps: Plasmoid.configuration.hiddenApps
    property string _filter: ""

    readonly property var _filteredApps: {
        var apps = page.cfg_hiddenApps || []
        if (!page._filter)
            return apps
        var needle = page._filter.toLowerCase()
        return apps.filter(function(sid) {
            if (!sid) return false
            if (sid.toLowerCase().indexOf(needle) >= 0) return true
            var info = Plasmoid.appsModel.getByStorageId(sid)
            return info && info.name && info.name.toLowerCase().indexOf(needle) >= 0
        })
    }

    function _unhide(storageId) {
        var list = page.cfg_hiddenApps.slice()
        var i = list.indexOf(storageId)
        if (i >= 0) {
            list.splice(i, 1)
            page.cfg_hiddenApps = list
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18nd("dev.xarbit.appgrid", "Right-click any app in the grid to hide it, or type h: in the search bar.")
        }

        Kirigami.SearchField {
            id: searchField
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            enabled: (page.cfg_hiddenApps || []).length > 0
            placeholderText: i18nd("dev.xarbit.appgrid", "Filter hidden apps…")
            onTextChanged: page._filter = text
        }

        Kirigami.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.gridUnit * 2
            visible: (page.cfg_hiddenApps || []).length === 0
            icon.name: "view-visible"
            text: i18nd("dev.xarbit.appgrid", "No hidden applications")
        }

        Kirigami.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.gridUnit * 2
            visible: (page.cfg_hiddenApps || []).length > 0 && page._filteredApps.length === 0
            icon.name: "system-search-symbolic"
            text: i18nd("dev.xarbit.appgrid", "No matches")
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 18
            visible: page._filteredApps.length > 0
            clip: true

            ListView {
                id: hiddenList
                model: page._filteredApps
                spacing: 0
                reuseItems: true

                delegate: QQC2.ItemDelegate {
                    width: hiddenList.width
                    required property string modelData
                    property var appInfo: Plasmoid.appsModel.getByStorageId(modelData) || ({})

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            source: appInfo.iconName || "application-x-executable"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: appInfo.name || modelData
                                elide: Text.ElideRight
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                visible: !!appInfo.name
                                text: modelData
                                font: Kirigami.Theme.smallFont
                                opacity: 0.4
                                elide: Text.ElideRight
                            }
                        }
                        QQC2.ToolButton {
                            icon.name: "view-visible"
                            QQC2.ToolTip.text: i18nd("dev.xarbit.appgrid", "Unhide")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                            onClicked: page._unhide(modelData)
                        }
                    }
                }
            }
        }

        QQC2.Button {
            visible: (page.cfg_hiddenApps || []).length > 0
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignHCenter
            icon.name: "edit-undo"
            text: i18nd("dev.xarbit.appgrid", "Unhide All")
            onClicked: page.cfg_hiddenApps = []
        }
    }
}
