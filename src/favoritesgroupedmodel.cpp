/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "favoritesgroupedmodel.h"

#include "pluginhelpers.h"

using namespace FavoritesFolderLogic;

FavoritesGroupedModel::FavoritesGroupedModel(QObject *parent)
    : AbstractGroupedModel(parent)
{
}

QVariantList FavoritesGroupedModel::favoriteFolders() const
{
    return foldersToVariant(m_state.folders);
}

void FavoritesGroupedModel::setFavoriteFolders(const QVariantList &folders)
{
    const QList<FavoritesFolderLogic::Folder> incoming = foldersFromVariant(folders);
    if (incoming == m_state.folders) {
        return;
    }
    apply(reconcile(m_flatFavorites, {incoming, m_state.tokens}));
}

QStringList FavoritesGroupedModel::favoriteLayout() const
{
    return m_state.tokens;
}

void FavoritesGroupedModel::setFavoriteLayout(const QStringList &layout)
{
    if (layout == m_state.tokens) {
        return;
    }
    apply(reconcile(m_flatFavorites, {m_state.folders, layout}));
}

void FavoritesGroupedModel::setFlatFavorites(const QStringList &flatFavorites)
{
    if (flatFavorites == m_flatFavorites) {
        return;
    }
    m_flatFavorites = flatFavorites;
    apply(reconcile(m_flatFavorites, m_state));
}

QString FavoritesGroupedModel::createFolder(const QString &sidA, const QString &sidB, const QString &name)
{
    return _applyCreate(FavoritesFolderLogic::createFolder(m_state, sidA, sidB, name));
}

QString FavoritesGroupedModel::createFolderFromMembers(const QStringList &sids, const QString &name)
{
    _adoptFavorites(sids);
    return _applyCreate(FavoritesFolderLogic::createFolderWith(m_state, sids, name));
}

QString FavoritesGroupedModel::createEmptyFolder(const QString &name)
{
    return _applyCreate(FavoritesFolderLogic::createFolderWith(m_state, {}, name));
}

QString FavoritesGroupedModel::_applyCreate(const Layout &next)
{
    // A new folder is appended last; pick up its id, apply, then announce it so
    // the UI can prompt for a name.
    if (next.folders.size() <= m_state.folders.size()) {
        return {};
    }
    const QString id = next.folders.constLast().id;
    apply(reconcile(m_flatFavorites, next), true);
    Q_EMIT folderCreated(id);
    return id;
}

void FavoritesGroupedModel::addToFolder(const QString &folderId, const QString &sid)
{
    _adoptFavorites({sid});
    apply(reconcile(m_flatFavorites, FavoritesFolderLogic::addToFolder(m_state, folderId, sid)), true);
}

void FavoritesGroupedModel::_adoptFavorites(const QStringList &sids)
{
    // The UI favourites a non-favourite app (in KAStats) just before grouping it.
    // KAStats only reports the new favourite a tick later, so optimistically take
    // these into the flat list now so the app reads as a favourite immediately;
    // the next real push carries the same id, and the contains() guard makes
    // re-adopting a no-op. (Folder membership itself no longer depends on this —
    // reconcile keeps members regardless of favourite status, see #18.)
    for (const QString &sid : sids) {
        if (!sid.isEmpty() && !m_flatFavorites.contains(sid)) {
            m_flatFavorites.append(sid);
        }
    }
}

void FavoritesGroupedModel::removeFromFolder(const QString &folderId, const QString &sid)
{
    apply(reconcile(m_flatFavorites, FavoritesFolderLogic::removeFromFolder(m_state, folderId, sid)), true);
}

void FavoritesGroupedModel::renameFolder(const QString &folderId, const QString &name)
{
    apply(reconcile(m_flatFavorites, FavoritesFolderLogic::renameFolder(m_state, folderId, name)), true);
}

void FavoritesGroupedModel::ungroupFolder(const QString &folderId)
{
    apply(reconcile(m_flatFavorites, FavoritesFolderLogic::dissolveFolder(m_state, folderId)), true);
}

void FavoritesGroupedModel::moveTopLevel(int fromRow, int toRow)
{
    apply(reconcile(m_flatFavorites, FavoritesFolderLogic::moveTopLevel(m_state, fromRow, toRow)), true);
}

void FavoritesGroupedModel::moveRow(int fromRow, int toRow)
{
    if (fromRow < 0 || toRow < 0 || fromRow >= m_state.tokens.size() || toRow >= m_state.tokens.size() || fromRow == toRow) {
        return;
    }
    // The layout stays valid under a pure reorder, so move the token + the row
    // in lockstep and emit a row-move instead of reconciling (which would reset).
    m_state.tokens.move(fromRow, toRow);
    moveRowAt(fromRow, toRow);
    Q_EMIT layoutChanged();
    Q_EMIT layoutPersistRequested();
}

void FavoritesGroupedModel::reorderInFolder(const QString &folderId, int fromIndex, int toIndex)
{
    apply(reconcile(m_flatFavorites, FavoritesFolderLogic::reorderInFolder(m_state, folderId, fromIndex, toIndex)), true);
}

void FavoritesGroupedModel::apply(const Layout &next, bool persist)
{
    const bool foldersMoved = next.folders != m_state.folders;
    const bool tokensMoved = next.tokens != m_state.tokens;
    if (!foldersMoved && !tokensMoved) {
        return;
    }
    m_state = next;
    rebuildRows();
    if (foldersMoved) {
        Q_EMIT foldersChanged();
        if (persist) {
            Q_EMIT foldersPersistRequested();
        }
    }
    if (tokensMoved) {
        Q_EMIT layoutChanged();
        if (persist) {
            Q_EMIT layoutPersistRequested();
        }
    }
}

void FavoritesGroupedModel::rebuildRows()
{
    QList<Row> rows;
    rows.reserve(m_state.tokens.size());
    for (const QString &token : m_state.tokens) {
        if (isFolderToken(token)) {
            const QString id = tokenPayload(token);
            for (const FavoritesFolderLogic::Folder &f : m_state.folders) {
                if (f.id == id) {
                    rows.append({AbstractGroupedModel::Folder, {}, f.id, f.name, f.members});
                    break;
                }
            }
        } else if (isAppToken(token)) {
            Row row;
            row.type = AbstractGroupedModel::App;
            row.favoriteId = PluginHelpers::ApplicationsUrlPrefix + tokenPayload(token);
            rows.append(row);
        }
    }
    setRows(rows);
}
