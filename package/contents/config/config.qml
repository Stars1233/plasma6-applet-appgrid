/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nc("@title:group", "General")
        icon: "preferences-desktop-plasma"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18nc("@title:group", "Appearance/Animations")
        icon: "preferences-desktop-theme-applications"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18nc("@title:group", "Search")
        icon: "system-search"
        source: "config/ConfigSearch.qml"
    }
    ConfigCategory {
        name: i18nc("@title:group", "Header Actions")
        icon: "configure-toolbars"
        source: "config/ConfigHeaderActions.qml"
    }
    ConfigCategory {
        name: i18nc("@title:group", "Hidden Apps")
        icon: "view-hidden"
        source: "config/ConfigHiddenApps.qml"
    }
}
