/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Root plasmoid item: panel icon + custom Window lifecycle.
    Display modes: fullscreen overlay (0) or centered popup (1).
*/

import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: kicker

    compactRepresentation: compactRepresentationComponent
    fullRepresentation: Item {}
    preferredRepresentation: compactRepresentation

    activationTogglesExpanded: false

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage
        ? Plasmoid.configuration.customButtonImage
        : Plasmoid.configuration.icon

    property GridWindow gridWindow: null
    property bool gridOpen: false

    // Shared drag proxy carrying the grab image and mime data while a
    // delegate's DragHandler is active. The same pattern Kickoff uses (see
    // its `dragSource` in main.qml + BUG 449426) — keeps the platform DnD
    // alive even when GridView recycles the dragged delegate.
    readonly property Item favoritesDragProxy: Item {
        id: dragSource
        property Item sourceItem
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.MoveAction | Qt.CopyAction | Qt.LinkAction
    }

    Component {
        id: compactRepresentationComponent
        CompactRepresentation {}
    }

    Connections {
        target: Plasmoid
        function onActivated() { kicker.toggleWindow() }
    }


    function destroyGridWindow() {
        if (gridWindow) {
            gridWindow.visible = false
            gridWindow.destroy()
            gridWindow = null
        }
        gridOpen = false
    }

    function toggleWindow() {
        if (gridOpen) {
            closeWindow()
        } else {
            openWindow()
        }
    }

    function openWindow() {
        gridOpen = true
        if (!gridWindow)
            gridWindow = gridWindowComponent.createObject(kicker, { appletInterface: kicker })
        gridWindow.showGrid()
    }

    function closeWindow() {
        gridOpen = false
        if (gridWindow)
            gridWindow.closeGrid()
    }

    Component {
        id: gridWindowComponent
        GridWindow {}
    }
}
