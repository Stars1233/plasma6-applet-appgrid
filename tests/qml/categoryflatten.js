/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Flatten grouped-by-category apps into one navigation list plus per-section
    start offsets (prefix sums), so section<->flat-index lookups are O(1) rather
    than re-summed on every read. Pure; CategoryGridView owns the live geometry.
*/

.pragma library

// Flatten groupedApps ([{ category, apps:[...] }]) into a single nav list with
// a parallel prefix-sum array of each section's start offset. Recompute once
// per groupedApps change, not per read.
function flatten(groupedApps) {
    var flat = [];
    var starts = [];
    var groups = groupedApps || [];
    for (var i = 0; i < groups.length; ++i) {
        starts.push(flat.length);
        var apps = groups[i].apps || [];
        for (var j = 0; j < apps.length; ++j)
            flat.push(apps[j]);
    }
    return { flatApps: flat, sectionStartIndices: starts };
}

// Section index owning a given flat index, via the prefix-sum starts. Returns
// the last section whose start is <= flatIndex (so a flat index landing in an
// empty section resolves to the following non-empty one), or -1 for a negative
// index. starts is ascending with starts[0] === 0.
function sectionForFlatIndex(flatIndex, starts) {
    if (flatIndex < 0)
        return -1;
    var result = -1;
    var list = starts || [];
    for (var i = 0; i < list.length; ++i) {
        if (list[i] <= flatIndex)
            result = i;
        else
            break;
    }
    return result;
}
