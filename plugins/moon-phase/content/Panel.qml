import QtQuick
import Ryoku.PluginKit.Singletons

// content/Panel.qml — карточка под глифом: крупная Луна и данные фазы.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 300
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property real frac: service ? service.frac : 0
    readonly property real illum: service ? service.illum : 0
    readonly property real age: service ? service.ageDays : 0
    readonly property string phaseName: service ? service.phaseName : ""
    readonly property string nextFull: service ? service.nextFullText : ""

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 8 * root.s

        Text {
            text: "MOON"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 9 * root.s
            font.letterSpacing: 2.2 * root.s
        }

        Canvas {
            id: big
            width: 96 * root.s
            height: 96 * root.s
            antialiasing: true
            renderStrategy: Canvas.Immediate
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var d = width, r = d / 2 - 1, cx = d / 2, cy = d / 2;
                var th = 2 * Math.PI * root.frac, c = Math.cos(th);
                var side = root.frac < 0.5 ? 1 : -1;

                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.fillStyle = Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.18);
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
                }
            }
            Connections {
                target: root
                function onFracChanged() { big.requestPaint(); }
            }
        }

        Text {
            visible: root.service !== null
            text: root.phaseName
            color: Theme.bright
            font.family: Theme.font
            font.pixelSize: 15 * root.s
        }

        Text {
            visible: root.service !== null
            text: Math.round(root.illum * 100) + "% · " + root.age.toFixed(1) + " d"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 12 * root.s
        }

        Text {
            visible: root.nextFull.length > 0
            text: "Next full: " + root.nextFull
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }
    }
}
