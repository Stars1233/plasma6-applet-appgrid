/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    A little extra context for a certain well-known number: when the search
    query is exactly 6 * 7 and the unified results are showing, surface a
    clickable row with the Answer. Self-contained so GridPanel's view tree
    stays about the real launcher chrome.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.ItemDelegate {
    id: root

    // The live search text and whether the unified results view owns the screen
    // (search active, not a prefix mode) — the row only shows then.
    property string queryText: ""
    property bool resultsActive: false
    property real iconSize: Kirigami.Units.iconSizes.large

    Layout.fillWidth: true
    leftPadding: Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.largeSpacing
    visible: root.resultsActive && Number(root.queryText.trim()) === 6 * 7
    implicitHeight: Math.max(root.iconSize, _answerRow.implicitHeight) + Kirigami.Units.smallSpacing * 2
    onClicked: Qt.openUrlExternally("https://en.wikipedia.org/wiki/Phrases_from_The_Hitchhiker%27s_Guide_to_the_Galaxy")

    contentItem: RowLayout {
        id: _answerRow
        spacing: Kirigami.Units.largeSpacing

        Text {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Math.round(root.iconSize * 0.8)
            text: "🌍"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: "42"
                font.bold: true
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                // Intentionally left untranslated (not localizable copy).
                text: "The Answer to the Ultimate Question of Life, the Universe, and Everything"
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                elide: Text.ElideRight
            }
        }
    }
}
