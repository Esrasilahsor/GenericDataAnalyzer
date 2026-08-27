#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QFile>
#include <QTextStream>
#include <QDateTime>

#include "backend/AppController.h"

void customLogHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(type);
    Q_UNUSED(context);
    QFile file("debug_startup.log");
    if (file.open(QIODevice::WriteOnly | QIODevice::Append))
    {
        QTextStream stream(&file);
        stream << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz ") << msg << "\n";
    }
}

int main(int argc, char *argv[])
{
    qInstallMessageHandler(customLogHandler);

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);

    QCoreApplication::setOrganizationName("GenericDataAnalyzer");
    QCoreApplication::setApplicationName("GenericDataAnalyzer");

    QQmlApplicationEngine engine;

    AppController appController;

    engine.rootContext()->setContextProperty(
        "appController",
        &appController
        );

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *object, const QUrl &objectUrl)
        {
            if (!object && url == objectUrl)
            {
                qWarning() << "Failed to create root object for URL:" << objectUrl;
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection
        );

    engine.load(url);

    return app.exec();
}