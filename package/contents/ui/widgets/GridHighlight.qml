/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Themed highlight rectangle shared by AppGridView (mounted via
    GridView.highlight) and CategoryGridView (per-delegate, manually
    visibility-gated). Visibility and position belong to the consumer;
    this component only owns the look.
*/

import QtQuick
import org.kde.kirigami as Kirigami

import "../js/themecolors.js" as ThemeColors

Rectangle {
    property real cellWidth: 0
    property real cellHeight: 0

    anchors.centerIn: parent
    width: cellWidth - Kirigami.Units.smallSpacing * 2
    height: cellHeight - Kirigami.Units.smallSpacing * 2
    radius: Kirigami.Units.cornerRadius
    color: ThemeColors.tint(Kirigami.Theme.highlightColor, 0.2)
    border.width: 1
    border.color: ThemeColors.tint(Kirigami.Theme.highlightColor, 0.6)
}
