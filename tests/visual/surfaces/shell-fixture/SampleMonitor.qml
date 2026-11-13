import QtQuick

// Deterministic input for the Controls board's real vitals and resource meters.
QtObject {
    property bool active: false
    readonly property int samplePeriodMs: 250
    readonly property int sampleCount: 5
    readonly property string userName: "studio"
    readonly property string hostName: "workstation"
    readonly property int uptimeSeconds: 5600
    readonly property real loadAverage: 0.6
    readonly property string cpuName: "Desktop CPU"
    readonly property bool cpuAvailable: true
    readonly property real cpuPercent: 36
    readonly property real cpuFrequencyGhz: 3.2
    readonly property bool cpuTempAvailable: true
    readonly property real cpuTemp: 49
    readonly property string cpuTempLabel: "package"
    readonly property var coreLoads: [18, 56, 35, 43, 32, 19, 41, 44]
    readonly property int coreCount: coreLoads.length
    readonly property bool memoryAvailable: true
    readonly property real memoryUsedGiB: 6.5
    readonly property real memoryTotalGiB: 16
    readonly property real swapUsedGiB: 0
    readonly property bool gpuAvailable: true
    readonly property real gpuPercent: 24
    readonly property real gpuTemp: 43
    readonly property bool gpuTempAvailable: true
    readonly property bool gpuMemoryAvailable: true
    readonly property real gpuMemoryUsedGiB: 2
    readonly property real gpuMemoryTotalGiB: 8
    readonly property bool networkAvailable: false
    readonly property string networkInterface: ""
    readonly property real networkRxBytesPerSec: 0
    readonly property real networkTxBytesPerSec: 0
    readonly property bool diskAvailable: true
    readonly property real diskReadBytesPerSec: 3145728
    readonly property real diskWriteBytesPerSec: 1048576
    readonly property real storageUsedGiB: 120
    readonly property real storageTotalGiB: 512
    readonly property bool storageTempAvailable: true
    readonly property real storageTemp: 37
    readonly property bool batteryAvailable: true
    readonly property real batteryPercent: 78
    readonly property bool batteryCharging: false
}
