#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QDateTime>
#include <QStandardPaths>
#include <QElapsedTimer>
#include <QDebug>
#include <QTimer>

#include "backend/AppController.h"

void customLogHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(type);
    Q_UNUSED(context);

    const QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!appData.isEmpty())
    {
        const QString logDirPath = QDir(appData).filePath(QStringLiteral("logs"));
        QDir logDir(logDirPath);
        if (!logDir.exists())
        {
            logDir.mkpath(QStringLiteral("."));
        }

        const QString logFilePath = logDir.filePath(QStringLiteral("application.log"));
        QFile file(logFilePath);
        if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
        {
            QTextStream stream(&file);
            stream << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz ") << msg << "\n";
        }
    }
}

int main(int argc, char *argv[])
{
    QElapsedTimer totalStartupTimer;
    totalStartupTimer.start();

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QCoreApplication::setOrganizationName("GenericDataAnalyzer");
    QCoreApplication::setApplicationName("GenericDataAnalyzer");

    qInstallMessageHandler(customLogHandler);

    qInfo() << "[STARTUP] Application startup sequence initiated";

    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(QStringLiteral(":/qml/assets/app_icon.ico")));

    QQmlApplicationEngine engine;

    QElapsedTimer controllerTimer;
    controllerTimer.start();
    AppController appController;
    qInfo() << "[STARTUP] AppController constructor total:" << controllerTimer.elapsed() << "ms";

    qmlRegisterSingletonInstance<AppController>(
        "GenericDataAnalyzer",
        1,
        0,
        "AppController",
        &appController
    );

    if (appController.autoRestoreEnabled())
    {
        qInfo() << "[STARTUP][Session] Auto-restoring datasets before UI engine load";
        appController.autoRestoreDatasets();
    }

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url, totalStartupTimer](QObject *object, const QUrl &objectUrl)
        {
            if (!object && url == objectUrl)
            {
                qWarning() << "Failed to create root object for URL:" << objectUrl;
                QCoreApplication::exit(-1);
            }
            else if (url == objectUrl)
            {
                qInfo() << "[STARTUP] Root object created & window ready:" << totalStartupTimer.elapsed() << "ms";
                qInfo() << "[STARTUP] TOTAL STARTUP TIME:" << totalStartupTimer.elapsed() << "ms";
            }
        },
        Qt::QueuedConnection
        );

    QElapsedTimer qmlTimer;
    qmlTimer.start();
    engine.load(url);
    qInfo() << "[STARTUP] QML engine.load():" << qmlTimer.elapsed() << "ms";

    return app.exec();
}