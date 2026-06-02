/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "appgridplugin.h"

// No embedded JSON: the plasmoid package's metadata.json (installed via
// plasma_install_package) is the authoritative applet metadata Plasma reads.
K_PLUGIN_CLASS(AppGridPlugin)

#include "appgridplugin_register.moc"
