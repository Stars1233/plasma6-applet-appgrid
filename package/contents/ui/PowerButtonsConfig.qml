/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Settings widget for the power/session buttons: drag-reorder the four
    top-level slots, show/hide each, and show/hide the Session dropdown's
    Lock / Log Out / Switch User items. Shared by both config pages — it
    takes the current config values in and emits `edited` with the new
    ones, leaving the KCM cfg_ plumbing to the page.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var buttonOrder: []
    property var hiddenButtons: []

    signal edited(var newOrder, var newHidden)

    spacing: Kirigami.Units.smallSpacing

    readonly property var slotLabels: ({
        "sleep": i18nd("dev.xarbit.appgrid", "Sleep"),
        "restart": i18nd("dev.xarbit.appgrid", "Restart"),
        "shutdown": i18nd("dev.xarbit.appgrid", "Shut Down"),
        "session": i18nd("dev.xarbit.appgrid", "Session"),
        "lock": i18nd("dev.xarbit.appgrid", "Lock"),
        "logout": i18nd("dev.xarbit.appgrid", "Log Out"),
        "switchuser": i18nd("dev.xarbit.appgrid", "Switch User")
    })

    readonly property var defaultSlotOrder: ["sleep", "restart", "shutdown", "session"]

    function _isHidden(id) {
        return (root.hiddenButtons || []).indexOf(id) >= 0
    }
    function _setHidden(id, hide) {
        var h = (root.hiddenButtons || []).slice()
        var i = h.indexOf(id)
        if (hide && i < 0)
            h.push(id)
        else if (!hide && i >= 0)
            h.splice(i, 1)
        root.edited(_currentOrder(), h)
    }

    // ListModel mirror of buttonOrder — a StringList can't drive a ListView.
    ListModel { id: orderModel }
    function _currentOrder() {
        var arr = []
        for (var i = 0; i < orderModel.count; i++)
            arr.push(orderModel.get(i).slotId)
        return arr
    }
    function _sameOrder(a, b) {
        if (a.length !== b.length)
            return false
        for (var i = 0; i < a.length; i++)
            if (a[i] !== b[i])
                return false
        return true
    }
    function _syncModel() {
        // Empty config means the default order.
        var target = (root.buttonOrder && root.buttonOrder.length > 0)
                     ? root.buttonOrder : defaultSlotOrder
        // Skip the rebuild when the model already matches — our own drag
        // round-trips back through cfg_, and clearing the model mid-drop
        // makes the reorder unreliable.
        if (_sameOrder(_currentOrder(), target))
            return
        orderModel.clear()
        for (var i = 0; i < target.length; i++)
            orderModel.append({ slotId: target[i] })
    }
    onButtonOrderChanged: _syncModel()
    Component.onCompleted: _syncModel()

    QQC2.Label {
        text: i18nd("dev.xarbit.appgrid", "Reorder with the arrows; untick to hide.")
        font: Kirigami.Theme.smallFont
        opacity: 0.8
    }

    function _move(from, to) {
        orderModel.move(from, to, 1)
        root.edited(root._currentOrder(), root.hiddenButtons)
    }

    Repeater {
        model: orderModel
        delegate: RowLayout {
            id: slotRow
            Layout.fillWidth: true
            required property int index
            required property string slotId
            spacing: Kirigami.Units.smallSpacing

            QQC2.ToolButton {
                icon.name: "arrow-up"
                display: QQC2.AbstractButton.IconOnly
                enabled: slotRow.index > 0
                onClicked: root._move(slotRow.index, slotRow.index - 1)
            }
            QQC2.ToolButton {
                icon.name: "arrow-down"
                display: QQC2.AbstractButton.IconOnly
                enabled: slotRow.index < orderModel.count - 1
                onClicked: root._move(slotRow.index, slotRow.index + 1)
            }
            QQC2.CheckBox {
                Layout.fillWidth: true
                text: root.slotLabels[slotRow.slotId] || slotRow.slotId
                checked: !root._isHidden(slotRow.slotId)
                onToggled: root._setHidden(slotRow.slotId, !checked)
            }
        }
    }

    QQC2.Label {
        Layout.topMargin: Kirigami.Units.smallSpacing
        text: i18nd("dev.xarbit.appgrid", "Session menu items:")
        font: Kirigami.Theme.smallFont
        opacity: 0.8
    }

    Repeater {
        model: ["lock", "logout", "switchuser"]
        delegate: QQC2.CheckBox {
            required property string modelData
            text: root.slotLabels[modelData]
            checked: !root._isHidden(modelData)
            onToggled: root._setHidden(modelData, !checked)
        }
    }
}
