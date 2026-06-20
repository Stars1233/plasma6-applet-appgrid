// SPDX-FileCopyrightText: 2026 AppGrid Contributors
// SPDX-License-Identifier: GPL-2.0-or-later
//
// Helpers for KAStats favorite ids. Favorites are stored prefixed with the
// "applications:" scheme; the rest of AppGrid works with bare storage ids
// (basename of the .desktop file). Centralising the conversion here avoids
// scattering the prefix string and its magic length around the codebase.
//
// Import as:
//     import "favoriteid.js" as FavoriteId

.pragma library

const SCHEME = "applications:"

// Returns `id` with the scheme prepended if it isn't already a complete id.
// An id that carries a scheme (preferred://) or is a local path (a file
// favourite, stored bare) is returned unchanged. `null` / `undefined` / empty
// become the bare scheme. Mirror of C++ PluginHelpers::toFavoriteId — keep the
// "already complete" rule identical in both.
function toPrefixed(id) {
    if (!id) return SCHEME
    return (id.indexOf(":") >= 0 || id.charAt(0) === "/") ? id : SCHEME + id
}

// Returns `id` with the scheme stripped if present, otherwise unchanged.
function stripPrefix(id) {
    if (typeof id !== "string") return ""
    return id.startsWith(SCHEME) ? id.substring(SCHEME.length) : id
}

function hasPrefix(id) {
    return typeof id === "string" && id.startsWith(SCHEME)
}
