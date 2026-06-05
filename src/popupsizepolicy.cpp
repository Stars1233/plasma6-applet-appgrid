/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "popupsizepolicy.h"

QString PopupSizePolicy::ownerTag(int w, int h)
{
    return QStringLiteral("appgrid:%1x%2").arg(w).arg(h);
}

PopupSizePolicy::RestoreAction PopupSizePolicy::decideRestore(int instW, int instH, const QString &tag, int globalW, int globalH)
{
    // Ours requires both pieces: a positive size and a tag identifying that
    // exact size. Another launcher (e.g. Kicker after an alternatives switch)
    // writes the size without touching the tag — a stale tag on a foreign size,
    // caught by the comparison.
    if (instW > 0 && instH > 0 && tag == ownerTag(instW, instH)) {
        return {RestoreAction::Keep, 0, 0};
    }
    if (globalW > 0 && globalH > 0) {
        return {RestoreAction::Adopt, globalW, globalH};
    }
    return {RestoreAction::Clear, 0, 0};
}

bool PopupSizePolicy::isPersistable(int w, int h)
{
    return w > 0 && h > 0;
}
