/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Unit tests for AppGridStandalone's D-Bus surface: every exported method emits
    its matching Qt signal (the QML entry / main.cpp wire these), and Version()
    reports the build the daemon was compiled as (the plasmoid's stale-daemon
    check compares against it). Registration is not exercised — it needs a live
    session bus — only the method→signal mapping, which is pure.
*/

#include <QSignalSpy>
#include <QTest>

#include "appgridstandalone.h"

class TestAppGridStandalone : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void methodsEmitSignals_data();
    void methodsEmitSignals();
    void versionIsBuildVersion();
};

void TestAppGridStandalone::methodsEmitSignals_data()
{
    QTest::addColumn<QByteArray>("method");
    QTest::addColumn<QByteArray>("signal");

    QTest::newRow("Show") << QByteArray("Show") << QByteArray(SIGNAL(showRequested()));
    QTest::newRow("Hide") << QByteArray("Hide") << QByteArray(SIGNAL(hideRequested()));
    QTest::newRow("Toggle") << QByteArray("Toggle") << QByteArray(SIGNAL(toggleRequested()));
    QTest::newRow("ToggleCompact") << QByteArray("ToggleCompact") << QByteArray(SIGNAL(toggleCompactRequested()));
    QTest::newRow("Configure") << QByteArray("Configure") << QByteArray(SIGNAL(configureRequested()));
    QTest::newRow("Quit") << QByteArray("Quit") << QByteArray(SIGNAL(quitRequested()));
}

void TestAppGridStandalone::methodsEmitSignals()
{
    QFETCH(QByteArray, method);
    QFETCH(QByteArray, signal);

    AppGridStandalone standalone;
    QSignalSpy spy(&standalone, signal.constData());
    QVERIFY(spy.isValid());
    QVERIFY(QMetaObject::invokeMethod(&standalone, method.constData()));
    QCOMPARE(spy.count(), 1);
}

void TestAppGridStandalone::versionIsBuildVersion()
{
    AppGridStandalone standalone;
    QCOMPARE(standalone.Version(), QStringLiteral(APPGRID_VERSION));
    QVERIFY(!standalone.Version().isEmpty());
}

QTEST_GUILESS_MAIN(TestAppGridStandalone)
#include "test_standalone.moc"
