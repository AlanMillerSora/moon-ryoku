pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// service/Main.qml — задачи лунного виджета. Читает tasks.json из stateDir,
// переключает одним своим процессом (bin/moon-task — единственный писатель под
// flock, поэтому двойной клик не теряется). Сеть и чужие файлы не трогает.
Item {
    id: svc

    property var pluginApi
    property var tasks: []
    property int openCount: 0
    property bool ready: false
    property bool busy: false
    property string error: ""

    readonly property string dir: pluginApi ? pluginApi.pluginDir : ""

    // Хост desktopWidget в 1.0.9 не отдаёт pluginApi.stateDir (он есть только у
    // бара). Собираем тот же каталог сами — это ровно путь R8, но записанный
    // явно, иначе виджет читал бы "undefined/tasks.json".
    readonly property string stateDir: (pluginApi && pluginApi.stateDir)
        ? pluginApi.stateDir
        : (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
          + "/ryoku/plugins/moon-tasks"
    readonly property string file: svc.stateDir + "/tasks.json"

    function refresh() {
        if (!file.length)
            return;
        tasksFile.reload();
    }

    function parse(text) {
        svc.error = "";
        try {
            var list = JSON.parse(text || "[]");
            if (!Array.isArray(list)) {
                svc.error = "tasks.json: ожидался список";
                return;
            }
            svc.tasks = list;
            var open = 0;
            for (var i = 0; i < list.length; i++)
                if (!list[i].done) open++;
            svc.openCount = open;
            svc.ready = true;
        } catch (e) {
            svc.tasks = [];
            svc.openCount = 0;
            svc.error = "tasks.json не читается";
            svc.ready = true;
        }
    }

    function run(command, id) {
        if (!dir.length || !pluginApi || svc.busy)
            return;
        svc.busy = true;
        toggler.command = ["bash", dir + "/bin/moon-task",
                           svc.stateDir, command, String(id)];
        toggler.running = true;
    }

    function toggle(id) { run("toggle", id); }
    function remove(id) { run("remove", id); }

    FileView {
        id: tasksFile
        path: svc.file
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: svc.parse(text())
    }

    Process {
        id: toggler
        onExited: {
            svc.busy = false;
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 200
        repeat: false
        onTriggered: svc.refresh()
    }

    Component.onCompleted: refresh()
}
