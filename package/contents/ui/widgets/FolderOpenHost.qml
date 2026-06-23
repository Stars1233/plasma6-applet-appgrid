/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Hosts an open favourites folder as a centered overlay card over the grid,
    wrapping a FolderContentsView (issue #18). Drag a member onto the area
    outside the card removes it from the folder.
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents

Item {
    id: host

    property string folderName: ""
    property var members: []
    property var appsModel: null
    property var sharedFavoritesModel: null
    property int favoriteIdRole: -1
    property var dragSource: null
    property real iconSize: Kirigami.Units.iconSizes.large
    property real fontScale: 1.0
    property bool shadowEnabled: false
    property bool reduceGridSpacing: false
    property int hoverAnimation: 0
    property bool hoverHighlight: true
    property bool showScrollbars: false
    // Main grid's column count + cell size, passed in by the host (the default is
    // a placeholder). The folder uses one fewer column at the same cell size, so
    // it fits with a drag-out margin (#18).
    property int columns: 5
    property real cellWidth: 0
    property real cellHeight: 0

    signal closeRequested()
    signal memberLaunched(string sid)
    signal memberRemoveRequested(string sid)
    signal memberContextRequested(string sid, string desktopFile)
    signal memberReorderRequested(int fromIndex, int toIndex)

    // The card spans at most this fraction of the grid's height; the content is
    // one column narrower than the grid so width rarely binds, but this caps it
    // just shy of the edges as a backstop.
    readonly property real _overlayFraction: 0.85
    readonly property real _overlayMaxWidthFraction: 0.98

    focus: true
    // Esc closes just the folder. The inner grid holds focus, so this catches the
    // Esc that bubbles up from it.
    Keys.onEscapePressed: closeRequested()

    // Give keyboard focus to the grid (not this host) and preselect the first
    // member, so arrow keys navigate and Enter launches right away on a keyboard
    // open. Runs after the child grid has built its model (children complete first).
    Component.onCompleted: {
        if (contents.count > 0)
            contents.currentIndex = 0
        contents.forceActiveFocus()
    }

    // Transparent catcher behind the card: tap outside to close, no dim. Uses a
    // hover-enabled MouseArea (not a bare TapHandler) so it also swallows hover
    // events — otherwise the grid underneath keeps showing its highlight through
    // the open folder (#200).
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: host.closeRequested()
        // Swallow wheel over the area outside the card so it can't scroll the
        // favourites grid behind the open folder (#200).
        onWheel: wheel => wheel.accepted = true
    }

    // Drop a member onto the area outside the card → remove it from the folder.
    DropArea {
        anchors.fill: parent
        onDropped: drag => {
            if (!host.dragSource || !host.dragSource.isOwnDrag(drag))
                return
            const sid = host.dragSource.sourceStorageId
            if (!sid)
                return
            const inCard = drag.x >= card.x && drag.x <= card.x + card.width
                        && drag.y >= card.y && drag.y <= card.y + card.height
            if (!inCard)
                host.memberRemoveRequested(sid)
        }
    }

    // Native themed card: the theme's "widgets/background" frame svg, the same
    // raised surface Plasma uses for floating panels — so fill, rounded corners
    // and the soft shadow all come from the active theme, no hand tinting.
    KSvg.FrameSvgItem {
        id: card

        imagePath: "widgets/background"

        // Content padding = the frame's own border/shadow margins plus a little
        // breathing room, so the grid never sits under the rounded edge or shadow.
        readonly property real _padLeft: margins.left + Kirigami.Units.largeSpacing
        readonly property real _padRight: margins.right + Kirigami.Units.largeSpacing
        readonly property real _padTop: margins.top + Kirigami.Units.largeSpacing
        readonly property real _padBottom: margins.bottom + Kirigami.Units.largeSpacing

        // Centered, sized to the content (one column narrower than the grid, so it
        // already fits with a drag-out margin). Height caps so a big folder scrolls.
        readonly property real _overlayWidth: Math.min(parent.width * host._overlayMaxWidthFraction,
                                                        contents.implicitWidth + _padLeft + _padRight)
        readonly property real _overlayHeight: Math.min(parent.height * host._overlayFraction,
                                                         header.implicitHeight + contents.implicitHeight
                                                         + _padTop + _padBottom + Kirigami.Units.largeSpacing)

        anchors.centerIn: parent
        width: _overlayWidth
        height: _overlayHeight

        // Absorb stray clicks on the card chrome (title, gaps) so they don't fall
        // through to the click-catcher behind and close the folder.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {}
            onPressed: {}
            // When the folder grid doesn't scroll (content fits), wheel events fall
            // through to here; swallow them so they don't reach the grid behind.
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: card._padLeft
            anchors.rightMargin: card._padRight
            anchors.topMargin: card._padTop
            anchors.bottomMargin: card._padBottom
            spacing: Kirigami.Units.largeSpacing

            Item {
                id: header
                Layout.fillWidth: true
                implicitHeight: closeButton.implicitHeight

                PlasmaComponents.Label {
                    // Centered across the whole card; kept clear of the close
                    // button so a long name never runs under it.
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - closeButton.width * 2 - Kirigami.Units.smallSpacing * 2)
                    text: host.folderName
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                PlasmaComponents.ToolButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon.name: "window-close-symbolic"
                    onClicked: host.closeRequested()
                }
            }

            FolderContentsView {
                id: contents
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                Layout.alignment: Qt.AlignHCenter
                members: host.members
                appsModel: host.appsModel
                sharedFavoritesModel: host.sharedFavoritesModel
                favoriteIdRole: host.favoriteIdRole
                dragSource: host.dragSource
                preferredColumns: Math.max(1, host.columns - 1)
                mainCellWidth: host.cellWidth
                mainCellHeight: host.cellHeight
                iconSize: host.iconSize
                fontScale: host.fontScale
                shadowEnabled: host.shadowEnabled
                reduceGridSpacing: host.reduceGridSpacing
                hoverAnimation: host.hoverAnimation
                hoverHighlight: host.hoverHighlight
                showScrollbars: host.showScrollbars
                onMemberLaunched: sid => host.memberLaunched(sid)
                onMemberContextRequested: (sid, df) => host.memberContextRequested(sid, df)
                onMemberReorderRequested: (from, to) => host.memberReorderRequested(from, to)
            }
        }
    }
}
