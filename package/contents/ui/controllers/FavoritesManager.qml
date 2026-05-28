/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    KAStats-backed favorites lifecycle: loads the private Kicker
    provider, runs the one-shot 1.7.x → KAStats migration (gated by
    favoritesPortedToKAstats), mirrors the live model into
    AppFilterModel for alpha-sort, and coalesces the burst of source
    signals into one mirror per event-loop turn.

    Pure decision math lives in favoritesmigration.js so the
    migration plan and mirror-id collection are unit-tested in
    isolation; this file owns the Plasma-glue around it.
*/

import QtQuick

import "../js/favoritesmigration.js" as FavoritesMigration

Item {
    id: manager

    // --- Inputs ---

    property var appsModel: null

    // KAStats client id for the favorites provider. Production builds it
    // from the plasmoid id; the default keeps tests isolated from the
    // user's real favorites store.
    property string clientInstance: "dev.xarbit.appgrid.favorites.instance-test"

    // Config inputs, injected from the boundary's ConfigCache.
    required property bool sortFavoritesAlphabetically
    required property bool favoritesPortedToKAstats
    required property list<string> legacyFavorites

    // Persists the one-shot "ported to KAStats" flag — replaces the direct
    // config write. A no-op stub in tests.
    required property var markPorted

    // --- Outputs (panel re-exposes these via aliases) ---

    // KAStatsFavoritesModel doesn't publish roleNames() to QML, so we
    // hard-code the well-known Kicker::FavoriteIdRole value and probe
    // it once on load. -1 means "not yet known"; consumers must guard
    // on that before reading row data at the role.
    property int favoriteIdRole: -1
    readonly property int _kickerFavoriteIdRole: 259
    readonly property var sharedFavoritesModel: sharedFavoritesLoader.item

    // Drives whether the live model gets mirrored into AppFilterModel.
    // Only alpha-sort needs that; drag-reorder reads the shared model
    // directly.
    readonly property bool mirrorRequired: manager.sortFavoritesAlphabetically

    // No layout; pure controller.
    visible: false

    // --- Provider ---
    //
    // SharedFavoritesProvider isolates the org.kde.plasma.private.kicker
    // import so a missing private launcher plugin is logged rather than
    // crashing the rest of the plasmoid.
    Loader {
        id: sharedFavoritesLoader
        active: true
        source: "../models/SharedFavoritesProvider.qml"
        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("AppGrid: org.kde.plasma.private.kicker plugin missing — favorites disabled")
                return
            }
            if (status === Loader.Ready && item) {
                item.initForClient(manager.clientInstance)
                if (item.count > 0) {
                    const probe = item.data(item.index(0, 0), manager._kickerFavoriteIdRole)
                    if (typeof probe === "string") {
                        manager.favoriteIdRole = manager._kickerFavoriteIdRole
                    } else {
                        console.warn("AppGrid: FavoriteIdRole probe failed (got " + typeof probe
                                     + "); favorites reorder will be inert. Kicker enum may have shifted.")
                    }
                } else {
                    // No entries yet — accept the well-known value; the probe
                    // re-runs once entries land via the source-watcher below.
                    manager.favoriteIdRole = manager._kickerFavoriteIdRole
                }
                // KAStats only honours portOldFavorites once
                // kactivitymanagerd has finished initialising; the
                // enabled-watcher below catches the later flip.
                if (item.enabled) {
                    manager._maybeMigrateAndMirror()
                }
            }
        }
    }

    // --- Migration + mirror ---

    function _maybeMigrateAndMirror() {
        const item = sharedFavoritesLoader.item
        if (!item) return
        // Role probe hasn't resolved yet — try once it has on the next
        // model signal. Skip mirror; nothing useful to do.
        if (favoriteIdRole < 0) return

        if (manager.favoritesPortedToKAstats) {
            _mirrorFavorites()
            return
        }

        const local = manager.legacyFavorites
        if (local.length > 0) {
            // 1.7.x upgrade path. KAStatsFavoritesModel has no clear()
            // and portOldFavorites only re-ranks, so any entry already
            // in the KActivities backing store (Plasma's seeded defaults
            // or favourites added during earlier 1.8.x sessions) would
            // survive and merge into the result — #144. Remove every
            // existing id first, then port the user's actual backup.
            const actions = FavoritesMigration.decideMigrationActions(
                item, favoriteIdRole, local)
            for (let i = 0; i < actions.idsToRemove.length; ++i)
                item.removeFavorite(actions.idsToRemove[i])
            item.portOldFavorites(actions.prefixedToPort)
        }
        // else: fresh install — leave KAStats's seed alone.

        _mirrorFavorites()
    }

    function _mirrorFavorites() {
        if (!appsModel || !sharedFavoritesModel) return
        if (favoriteIdRole < 0) return
        appsModel.favoriteApps = FavoritesMigration.collectMirrorIds(
            sharedFavoritesModel, favoriteIdRole)
    }

    // --- Watchers ---

    Connections {
        target: sharedFavoritesLoader.item
        ignoreUnknownSignals: true
        function onEnabledChanged() {
            if (sharedFavoritesLoader.item && sharedFavoritesLoader.item.enabled)
                manager._maybeMigrateAndMirror()
        }
    }

    // KAStatsFavoritesModel's `favoritesChanged` is a stub in upstream
    // Kicker, so we listen to QAbstractItemModel signals and coalesce
    // the resulting burst (insert/remove/move/reset/layoutChanged/dataChanged
    // often fire back-to-back) into one mirror per event-loop turn. The
    // mirror only runs in alpha-sort mode; drag-reorder reads the shared
    // model directly.
    Timer {
        id: mirrorCoalesce
        interval: 0
        repeat: false
        onTriggered: {
            if (!manager.favoritesPortedToKAstats
                    && manager.sharedFavoritesModel
                    && manager.sharedFavoritesModel.count > 0) {
                manager.markPorted()
            }
            if (manager.mirrorRequired)
                manager._mirrorFavorites()
        }
    }

    // Catch up the proxy when the user enables alpha-sort mid-session.
    onMirrorRequiredChanged: {
        if (mirrorRequired) mirrorCoalesce.restart()
    }

    Connections {
        target: manager.sharedFavoritesModel
        ignoreUnknownSignals: true
        function _scheduleMirror() {
            // Migration finalisation still needs to happen even when not
            // mirroring (so the ported flag flips once KAStats has data).
            mirrorCoalesce.restart()
        }
        function onRowsInserted() { _scheduleMirror() }
        function onRowsRemoved() { _scheduleMirror() }
        function onRowsMoved() { _scheduleMirror() }
        function onModelReset() { _scheduleMirror() }
        function onLayoutChanged() { _scheduleMirror() }
        function onDataChanged() { _scheduleMirror() }
    }
}
