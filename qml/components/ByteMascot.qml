import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    // =========================================================
    // 1. PUBLIC PROPERTIES
    // =========================================================

    property string source: ""
    property bool animated: false

    // Size variants: "hero", "placeholder" (or "large"), "section" (or "medium"), "inline" (or "compact"), "custom"
    property string sizeVariant: "section"

    // Responsive scaling tuning
    property real sizeScale: 1.0

    // Explicit overrides (if undefined/not set, computed from sizeVariant & responsive rules)
    property real minimumSize: defaultMinimumSize
    property real maximumSize: defaultMaximumSize
    property real scaleRatio: defaultScaleRatio

    // =========================================================
    // 2. VARIANT PRESETS
    // =========================================================

    readonly property real defaultMinimumSize: {
        switch (root.sizeVariant) {
        case "hero":
            return 100
        case "placeholder":
        case "large":
            return 120
        case "inline":
        case "compact":
            return 48
        case "section":
        case "medium":
        default:
            return 60
        }
    }

    readonly property real defaultMaximumSize: {
        switch (root.sizeVariant) {
        case "hero":
            return 170
        case "placeholder":
        case "large":
            return 200
        case "inline":
        case "compact":
            return 72
        case "section":
        case "medium":
        default:
            return 96
        }
    }

    readonly property real defaultScaleRatio: {
        switch (root.sizeVariant) {
        case "hero":
            return 0.12
        case "placeholder":
        case "large":
            return 0.16
        case "inline":
        case "compact":
            return 0.05
        case "section":
        case "medium":
        default:
            return 0.075
        }
    }

    // =========================================================
    // 3. RESPONSIVE CONTAINER & SIZE CALCULATION
    // =========================================================

    readonly property real containerWidth: {
        var p = root.parent
        while (p) {
            if (p.width > 200 && p.width < 10000) {
                return p.width
            }
            p = p.parent
        }
        return 1000
    }

    readonly property real baseCalculatedSize: Math.min(
        root.maximumSize,
        Math.max(
            root.minimumSize,
            root.containerWidth * root.scaleRatio
        )
    )

    readonly property real effectiveSize: Math.round(baseCalculatedSize * root.sizeScale)

    // Backward-compatible properties that sync to effectiveSize
    property real mascotWidth: effectiveSize
    property real mascotHeight: effectiveSize

    // Layout integration
    implicitWidth: effectiveSize
    implicitHeight: effectiveSize
    Layout.preferredWidth: effectiveSize
    Layout.preferredHeight: effectiveSize

    // =========================================================
    // 4. MASCOT IMAGE
    // =========================================================

    Image {
        id: mascotImage

        anchors.centerIn: parent

        width: root.effectiveSize
        height: root.effectiveSize

        source: root.source

        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        cache: true

        opacity: 1.0
    }

    // =========================================================
    // 5. FLOATING ANIMATION
    // =========================================================

    SequentialAnimation {
        running: root.animated
        loops: Animation.Infinite

        NumberAnimation {
            target: mascotImage
            property: "anchors.verticalCenterOffset"
            from: 0
            to: -5
            duration: 900
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: mascotImage
            property: "anchors.verticalCenterOffset"
            from: -5
            to: 0
            duration: 900
            easing.type: Easing.InOutQuad
        }
    }
}
