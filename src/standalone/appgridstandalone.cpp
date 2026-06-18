/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "appgridstandalone.h"

#include "appgridconstants.h"

#include <QDBusConnection>
#include <QDBusMessage>

AppGridStandalone::AppGridStandalone(QObject *parent)
    : QObject(parent)
{
}

QString AppGridStandalone::serviceName()
{
    return AppGrid::Dbus::Service;
}

QString AppGridStandalone::objectPath()
{
    return AppGrid::Dbus::Path;
}

QString AppGridStandalone::interfaceName()
{
    return AppGrid::Dbus::Interface;
}

bool AppGridStandalone::registerService()
{
    auto bus = QDBusConnection::sessionBus();
    // Export the scriptable Show/Hide/Toggle slots before claiming the name, so
    // a client that races in right after the name lands finds the object live.
    if (!bus.registerObject(objectPath(), this, QDBusConnection::ExportScriptableSlots)) {
        return false;
    }
    return bus.registerService(serviceName());
}

bool AppGridStandalone::callToggleOnRunningInstance()
{
    auto msg = QDBusMessage::createMethodCall(serviceName(), objectPath(), interfaceName(), QStringLiteral("Toggle"));
    // Fire-and-forget: we exit straight after, so no reply is awaited.
    return QDBusConnection::sessionBus().send(msg);
}

bool AppGridStandalone::callConfigureOnRunningInstance()
{
    auto msg = QDBusMessage::createMethodCall(serviceName(), objectPath(), interfaceName(), QStringLiteral("Configure"));
    return QDBusConnection::sessionBus().send(msg);
}

void AppGridStandalone::Show()
{
    Q_EMIT showRequested();
}

void AppGridStandalone::Hide()
{
    Q_EMIT hideRequested();
}

void AppGridStandalone::Toggle()
{
    Q_EMIT toggleRequested();
}

void AppGridStandalone::ToggleCompact()
{
    Q_EMIT toggleCompactRequested();
}

void AppGridStandalone::Configure()
{
    Q_EMIT configureRequested();
}

QString AppGridStandalone::Version() const
{
    return QStringLiteral(APPGRID_VERSION);
}

void AppGridStandalone::Quit()
{
    Q_EMIT quitRequested();
}
