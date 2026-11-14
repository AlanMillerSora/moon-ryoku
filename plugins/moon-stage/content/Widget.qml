pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// content/Widget.qml — вид на сцене (хост desktopWidget): крупный серп, фаза,
// процент и следующее полнолуние. Никаких анимаций и своих окон: рисуем один
// Canvas и перерисовываем его только когда меняется фаза (раз в минуту).
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "compact"
    property real s: 1
    property real widthBudget: 360
    property bool open: false
    property real reveal: 0
    property bool tabActive: false
    signal requestClose()

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    readonly property bool showDetails: settings ? (settings.showDetails !== false) : true
    readonly property real frac: service ? service.frac : 0
    readonly property real illum: service ? service.illum : 0
    readonly property real age: service ? service.ageDays : 0
    readonly property string phaseName: service ? service.phaseName : ""
    readonly property string nextFull: service ? service.nextFullText : ""

    readonly property real moonSize: Math.round(104 * root.s)

    implicitWidth: Math.round((root.moonSize + 18 + 190) * root.s)
    implicitHeight: Math.round((root.moonSize + 12) * root.s)

    Row {
        id: row
        visible: root.service !== null
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18 * root.s

        Canvas {
            id: moon
            width: root.moonSize
            height: root.moonSize
            anchors.verticalCenter: parent.verticalCenter
            antialiasing: true
            renderStrategy: Canvas.Immediate
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var d = width, r = d / 2 - 1.5, cx = d / 2, cy = d / 2;
                var th = 2 * Math.PI * root.frac, c = Math.cos(th);
                var side = root.frac < 0.5 ? 1 : -1;

                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.fillStyle = Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.16);
                ctx.fill();

                if (root.illum > 0.005) {
                    ctx.beginPath();
                    var a, rad, first = true;
                    for (a = -90; a <= 90; a += 1.5) {
                        rad = a * Math.PI / 180;
                        var x = cx + side * r * Math.cos(rad);
                        var y = cy + r * Math.sin(rad);
                        if (first) { ctx.moveTo(x, y); first = false; } else ctx.lineTo(x, y);
                    }
                    for (a = 90; a >= -90; a -= 1.5) {
                        rad = a * Math.PI / 180;
                        ctx.lineTo(cx + side * r * c * Math.cos(rad), cy + r * Math.sin(rad));
                    }
                    ctx.closePath();
                    ctx.fillStyle = Theme.bright;
                    ctx.fill();
                } else {
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.strokeStyle = Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.55);
                    ctx.lineWidth = 1;
                    ctx.stroke();
                }
            }
            Connections {
                target: root
                function onFracChanged() { moon.requestPaint(); }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(190 * root.s)
            spacing: 6 * root.s

            Text {
                text: "MOON"
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 9 * root.s
                font.letterSpacing: 2.2 * root.s
            }

            Text {
                text: root.phaseName
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: 17 * root.s
                width: parent.width
                elide: Text.ElideRight
            }

            Text {
                text: Math.round(root.illum * 100) + "%" + (root.showDetails ? " · " + root.age.toFixed(1) + " d" : "")
                color: Theme.bright
                font.family: Theme.mono
                font.pixelSize: 13 * root.s
            }

            Text {
                visible: root.showDetails && root.nextFull.length > 0
                text: "Next full: " + root.nextFull
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 10 * root.s
                width: parent.width
                elide: Text.ElideRight
            }
        }
    }
}
