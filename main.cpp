#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>


#include "backend/AppController.h"

int main(int argc, char *argv[])
{

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);




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
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
        );

    engine.load(url);

    return app.exec();
}