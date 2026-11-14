-- Every shell surface that fills with the crate glass (Tokens.glass, the QS Bar's
-- connected panel silhouette, the control center plate) must be frosted by a
-- decoration.lua layer rule, or it reads as a different, unfrosted glass from the
-- Controls panel (Super+Esc). Run from the repo root: lua tests/hyprland-crate-glass.lua
local source = "ryoku/hyprland/modules/decoration.lua"
local shell_root = "ryoku/shell/quickshell/shell"
local home = "/home/ryoku-test"

-- Loads decoration.lua against a fake home whose shell.json and performance.json
-- are the given strings, and returns the layer rules it registered.
local function load_rules(shell_json, performance_json)
    local files = {
        [home .. "/.config/ryoku/shell.json"] = shell_json,
        [home .. "/.config/ryoku/performance.json"] = performance_json,
    }
    local rules = {}
    local hl = setmetatable({
        layer_rule = function(rule) rules[#rules + 1] = rule end,
    }, { __index = function() return function() end end })
    local environment = {
        hl = hl,
        os = { getenv = function(name) return name == "HOME" and home or nil end },
        io = {
            open = function(path)
                local body = files[path]
                if not body then return nil end
                return { read = function() return body end, close = function() end }
            end,
            popen = function() return nil end,
        },
        dofile = function() error("no file") end,
    }
    setmetatable(environment, { __index = _G })
    assert(loadfile(source, "t", environment))()
    return rules
end

-- Hyprland matches namespaces with a regex; the crate rules keep to the
-- "^prefix(a|b|c)$" shape, which this checks without a regex engine.
local function matches(pattern, namespace)
    local prefix, alternatives = pattern:match("^%^([%w%-]*)%(([^()]*)%)%$$")
    if not prefix then
        local literal = pattern:match("^%^([%w%-]+)%$$")
        assert(literal, "unsupported namespace pattern: " .. pattern)
        return namespace == literal
    end
    for alternative in (alternatives .. "|"):gmatch("([^|]*)|") do
        if namespace == prefix .. alternative then return true end
    end
    return false
end

local function blurred(rules, namespace)
    for _, rule in ipairs(rules) do
        if rule.blur and rule.match and rule.match.namespace
            and rule.name and rule.name:match("^crate%-glass")
            and matches(rule.match.namespace, namespace) then
            assert(rule.ignore_alpha and rule.ignore_alpha > 0,
                rule.name .. " must keep the frost on the card (ignore_alpha)")
            return true
        end
    end
    return false
end

-- The glass surfaces, discovered from the QML: any file that draws one of the
-- glass fills and maps its own layer namespace.
local glass_marker = [[Tokens\.glass|ConnectedPanelSurface|AiPanelSurface|cc\.plateFill|color: root\.bg$]]
local listing = assert(io.popen("grep -rlE '" .. glass_marker .. "' " .. shell_root .. " --include='*.qml'"))
-- the first-boot Kit hint and the pins are their own configs (keys-hint, ryopin),
-- outside the shell tree; a pin's glass is its action strip
local namespaces = {
    ["ryoku-sidebar-left"] = "SidebarFrame (Super+Esc)",
    ["ryoku-keys-hint"] = "keys-hint/HintCards.qml",
    ["ryopin"] = "ryopin/PinCard.qml",
    -- the Ask bar and bubble draw their glass in child files (AskSurface,
    -- AskBubbleCard/Disc), not the file that maps the layer
    ["ryoku-ask"] = "AskBar (AskSurface)",
    ["ryoku-ask-bubble"] = "AskBubble (AskBubbleCard, AskBubbleDisc)",
    -- the hero launcher's layers host the glass drawn in LauncherCard and WindowTile
    ["launcher"] = "modules/launcher/variants/hero/LauncherCard.qml",
    ["launcher-window-rail"] = "modules/launcher/variants/hero/WindowTile.qml",
}
for path in listing:lines() do
    local file = assert(io.open(path))
    local body = file:read("a")
    file:close()
    local namespace = body:match('WlrLayershell%.namespace:%s*"([^"]+)"')
    if namespace then namespaces[namespace] = path end
end
listing:close()

for _, required in ipairs({ "ryoku-volume", "ryoku-control", "ryoku-dashboard", "ryoku-traymenu",
                            "ryoku-ask", "ryoku-ask-bubble" }) do
    assert(namespaces[required], "glass discovery missed " .. required)
end

local crate = load_rules('{ "themeStyle": { "controls": "crate" } }', "{}")
for namespace, path in pairs(namespaces) do
    assert(blurred(crate, namespace),
        string.format("%s (%s) fills with the crate glass but no crate-glass rule blurs it", namespace, path))
end

-- Blur off (power saver, disableBlur): the rules stay but never frost, and the
-- shell turns the glass opaque to match.
for _, rule in ipairs(load_rules('{ "controls": "crate" }', '{ "disableBlur": true }')) do
    if rule.name and rule.name:match("^crate%-glass") then
        assert(rule.blur == false, rule.name .. " blurs with blur disabled")
    end
end

-- Any other theme style keeps its own surfaces: no crate glass rules at all.
for _, rule in ipairs(load_rules('{ "controls": "classic" }', "{}")) do
    assert(not (rule.name and rule.name:match("^crate%-glass")),
        rule.name .. " registered without controls crate")
end

-- The panels reveal themselves in QML, so the compositor must not animate their
-- layers too (its 400 ms move and 700 ms fade made panels slow to answer).
local function no_anim(rules, namespace)
    for _, rule in ipairs(rules) do
        -- other rules use patterns this reader does not parse (^launcher); skip them
        if rule.no_anim and rule.match and rule.match.namespace then
            local ok, hit = pcall(matches, rule.match.namespace, namespace)
            if ok and hit then return true end
        end
    end
    return false
end
for _, rules in ipairs({ crate, load_rules('{ "controls": "classic" }', "{}") }) do
    for _, namespace in ipairs({ "ryoku-sidebar-left", "ryoku-volume", "ryoku-network", "ryoku-dashboard",
                                 "ryoku-plugin-panel", "ryoku-control", "ryoku-osd", "ryoku-dialog" }) do
        assert(no_anim(rules, namespace), namespace .. " still gets the compositor's layer animation")
    end
end

print("hyprland-crate-glass: OK")
