/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "runnerfiltermodel.h"

#include "appmodel.h"

#include <QFileInfo>
#include <QList>
#include <QUrl>

RunnerFilterModel::RunnerFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

void RunnerFilterModel::setAppModel(AppFilterModel *model)
{
    m_appModel = model;
    const auto refresh = [this]() {
        rebuildAppNameCache();
        invalidate();
    };
    connect(m_appModel, &QAbstractItemModel::modelReset, this, refresh);
    connect(m_appModel, &QAbstractItemModel::layoutChanged, this, refresh);
    connect(m_appModel, &QAbstractItemModel::rowsInserted, this, refresh);
    connect(m_appModel, &QAbstractItemModel::rowsRemoved, this, refresh);
    // Hidden-set + searchShowsHidden control whether KRunner-served
    // hidden apps drop out — same gate AppFilterModel applies on its
    // own rows.
    connect(m_appModel, &AppFilterModel::hiddenAppsChanged, this, &RunnerFilterModel::invalidate);
    connect(m_appModel, &AppFilterModel::searchShowsHiddenChanged, this, &RunnerFilterModel::invalidate);
    rebuildAppNameCache();
}

void RunnerFilterModel::setSourceModel(QAbstractItemModel *model)
{
    QSortFilterProxyModel::setSourceModel(model);
    captureSourceRoles();
}

void RunnerFilterModel::captureSourceRoles()
{
    m_urlsRole = -1;
    if (!sourceModel())
        return;
    const auto roles = sourceModel()->roleNames();
    for (auto it = roles.begin(); it != roles.end(); ++it) {
        if (it.value() == QByteArrayLiteral("urls")) {
            m_urlsRole = it.key();
            return;
        }
    }
}

void RunnerFilterModel::rebuildAppNameCache()
{
    m_appNameCache.clear();
    if (!m_appModel)
        return;
    const int n = m_appModel->rowCount();
    m_appNameCache.reserve(n);
    for (int i = 0; i < n; ++i) {
        const auto name = m_appModel->index(i, 0).data(AppModel::NameRole).toString();
        if (!name.isEmpty())
            m_appNameCache.insert(name.toCaseFolded());
    }
}

QString RunnerFilterModel::storageIdFromRow(const QModelIndex &idx) const
{
    if (m_urlsRole < 0)
        return {};
    const auto urls = idx.data(m_urlsRole).value<QList<QUrl>>();
    for (const auto &url : urls) {
        const auto path = url.toLocalFile();
        if (path.endsWith(QLatin1String(".desktop")))
            return QFileInfo(path).fileName();
    }
    return {};
}

bool RunnerFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (!m_appModel)
        return true;

    const auto idx = sourceModel()->index(sourceRow, 0, sourceParent);

    // Dedup against visible app names so the unified view doesn't show
    // the same app twice (once via AppFilterModel, once via KRunner's
    // services runner).
    const auto runnerName = idx.data(Qt::DisplayRole).toString();
    if (m_appNameCache.contains(runnerName.toCaseFolded()))
        return false;

    // Hidden-app filter — mirrors AppFilterModel: hidden rows drop out
    // unless searchShowsHidden is on (the default). Without this,
    // toggling the knob off would still leak hidden apps via the
    // services runner's row for the same .desktop file.
    if (!m_appModel->searchShowsHidden()) {
        const auto sid = storageIdFromRow(idx);
        if (!sid.isEmpty() && m_appModel->isHidden(sid))
            return false;
    }

    return true;
}
