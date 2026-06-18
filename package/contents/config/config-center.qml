/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Center variant's applet config model. The launcher itself runs as the
    standalone daemon and is configured from its own settings window, so the
    Plasma applet config keeps only the panel button's appearance (icon + label).
    Plasma appends Keyboard Shortcuts and About automatically.
*/

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nc("@title:group", "General")
        icon: "preferences-desktop-plasma"
        source: "config/ConfigButton.qml"
    }
}
