/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Animated overlay for the shuffle icon swap effect.
    Two icons fly along arc paths to each other's positions.
*/

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: overlay

    property real iconSize: Kirigami.Units.iconSizes.huge

    signal swapFinished(int fromIndex, int toIndex, string fromIcon, string toIcon)

    property int pendingFromIndex: -1
    property int pendingToIndex: -1
    property string pendingFromIcon: ""
    property string pendingToIcon: ""

    function startAnim(fromX, fromY, toX, toY, fromIcon, toIcon, fromIndex, toIndex) {
        pendingFromIndex = fromIndex
        pendingToIndex = toIndex
        pendingFromIcon = fromIcon
        pendingToIcon = toIcon

        flyA.width = iconSize
        flyA.height = iconSize
        flyA.source = fromIcon
        flyA.x = fromX
        flyA.y = fromY
        flyA.visible = true
        flyA.opacity = 0.9

        flyB.width = iconSize
        flyB.height = iconSize
        flyB.source = toIcon
        flyB.x = toX
        flyB.y = toY
        flyB.visible = true
        flyB.opacity = 0.9

        flyAnim.fromX = fromX; flyAnim.fromY = fromY
        flyAnim.toX = toX;     flyAnim.toY = toY
        flyAnim.start()
    }

    Kirigami.Icon {
        id: flyA
        visible: false
        z: 1
    }

    Kirigami.Icon {
        id: flyB
        visible: false
        z: 1
    }

    ParallelAnimation {
        id: flyAnim
        property real fromX: 0
        property real fromY: 0
        property real toX: 0
        property real toY: 0
        readonly property real midY: Math.min(fromY, toY) - overlay.iconSize * 0.6

        // Icon A flies to B's position via arc
        SequentialAnimation {
            NumberAnimation { target: flyA; property: "x"; from: flyAnim.fromX; to: flyAnim.toX; duration: 350; easing.type: Easing.InOutQuad }
        }
        SequentialAnimation {
            NumberAnimation { target: flyA; property: "y"; from: flyAnim.fromY; to: flyAnim.midY; duration: 175; easing.type: Easing.OutQuad }
            NumberAnimation { target: flyA; property: "y"; from: flyAnim.midY; to: flyAnim.toY; duration: 175; easing.type: Easing.InQuad }
        }

        // Icon B flies to A's position via arc
        SequentialAnimation {
            NumberAnimation { target: flyB; property: "x"; from: flyAnim.toX; to: flyAnim.fromX; duration: 350; easing.type: Easing.InOutQuad }
        }
        SequentialAnimation {
            NumberAnimation { target: flyB; property: "y"; from: flyAnim.toY; to: flyAnim.midY; duration: 175; easing.type: Easing.OutQuad }
            NumberAnimation { target: flyB; property: "y"; from: flyAnim.midY; to: flyAnim.fromY; duration: 175; easing.type: Easing.InQuad }
        }

        onFinished: {
            flyA.visible = false
            flyB.visible = false
            overlay.swapFinished(overlay.pendingFromIndex,
                                 overlay.pendingToIndex,
                                 overlay.pendingFromIcon,
                                 overlay.pendingToIcon)
        }
    }
}
