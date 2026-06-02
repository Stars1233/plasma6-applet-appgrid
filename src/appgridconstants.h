/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QString>

namespace AppGrid
{
/** Application id. APPGRID_APP_ID is injected by CMake so the translation
 *  domain, the KActivities agent id, and this constant all derive from one
 *  value in CMakeLists.txt. */
inline constexpr QLatin1String ApplicationId{APPGRID_APP_ID};
}
