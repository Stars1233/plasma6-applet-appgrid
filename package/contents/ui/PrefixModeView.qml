/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Switcher for prefix mode views: help, terminal, command, files, info, hidden.
    Each mode is implemented in its own component under prefix/.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

import "prefix" as Prefix

Item {
    id: prefixView

    property string mode: ""
    property string argument: ""
    property Item searchField: null

    signal fileOpened()
    signal directoryNavigated(string path)

    function focusFileList() { fileBrowser.focusList() }
    function activateFileCurrent() { fileBrowser.activateCurrent() }

    // -- Help --
    Prefix.PrefixHelpView {
        anchors.fill: parent
        visible: prefixView.mode === "help"
    }

    // -- Terminal / Command --
    Prefix.PrefixCommandView {
        mode: prefixView.mode
        argument: prefixView.argument
        visible: prefixView.mode === "terminal" || prefixView.mode === "command"
    }

    // -- System info --
    Prefix.PrefixInfoView {
        anchors.fill: parent
        visible: prefixView.mode === "info"
    }

    // -- Hidden apps --
    Prefix.PrefixHiddenView {
        anchors.fill: parent
        visible: prefixView.mode === "hidden"
    }

    // -- File browser --
    Prefix.PrefixFileBrowser {
        id: fileBrowser
        anchors.fill: parent
        visible: prefixView.mode === "files"
        path: prefixView.argument
        searchField: prefixView.searchField
        onFileOpened: prefixView.fileOpened()
        onDirectoryNavigated: function(path) { prefixView.directoryNavigated(path) }
    }
}
