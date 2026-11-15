pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// service/Main.qml — задачи лунного виджета. Читает tasks.json из stateDir,
// переключает через свой bin/moon-task (единственный писатель), ничего не
// держит в сети и не трогает чужие файлы.
Item {
    id: svc

    property var pluginApi
    property var tasks: []
    property int openCount: 0
    property bool ready: false

    readonly property string dir: pluginApi ? pluginApi.pluginDir : ""
    readonly property string file: pluginApi ? pluginApi.stateDir + "/tasks.json" : ""

    function refresh() {
        if (!file.length)
            return;
        tasksFile.reload();
    }

    function parse(text) {
        try {
            var list = JSON.parse(text || "[]");
            if (!Array.isArray(list))
                list = [];
            svc.tasks = list;
            var open = 0;
            for (var i = 0; i < list.length; i++)
                if (!list[i].done) open++;
            svc.openCount = open;
            svc.ready = true;
        } catch (e) {
            svc.tasks = [];
            svc.openCount = 0;
            svc.ready = true;
        }
    }

    function toggle(id) {
        if (!dir.length || !pluginApi)
            return;
        Quickshell.execDetached(["bash", dir + "/bin/moon-task",
                                 pluginApi.stateDir, "toggle", String(id)]);
        refreshTimer.restart();
    }

    FileView {
        id: tasksFile
        path: svc.file
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: svc.parse(text())
    }

    Timer {
        id: refreshTimer
        interval: 250
        repeat: false
        onTriggered: svc.refresh()
    }

    Component.onCompleted: refresh()
}
