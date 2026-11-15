pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// content/Widget.qml — лунные часы: кольцо синодического месяца с меткой на
// текущем возрасте и временем внутри. Два перерисовки в минуту, без анимаций.
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
    readonly property bool showDate: settings ? (settings.showDate !== false) : true
    readonly property real frac: service ? service.frac : 0
    readonly property real age: service ? service.ageDays : 0

    readonly property real dial: Math.round(168 * root.s)

    property string clockText: ""
    property string dateText: ""

    implicitWidth: root.service === null ? 0 : root.dial
    implicitHeight: root.service === null ? 0 : root.dial
    width: implicitWidth
    height: implicitHeight

    function tick() {
        var now = new Date();
        root.clockText = Qt.formatTime(now, "hh:mm");
        root.dateText = now.toLocaleDateString(Qt.locale("ru_RU"), "ddd, dd.MM");
        dial.requestPaint();
    }

    Canvas {
        id: dial
        visible: root.service !== null
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Immediate
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var d = width, cx = d / 2, cy = d / 2;
            var r = d / 2 - 8;
            var thin = Math.max(0.75, d / 200);

            // волос по внешнему кольцу
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.lineWidth = thin;
            ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.14);
            ctx.stroke();

            // 30 делений: месяц в 29.5 суток округлён до ровного шага
            var n = 30;
            for (var i = 0; i < n; i++) {
                var ang = (i / n) * 2 * Math.PI - Math.PI / 2;
                var quarter = (i % 7 === 0);
                var r1 = r - (quarter ? 8 : 4);
                var r2 = r - 1;
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(ang) * r1, cy + Math.sin(ang) * r1);
                ctx.lineTo(cx + Math.cos(ang) * r2, cy + Math.sin(ang) * r2);
                ctx.lineWidth = thin;
                ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, quarter ? 0.4 : 0.15);
                ctx.stroke();
            }

            // полнолуние — короткая светлая риска на половине месяца
            var fa = 0.5 * 2 * Math.PI - Math.PI / 2;
            ctx.beginPath();
            ctx.moveTo(cx + Math.cos(fa) * (r - 12), cy + Math.sin(fa) * (r - 12));
            ctx.lineTo(cx + Math.cos(fa) * (r - 1), cy + Math.sin(fa) * (r - 1));
            ctx.lineWidth = thin * 1.6;
            ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.72);
            ctx.stroke();

            // метка текущего возраста
            var ma = root.frac * 2 * Math.PI - Math.PI / 2;
            var mx = cx + Math.cos(ma) * (r - 6);
            var my = cy + Math.sin(ma) * (r - 6);
            ctx.beginPath();
            ctx.arc(mx, my, Math.max(2.2, d * 0.017), 0, 2 * Math.PI);
            ctx.fillStyle = "#F4F4F6";
            ctx.fill();
        }
    }

    Column {
        visible: root.service !== null
        anchors.centerIn: parent
        spacing: 2 * root.s

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.clockText
            color: Theme.bright
            font.family: Theme.mono
            font.pixelSize: 22 * root.s
            font.letterSpacing: 0.5
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.age.toFixed(1) + " / 29.5"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 9 * root.s
            font.letterSpacing: 1.4
        }

        Text {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 9 * root.s
            font.letterSpacing: 1.4
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
