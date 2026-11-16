.pragma library

// When the lock tells its skins that the surface is up (sddm.surfaceRevealed).
// A skin may hide its UI for an unlock reveal; after a failed or cancelled
// unlock the lock is put back, and the skin needs the same signal again to
// show it. So the announcement is made the first time authentication arms and
// again the first time it arms after each recovery, never twice in between.
// state: {announced: bool, recovered: bool}

function initial() {
    return {announced: false, recovered: false}
}

// authentication armed: returns {announce, state}
function armed(state) {
    const announce = !state.announced || state.recovered
    return {announce: announce, state: {announced: true, recovered: false}}
}

// a failed or cancelled unlock restored the lock. Before the first
// announcement there is nothing to repeat: the first arm announces anyway.
function recovered(state) {
    return {announced: state.announced, recovered: state.announced}
}
