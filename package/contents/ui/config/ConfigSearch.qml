/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Thin Plasma-dialog wrapper around ConfigSearchContent: hosts the shared,
    Plasmoid-free body and feeds it directly from Plasmoid. Writes go straight
    to Plasmoid.configuration (live; the cfg_ buffering is gone — acceptable).
*/

import QtQuick

import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: page

    ConfigSearchContent {
        configuration: Plasmoid.configuration
    }
}
