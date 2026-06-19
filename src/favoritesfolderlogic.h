/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QString>
#include <QStringList>
#include <QVariantList>

/**
 * Pure, Qt-free-of-QObject logic for the favourites folder layer (issue #18).
 *
 * Folders are an AppGrid-only grouping over the flat KAStats favourites list: a
 * top-level @c layout of ordered tokens ("app:<storageId>" or "folder:<id>")
 * plus a set of @c Folder definitions. KAStats stays the source of truth for
 * which apps are favourites; this layer only arranges them. Everything here is a
 * value transform — no model, no I/O — so it unit-tests directly (mirrors
 * frecencyscoring).
 */
namespace FavoritesFolderLogic
{

struct Folder {
    QString id;
    QString name;
    QStringList members; // ordered bare storageIds

    bool operator==(const Folder &o) const
    {
        return id == o.id && name == o.name && members == o.members;
    }
};

struct Layout {
    QList<Folder> folders;
    QStringList tokens; // top-level order of "app:<sid>" / "folder:<id>"

    bool operator==(const Layout &o) const
    {
        return folders == o.folders && tokens == o.tokens;
    }
};

// Token helpers.
[[nodiscard]] QString appToken(const QString &storageId);
[[nodiscard]] QString folderToken(const QString &folderId);
[[nodiscard]] bool isAppToken(const QString &token);
[[nodiscard]] bool isFolderToken(const QString &token);
[[nodiscard]] QString tokenPayload(const QString &token); // sid or folder id

/**
 * Reconcile @p in against the live flat favourite list @p flatFavorites
 * (KAStats order). Pure; returns a normalised layout where:
 *  - folder members not in @p flatFavorites are dropped (cleans externally
 *    removed favourites),
 *  - folders left with one member auto-ungroup, with zero members auto-delete,
 *  - every favourite appears in exactly one place (folder membership wins),
 *  - favourites absent from the layout are appended in @p flatFavorites order.
 */
[[nodiscard]] Layout reconcile(const QStringList &flatFavorites, const Layout &in);

// Mutations — each returns a new layout to be reconcile()d by the caller. A bad
// argument (unknown folder, identical sids) returns @p in unchanged.
[[nodiscard]] Layout createFolder(const Layout &in, const QString &sidA, const QString &sidB, const QString &name);
// Group two or more members (deduplicated) into a new folder anchored at the
// first member's slot. Fewer than two distinct members returns @p in unchanged.
[[nodiscard]] Layout createFolderWith(const Layout &in, const QStringList &members, const QString &name);
[[nodiscard]] Layout addToFolder(const Layout &in, const QString &folderId, const QString &sid);
[[nodiscard]] Layout removeFromFolder(const Layout &in, const QString &folderId, const QString &sid);
[[nodiscard]] Layout renameFolder(const Layout &in, const QString &folderId, const QString &name);
// Dissolve a folder: remove it and drop its members back in its place as loose
// top-level apps (they stay favourites).
[[nodiscard]] Layout dissolveFolder(const Layout &in, const QString &folderId);
[[nodiscard]] Layout moveTopLevel(const Layout &in, int fromRow, int toRow);
[[nodiscard]] Layout reorderInFolder(const Layout &in, const QString &folderId, int fromIndex, int toIndex);

/** Next free "f<n>" id given the existing folders. */
[[nodiscard]] QString nextFolderId(const QList<Folder> &folders);

// Boundary conversions for the QVariant world (QML + LaunchStateStore).
[[nodiscard]] QVariantList foldersToVariant(const QList<Folder> &folders);
[[nodiscard]] QList<Folder> foldersFromVariant(const QVariantList &list);
// On-disk form: one compact-JSON object per StringList entry.
[[nodiscard]] QStringList foldersToJsonList(const QVariantList &folders);
[[nodiscard]] QVariantList foldersFromJsonList(const QStringList &list);

}
