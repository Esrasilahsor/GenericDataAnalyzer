pragma Singleton

import QtQuick 2.15

QtObject {
    property bool darkMode: false

    // Light mode
    property color lightBackground: "#F7F5FB"
    property color lightSurface: "#FFFFFF"
    property color lightSurfaceAlt: "#F1EDF8"
    property color lightBorder: "#E5DFF0"

    property color lightText: "#302B3D"
    property color lightTextSecondary: "#777184"

    property color lightPrimary: "#A78BCE"
    property color lightPrimaryDark: "#8F72B8"
    property color lightAccent: "#D9A8C8"

    // Dark mode
    property color darkBackground: "#181520"
    property color darkSurface: "#221E2D"
    property color darkSurfaceAlt: "#2A2536"
    property color darkBorder: "#393245"

    property color darkText: "#F5F1FA"
    property color darkTextSecondary: "#B8B0C4"

    property color darkPrimary: "#B69AD8"
    property color darkPrimaryDark: "#9B7BC1"
    property color darkAccent: "#D8A6C5"

    // Semantic
    property color success: "#8BC9A3"
    property color warning: "#E8C889"
    property color error: "#DF929C"
    property color info: "#91B7D8"

    // Active colors
    property color background:
        darkMode ? darkBackground : lightBackground

    property color surface:
        darkMode ? darkSurface : lightSurface

    property color surfaceAlt:
        darkMode ? darkSurfaceAlt : lightSurfaceAlt

    property color border:
        darkMode ? darkBorder : lightBorder

    property color text:
        darkMode ? darkText : lightText

    property color textSecondary:
        darkMode ? darkTextSecondary : lightTextSecondary

    property color primary:
        darkMode ? darkPrimary : lightPrimary

    property color primaryDark:
        darkMode ? darkPrimaryDark : lightPrimaryDark

    property color accent:
        darkMode ? darkAccent : lightAccent
}