pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// content/Widget.qml — вид на баре: серп Луны по текущей фазе и, по настройке,
// процент освещённости. Рисуется полигоном, без картинок и без сети.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0
    property bool open: false
    property real reveal: 0
    property bool tabActive: false
    signal requestClose()

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    readonly property real frac: service ? service.frac : 0
    readonly property real illum: service ? service.illum : 0
    readonly property bool showPercent: settings ? (settings.showPercent !== false) : true
    readonly property int glyphSize: Math.round(13 * root.s)

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(row.implicitHeight, 18 * root.s)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5 * root.s

        Canvas {
            id: moon
            width: root.glyphSize
            height: root.glyphSize
            anchors.verticalCenter: parent.verticalCenter
            antialiasing: true
            renderStrategy: Canvas.Immediate
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var d = width, r = d / 2 - 0.5, cx = d / 2, cy = d / 2;
                var th = 2 * Math.PI * root.frac, c = Math.cos(th);
                var side = root.frac < 0.5 ? 1 : -1;

                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.fillStyle = Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.22);
                ctx.fill();

                if (root.illum > 0.005) {
                    ctx.beginPath();
                    var a, rad, first = true;
                    for (a = -90; a <= 90; a += 3) {
                        rad = a * Math.PI / 180;
                        var x = cx + side * r * Math.cos(rad);
                        var y = cy + r * Math.sin(rad);
                        if (first) { ctx.moveTo(x, y); first = false; } else ctx.lineTo(x, y);
                    }
                    for (a = 90; a >= -90; a -= 3) {
                        rad = a * Math.PI / 180;
                        ctx.lineTo(cx + side * r * c * Math.cos(rad), cy + r * Math.sin(rad));
                    }
                    ctx.closePath();
                    ctx.fillStyle = (root.active || root.open) ? Theme.accent : Theme.bright;
                    ctx.fill();
                } else {
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.strokeStyle = Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.6);
                    ctx.lineWidth = 1;
                    ctx.stroke();
                }
            }
            Connections {
                target: root
                function onFracChanged() { moon.requestPaint(); }
                function onActiveChanged() { moon.requestPaint(); }
            }
        }

        Text {
            visible: root.showPercent
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.illum * 100) + "%"
            color: (root.active || root.open) ? Theme.accent : Theme.bright
            font.family: Theme.mono
            font.pixelSize: 11 * root.s
            elide: Text.ElideRight
            width: root.widthBudget > 0 ? Math.min(implicitWidth, root.widthBudget) : implicitWidth
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.pluginApi)
                return;
            if (root.open)
                root.requestClose();
            else if (root.pluginApi.togglePanel)
                root.pluginApi.togglePanel();
        }
    }
}
