/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    The model<->config bridge, lifted out of GridPanel. Two directions:

      * sync()   — push the persisted settings (hidden filter, sort, categories,
                   launch bookkeeping) into the AppFilterModel. Called on open
                   and on every reset, plus by the daemon when the settings
                   window mutates the live config.
      * writeback — as the model mutates its own bookkeeping (recents, launch
                   counts, known/hidden apps from a launch or a hide), persist it
                   straight back to the config object.

    `cfg` is the ConfigCache read surface; `configuration` is the writable handle
    (Plasmoid.configuration / the daemon's AppGridConfig). Kept injected so the
    panel doesn't reach globals and this tests with plain stubs.
*/

import QtQuick

import "../js/launchcounts.js" as LaunchCounts

QtObject {
    id: root

    property var appsModel: null
    property var cfg: null            // read surface (ConfigCache)
    property var configuration: null  // write target

    // Push config -> model. Favorites are loaded separately from
    // KAStatsFavoritesModel after migration (see FavoritesManager.qml).
    function sync() {
        if (!appsModel || !cfg)
            return
        appsModel.hiddenApps = cfg.hiddenApps
        appsModel.maxRecentApps = cfg.gridColumns
        appsModel.sortMode = cfg.sortMode
        appsModel.useSystemCategories = cfg.useSystemCategories
        appsModel.sortFavoritesAlphabetically = cfg.sortFavoritesAlphabetically
        appsModel.searchShowsHidden = cfg.searchShowsHidden
        appsModel.launchCounts = LaunchCounts.toMap(cfg.launchCounts)
        appsModel.knownApps = cfg.knownApps
        appsModel.recentApps = cfg.showRecentApps ? cfg.recentApps : []
        if (appsModel.knownApps.length === 0)
            appsModel.markAllKnown()
    }

    // Keep the recents cap in step with the column count as it changes.
    readonly property int columns: cfg ? cfg.gridColumns : 0
    onColumnsChanged: if (appsModel) appsModel.maxRecentApps = columns

    // Model -> config: persist the launch bookkeeping the model owns.
    property Connections _writeback: Connections {
        target: root.appsModel
        function onRecentAppsChanged() {
            root.configuration.recentApps = root.appsModel.recentApps
        }
        function onLaunchCountsChanged() {
            root.configuration.launchCounts = LaunchCounts.toList(root.appsModel.launchCounts)
        }
        function onKnownAppsChanged() {
            root.configuration.knownApps = root.appsModel.knownApps
        }
        function onHiddenAppsChanged() {
            root.configuration.hiddenApps = root.appsModel.hiddenApps
        }
    }
}
