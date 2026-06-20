/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Coverage for AppActionId::parse / hasAction — splitting jump-list action
    favourite ids (applications:<storageId>?action=<name>, #64). resolveAction()
    needs a live KService so it stays integration-level, like the launch tests.
*/

#include "appactionid.h"

#include <QTest>

class TestAppActionId : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void plainIdHasNoAction()
    {
        const auto p = AppActionId::parse(QStringLiteral("org.kde.spectacle.desktop"));
        QCOMPARE(p.storageId, QStringLiteral("org.kde.spectacle.desktop"));
        QVERIFY(p.actionName.isEmpty());
        QVERIFY(!AppActionId::hasAction(QStringLiteral("org.kde.spectacle.desktop")));
    }

    void parsesActionFromBareId()
    {
        const auto p = AppActionId::parse(QStringLiteral("org.kde.spectacle.desktop?action=RecordRegion"));
        QCOMPARE(p.storageId, QStringLiteral("org.kde.spectacle.desktop"));
        QCOMPARE(p.actionName, QStringLiteral("RecordRegion"));
        QVERIFY(AppActionId::hasAction(QStringLiteral("org.kde.spectacle.desktop?action=RecordRegion")));
    }

    void stripsApplicationsScheme()
    {
        const auto p = AppActionId::parse(QStringLiteral("applications:org.kde.spectacle.desktop?action=RecordRegion"));
        QCOMPARE(p.storageId, QStringLiteral("org.kde.spectacle.desktop"));
        QCOMPARE(p.actionName, QStringLiteral("RecordRegion"));
    }

    void schemeWithoutAction()
    {
        const auto p = AppActionId::parse(QStringLiteral("applications:org.kde.spectacle.desktop"));
        QCOMPARE(p.storageId, QStringLiteral("org.kde.spectacle.desktop"));
        QVERIFY(p.actionName.isEmpty());
    }

    void queryWithoutActionKeyIsNoAction()
    {
        const auto p = AppActionId::parse(QStringLiteral("org.kde.spectacle.desktop?foo=bar"));
        QCOMPARE(p.storageId, QStringLiteral("org.kde.spectacle.desktop"));
        QVERIFY(p.actionName.isEmpty());
        QVERIFY(!AppActionId::hasAction(QStringLiteral("org.kde.spectacle.desktop?foo=bar")));
    }

    void emptyId()
    {
        const auto p = AppActionId::parse(QString());
        QVERIFY(p.storageId.isEmpty());
        QVERIFY(p.actionName.isEmpty());
        QVERIFY(!AppActionId::hasAction(QString()));
    }
};

QTEST_MAIN(TestAppActionId)
#include "test_appactionid.moc"
