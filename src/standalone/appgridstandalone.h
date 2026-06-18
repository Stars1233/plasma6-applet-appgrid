/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>
#include <QString>

/**
 * @brief Single-instance D-Bus surface for the standalone `appgrid` executable.
 *
 * Registered on the session bus at service `dev.xarbit.appgrid`, object
 * `/Standalone`. A second invocation of the binary finds the service already
 * taken, calls Toggle() on the running instance and exits — so the daemon
 * behaves like KRunner (one process, toggled by a shortcut/launcher). The
 * Show/Hide/Toggle slots are exported as D-Bus methods and also emit the
 * matching Qt signals the QML entry connects to.
 */
class AppGridStandalone : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "dev.xarbit.appgrid.Standalone")

public:
    explicit AppGridStandalone(QObject *parent = nullptr);

    static QString serviceName();
    static QString objectPath();
    static QString interfaceName();

    /** True if registration succeeded (we are the primary instance). */
    bool registerService();

    /** Ask an already-running primary instance to toggle its window. Returns
     *  true if the call was dispatched. Used by a secondary invocation. */
    static bool callToggleOnRunningInstance();

    /** Ask an already-running primary instance to open its config window. */
    static bool callConfigureOnRunningInstance();

public Q_SLOTS:
    Q_SCRIPTABLE void Show();
    Q_SCRIPTABLE void Hide();
    Q_SCRIPTABLE void Toggle();
    Q_SCRIPTABLE void ToggleCompact();
    Q_SCRIPTABLE void Configure();
    /** Build version of this daemon — the plasmoid compares it against the
     *  installed build to detect a stale daemon left over from an upgrade. */
    Q_SCRIPTABLE QString Version() const;
    /** Quit the daemon (so a freshly-installed build can take its place). */
    Q_SCRIPTABLE void Quit();

Q_SIGNALS:
    void showRequested();
    void hideRequested();
    void toggleRequested();
    void toggleCompactRequested();
    void configureRequested();
    void quitRequested();
};
