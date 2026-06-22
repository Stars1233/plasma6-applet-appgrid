/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "categoryqueries.h"

#include "appmodel.h"

#include <QAbstractItemModel>
#include <QMap>

namespace CategoryQueries
{
QVariantMap appDataMap(const QModelIndex &index)
{
    QVariantMap map;
    map[QStringLiteral("name")] = index.data(AppModel::NameRole);
    map[QStringLiteral("iconName")] = index.data(AppModel::IconRole);
    map[QStringLiteral("desktopFile")] = index.data(AppModel::DesktopFileRole);
    map[QStringLiteral("storageId")] = index.data(AppModel::StorageIdRole);
    map[QStringLiteral("comment")] = index.data(AppModel::CommentRole);
    map[QStringLiteral("installSource")] = index.data(AppModel::InstallSourceRole);
    return map;
}

QVariantList groupByCategory(const QAbstractItemModel *model)
{
    if (!model) {
        return {};
    }

    QMap<QString, QVariantList> byCategory; // sorted by category name
    for (int row = 0; row < model->rowCount(); ++row) {
        const QModelIndex idx = model->index(row, 0);
        QVariantMap app = appDataMap(idx);
        app[QStringLiteral("proxyIndex")] = row;
        const auto categories = idx.data(AppModel::CategoriesRole).toStringList();
        for (const QString &category : categories) {
            byCategory[category].append(app);
        }
    }

    QVariantList sections;
    sections.reserve(byCategory.size());
    for (auto it = byCategory.cbegin(); it != byCategory.cend(); ++it) {
        sections.append(QVariantMap{
            {QStringLiteral("category"), it.key()},
            {QStringLiteral("apps"), it.value()},
        });
    }
    return sections;
}
}
