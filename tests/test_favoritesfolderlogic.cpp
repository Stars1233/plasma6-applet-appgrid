/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Unit tests for FavoritesFolderLogic — the pure folder/layout transforms
    behind the favourites virtual-folders feature (issue #18). Pins the
    reconcile rules (clean removed favourites, auto-ungroup, auto-delete,
    dedup, append-new) and every mutation, plus the JSON round-trip.
*/

#include <QTest>

#include "favoritesfolderlogic.h"

using namespace FavoritesFolderLogic;

namespace
{
// Convenience: storageIds and tokens.
QString app(const QString &sid)
{
    return appToken(sid);
}
QString fold(const QString &id)
{
    return folderToken(id);
}
Folder folder(const QString &id, const QStringList &members, const QString &name = QStringLiteral("F"))
{
    return Folder{id, name, members};
}
}

class TestFavoritesFolderLogic : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void reconcileAppendsNewFavourites();
    void reconcileKeepsFolderMemberNotInFavourites();
    void reconcileSingleMemberFolderPersists();
    void reconcileEmptyFolderPersists();
    void reconcileEmptyFavouritesKeepsLayout();
    void dissolveFolderFreesMembersInPlace();
    void reconcileDedupsFolderWins();
    void createFolderAnchorsAtFirstAndDropsSecond();
    void addToFolderMovesAppIn();
    void addToFolderMovesBetweenFolders();
    void removeFromFolderReturnsAppToTopLevel();
    void renameKeepsIdAndMembers();
    void moveTopLevelReorders();
    void reorderInFolderReorders();
    void nextFolderIdIsMonotonic();
    void reconcileDedupsDuplicateTokens();
    void createFolderDedupsMembers();
    void moveTopLevelInvalidIndicesNoop();
    void jsonRoundTrip();
    void globalFlagToggleReconcileAndRoundTrip();
};

void TestFavoritesFolderLogic::reconcileAppendsNewFavourites()
{
    // Empty layout + two favourites → both appended as loose apps in order.
    const Layout out = reconcile({QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}, {});
    QCOMPARE(out.tokens, QStringList({app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop"))}));
    QVERIFY(out.folders.isEmpty());
}

void TestFavoritesFolderLogic::reconcileKeepsFolderMemberNotInFavourites()
{
    // Folder membership is the user's intent, not filtered by favourite status:
    // c.desktop isn't in the flat list (KAStats lag after add, or unfavourited on
    // another instance) but must stay in the folder. Dropping it here is what let
    // a cross-process reconcile round-trip clobber a just-added member (#18).
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop"), QStringLiteral("c.desktop")})};
    in.tokens = {fold(QStringLiteral("f1"))};
    const Layout out = reconcile({QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}, in);
    QCOMPARE(out.folders.size(), 1);
    QCOMPARE(out.folders.first().members, QStringList({QStringLiteral("a.desktop"), QStringLiteral("b.desktop"), QStringLiteral("c.desktop")}));
    // c is held by the folder, so it is not also emitted as a loose app token.
    QCOMPARE(out.tokens, QStringList{fold(QStringLiteral("f1"))});
}

void TestFavoritesFolderLogic::reconcileSingleMemberFolderPersists()
{
    // Folders are persistent containers: a single-member folder is kept as-is
    // (no auto-ungroup to a loose app), so building one up doesn't dissolve it.
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop")})};
    in.tokens = {fold(QStringLiteral("f1"))};
    const Layout out = reconcile({QStringLiteral("a.desktop")}, in);
    QCOMPARE(out.folders.size(), 1);
    QCOMPARE(out.folders.first().members, QStringList({QStringLiteral("a.desktop")}));
    QCOMPARE(out.tokens, QStringList({fold(QStringLiteral("f1"))}));
}

void TestFavoritesFolderLogic::reconcileEmptyFolderPersists()
{
    // An empty folder is kept (no auto-delete) — it is a user-created container.
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {})};
    in.tokens = {fold(QStringLiteral("f1"))};
    const Layout out = reconcile({QStringLiteral("z.desktop")}, in);
    QCOMPARE(out.folders.size(), 1);
    QVERIFY(out.folders.first().members.isEmpty());
    // z is a loose favourite, the empty folder still has its slot.
    QVERIFY(out.tokens.contains(fold(QStringLiteral("f1"))));
    QVERIFY(out.tokens.contains(app(QStringLiteral("z.desktop"))));
}

void TestFavoritesFolderLogic::dissolveFolderFreesMembersInPlace()
{
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop")})};
    in.tokens = {app(QStringLiteral("x.desktop")), fold(QStringLiteral("f1"))};
    const Layout out = dissolveFolder(in, QStringLiteral("f1"));
    QVERIFY(out.folders.isEmpty());
    // Members replace the folder token in place.
    QCOMPARE(out.tokens, QStringList({app(QStringLiteral("x.desktop")), app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop"))}));
}

void TestFavoritesFolderLogic::reconcileEmptyFavouritesKeepsLayout()
{
    // Empty favourites = "not loaded / unknown" → folders must survive (#18).
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop")})};
    in.tokens = {fold(QStringLiteral("f1"))};
    const Layout out = reconcile({}, in);
    QCOMPARE(out, in);
}

void TestFavoritesFolderLogic::reconcileDedupsFolderWins()
{
    // a.desktop is both a loose token and a folder member → folder wins, the
    // loose token is dropped.
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop")})};
    in.tokens = {app(QStringLiteral("a.desktop")), fold(QStringLiteral("f1"))};
    const Layout out = reconcile({QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}, in);
    QCOMPARE(out.tokens, QStringList({fold(QStringLiteral("f1"))}));
}

void TestFavoritesFolderLogic::createFolderAnchorsAtFirstAndDropsSecond()
{
    Layout in;
    in.tokens = {app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop")), app(QStringLiteral("c.desktop"))};
    Layout made = createFolder(in, QStringLiteral("a.desktop"), QStringLiteral("c.desktop"), QStringLiteral("Work"));
    made = reconcile({QStringLiteral("a.desktop"), QStringLiteral("b.desktop"), QStringLiteral("c.desktop")}, made);
    // Folder anchored where a.desktop was; b stays after it; c folded in.
    QCOMPARE(made.tokens, QStringList({fold(QStringLiteral("f1")), app(QStringLiteral("b.desktop"))}));
    QCOMPARE(made.folders.size(), 1);
    QCOMPARE(made.folders.first().name, QStringLiteral("Work"));
    QCOMPARE(made.folders.first().members, QStringList({QStringLiteral("a.desktop"), QStringLiteral("c.desktop")}));
}

void TestFavoritesFolderLogic::addToFolderMovesAppIn()
{
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop")})};
    in.tokens = {fold(QStringLiteral("f1")), app(QStringLiteral("c.desktop"))};
    Layout out = addToFolder(in, QStringLiteral("f1"), QStringLiteral("c.desktop"));
    out = reconcile({QStringLiteral("a.desktop"), QStringLiteral("b.desktop"), QStringLiteral("c.desktop")}, out);
    QCOMPARE(out.tokens, QStringList({fold(QStringLiteral("f1"))}));
    QCOMPARE(out.folders.first().members.size(), 3);
}

void TestFavoritesFolderLogic::addToFolderMovesBetweenFolders()
{
    // A member belongs to one folder: adding it to another moves it.
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}),
                  folder(QStringLiteral("f2"), {QStringLiteral("c.desktop"), QStringLiteral("d.desktop")})};
    in.tokens = {fold(QStringLiteral("f1")), fold(QStringLiteral("f2"))};
    const Layout out = addToFolder(in, QStringLiteral("f2"), QStringLiteral("a.desktop"));
    QCOMPARE(out.folders.at(0).members, QStringList({QStringLiteral("b.desktop")}));
    QVERIFY(out.folders.at(1).members.contains(QStringLiteral("a.desktop")));
}

void TestFavoritesFolderLogic::removeFromFolderReturnsAppToTopLevel()
{
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop"), QStringLiteral("c.desktop")})};
    in.tokens = {fold(QStringLiteral("f1"))};
    Layout out = removeFromFolder(in, QStringLiteral("f1"), QStringLiteral("c.desktop"));
    out = reconcile({QStringLiteral("a.desktop"), QStringLiteral("b.desktop"), QStringLiteral("c.desktop")}, out);
    // c stays a favourite, now loose; folder keeps a and b.
    QCOMPARE(out.tokens, QStringList({fold(QStringLiteral("f1")), app(QStringLiteral("c.desktop"))}));
    QCOMPARE(out.folders.first().members, QStringList({QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}));
}

void TestFavoritesFolderLogic::renameKeepsIdAndMembers()
{
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}, QStringLiteral("Old"))};
    in.tokens = {fold(QStringLiteral("f1"))};
    const Layout out = renameFolder(in, QStringLiteral("f1"), QStringLiteral("New"));
    QCOMPARE(out.folders.first().id, QStringLiteral("f1"));
    QCOMPARE(out.folders.first().name, QStringLiteral("New"));
    QCOMPARE(out.folders.first().members.size(), 2);
}

void TestFavoritesFolderLogic::moveTopLevelReorders()
{
    Layout in;
    in.tokens = {app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop")), app(QStringLiteral("c.desktop"))};
    const Layout out = moveTopLevel(in, 0, 2);
    QCOMPARE(out.tokens, QStringList({app(QStringLiteral("b.desktop")), app(QStringLiteral("c.desktop")), app(QStringLiteral("a.desktop"))}));
}

void TestFavoritesFolderLogic::reorderInFolderReorders()
{
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop"), QStringLiteral("c.desktop")})};
    const Layout out = reorderInFolder(in, QStringLiteral("f1"), 2, 0);
    QCOMPARE(out.folders.first().members, QStringList({QStringLiteral("c.desktop"), QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}));
}

void TestFavoritesFolderLogic::nextFolderIdIsMonotonic()
{
    QCOMPARE(nextFolderId({}), QStringLiteral("f1"));
    QCOMPARE(nextFolderId({folder(QStringLiteral("f1"), {}), folder(QStringLiteral("f3"), {})}), QStringLiteral("f4"));
}

void TestFavoritesFolderLogic::reconcileDedupsDuplicateTokens()
{
    // A layout with the same app token twice → it appears once.
    Layout in;
    in.tokens = {app(QStringLiteral("a.desktop")), app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop"))};
    const Layout out = reconcile({QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}, in);
    QCOMPARE(out.tokens, QStringList({app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop"))}));
}

void TestFavoritesFolderLogic::createFolderDedupsMembers()
{
    Layout in;
    in.tokens = {app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop"))};
    // Duplicate members collapse to distinct ones, in first-seen order.
    const Layout out = createFolderWith(in, {QStringLiteral("a.desktop"), QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}, QStringLiteral("F"));
    QCOMPARE(out.folders.size(), 1);
    QCOMPARE(out.folders.first().members, QStringList({QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}));
}

void TestFavoritesFolderLogic::moveTopLevelInvalidIndicesNoop()
{
    Layout in;
    in.tokens = {app(QStringLiteral("a.desktop")), app(QStringLiteral("b.desktop"))};
    QCOMPARE(moveTopLevel(in, 5, 0), in);
    QCOMPARE(moveTopLevel(in, 0, -1), in);
    QCOMPARE(moveTopLevel(in, 1, 1), in);
}

void TestFavoritesFolderLogic::jsonRoundTrip()
{
    const QVariantList in =
        foldersToVariant({folder(QStringLiteral("f1"), {QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}, QStringLiteral("Games"))});
    const QStringList json = foldersToJsonList(in);
    QCOMPARE(json.size(), 1);
    const QList<Folder> back = foldersFromVariant(foldersFromJsonList(json));
    QCOMPARE(back.size(), 1);
    QCOMPARE(back.first().id, QStringLiteral("f1"));
    QCOMPARE(back.first().name, QStringLiteral("Games"));
    QCOMPARE(back.first().members, QStringList({QStringLiteral("a.desktop"), QStringLiteral("b.desktop")}));
}

void TestFavoritesFolderLogic::globalFlagToggleReconcileAndRoundTrip()
{
    Layout in;
    in.folders = {folder(QStringLiteral("f1"), {QStringLiteral("a.desktop")}, QStringLiteral("Work"))};
    in.tokens = {fold(QStringLiteral("f1"))};
    QVERIFY(!in.folders.first().global); // local by default

    // setFolderGlobal flips it, reconcile preserves it.
    const Layout out = setFolderGlobal(in, QStringLiteral("f1"), true);
    QVERIFY(out.folders.first().global);
    const Layout rec = reconcile({QStringLiteral("a.desktop")}, out);
    QVERIFY(rec.folders.first().global);

    // JSON round-trip carries the flag (and absence reads back as local).
    const QList<Folder> global = foldersFromVariant(foldersFromJsonList(foldersToJsonList(foldersToVariant(out.folders))));
    QVERIFY(global.first().global);
    const QList<Folder> local = foldersFromVariant(foldersFromJsonList(foldersToJsonList(foldersToVariant(in.folders))));
    QVERIFY(!local.first().global);
}

QTEST_GUILESS_MAIN(TestFavoritesFolderLogic)
#include "test_favoritesfolderlogic.moc"
