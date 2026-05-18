/*
    SPDX-FileCopyrightText: 2026 AppGrid Contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QDateTime>
#include <QObject>
#include <QTimer>

class QNetworkAccessManager;

/**
 * Polls the AppGrid website's static `latest.json` to flag updates.
 * Notify-only; click opens the release page. Opt-in via settings.
 *
 * Only compiled when APPGRID_UNIVERSAL_BUILD is set — distro packages
 * leave update handling to their package manager.
 */
class UpdateChecker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasUpdate READ hasUpdate NOTIFY hasUpdateChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)
    Q_PROPERTY(QString releaseUrl READ releaseUrl NOTIFY releaseUrlChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)

public:
    explicit UpdateChecker(const QString &currentVersion, QObject *parent = nullptr);
    ~UpdateChecker() override;

    bool hasUpdate() const { return m_hasUpdate; }
    QString latestVersion() const { return m_latestVersion; }
    QString releaseUrl() const { return m_releaseUrl; }
    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    Q_INVOKABLE void checkNow();
    Q_INVOKABLE void openReleasePage();

    // Pure helpers — public for unit testing.
    static bool isNewer(const QString &candidate, const QString &current);
    static bool isAllowedReleaseScheme(const class QUrl &url);
    static bool isValidVersionString(const QString &v);

Q_SIGNALS:
    void hasUpdateChanged();
    void latestVersionChanged();
    void releaseUrlChanged();
    void enabledChanged();

private:
    void runCheck(bool force);
    void handleReply(class QNetworkReply *reply);
    void loadState();
    void saveState();

    QString m_currentVersion;
    QString m_latestVersion;
    QString m_releaseUrl;
    QDateTime m_lastCheck;
    QString m_etag;
    bool m_hasUpdate = false;
    bool m_enabled = false;
    // ETag rotates every kEtagResetEvery saves to prevent long-term tracking.
    int m_etagAge = 0;
    // Parent-owned, torn down + rebuilt each check (TLS session ticket reset).
    QNetworkAccessManager *m_network = nullptr;
    QTimer m_periodicTimer;
};
