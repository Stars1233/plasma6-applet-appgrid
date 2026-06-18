/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Runs "Pin to Task Manager" in-process for both plasmoid variants. Kicker's
    ContainmentInterface needs a live applet + corona (and handles activities),
    which a separate process can't reach — so the C++ applet emits
    addToTaskManagerRequested (from the panel's own menu, or the daemon's request
    over D-Bus) and this turns it into the real addLauncher call.
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

QtObject {
    id: pinner

    // The root PlasmoidItem — ContainmentInterface resolves the applet/corona
    // through it (same object the menu passed Kicker before).
    required property var applet

    // Typed `var`: the namespaced typename trips QML 2's strict property check.
    readonly property var _ci: Kicker.ContainmentInterface {}

    property Connections _conn: Connections {
        target: Plasmoid
        function onAddToTaskManagerRequested(desktopFile) {
            if (desktopFile)
                pinner._ci.addLauncher(pinner.applet, Kicker.ContainmentInterface.TaskManager, desktopFile)
        }
    }
}
