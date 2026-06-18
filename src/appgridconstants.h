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

/** D-Bus single-instance surface of the standalone `appgrid` daemon
 *  (src/standalone): the daemon registers/exports it, the plasmoid toggles the
 *  daemon through it. One source so the two never drift. */
namespace Dbus
{
inline constexpr QLatin1String Service{APPGRID_APP_ID};
inline constexpr QLatin1String Path{"/Standalone"};
inline constexpr QLatin1String Interface{APPGRID_APP_ID ".Standalone"};
// Method names exported by AppGridStandalone — must match its Q_SCRIPTABLE slots.
inline constexpr QLatin1String MethodToggle{"Toggle"};
inline constexpr QLatin1String MethodToggleCompact{"ToggleCompact"};
inline constexpr QLatin1String MethodConfigure{"Configure"};
inline constexpr QLatin1String MethodVersion{"Version"};
inline constexpr QLatin1String MethodQuit{"Quit"};
}

/** The standalone daemon executable and the launch flags the plasmoid passes and
 *  the daemon parses. One source so the producer (AppGridPlugin) and the consumer
 *  (src/standalone/main.cpp) never drift. */
namespace Standalone
{
inline constexpr QLatin1String Executable{"appgrid"};
inline constexpr QLatin1String FlagFromPlasmoid{"--from-plasmoid"};
inline constexpr QLatin1String FlagConfigure{"--configure"};
inline constexpr QLatin1String FlagCompact{"--compact"};
// Replace a running (stale) daemon instead of forwarding to it — used by the
// plasmoid when the running daemon's version differs from the installed build.
inline constexpr QLatin1String FlagReplace{"--replace"};
}

/** KWin's session D-Bus surface. Queried for the active output to place the
 *  launcher on the right screen (the same source KRunner uses). */
namespace KWinDbus
{
inline constexpr QLatin1String Service{"org.kde.KWin"};
inline constexpr QLatin1String Path{"/KWin"};
inline constexpr QLatin1String Interface{"org.kde.KWin"};
inline constexpr QLatin1String ActiveOutputName{"activeOutputName"};
}

/** D-Bus helper the center plasmoid exports so the standalone daemon can ask it
 *  to run an in-process action that needs a live Plasma::Applet + corona — which
 *  the daemon's own process lacks. Pinning to the Task Manager (with activities)
 *  goes through Kicker's ContainmentInterface, reachable only with an applet. */
namespace PlasmoidDbus
{
inline constexpr QLatin1String Service{APPGRID_APP_ID ".plasmoid"};
inline constexpr QLatin1String Path{"/Plasmoid"};
inline constexpr QLatin1String Interface{APPGRID_APP_ID ".Plasmoid"};
inline constexpr QLatin1String AddToTaskManager{"requestAddToTaskManager"};
inline constexpr QLatin1String PanelScreenName{"panelScreenName"};
}

/** Keys for reading the Plasma shell layout (which desktops/containments exist).
 *  Used to tell whether a Folder View desktop is present to show a dropped
 *  .desktop launcher. */
namespace ShellLayout
{
inline constexpr QLatin1String AppletsConfig{"plasma-org.kde.plasma.desktop-appletsrc"};
inline constexpr QLatin1String ContainmentsGroup{"Containments"};
inline constexpr QLatin1String PluginKey{"plugin"};
inline constexpr QLatin1String FolderViewPlugin{"org.kde.plasma.folder"};
}
}
