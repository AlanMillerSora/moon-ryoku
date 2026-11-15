pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// content/Widget.qml — луна на сцене: тонкий контур диска, освещённая часть
// с мягким градиентом по лимбу и почти невидимым ореолом. Никаких кратеров и
// анимаций: один Canvas, перерисовка раз в минуту.
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

    readonly property real moonSize: Math.round(96 * root.s)
    readonly property real captionWidth: Math.round(196 * root.s)

    implicitWidth: root.service === null ? 0
                 : (root.showDetails ? root.moonSize + 20 * root.s + root.captionWidth
                                     : root.moonSize)
    implicitHeight: root.service === null ? 0 : Math.round(root.moonSize + 8 * root.s)

    Canvas {
        id: moon
        visible: root.service !== null
        width: root.moonSize
        height: root.moonSize
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        antialiasing: true
        renderStrategy: Canvas.Immediate
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var d = width, r = d / 2 - 3, cx = d / 2, cy = d / 2;
            var th = 2 * Math.PI * root.frac, c = Math.cos(th);
            var side = root.frac < 0.5 ? 1 : -1;
            var thin = Math.max(0.75, d / 120);

            // тёмная сторона: едва заметная заливка и волос по контуру
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fillStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.045);
            ctx.fill();
            ctx.lineWidth = thin;
            ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.16);
            ctx.stroke();

            if (root.illum <= 0.005)
                return;

            // освещённая часть: полигон терминатора
            var pts = [], a, rad;
            for (a = -90; a <= 90; a += 0.75) {
                rad = a * Math.PI / 180;
                pts.push([cx + side * r * Math.cos(rad), cy + r * Math.sin(rad)]);
            }
            for (a = 90; a >= -90; a -= 0.75) {
                rad = a * Math.PI / 180;
                pts.push([cx + side * r * c * Math.cos(rad), cy + r * Math.sin(rad)]);
            }

            ctx.save();
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (var i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
            ctx.closePath();

            // свет приходит с освещённого лимба: градиент поперёк диска
            var x0 = cx + side * r, x1 = cx - side * r * c;
            var g = ctx.createLinearGradient(x0, cy, x1, cy);
            g.addColorStop(0.0, "#FCFCFD");
            g.addColorStop(0.55, "#E9EBF0");
            g.addColorStop(1.0, "#C3C7D0");
            ctx.fillStyle = g;

            ctx.fill();

            // терминатор: мягкая линия вместо резкого среза
            ctx.save();
            ctx.beginPath();
            for (var k = 90; k >= -90; k -= 0.75) {
                var rk = k * Math.PI / 180;
                var tx = cx + side * r * c * Math.cos(rk);
                var ty = cy + r * Math.sin(rk);
                if (k === 90) ctx.moveTo(tx, ty); else ctx.lineTo(tx, ty);
            }
            ctx.lineWidth = Math.max(1, d * 0.012);
            ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.30);
            ctx.stroke();
            ctx.restore();

            // волос по освещённому краю, чтобы срез был чистым
            ctx.lineWidth = thin;
            ctx.strokeStyle = Qt.rgba(252 / 255, 252 / 255, 253 / 255, 0.55);
            ctx.stroke();
            ctx.restore();
        }
        Connections {
            target: root
            function onFracChanged() { moon.requestPaint(); }
        }
    }

    Column {
        visible: root.service !== null && root.showDetails
        anchors.left: moon.right
        anchors.leftMargin: 20 * root.s
        anchors.verticalCenter: parent.verticalCenter
        width: root.captionWidth
        spacing: 5 * root.s

        Text {
            text: root.phaseName
            color: Theme.bright
            font.family: Theme.font
            font.pixelSize: 15 * root.s
            width: parent.width
            elide: Text.ElideRight
        }

        Text {
            text: Math.round(root.illum * 100) + "%  ·  " + root.age.toFixed(1) + " d"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 12 * root.s
        }

        Text {
            visible: root.nextFull.length > 0
            text: "полнолуние " + root.nextFull
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 10 * root.s
            width: parent.width
            elide: Text.ElideRight
        }
    }
}
