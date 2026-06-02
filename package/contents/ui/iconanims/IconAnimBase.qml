/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Shared contract for per-icon hover animations loaded by AppIconDelegate:
    a target to animate, a hovered flag (only the Grow animation reacts to
    it; the others ignore it), and a one-shot start(). Concrete animations
    derive from this and override start().
*/

import QtQuick

Item {
    id: root

    property Item target: null
    property bool hovered: false

    function start() {}
}
