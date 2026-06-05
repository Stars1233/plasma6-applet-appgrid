/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Unit tests for PopupSizePolicy — the panel applet's popup-size save/restore
    decisions, extracted from AppGridPanelPlugin so the stale-/foreign-size
    detection (the alternatives-switch case) is testable without KConfig.
*/

#include <QTest>

#include "popupsizepolicy.h"

using RA = PopupSizePolicy::RestoreAction;

class TestPopupSizePolicy : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void ownerTagEncodesSize();
    void keepsWhenTagMatchesOurSize();
    void adoptsGlobalWhenTagIsStale();
    void adoptsGlobalWhenNoInstanceSize();
    void clearsWhenNothingTrustworthy();
    void isPersistableRequiresBothPositive();
};

void TestPopupSizePolicy::ownerTagEncodesSize()
{
    QCOMPARE(PopupSizePolicy::ownerTag(800, 600), QStringLiteral("appgrid:800x600"));
    // Different sizes produce different tags — that's what makes a foreign
    // write (size changed, tag untouched) detectable.
    QVERIFY(PopupSizePolicy::ownerTag(800, 600) != PopupSizePolicy::ownerTag(801, 600));
}

void TestPopupSizePolicy::keepsWhenTagMatchesOurSize()
{
    // Instance size present and the tag matches it exactly → ours, leave it.
    const auto a = PopupSizePolicy::decideRestore(800, 600, PopupSizePolicy::ownerTag(800, 600), 1000, 700);
    QCOMPARE(a.kind, RA::Keep);
}

void TestPopupSizePolicy::adoptsGlobalWhenTagIsStale()
{
    // Foreign write: Kicker set 800x600 after an alternatives switch but left
    // OUR old tag (640x480) on it. Mismatch → adopt the saved global size.
    const auto a = PopupSizePolicy::decideRestore(800, 600, PopupSizePolicy::ownerTag(640, 480), 1000, 700);
    QCOMPARE(a.kind, RA::Adopt);
    QCOMPARE(a.width, 1000);
    QCOMPARE(a.height, 700);
}

void TestPopupSizePolicy::adoptsGlobalWhenNoInstanceSize()
{
    // Fresh instance (-1 size, empty tag) with a saved global → adopt global.
    const auto a = PopupSizePolicy::decideRestore(-1, -1, QString(), 1000, 700);
    QCOMPARE(a.kind, RA::Adopt);
    QCOMPARE(a.width, 1000);
    QCOMPARE(a.height, 700);
}

void TestPopupSizePolicy::clearsWhenNothingTrustworthy()
{
    // Stale/foreign instance size AND no saved global → clear so the popup
    // self-sizes instead of inheriting the other launcher's geometry.
    const auto a = PopupSizePolicy::decideRestore(800, 600, PopupSizePolicy::ownerTag(640, 480), -1, -1);
    QCOMPARE(a.kind, RA::Clear);
}

void TestPopupSizePolicy::isPersistableRequiresBothPositive()
{
    QVERIFY(PopupSizePolicy::isPersistable(800, 600));
    QVERIFY(!PopupSizePolicy::isPersistable(0, 600));
    QVERIFY(!PopupSizePolicy::isPersistable(800, 0));
    QVERIFY(!PopupSizePolicy::isPersistable(-1, -1));
}

QTEST_GUILESS_MAIN(TestPopupSizePolicy)
#include "test_popup_size_policy.moc"
