pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// content/Widget.qml — лунный список задач на сцене: серп рядом с каждым делом,
// полная Луна — когда сделано. Клик переключает. Ни окон, ни анимаций.
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
    readonly property int limit: settings && settings.limit ? Math.max(1, Math.min(24, settings.limit)) : 6
    readonly property bool keepDone: settings ? (settings.showDone !== false) : true

    readonly property var all: service ? (service.tasks || []) : []
    readonly property var shown: {
        var out = [];
        for (var i = 0; i < all.length && out.length < root.limit; i++) {
            if (all[i].done && !root.keepDone) continue;
            out.push(all[i]);
        }
        return out;
    }
    // «ещё N» считает только то, что реально скрыто лимитом: при showDone=false
    // сделанные скрыты осознанно и в счётчик не идут
    readonly property int hidden: {
        var open = 0, out = 0;
        for (var i = 0; i < all.length; i++) {
            if (all[i].done && !keepDone) continue;
            if (out < limit) out++; else open++;
        }
        return open;
    }

    implicitWidth: Math.round(324 * root.s)
    implicitHeight: Math.round((44 + shown.length * 26 + (hidden > 0 ? 18 : 0)) * root.s)
    width: implicitWidth
    height: implicitHeight

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 2 * root.s

        Item {
            width: parent.width
            height: 30 * root.s

            Text {
                anchors.left: parent.left
                anchors.baseline: parent.bottom
                text: "задачи"
                color: Theme.bright
                font.family: Theme.display
                font.pixelSize: 16 * root.s
            }

            Text {
                anchors.right: parent.right
                anchors.baseline: parent.bottom
                text: root.all.length === 0 ? "—"
                                            : (root.all.length - (root.service ? root.service.openCount : 0))
                                              + " / " + root.all.length
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 10 * root.s
            }
        }

        Text {
            visible: root.service && root.service.error.length > 0
            width: parent.width
            text: root.service ? root.service.error : ""
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 11 * root.s
            wrapMode: Text.Wrap
        }

        Text {
            visible: root.shown.length === 0 && !(root.service && root.service.error.length > 0)
            width: parent.width
            text: "пусто. добавить: moon-task add «…»"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 11 * root.s
            wrapMode: Text.Wrap
        }

        Repeater {
            model: root.shown

            delegate: Item {
                id: row
                required property var modelData
                width: col.width
                height: 24 * root.s

                Canvas {
                    id: phase
                    width: 14 * root.s
                    height: 14 * root.s
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    renderStrategy: Canvas.Immediate
                    property bool done: row.modelData.done === true
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var d = width, r = d / 2 - 0.5, cx = d / 2, cy = d / 2;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                        ctx.lineWidth = 1;
                        ctx.strokeStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255,
                                                  phase.done ? 0.55 : 0.28);
                        ctx.stroke();
                        if (!phase.done) {
                            // открытая задача: узкий серп
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2);
                            ctx.arc(cx, cy, r * 0.62, Math.PI / 2, -Math.PI / 2, true);
                            ctx.closePath();
                            ctx.fillStyle = "#F4F4F6";
                            ctx.fill();
                        } else {
                            ctx.beginPath();
                            ctx.arc(cx, cy, r * 0.72, 0, 2 * Math.PI);
                            ctx.fillStyle = Qt.rgba(244 / 255, 244 / 255, 246 / 255, 0.9);
                            ctx.fill();
                        }
                    }
                    onDoneChanged: requestPaint()
                }

                Text {
                    id: label
                    anchors.left: phase.right
                    anchors.leftMargin: 10 * root.s
                    anchors.right: parent.right
                    anchors.rightMargin: 20 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.text
                    color: row.modelData.done ? Theme.dim : Theme.bright
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                    elide: Text.ElideRight
                    font.strikeout: row.modelData.done === true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.service) root.service.toggle(row.modelData.id)
                }

                // удалить совсем: маленький крестик в конце строки
                Item {
                    id: kill
                    width: 20 * root.s
                    height: parent.height
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property bool hot: hover.hovered

                    HoverHandler { id: hover }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: kill.hot ? Theme.bright : Theme.dim
                        opacity: kill.hot ? 1 : 0.45
                        font.family: Theme.mono
                        font.pixelSize: 14 * root.s
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.service) root.service.remove(row.modelData.id)
                    }
                }
            }
        }

        Text {
            visible: root.hidden > 0
            text: "ещё " + root.hidden
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 10 * root.s
        }
    }
}
