pragma ComponentBehavior: Bound

import QtQuick

// service/Main.qml — логика плагина, без UI.
// Фаза считается по разности эклиптических долгот Луны и Солнца (усечённый ряд
// Meeus, точность ~минуты). Сеть не используется, состояние только в памяти.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    // 0 = новолуние, 0.5 = полнолуние, 1 = снова новолуние.
    property real frac: 0
    property real illum: 0
    property real ageDays: 0
    property string phaseName: ""
    property string nextFullText: ""
    property bool ready: false

    readonly property int synodicDays: 29.530588853
    readonly property real rad: Math.PI / 180

    function norm(x) { return ((x % 360) + 360) % 360; }
    function jd(d) { return d.getTime() / 86400000 + 2440587.5; }

    function sunLon(T) {
        var L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T;
        var M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T;
        var C = 1.914602 * Math.sin(M * svc.rad)
              - 0.004817 * T * Math.sin(M * svc.rad)
              - 0.000014 * T * T * Math.sin(M * svc.rad)
              + 0.019993 * Math.sin(2 * M * svc.rad)
              + 0.000289 * Math.sin(3 * M * svc.rad);
        return svc.norm(L0 + C);
    }

    function moonLon(T) {
        var Lp = 218.3164477 + 481267.88123421 * T - 0.0015786 * T * T
               + T * T * T / 538841 - T * T * T * T / 65194000;
        var D = 297.8501921 + 445267.1114034 * T - 0.0018819 * T * T
              + T * T * T / 545868 - T * T * T * T / 113065000;
        var M = 357.5291092 + 35999.0502909 * T - 0.0001536 * T * T + T * T * T / 24490000;
        var Mp = 134.9633964 + 477198.8675055 * T + 0.0087414 * T * T
               + T * T * T / 69699 - T * T * T * T / 14712000;
        var F = 93.2720950 + 483202.0175233 * T - 0.0036539 * T * T
              - T * T * T / 3526000 + T * T * T * T / 863310000;
        var s = Math.sin;
        var dl = 6.288774 * s(Mp * svc.rad)
               + 1.274027 * s((2 * D - Mp) * svc.rad)
               + 0.658314 * s(2 * D * svc.rad)
               + 0.213618 * s(2 * Mp * svc.rad)
               - 0.185116 * s(M * svc.rad)
               - 0.114332 * s(2 * F * svc.rad)
               + 0.058793 * s((2 * D - 2 * Mp) * svc.rad)
               + 0.057066 * s((2 * D - M - Mp) * svc.rad)
               + 0.053322 * s((2 * D + Mp) * svc.rad)
               + 0.045758 * s((2 * D - M) * svc.rad)
               - 0.040923 * s((M - Mp) * svc.rad)
               - 0.034720 * s(D * svc.rad)
               - 0.030383 * s((M + Mp) * svc.rad)
               + 0.015327 * s((2 * D - 2 * F) * svc.rad)
               - 0.012528 * s((Mp + 2 * F) * svc.rad)
               + 0.010980 * s((Mp - 2 * F) * svc.rad)
               + 0.010675 * s((4 * D - Mp) * svc.rad)
               + 0.010034 * s(3 * Mp * svc.rad);
        return svc.norm(Lp + dl);
    }

    function elongation(date) {
        var T = (svc.jd(date) - 2451545) / 36525;
        return svc.norm(svc.moonLon(T) - svc.sunLon(T));
    }

    function nameFor(f) {
        if (f < 0.02 || f > 0.98) return "New moon";
        if (f < 0.22) return "Waxing crescent";
        if (f < 0.28) return "First quarter";
        if (f < 0.47) return "Waxing gibbous";
        if (f <= 0.53) return "Full moon";
        if (f < 0.72) return "Waning gibbous";
        if (f < 0.78) return "Last quarter";
        return "Waning crescent";
    }

    function signedDiff(date, target) {
        return ((svc.elongation(date) - target + 180) % 360 + 360) % 360 - 180;
    }

    function nextFull(date) {
        var t = date.getTime(), step = 3600000, prev = svc.signedDiff(new Date(t), 180);
        for (var i = 1; i <= 24 * 40; i++) {
            var cur = t + i * step;
            var f = svc.signedDiff(new Date(cur), 180);
            if (prev <= 0 && f > 0) {
                var lo = cur - step, hi = cur;
                for (var j = 0; j < 32; j++) {
                    var mid = (lo + hi) / 2;
                    if (svc.signedDiff(new Date(mid), 180) > 0) hi = mid;
                    else lo = mid;
                }
                return new Date(hi);
            }
            prev = f;
        }
        return null;
    }

    function refresh() {
        var now = new Date();
        var e = svc.elongation(now);
        svc.frac = e / 360;
        svc.illum = (1 - Math.cos(e * svc.rad)) / 2;
        svc.ageDays = svc.frac * svc.synodicDays;
        svc.phaseName = svc.nameFor(svc.frac);
        var nf = svc.nextFull(now);
        svc.nextFullText = nf ? Qt.formatDateTime(nf, "dd.MM.yyyy hh:mm") : "";
        svc.ready = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: svc.refresh()
    }
}
