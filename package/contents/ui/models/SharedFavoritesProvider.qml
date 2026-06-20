/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    AppGrid's own KActivities favourites model (src/appgridfavoritesmodel).
    Replaces org.kde.plasma.private.kicker's KAStatsFavoritesModel: it reads and
    writes the same shared favourites store, so plain-app favourites stay in sync
    with Kickoff/Kicker, but it keeps jump-list action ids verbatim (#64) and
    drops the private QML dependency. Loaded lazily by FavoritesManager.
*/

import dev.xarbit.appgrid.models

AppGridFavoritesModel {
}
