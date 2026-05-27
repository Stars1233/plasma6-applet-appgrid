/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Pure helpers for FavoritesManager — the migration-decision logic
    and the mirror-id collection are factored out so they can be
    exercised against a plain stub object instead of the real
    KAStatsFavoritesModel (which only loads in a live Plasma session).

    Import as:
        import "favoritesmigration.js" as FavoritesMigration
*/

.pragma library
.import "favoriteid.js" as FavoriteId

// Plan a migration pass from the legacy `local` favorites list into
// the live KAStats `item`. Returns the actions the caller should
// apply in order: first remove every id that is already in the model
// (so KAStats's seeded defaults — Konsole, Discover, Settings on
// fresh installs — don't union back into the user's intended list),
// then port the prefixed legacy list.
//
//   item             - object with .count and .data(index, role)
//   favoriteIdRole   - int role to read existing ids from
//   localFavorites   - array of bare storage ids from the 1.7.x config
//
// Returns { idsToRemove: [string], prefixedToPort: [string] }.
function decideMigrationActions(item, favoriteIdRole, localFavorites) {
    const idsToRemove = []
    for (let i = 0; i < item.count; ++i) {
        const v = item.data(item.index(i, 0), favoriteIdRole)
        if (v) idsToRemove.push(v.toString())
    }
    const prefixedToPort = localFavorites.map(function(id) {
        return FavoriteId.toPrefixed(id)
    })
    return { idsToRemove: idsToRemove, prefixedToPort: prefixedToPort }
}

// Collect the storage-id list to mirror into AppFilterModel's
// favorites view. Reads each row's prefixed favoriteId, strips the
// "applications:" scheme, and skips rows with no value.
//
//   model          - object with .count and .data(index, role)
//   favoriteIdRole - int role
//
// Returns [string].
function collectMirrorIds(model, favoriteIdRole) {
    const ids = []
    for (let i = 0; i < model.count; ++i) {
        const raw = model.data(model.index(i, 0), favoriteIdRole)
        if (!raw) continue
        ids.push(FavoriteId.stripPrefix(raw))
    }
    return ids
}
