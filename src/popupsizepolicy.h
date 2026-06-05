/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QString>

/**
 * Pure decisions for the panel applet's popup-size save/restore, free of
 * KConfig so the stale-/foreign-size detection can be unit-tested. The plugin
 * does the actual config reads/writes; this only decides what should happen.
 */
namespace PopupSizePolicy
{
/// Ownership marker we stamp alongside a size we wrote, so a later read can tell
/// our own size from one another launcher left behind after an alternatives
/// switch. Encodes the size so a foreign write (size changed, tag untouched) is
/// detectable.
[[nodiscard]] QString ownerTag(int w, int h);

/// What restorePopupSizeIfStranger should do with the instance config.
struct RestoreAction {
    enum Kind {
        Keep, ///< instance size is ours (tag matches) — leave it
        Adopt, ///< replace it with the saved global AppGrid size (width/height)
        Clear, ///< no trustworthy size anywhere — drop the keys so the popup self-sizes
    };
    Kind kind = Clear;
    int width = 0;
    int height = 0;
};

/// Decide from the instance size + its owner tag and the saved global size.
/// "Ours" needs both a positive size and a tag that matches that exact size;
/// otherwise adopt the global size when present, else clear.
[[nodiscard]] RestoreAction decideRestore(int instW, int instH, const QString &tag, int globalW, int globalH);

/// A size is worth persisting to the global slot only when both dimensions are
/// positive (a real, measured popup).
[[nodiscard]] bool isPersistable(int w, int h);
}
