/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "appstreamresolver.h"

#include <AppStreamQt/component-box.h>
#include <AppStreamQt/component.h>
#include <AppStreamQt/launchable.h>
#include <AppStreamQt/pool.h>

#include <QDebug>
#include <QObject>

namespace AppStreamResolver
{
namespace
{
// Shared AppStream metadata pool. Warmed asynchronously so the UI thread
// never blocks parsing metadata. Queries are gated on poolReady() so we never
// read the pool mid-load.
AppStream::Pool &pool()
{
    static AppStream::Pool instance;
    return instance;
}

bool &poolReady()
{
    static bool ready = false;
    return ready;
}
}

void warm()
{
    static bool started = false;
    if (started)
        return;
    started = true;
    QObject::connect(&pool(), &AppStream::Pool::loadFinished, &pool(), [](bool success) {
        poolReady() = success;
        if (!success)
            qWarning() << "AppGrid: AppStream pool load failed:" << pool().lastError();
    });
    pool().loadAsync();
}

QString resolve(const QString &desktopId)
{
    if (!poolReady())
        return {};
    const auto components = pool().componentsByLaunchable(AppStream::Launchable::KindDesktopId, desktopId);
    for (const AppStream::Component &component : components) {
        if (!component.id().isEmpty())
            return component.id();
    }
    return {};
}
}
