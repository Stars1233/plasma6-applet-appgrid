/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>
#include <QSet>
#include <QString>

namespace KActivities
{
namespace Stats
{
class ResultModel;
}
}

/**
 * Always-on KActivities view of which applications have been used (have any
 * usage score). Drives the "new app" badge the way kicker does, but owned here
 * instead of via the private kicker API: an app the user has never launched and
 * whose .desktop file is recent counts as newly installed. AppGrid's own launch
 * broadcasts (ResourceInstance::notifyAccessed) feed the same database, so an
 * app stops being "new" the moment it is launched.
 */
class UsedAppsProvider : public QObject
{
    Q_OBJECT

public:
    explicit UsedAppsProvider(QObject *parent = nullptr);
    ~UsedAppsProvider() override;

    /** True once @p storageId has any recorded usage. */
    [[nodiscard]] bool isUsed(const QString &storageId) const
    {
        return m_used.contains(storageId);
    }
    [[nodiscard]] QSet<QString> usedApps() const
    {
        return m_used;
    }

Q_SIGNALS:
    void usedAppsChanged();

private:
    void rebuild();

    KActivities::Stats::ResultModel *m_model = nullptr;
    QSet<QString> m_used;
};
