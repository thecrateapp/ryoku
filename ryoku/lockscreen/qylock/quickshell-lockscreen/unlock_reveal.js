.pragma library

// How long the lock surface stays raised after a successful unlock so a skin's
// reveal animation can finish. Skins opt in through theme.conf:
//   unlockRevealMs        password win, 0..5000
//   unlockSensorRevealMs  sensor win, 0..5000, falls back to unlockRevealMs
// A missing or invalid key falls through to the built-in rule: clockwork with
// enableWindup=true keeps 720/2300 ms, every other skin 100 ms.
var MAX_MS = 5000
var DEFAULT_MS = 100

function parseMs(value) {
    if (value === undefined || value === null)
        return -1
    const text = String(value).trim()
    if (!/^[0-9]+$/.test(text))
        return -1
    return Math.min(MAX_MS, parseInt(text, 10))
}

function revealDelay(theme, config, sensor) {
    const conf = config || {}
    const password = parseMs(conf.unlockRevealMs)
    const sensorMs = parseMs(conf.unlockSensorRevealMs)
    if (sensor && sensorMs >= 0)
        return sensorMs
    if (password >= 0)
        return password
    if (String(theme).includes("clockwork") && conf.enableWindup === "true") {
        // A password win answers after the wind-up already played, so only the
        // 560 ms reveal remains; a sensor win starts the full wind-up at this
        // instant (1600 ms + blast + reveal).
        return sensor ? 2300 : 720
    }
    return DEFAULT_MS
}
