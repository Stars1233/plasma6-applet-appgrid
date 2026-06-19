/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Resolve a favourite's display name + icon from a bare storageId. Prefers the
    app model; falls back to the KAStats row for entries the app model doesn't
    know — a System Settings module favourited via #64 — whose icon is a QIcon
    (KAStats Qt::DecorationRole) the grouped model can't carry. One place so the
    grid, the folder preview and the open folder all resolve identically (#18).
*/

.import "favoriteid.js" as FavoriteId

// Returns { name, icon }; icon may be an icon-name string or a QIcon.
function resolve(appsModel, sharedFavoritesModel, favoriteIdRole, sid, defaultIcon) {
    if (sid && appsModel) {
        const a = appsModel.getByStorageId(sid)
        if (a && a.iconName)
            return { name: a.name || "", icon: a.iconName }
    }
    if (sid && sharedFavoritesModel && favoriteIdRole >= 0) {
        const prefixed = FavoriteId.toPrefixed(sid)
        for (let i = 0; i < sharedFavoritesModel.count; ++i) {
            const idx = sharedFavoritesModel.index(i, 0)
            const fid = sharedFavoritesModel.data(idx, favoriteIdRole)
            if (fid === prefixed || fid === sid) {
                return {
                    name: sharedFavoritesModel.data(idx, Qt.DisplayRole) || "",
                    icon: sharedFavoritesModel.data(idx, Qt.DecorationRole) || defaultIcon || ""
                }
            }
        }
    }
    return { name: "", icon: defaultIcon || "" }
}
