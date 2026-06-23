/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    The contents of one open folder: a small grid of its member apps, reusing the
    same AppIconDelegate as the main grid so launch, icons and labels match
    (issue #18). Source-agnostic: it is handed member storageIds and resolves them
    through the app model. Members can be dragged to reorder within the folder
    (animated, like the main grid), or out of it (the host handles drop-outside).

    Reorder runs against an internal ListModel mirroring `members`, so live
    ListModel.move() during the drag animates via the move/moveDisplaced
    transitions; the final order is committed to the real model on drop.
*/

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../js/constants.js" as Const
import "../js/favoritevisual.js" as FavoriteVisual
import "../js/gridmetrics.js" as GridMetrics

GridView {
    id: root

    // Bare member storageIds, in order.
    property var members: []
    property var appsModel: null
    // For resolving KCM members the app model doesn't know (#64).
    property var sharedFavoritesModel: null
    property int favoriteIdRole: -1
    // Shared DragSource so a member can be dragged out of the folder (#18).
    property var dragSource: null
    property real iconSize: Kirigami.Units.iconSizes.large
    property real fontScale: 1.0
    property bool shadowEnabled: false
    property bool reduceGridSpacing: false
    property int hoverAnimation: 0
    property bool hoverHighlight: true
    property bool showScrollbars: false
    property int preferredColumns: 4
    // The main grid's cell size; when set the folder reuses it so cells line up
    // with the grid exactly. Falls back to icon-derived metrics otherwise.
    property real mainCellWidth: 0
    property real mainCellHeight: 0

    signal memberLaunched(string sid)
    signal memberContextRequested(string sid, string desktopFile)
    signal memberReorderRequested(int fromIndex, int toIndex)

    readonly property int _cols: Math.max(1, Math.min(preferredColumns, members.length))

    cellWidth: mainCellWidth > 0 ? mainCellWidth
               : GridMetrics.labelledCellWidth(iconSize, Kirigami.Units.gridUnit,
                                               Kirigami.Units.smallSpacing, fontScale, reduceGridSpacing)
    cellHeight: mainCellHeight > 0 ? mainCellHeight
                : GridMetrics.labelledCellHeight(iconSize, Kirigami.Units.gridUnit,
                                                 Kirigami.Units.smallSpacing, fontScale)

    // Fixed width = exactly _cols columns, so it never reflows to fewer.
    implicitWidth: _cols * cellWidth
    width: implicitWidth
    implicitHeight: Math.ceil(members.length / _cols) * cellHeight

    interactive: contentHeight > height
    clip: true
    focus: true
    keyNavigationEnabled: true

    PlasmaComponents.ScrollBar.vertical: OverlayScrollBar { showScrollbars: root.showScrollbars }

    // Live reorder model: a mirror of `members` we mutate during a drag so the
    // grid animates. True while a member of this folder is being dragged here, to
    // hold off rebuilding from an external `members` change mid-shuffle.
    property bool _reordering: false

    model: ListModel { id: orderModel }

    // Rebuild on external changes (add/remove member) but not when members just
    // caught up to a reorder we already animated — that would reset the model and
    // flicker for no visible change.
    onMembersChanged: if (!_reordering && !_orderMatches()) _rebuild()
    Component.onCompleted: _rebuild()

    function _rebuild() {
        orderModel.clear()
        for (let i = 0; i < members.length; ++i)
            orderModel.append({ sid: members[i] })
    }

    function _orderMatches() {
        if (orderModel.count !== members.length)
            return false
        for (let i = 0; i < members.length; ++i) {
            if (orderModel.get(i).sid !== members[i])
                return false
        }
        return true
    }

    function _indexOfSid(sid) {
        for (let i = 0; i < orderModel.count; ++i) {
            if (orderModel.get(i).sid === sid)
                return i
        }
        return -1
    }

    // Animate items sliding to their new slots during a reorder.
    move: Transition {
        NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
    }
    moveDisplaced: Transition {
        NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
    }

    delegate: Item {
        id: cell
        width: root.cellWidth
        height: root.cellHeight

        required property int index
        required property string sid

        readonly property var _appData: root.appsModel ? root.appsModel.getByStorageId(sid) : null
        readonly property var _vis: FavoriteVisual.resolve(root.appsModel, root.sharedFavoritesModel,
                                                           root.favoriteIdRole, sid, Const.DEFAULT_ICON)

        AppIconDelegate {
            anchors.fill: parent
            appName: cell._vis.name
            appIcon: cell._vis.icon
            appGenericName: cell._appData ? (cell._appData.genericName || "") : ""
            appComment: cell._appData ? (cell._appData.comment || "") : ""
            storageId: cell.sid
            desktopFile: cell._appData ? (cell._appData.desktopFile || "") : ""
            dragSource: root.dragSource
            iconSize: root.iconSize
            fontScale: root.fontScale
            hoverAnimation: root.hoverAnimation
            shadowEnabled: root.shadowEnabled
            hoverHighlight: root.hoverHighlight
            isCurrentItem: root.currentIndex === cell.index && root.activeFocus
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.memberContextRequested(cell.sid,
                        cell._appData ? (cell._appData.desktopFile || "") : "")
                else
                    root.memberLaunched(cell.sid)
            }
        }
    }

    // Launch the focused member by its rendered (orderModel) row — currentIndex
    // indexes the live model, which may differ from `members` after a reorder.
    Keys.onReturnPressed: if (currentIndex >= 0) memberLaunched(orderModel.get(currentIndex).sid)
    Keys.onEnterPressed: if (currentIndex >= 0) memberLaunched(orderModel.get(currentIndex).sid)

    // Reorder members by dragging one over another's cell: the order updates live
    // (animated) and commits on drop. Sits behind the delegates (z: -1) so clicks
    // still reach icons. A drop outside the grid (drag-out) is handled by the
    // host's own DropArea, not this one (#18).
    DropArea {
        anchors.fill: parent
        z: -1
        enabled: root.dragSource !== null

        // The storageId of the member currently being dragged within this folder,
        // or "" when the drag isn't one of our members.
        function _draggedMember(drag) {
            if (!root.dragSource || !root.dragSource.isOwnDrag(drag))
                return ""
            const sid = root.dragSource.sourceStorageId
            return (sid && root.members.indexOf(sid) >= 0) ? sid : ""
        }

        onPositionChanged: drag => {
            const sid = _draggedMember(drag)
            if (!sid)
                return
            root._reordering = true
            const from = root._indexOfSid(sid)
            let to = root.indexAt(root.contentX + drag.x, root.contentY + drag.y)
            if (to >= 0 && to !== from)
                orderModel.move(from, to, 1)
        }

        onExited: {
            // Cursor left the grid (e.g. heading for a drag-out): drop the live
            // preview and restore the committed order.
            if (root._reordering) {
                root._reordering = false
                root._rebuild()
            }
        }

        onDropped: drag => {
            const sid = _draggedMember(drag)
            root._reordering = false
            if (!sid) {
                _rebuild()
                return
            }
            const from = root.members.indexOf(sid)
            const to = root._indexOfSid(sid)
            if (to >= 0 && to !== from)
                root.memberReorderRequested(from, to)
            else
                _rebuild()  // unchanged — snap the preview back
        }
    }
}
