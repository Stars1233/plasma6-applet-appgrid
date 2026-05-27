/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QHash>
#include <QString>

/**
 * Maps a freedesktop .desktop Categories token to one of the
 * AppGrid display buckets (Utilities, Development, Graphics,
 * Internet, Multimedia, Office, Games, Education, System).
 * Returns an empty string when the token is not mapped.
 *
 * The lookup table is built once on first call.
 */
QString mapCategoryToken(const QString &token);

/**
 * Direct read access to the lookup table for unit tests.
 * Returns a reference to the static map.
 */
const QHash<QString, QString> &categoryMap();
