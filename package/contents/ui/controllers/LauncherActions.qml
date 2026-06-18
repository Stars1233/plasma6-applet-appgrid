/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Context-menu actions that touch other Plasma surfaces (Task Manager,
    Desktop) or invoke external editors. "Add to Desktop" / "Pin to Task
    Manager" go through the injected bridge (the plasmoid forwards to the
    controller; the standalone calls the controller directly), which scripts
    plasmashell over D-Bus — Kicker's in-process ContainmentInterface needs a
    live applet + corona and so silently no-ops in the standalone process.
    KMenuEdit is just a process launch, so it stays on Kicker's ProcessRunner.
*/

import QtQuick
import org.kde.plasma.private.kicker as Kicker

QtObject {
    id: root

    // plasmoidBridge (panel variant) or appGridController (standalone): both
    // expose addToTaskManager(desktopFile) / addToDesktop(desktopFile).
    required property var actions

    function pinToTaskManager(desktopFile) {
        if (desktopFile)
            root.actions.addToTaskManager(desktopFile)
    }
    function addToDesktop(desktopFile) {
        if (desktopFile)
            root.actions.addToDesktop(desktopFile)
    }
    // Capability probes — the menu hides actions that would no-op. Default true
    // if the injected bridge predates them (test stubs).
    function canPinToTaskManager() {
        return root.actions.canPinToTaskManager ? root.actions.canPinToTaskManager() : true
    }
    function canAddToDesktop() {
        return root.actions.canAddToDesktop ? root.actions.canAddToDesktop() : true
    }
    // KMenuEdit takes either an app storage id or a menu group path — same
    // call, the editor figures out the type. Empty string opens at root.
    function editMenuItem(itemId) {
        _runner.runMenuEditor(itemId || "")
    }

    // Typed as `var` — namespaced typenames trip QML 2's strict
    // property-type check even though they refer to the same C++ class.
    readonly property var _runner: Kicker.ProcessRunner {}
}
