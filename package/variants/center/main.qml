/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Root plasmoid item for the center variant: just the panel icon. Activating it
    toggles the standalone `appgrid` daemon's window over D-Bus (launching the
    daemon if needed) — the launcher window runs in its own process so KWin can
    animate it with any window open/close effect, like KRunner. See src/standalone
    and AppGridPlugin::toggleStandaloneWindow().
*/

import QtQuick
import org.kde.plasma.plasmoid

import "controllers"
import "js/migrations.js" as Migrations

PlasmoidItem {
    id: appgrid

    compactRepresentation: compactRepresentationComponent
    fullRepresentation: Item {}
    preferredRepresentation: compactRepresentation

    activationTogglesExpanded: false

    // The launcher's settings live in its own window (the daemon): opened from
    // the gear in the launcher header, or the "Configure Launcher…" button on the
    // General tab of this plasmoid's Plasma config (ConfigButton.qml). No separate
    // context-menu entry — Plasma's own "Configure AppGrid…" covers the applet.

    ConfigCache { id: cfg; source: Plasmoid.configuration }

    Plasmoid.icon: cfg.useCustomButtonImage ? cfg.customButtonImage : cfg.icon

    Component.onCompleted: {
        Migrations.migrateLauncherIcon(Plasmoid.configuration)
        // One-shot: hand the user's existing settings to the daemon's appgridrc.
        Plasmoid.migrateConfigToStandalone()
    }

    Component {
        id: compactRepresentationComponent
        CompactRepresentation {
            formFactor: Plasmoid.formFactor
            title: Plasmoid.title
            configuration: Plasmoid.configuration
            onActivated: Plasmoid.toggleStandaloneWindow()
        }
    }

    Connections {
        target: Plasmoid
        function onActivated() { Plasmoid.toggleStandaloneWindow() }
        // Secondary "Open in Compact Mode" shortcut → daemon's ToggleCompact.
        function onCompactActivated() { Plasmoid.toggleStandaloneWindowCompact() }
    }

    // Runs the daemon's "Pin to Task Manager" in this applet's process (it has the
    // corona Kicker needs); the daemon reaches us via the plasmoid D-Bus helper.
    TaskManagerPinner { applet: appgrid }
}
