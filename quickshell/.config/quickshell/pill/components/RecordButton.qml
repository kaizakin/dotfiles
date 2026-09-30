import QtQuick
import QtQuick.Effects
import Quickshell.Io
import "../Singletons" as Local

Item {
    id: root

    // OBS authentication is disabled, so this URL has no password.
    property string websocketUrl: "obsws://localhost:4455"

    property bool obsAvailable: false
    property bool recording: false
    property bool statusQueued: false

    width: 30
    height: 30

    function poll() {
        if (statusProcess.running) return
        statusProcess.running = true
    }

    function pollAfterToggle() {
        if (statusProcess.running) {
            statusQueued = true
            return
        }
        statusProcess.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Process {
        id: statusProcess
        command: ["obs-cmd", "--websocket", root.websocketUrl, "recording", "status"]

        stdout: StdioCollector {
            id: statusOut
            waitForEnd: true
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.obsAvailable = false
                root.recording = false
            } else {
                root.obsAvailable = true
                // Idle prints "Active: false". Recording prints "Active: true".
                root.recording = statusOut.text.indexOf("Active: true") !== -1
            }

            if (root.statusQueued) {
                root.statusQueued = false
                statusProcess.running = true
            }
        }
    }

    Process {
        id: toggleProcess
        command: ["obs-cmd", "--websocket", root.websocketUrl, "recording", "toggle"]
        onExited: root.pollAfterToggle()
    }

    Item {
        anchors.fill: parent
        opacity: root.obsAvailable ? 1 : 0.85

        Image {
            id: logo
            anchors.fill: parent
            source: "../assets/obs-logo.png"
            sourceSize: Qt.size(64, 64)
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: false
            onStatusChanged: if (status === Image.Error) console.warn("obs logo failed to load")
        }

        MultiEffect {
            anchors.fill: parent
            source: logo
            brightness: mouse.containsMouse && root.obsAvailable ? 0.22 : 0
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: root.recording ? 3 : 0
            border.color: mouse.containsMouse ? "#FF6A5C" : "#FF3B30"
            antialiasing: true
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: root.obsAvailable && !toggleProcess.running
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: toggleProcess.running = true
        }
    }
}
