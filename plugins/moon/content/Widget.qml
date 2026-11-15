pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// content/Widget.qml — одни часы и одна Луна на сцене.
// Кольцо — синодический месяц: волосяные деления, светлая риска полнолуния,
// серп-метка на текущем возрасте. Внутри — время, под циферблатом — фаза.
// Один Canvas, перерисовка раз в минуту, ни анимаций, ни своих окон.
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
    readonly property bool showPhase: settings ? (settings.showPhase !== false) : true
    readonly property bool showPercent: settings ? (settings.showPercent !== false) : true
    readonly property real frac: service ? service.frac : 0
    readonly property real illum: service ? service.illum : 0
    readonly property string phaseName: service ? service.phaseName : ""

    readonly property real dial: Math.round(176 * root.s)
    readonly property real textBlock: (root.showPhase ? Math.round(26 * root.s) : 0)
                                   + (root.showPercent ? Math.round(18 * root.s) : 0)

    property string clockText: ""
    property string dateText: ""

    implicitWidth: root.service === null ? 0 : root.dial
    implicitHeight: root.service === null ? 0 : root.dial + root.textBlock + 6 * root.s
    width: implicitWidth
    height: implicitHeight

    function tick() {
        var now = new Date();
        root.clockText = Qt.formatTime(now, "hh:mm");
        root.dateText = now.toLocaleDateString(Qt.locale("ru_RU"), "dddd");
        dial.requestPaint();
    }

    Canvas {
        id: dial
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.dial
        height: root.dial
        antialiasing: true
        renderStrategy: Canvas.Immediate
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var d = width, cx = d / 2, cy = d / 2;
            var r = d / 2 - 10;
            var hair = Math.max(0.75, d / 220);

            // кольцо
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.lineWidth = hair;
            ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.12);
            ctx.stroke();

            // 30 делений; каждое седьмое — длиннее
            for (var i = 0; i < 30; i++) {
                var ang = (i / 30) * 2 * Math.PI - Math.PI / 2;
                var quarter = (i % 7 === 0);
                var r1 = r - (quarter ? 7 : 3);
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(ang) * r1, cy + Math.sin(ang) * r1);
                ctx.lineTo(cx + Math.cos(ang) * (r - 1), cy + Math.sin(ang) * (r - 1));
                ctx.lineWidth = hair;
                ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, quarter ? 0.34 : 0.13);
                ctx.stroke();
            }

            // полнолуние: короткая светлая риска
            var fa = Math.PI / 2;
            ctx.beginPath();
            ctx.moveTo(cx + Math.cos(fa) * (r - 11), cy + Math.sin(fa) * (r - 11));
            ctx.lineTo(cx + Math.cos(fa) * (r - 1), cy + Math.sin(fa) * (r - 1));
            ctx.lineWidth = hair * 1.5;
            ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.7);
            ctx.stroke();

            // серп-метка на кольце: настоящая фаза, только маленькая
            var ma = root.frac * 2 * Math.PI - Math.PI / 2;
            var mx = cx + Math.cos(ma) * (r - 9);
            var my = cy + Math.sin(ma) * (r - 9);
            var mr = Math.max(5, d * 0.042);
            var th = 2 * Math.PI * root.frac, c = Math.cos(th);
            var side = root.frac < 0.5 ? 1 : -1;

            ctx.beginPath();
            ctx.arc(mx, my, mr, 0, 2 * Math.PI);
            ctx.fillStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.10);
            ctx.fill();
            ctx.lineWidth = hair;
            ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.35);
            ctx.stroke();

            if (root.illum > 0.005) {
                ctx.beginPath();
                var a, rad, first = true;
                for (a = -90; a <= 90; a += 3) {
                    rad = a * Math.PI / 180;
                    var x = mx + side * mr * Math.cos(rad);
                    var y = my + mr * Math.sin(rad);
                    if (first) { ctx.moveTo(x, y); first = false; } else ctx.lineTo(x, y);
                }
                for (a = 90; a >= -90; a -= 3) {
                    rad = a * Math.PI / 180;
                    ctx.lineTo(mx + side * mr * c * Math.cos(rad), my + mr * Math.sin(rad));
                }
                ctx.closePath();
                ctx.fillStyle = "#F4F4F6";
                ctx.fill();
            }
        }
    }

    Text {
        anchors.centerIn: dial
        text: root.clockText
        color: Theme.bright
        font.family: Theme.mono
        font.pixelSize: 27 * root.s
        font.letterSpacing: 0.4
    }

    Column {
        anchors.top: dial.bottom
        anchors.topMargin: 2 * root.s
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3 * root.s

        Text {
            visible: root.showPhase
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.phaseName.toLowerCase()
            color: Theme.bright
            font.family: Theme.display
            font.pixelSize: 16 * root.s
        }

        Text {
            visible: root.showPercent
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.illum * 100) + " %"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 10 * root.s
            font.letterSpacing: 1.2
        }
    }

    Timer {
        interval: 60000
        running: root.service !== null
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    Connections {
        target: root
        function onFracChanged() { root.tick(); }
    }
}
