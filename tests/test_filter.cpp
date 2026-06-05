/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later

    Verifies filterAcceptsRow logic: category, hidden, favorites-only,
    and recents-from-grid hiding.
*/

#include <QTest>

#include "appfiltermodel.h"
#include "stubappmodel.h"

class TestFilter : public QObject {
    Q_OBJECT
private Q_SLOTS:
    void initTestCase();
    void init();
    void hiddenAppsExcluded();
    void hiddenAppsStayHiddenInSearchByDefault();
    void hiddenAppsSurfaceInSearchWhenToggleOn();
    void categoryFilterIncludesOnlyMatching();
    void emptyCategoryAcceptsAll();
    void favoritesOnlyExcludesNonFavorites();
    void favoritesOnlyRejectsEmptyStorageId();
    void recentsHiddenFromAllViewInAlphabetical();
    void recentsVisibleInMostUsed();
    void recentsShownWhenCategoryActive();

private:
    QStringList visibleStorageIds() const;
    StubAppModel m_source;
    AppFilterModel m_filter;
};

void TestFilter::initTestCase()
{
    m_filter.setSourceModel(&m_source);
}

void TestFilter::init()
{
    m_source.setApps({});
    m_filter.setSearchText(QString());
    m_filter.setFilterCategory(QString());
    m_filter.setHiddenApps({});
    m_filter.setFavoriteApps({});
    m_filter.setRecentApps({});
    m_filter.setShowFavoritesOnly(false);
    m_filter.setSortMode(AppFilterModel::Alphabetical);
    m_filter.setLaunchCountsMap({});
    m_filter.setSearchShowsHidden(false);
}

QStringList TestFilter::visibleStorageIds() const
{
    QStringList ids;
    for (int i = 0; i < m_filter.count(); ++i)
        ids << m_filter.index(i, 0).data(AppModel::StorageIdRole).toString();
    ids.sort();
    return ids;
}

void TestFilter::hiddenAppsExcluded()
{
    m_source.setApps({
        {QStringLiteral("A"), {}, {}, {}, {}, QStringLiteral("a.desktop"), {}, {}, {}},
        {QStringLiteral("B"), {}, {}, {}, {}, QStringLiteral("b.desktop"), {}, {}, {}},
        {QStringLiteral("C"), {}, {}, {}, {}, QStringLiteral("c.desktop"), {}, {}, {}},
    });
    m_filter.setHiddenApps({QStringLiteral("b.desktop")});
    QCOMPARE(visibleStorageIds(), (QStringList{QStringLiteral("a.desktop"), QStringLiteral("c.desktop")}));
}

void TestFilter::hiddenAppsStayHiddenInSearchByDefault()
{
    m_source.setApps({
        {QStringLiteral("Konsole"), {}, {}, {}, {}, QStringLiteral("konsole.desktop"), {}, {}, {}},
        {QStringLiteral("Krita"),   {}, {}, {}, {}, QStringLiteral("krita.desktop"),   {}, {}, {}},
    });
    m_filter.setHiddenApps({QStringLiteral("krita.desktop")});
    // Empty query → hidden app excluded from the grid (existing).
    QCOMPARE(visibleStorageIds(), QStringList{QStringLiteral("konsole.desktop")});
    // Search → hidden app still excluded (searchShowsHidden defaults false).
    m_filter.setSearchText(QStringLiteral("kri"));
    QCOMPARE(visibleStorageIds(), QStringList());
}

void TestFilter::hiddenAppsSurfaceInSearchWhenToggleOn()
{
    m_source.setApps({
        {QStringLiteral("Konsole"), {}, {}, {}, {}, QStringLiteral("konsole.desktop"), {}, {}, {}},
        {QStringLiteral("Krita"),   {}, {}, {}, {}, QStringLiteral("krita.desktop"),   {}, {}, {}},
    });
    m_filter.setHiddenApps({QStringLiteral("krita.desktop")});
    m_filter.setSearchShowsHidden(true);
    m_filter.setSearchText(QStringLiteral("kri"));
    QCOMPARE(visibleStorageIds(), QStringList{QStringLiteral("krita.desktop")});
}

void TestFilter::categoryFilterIncludesOnlyMatching()
{
    m_source.setApps({
        {QStringLiteral("Kate"), {}, {}, {QStringLiteral("Development")}, {}, QStringLiteral("kate"), {}, {}, {}},
        {QStringLiteral("Firefox"), {}, {}, {QStringLiteral("Internet")}, {}, QStringLiteral("ff"), {}, {}, {}},
        {QStringLiteral("Code"), {}, {}, {QStringLiteral("Development"), QStringLiteral("Utility")}, {}, QStringLiteral("vs"), {}, {}, {}},
    });
    m_filter.setFilterCategory(QStringLiteral("Development"));
    QCOMPARE(visibleStorageIds(), (QStringList{QStringLiteral("kate"), QStringLiteral("vs")}));
    m_filter.setFilterCategory(QStringLiteral("Internet"));
    QCOMPARE(visibleStorageIds(), QStringList{QStringLiteral("ff")});
}

void TestFilter::emptyCategoryAcceptsAll()
{
    m_source.setApps({
        {QStringLiteral("A"), {}, {}, {QStringLiteral("X")}, {}, QStringLiteral("a"), {}, {}, {}},
        {QStringLiteral("B"), {}, {}, {QStringLiteral("Y")}, {}, QStringLiteral("b"), {}, {}, {}},
    });
    m_filter.setFilterCategory(QString());
    QCOMPARE(m_filter.count(), 2);
}

void TestFilter::favoritesOnlyExcludesNonFavorites()
{
    m_source.setApps({
        {QStringLiteral("A"), {}, {}, {}, {}, QStringLiteral("a"), {}, {}, {}},
        {QStringLiteral("B"), {}, {}, {}, {}, QStringLiteral("b"), {}, {}, {}},
        {QStringLiteral("C"), {}, {}, {}, {}, QStringLiteral("c"), {}, {}, {}},
    });
    m_filter.setFavoriteApps({QStringLiteral("c"), QStringLiteral("a")});
    m_filter.setShowFavoritesOnly(true);
    QCOMPARE(visibleStorageIds(), (QStringList{QStringLiteral("a"), QStringLiteral("c")}));
}

void TestFilter::favoritesOnlyRejectsEmptyStorageId()
{
    // A row with no storageId can't be a favorite → excluded from the
    // favorites view (the sid.isEmpty() guard, not just !isFavorite).
    m_source.setApps({
        {QStringLiteral("NoId"), {}, {}, {}, {}, QString(), {}, {}, {}},
        {QStringLiteral("Fav"), {}, {}, {}, {}, QStringLiteral("fav"), {}, {}, {}},
    });
    m_filter.setFavoriteApps({QStringLiteral("fav")});
    m_filter.setShowFavoritesOnly(true);
    QCOMPARE(visibleStorageIds(), QStringList{QStringLiteral("fav")});
}

void TestFilter::recentsHiddenFromAllViewInAlphabetical()
{
    m_source.setApps({
        {QStringLiteral("A"), {}, {}, {}, {}, QStringLiteral("a"), {}, {}, {}},
        {QStringLiteral("B"), {}, {}, {}, {}, QStringLiteral("b"), {}, {}, {}},
        {QStringLiteral("C"), {}, {}, {}, {}, QStringLiteral("c"), {}, {}, {}},
    });
    m_filter.setSortMode(AppFilterModel::Alphabetical);
    m_filter.setRecentApps({QStringLiteral("b")});
    QCOMPARE(visibleStorageIds(), (QStringList{QStringLiteral("a"), QStringLiteral("c")}));
}

void TestFilter::recentsVisibleInMostUsed()
{
    m_source.setApps({
        {QStringLiteral("A"), {}, {}, {}, {}, QStringLiteral("a"), {}, {}, {}},
        {QStringLiteral("B"), {}, {}, {}, {}, QStringLiteral("b"), {}, {}, {}},
    });
    m_filter.setSortMode(AppFilterModel::MostUsed);
    m_filter.setRecentApps({QStringLiteral("b")});
    QCOMPARE(m_filter.count(), 2); // recents NOT filtered when sortMode != Alphabetical
}

void TestFilter::recentsShownWhenCategoryActive()
{
    // The recents-from-grid hide only applies in the unfiltered All view; with
    // a category filter active a recent app still shows (guard requires an
    // empty filterCategory).
    m_source.setApps({
        {QStringLiteral("Kate"), {}, {}, {QStringLiteral("Dev")}, {}, QStringLiteral("kate"), {}, {}, {}},
    });
    m_filter.setSortMode(AppFilterModel::Alphabetical);
    m_filter.setRecentApps({QStringLiteral("kate")});
    m_filter.setFilterCategory(QStringLiteral("Dev"));
    QCOMPARE(m_filter.count(), 1);
}

QTEST_MAIN(TestFilter)
#include "test_filter.moc"
