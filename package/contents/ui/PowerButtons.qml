/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Power and session management buttons using Kicker.SystemModel.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

RowLayout {
    id: powerButtons

    signal actionTriggered()
    function closeMenus() { sessionMenu.close() }

    spacing: Kirigami.Units.smallSpacing
    readonly property bool showLabels: Plasmoid.configuration.showActionLabels

    // KDE native session model — provides Sleep, Restart, Shut Down, Lock, Log Out, Switch User
    Kicker.SystemModel {
        id: systemModel
        Component.onCompleted: refresh()
    }

    // Map system model entries to our button layout
    // Primary buttons: Sleep, Restart, Shut Down
    // Session menu: Lock, Log Out, Switch User
    readonly property var primaryActions: {
        var actions = []
        var menuActions = []
        for (var i = 0; i < systemModel.count; i++) {
            var item = systemModel.data(systemModel.index(i, 0), Qt.DisplayRole)
            var icon = systemModel.data(systemModel.index(i, 0), Qt.DecorationRole)
            var entry = { index: i, label: item || "", icon: icon || "" }

            // Match by icon name to determine primary vs menu actions
            var iconStr = String(icon)
            if (iconStr.indexOf("suspend") >= 0 || iconStr.indexOf("reboot") >= 0 || iconStr.indexOf("shutdown") >= 0)
                actions.push(entry)
            else
                menuActions.push(entry)
        }
        return { primary: actions, menu: menuActions }
    }

    Repeater {
        model: powerButtons.primaryActions.primary
        delegate: PlasmaComponents.ToolButton {
            required property var modelData
            icon.name: modelData.icon
            text: powerButtons.showLabels ? modelData.label : ""
            display: powerButtons.showLabels ? PlasmaComponents.AbstractButton.TextBesideIcon
                                             : PlasmaComponents.AbstractButton.IconOnly
            PlasmaComponents.ToolTip.text: modelData.label
            PlasmaComponents.ToolTip.visible: !powerButtons.showLabels && hovered
            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            onClicked: {
                systemModel.trigger(modelData.index, "", null)
                powerButtons.actionTriggered()
            }

            Accessible.name: modelData.label
            Accessible.role: Accessible.Button
        }
    }

    PlasmaComponents.ToolButton {
        id: sessionButton
        visible: powerButtons.primaryActions.menu.length > 0
        icon.name: "system-log-out"
        text: powerButtons.showLabels ? i18nd("dev.xarbit.appgrid", "Session") : ""
        display: powerButtons.showLabels ? PlasmaComponents.AbstractButton.TextBesideIcon
                                         : PlasmaComponents.AbstractButton.IconOnly
        PlasmaComponents.ToolTip.text: i18nd("dev.xarbit.appgrid", "Session")
        PlasmaComponents.ToolTip.visible: !powerButtons.showLabels && hovered
        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
        checked: sessionMenu.visible
        onClicked: sessionMenu.visible ? sessionMenu.close() : sessionMenu.open()

        Accessible.name: i18nd("dev.xarbit.appgrid", "Session")
        Accessible.role: Accessible.Button

        PlasmaComponents.Menu {
            id: sessionMenu
            y: sessionButton.height

            Instantiator {
                model: powerButtons.primaryActions.menu
                delegate: PlasmaComponents.MenuItem {
                    required property var modelData
                    icon.name: modelData.icon
                    text: modelData.label
                    onClicked: {
                        systemModel.trigger(modelData.index, "", null)
                        powerButtons.actionTriggered()
                    }
                    Accessible.name: modelData.label
                    Accessible.role: Accessible.MenuItem
                }
                onObjectAdded: (index, object) => sessionMenu.insertItem(index, object)
                onObjectRemoved: (index, object) => sessionMenu.removeItem(object)
            }
        }
    }
}
