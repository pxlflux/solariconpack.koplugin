-- Solar Icon Pack installer for KOReader

local DataStorage = require("datastorage")
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local LuaSettings = require("luasettings")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local ffiutil = require("ffi/util")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local util = require("util")
local _ = require("gettext")
local T = ffiutil.template

local STYLES = { "Colour", "Mono" }
local BACKUP_DIRNAME = ".solariconpack-backup"
local ACTION_ALIAS = { library = "home", settings = "sui_settings" }

local SolarIcons = WidgetContainer:extend{
    name = "solariconpack",
    is_doc_only = false,
}

-- Paths and plugin detection

local function koreaderIconsDir()
    return DataStorage:getDataDir() .. "/icons"
end

local function simpleuiDir()
    return DataStorage:getSettingsDir() .. "/simpleui"
end

local function suiIconsDir()
    return simpleuiDir() .. "/sui_icons"
end

local function simpleUIActive()
    return package.loaded["features/sui_style"] ~= nil
end

function SolarIcons:pluginsDir()
    return self.path:match("^(.*)/[^/]+$")
end

local function pluginDisabled(name)
    local disabled = G_reader_settings and G_reader_settings:readSetting("plugins_disabled")
    return type(disabled) == "table" and disabled[name] and true or false
end

function SolarIcons:simpleUIInstalled()
    return util.directoryExists(self:pluginsDir() .. "/simpleui.koplugin")
end

function SolarIcons:simpleUIEnabled()
    return simpleUIActive() or (self:simpleUIInstalled() and not pluginDisabled("simpleui"))
end

function SolarIcons:projectTitleDir()
    local dir = self:pluginsDir() .. "/projecttitle.koplugin"
    if util.directoryExists(dir .. "/resources") then return dir end
end

function SolarIcons:projectTitleEnabled()
    return self:projectTitleDir() ~= nil and not pluginDisabled("projecttitle")
end

function SolarIcons:bookshelfEnabled()
    return util.directoryExists(self:pluginsDir() .. "/bookshelf.koplugin") and not pluginDisabled("bookshelf")
end

function SolarIcons:zenOSDir()
    for __, name in ipairs({ "zenos.koplugin", "zen_ui.koplugin" }) do
        local dir = self:pluginsDir() .. "/" .. name
        if util.directoryExists(dir) then return dir end
    end
end

function SolarIcons:zenOSInstalled()
    return self:zenOSDir() ~= nil
end

function SolarIcons:zenOSEnabled()
    return self:zenOSInstalled() and not pluginDisabled("zenos") and not pluginDisabled("zen_ui")
end

local function zenPackDir(style)
    return koreaderIconsDir() .. "/zen/Solar_" .. style
end

local ZEN_PLUGIN_ICONS = { "zen_ui.svg", "zen_ui_update.svg" }

-- Icon build

local function buildRoot()
    return DataStorage:getSettingsDir() .. "/solariconpack-build"
end

local function fmt(v)
    local s = string.format("%.3f", v):gsub("0+$", ""):gsub("%.$", "")
    if s == "-0" then return "0" end
    return s
end

local function movePoint(x, y, step)
    local dx, dy = x - 12, y - 12
    local k = step.scale or 1
    local shift = step.shift or { 0, 0 }
    return 12 + dx * k + shift[1], 12 + dy * k + shift[2]
end

local ARGS = { M = 2, L = 2, C = 6, S = 4, Q = 4, T = 2, H = 1, V = 1, A = 7, Z = 0 }

local function movePath(d, step)
    local tokens = {}
    for token in d:gsub("([A-Za-z])", " %1 "):gsub(",", " "):gsub("(%d)%-", "%1 -"):gmatch("%S+") do
        table.insert(tokens, token)
    end
    local out, i, cmd = {}, 1, nil
    local x, y, start_x, start_y = 0, 0, 0, 0
    while i <= #tokens do
        if tokens[i]:match("^%a$") then
            cmd = tokens[i]
            i = i + 1
        end
        local upper, rel = cmd:upper(), cmd ~= cmd:upper()
        local n = ARGS[upper]
        if n == 0 then
            x, y = start_x, start_y
            table.insert(out, "Z")
        else
            local a = {}
            for j = 1, n do a[j] = tonumber(tokens[i + j - 1]) end
            i = i + n
            if upper == "H" then
                a = { rel and x + a[1] or a[1], y }
                upper = "L"
            elseif upper == "V" then
                a = { x, rel and y + a[1] or a[1] }
                upper = "L"
            elseif rel then
                local first = upper == "A" and 6 or 1
                for j = first, #a, 2 do
                    a[j], a[j + 1] = a[j] + x, a[j + 1] + y
                end
            end
            x, y = a[#a - 1], a[#a]
            if upper == "M" then
                start_x, start_y = x, y
                cmd = rel and "l" or "L"
            end
            local parts = { upper }
            if upper == "A" then
                local k = step.scale or 1
                local px, py = movePoint(a[6], a[7], step)
                table.insert(parts, string.format("%s,%s %s %d %d %s,%s", fmt(a[1] * k), fmt(a[2] * k),
                    fmt(a[3]), a[4], a[5], fmt(px), fmt(py)))
            else
                for j = 1, #a, 2 do
                    local px, py = movePoint(a[j], a[j + 1], step)
                    table.insert(parts, fmt(px) .. "," .. fmt(py))
                end
            end
            table.insert(out, table.concat(parts, " "))
        end
    end
    return table.concat(out, " ")
end

local function getAttr(element, name)
    return element:match("%s" .. name:gsub("%-", "%%-") .. '="([^"]*)"')
end

local function setAttr(element, name, value)
    local pattern = "(%s" .. name:gsub("%-", "%%-") .. '=")[^"]*(")'
    if value == false then
        return (element:gsub("%s" .. name:gsub("%-", "%%-") .. '="[^"]*"', ""))
    elseif element:match(pattern) then
        return (element:gsub(pattern, "%1" .. value .. "%2"))
    end
    return (element:gsub("^(<%a+)", "%1 " .. name .. '="' .. value .. '"'))
end

local function moveElement(element, step)
    local tag = element:match("^<(%a+)")
    local num = function(name) return tonumber(getAttr(element, name)) end
    local k = step.scale or 1
    if tag == "path" then
        element = setAttr(element, "d", movePath(getAttr(element, "d"), step))
    elseif tag == "circle" or tag == "ellipse" then
        local cx, cy = movePoint(num("cx"), num("cy"), step)
        element = setAttr(setAttr(element, "cx", fmt(cx)), "cy", fmt(cy))
        if num("r") then element = setAttr(element, "r", fmt(num("r") * k)) end
        if num("rx") then
            element = setAttr(setAttr(element, "rx", fmt(num("rx") * k)), "ry", fmt(num("ry") * k))
        end
    elseif tag == "rect" then
        local x, y, w, h = num("x") or 0, num("y") or 0, num("width"), num("height")
        local x1, y1 = movePoint(x, y, step)
        local x2, y2 = movePoint(x + w, y + h, step)
        element = setAttr(setAttr(element, "x", fmt(math.min(x1, x2))), "y", fmt(math.min(y1, y2)))
        element = setAttr(setAttr(element, "width", fmt(math.abs(x2 - x1))), "height", fmt(math.abs(y2 - y1)))
    elseif tag == "line" then
        local x1, y1 = movePoint(num("x1"), num("y1"), step)
        local x2, y2 = movePoint(num("x2"), num("y2"), step)
        element = setAttr(setAttr(element, "x1", fmt(x1)), "y1", fmt(y1))
        element = setAttr(setAttr(element, "x2", fmt(x2)), "y2", fmt(y2))
    end
    return element
end

local SHAPES = { path = true, circle = true, rect = true, ellipse = true, line = true, polygon = true, polyline = true }

local function buildIcon(svg, step)
    local shapes = {}
    for element in svg:gmatch("<%a+[^>]*>") do
        if SHAPES[element:match("^<(%a+)")] then table.insert(shapes, element) end
    end
    local moved = step.scale or step.shift
    local new = {}
    for i, element in ipairs(shapes) do
        if moved then element = moveElement(element, step) end
        if step.stroke_width and getAttr(element, "stroke-width") then
            element = setAttr(element, "stroke-width", step.stroke_width)
        end
        for name, value in pairs(step.fills and step.fills[i] or {}) do
            element = setAttr(element, name, value)
        end
        new[i] = element
    end
    if step.canvas then
        svg = svg:gsub('viewBox="[^"]*"', 'viewBox="' .. step.canvas .. '"', 1)
    end
    local i = 0
    return (svg:gsub("<%a+[^>]*>", function(element)
        if not SHAPES[element:match("^<(%a+)")] then return element end
        i = i + 1
        return new[i]
    end))
end

-- Builds one plugin's pack (e.g. "ZenOS Icons") only when it's needed
local PACK_FILES = { ["SimpleUI Icons"] = "pack.lua", ["ZenOS Icons"] = "pack.json" }

function SolarIcons:buildPart(style, part)
    local dir = string.format("%s/Solar %s/%s (%s)", buildRoot(), style, part, style)
    local marker = string.format("%s/Solar %s/.%s.built", buildRoot(), style, part)
    local version = tostring(self.version)
    if util.readFromFile(marker, "r") == version then return dir end
    if util.directoryExists(dir) then ffiutil.purgeDir(dir) end
    local manifest = dofile(self.path .. "/install/manifest.lua")[style]
    local bases = {}
    for target, step in pairs(manifest) do
        local target_part, rel = target:match("^([^/]+)/(.+)$")
        if target_part == part then
            local folder, name = step.base:match("^([^/]+)/(.+)$")
            bases[step.base] = bases[step.base]
                or util.readFromFile(string.format("%s/Solar %s/%s (%s)/%s", self.path, style, folder, style, name), "rb")
            local path = dir .. "/" .. rel
            util.makePath(path:match("^(.*)/"))
            util.writeToFile(buildIcon(bases[step.base], step), path)
        end
    end
    if PACK_FILES[part] then
        ffiutil.copyFile(self.path .. "/install/" .. style .. "/" .. PACK_FILES[part], dir .. "/" .. PACK_FILES[part])
    end
    util.writeToFile(version, marker)
    return dir
end

function SolarIcons:sourceDir(style, part)
    if part == "KOReader Icons" or part == "Base Icons" then
        return string.format("%s/Solar %s/%s (%s)", self.path, style, part, style)
    end
    return self:buildPart(style, part)
end

-- File helpers

local function isIconFile(name)
    return name:sub(1, 1) ~= "." and (name:lower():match("%.svg$") or name:lower():match("%.png$"))
end

local function listFiles(dir, filter)
    local files = {}
    util.findFiles(dir, function(__path, name)
        if not filter or filter(name) then
            table.insert(files, name)
        end
    end, false)
    table.sort(files)
    return files
end

local function copyFile(from, to)
    local err = ffiutil.copyFile(from, to)
    if err then
        logger.warn("solariconpack: could not copy", from, "to", to, err)
        return false
    end
    return true
end

local function sameFile(a, b)
    local data = util.readFromFile(a, "rb")
    return data ~= nil and data == util.readFromFile(b, "rb")
end

-- The base icons offered as Quick Action icons, leaving out the plugin-only ones
function SolarIcons:quickActionFilter()
    local skip = {}
    for __, name in ipairs(dofile(self.path .. "/install/manifest.lua").quick_action_skip or {}) do skip[name] = true end
    return function(name) return isIconFile(name) and not skip[name] end
end

local function installFiles(src_dir, dst_dir, filter)
    local records = {}
    util.makePath(dst_dir)
    local backup_dir = dst_dir .. "/" .. BACKUP_DIRNAME
    for __, name in ipairs(listFiles(src_dir, filter or isIconFile)) do
        local dest = dst_dir .. "/" .. name
        local record = { dest = dest }
        if util.fileExists(dest) then
            util.makePath(backup_dir)
            local backup = backup_dir .. "/" .. name
            if os.rename(dest, backup) then
                record.backup = backup
            end
        end
        if copyFile(src_dir .. "/" .. name, dest) then
            table.insert(records, record)
        elseif record.backup then
            os.rename(record.backup, dest)
        end
    end
    return records
end

local function removeDirIfEmpty(dir)
    if util.isEmptyDir(dir) then
        lfs.rmdir(dir)
    end
end

-- SimpleUI install

local function simpleuiSettingKeys(pack_lua)
    local ok, pack = pcall(dofile, pack_lua)
    if not ok or type(pack) ~= "table" or type(pack.map) ~= "table" then return {} end
    local keys = {}
    for slot in pairs(pack.map) do
        local action = slot:match("^sui_action_(.+)$")
        if action then
            table.insert(keys, "simpleui_action_" .. (ACTION_ALIAS[action] or action) .. "_icon")
        else
            table.insert(keys, "simpleui_sysicon_" .. slot)
        end
    end
    return keys
end

local function simpleuiStore()
    local ok, store = pcall(require, "infra/sui_store")
    if ok and type(store) == "table" then return store end
end

local function applySimpleUIPack(pack_dir)
    local ok, sui_style = pcall(require, "features/sui_style")
    if not ok or type(sui_style) ~= "table" or type(sui_style.applyPack) ~= "function" then
        return nil
    end
    local ok_apply, result = pcall(sui_style.applyPack, pack_dir)
    if not ok_apply or type(result) ~= "table" then
        logger.warn("solariconpack: SimpleUI could not apply the pack", result)
        return nil
    end
    local store = simpleuiStore()
    if store and store.flush then pcall(store.flush, store) end
    return result.applied
end

local function snapshotSimpleUI(pack_lua)
    local store = simpleuiStore()
    if not store then return nil end
    local previous = {}
    for __, key in ipairs(simpleuiSettingKeys(pack_lua)) do
        local value = store:get(key)
        previous[key] = type(value) == "string" and value or false
    end
    return previous
end

local function restoreSimpleUI(pack_dir, pack_lua, previous)
    local store = simpleuiStore()
    if not store then return end
    previous = previous or {}
    local prefix = pack_dir .. "/"
    for __, key in ipairs(simpleuiSettingKeys(pack_lua)) do
        local value = store:get(key)
        if type(value) == "string" and value:sub(1, #prefix) == prefix then
            if previous[key] then
                store:set(key, previous[key])
            else
                store:del(key)
            end
        end
    end
    if store.flush then pcall(store.flush, store) end
end

-- ZenOS and Project Title icon swaps

local function pluginBackupRoot()
    return DataStorage:getSettingsDir() .. "/solariconpack-backup"
end

local function replacePluginFiles(src_dir, names, dest_dir, backup_name)
    local backup_dir = pluginBackupRoot() .. "/" .. backup_name
    util.makePath(backup_dir)
    local count = 0
    for __, name in ipairs(names) do
        local src, dest = src_dir .. "/" .. name, dest_dir .. "/" .. name
        if util.fileExists(src) and not sameFile(src, dest) then
            if util.fileExists(dest) then
                copyFile(dest, backup_dir .. "/" .. name)
            end
            if copyFile(src, dest) then count = count + 1 end
        end
    end
    return count
end

local function restorePluginFiles(dest_dir, backup_name)
    local backup_dir = pluginBackupRoot() .. "/" .. backup_name
    for __, name in ipairs(listFiles(backup_dir, isIconFile)) do
        if dest_dir then copyFile(backup_dir .. "/" .. name, dest_dir .. "/" .. name) end
        util.removeFile(backup_dir .. "/" .. name)
    end
    removeDirIfEmpty(backup_dir)
end

function SolarIcons:applyPTImages(style, pt_dir)
    local src_dir = self:sourceDir(style, "Project Title Icons") .. "/resources"
    return replacePluginFiles(src_dir, listFiles(src_dir, isIconFile), pt_dir .. "/resources", "projecttitle")
end

function SolarIcons:applyZenPluginIcons(style, zen_plugin_dir)
    return replacePluginFiles(self:sourceDir(style, "ZenOS Icons") .. "/menus", ZEN_PLUGIN_ICONS,
        zen_plugin_dir .. "/icons", "zenos")
end

-- ZenOS install

local function installZenPack(zen_src, koreader_src, pack_dir, supplementary_src, supplementary_filter)
    if util.directoryExists(pack_dir) then ffiutil.purgeDir(pack_dir) end
    util.makePath(pack_dir)
    copyFile(zen_src .. "/pack.json", pack_dir .. "/pack.json")
    local count = 0
    for __, src in ipairs({ koreader_src, zen_src }) do
        util.findFiles(src, function(path, name)
            if isIconFile(name) and copyFile(path, pack_dir .. "/" .. name) then count = count + 1 end
        end, src == zen_src)
    end
    local present = {}
    for __, name in ipairs(listFiles(pack_dir, isIconFile)) do
        present[util.readFromFile(pack_dir .. "/" .. name, "rb") or name] = true
    end
    for __, name in ipairs(supplementary_src and listFiles(supplementary_src, supplementary_filter or isIconFile) or {}) do
        local path, dest = supplementary_src .. "/" .. name, pack_dir .. "/" .. name
        local data = util.readFromFile(path, "rb")
        if data and not present[data] and not util.fileExists(dest) and copyFile(path, dest) then
            present[data] = true
            count = count + 1
        end
    end
    return count
end

local function zenConfig()
    local manager = package.loaded["config/manager"]
    if type(manager) ~= "table" or type(manager.get) ~= "function" or type(manager.save) ~= "function" then return end
    local ok, config = pcall(manager.get)
    if ok and type(config) == "table" and type(config.features) == "table" then return config, manager end
end

local function applyZenPack(pack_id, colour)
    local config, manager = zenConfig()
    if not config then return nil end
    if type(config.custom_icons) ~= "table" then config.custom_icons = { active_pack = "" } end
    local previous = {
        enabled = config.features.custom_icons_enabled == true,
        pack = type(config.custom_icons.active_pack) == "string" and config.custom_icons.active_pack or "",
        invert = config.custom_icons.invert_with_dark_mode,
    }
    config.features.custom_icons_enabled = true
    config.custom_icons.active_pack = pack_id
    if colour then config.custom_icons.invert_with_dark_mode = false end
    local ok = pcall(manager.save, config)
    if not ok then return nil end
    return previous
end

local function restoreZenPack(pack_id, previous)
    local config, manager = zenConfig()
    if not config or type(previous) ~= "table" or type(config.custom_icons) ~= "table" then return end
    if config.custom_icons.active_pack ~= pack_id then return end
    config.features.custom_icons_enabled = previous.enabled == true
    config.custom_icons.active_pack = previous.pack or ""
    config.custom_icons.invert_with_dark_mode = previous.invert
    pcall(manager.save, config)
end

-- Startup check

function SolarIcons:init()
    self.state = LuaSettings:open(DataStorage:getSettingsDir() .. "/solariconpack.lua")
    self.ui.menu:registerToMainMenu(self)
    UIManager:nextTick(function()
        self:checkPluginImages()
    end)
end

-- A ZenOS or Project Title update puts its own images back; this puts Solar's back again
function SolarIcons:checkPluginImages()
    local style = self:installedStyle()
    if not style or self.state:readSetting("installed_version") ~= self.version then
        return
    end
    local pt_dir = self:projectTitleDir()
    if pt_dir and self.state:isTrue("pt_installed") then
        local count = self:applyPTImages(style, pt_dir)
        if count > 0 then logger.info("solariconpack: restored", count, "Project Title images") end
    end
    local zen_plugin_dir = self:zenOSDir()
    if zen_plugin_dir and self.state:readSetting("zen_dir") then
        local count = self:applyZenPluginIcons(style, zen_plugin_dir)
        if count > 0 then logger.info("solariconpack: restored", count, "ZenOS icons") end
    end
end

function SolarIcons:installedStyle()
    return self.state:readSetting("style")
end

-- Icon restore (Off)

function SolarIcons:uninstallFiles()
    local records = self.state:readSetting("files") or {}
    for i = #records, 1, -1 do
        local record = records[i]
        util.removeFile(record.dest)
        if record.backup and util.fileExists(record.backup) then
            os.rename(record.backup, record.dest)
        end
    end
    local pack_dir = self.state:readSetting("pack_dir")
    if pack_dir and util.directoryExists(pack_dir) then
        restoreSimpleUI(pack_dir, pack_dir .. "/pack.lua", self.state:readSetting("simpleui_previous"))
        ffiutil.purgeDir(pack_dir)
    end
    local pt_dir, zen_plugin_dir = self:projectTitleDir(), self:zenOSDir()
    restorePluginFiles(pt_dir and pt_dir .. "/resources", "projecttitle")
    restorePluginFiles(zen_plugin_dir and zen_plugin_dir .. "/icons", "zenos")
    removeDirIfEmpty(pluginBackupRoot())
    if util.directoryExists(buildRoot()) then ffiutil.purgeDir(buildRoot()) end
    local zen_dir = self.state:readSetting("zen_dir")
    if zen_dir then
        restoreZenPack(zen_dir:match("([^/]+)$"), self.state:readSetting("zen_previous"))
    end
    if zen_dir and util.directoryExists(zen_dir) then
        ffiutil.purgeDir(zen_dir)
        removeDirIfEmpty(koreaderIconsDir() .. "/zen")
    end
    removeDirIfEmpty(koreaderIconsDir() .. "/" .. BACKUP_DIRNAME)
    removeDirIfEmpty(suiIconsDir() .. "/" .. BACKUP_DIRNAME)
    self.state:delSetting("files")
    self.state:delSetting("pack_dir")
    self.state:delSetting("zen_dir")
    self.state:delSetting("zen_previous")
    self.state:delSetting("pt_installed")
    self.state:delSetting("simpleui_previous")
    self.state:delSetting("installed_version")
    self.state:delSetting("style")
    self.state:purge()
    os.remove(self.state.file .. ".old")
end

-- Install

function SolarIcons:install(style)
    if self:installedStyle() then
        self:uninstallFiles()
    end

    local records = installFiles(self:sourceDir(style, "KOReader Icons"), koreaderIconsDir())
    local parts = {}

    local sui_applied
    if self:simpleUIEnabled() then
        local pack_dir = suiIconsDir() .. "/packs/Solar " .. style
        if util.directoryExists(pack_dir) then
            ffiutil.purgeDir(pack_dir)
        end
        util.makePath(pack_dir)
        local pack_src = self:sourceDir(style, "SimpleUI Icons")
        for __, name in ipairs(listFiles(pack_src)) do
            copyFile(pack_src .. "/" .. name, pack_dir .. "/" .. name)
        end
        self.state:saveSetting("pack_dir", pack_dir)
        for __, record in ipairs(installFiles(self:sourceDir(style, "Base Icons"), suiIconsDir(), self:quickActionFilter())) do
            table.insert(records, record)
        end
        self.state:saveSetting("simpleui_previous", snapshotSimpleUI(pack_dir .. "/pack.lua"))
        sui_applied = applySimpleUIPack(pack_dir)
        table.insert(parts, sui_applied
            and T(_("SimpleUI: the Solar pack has been applied (%1 icons)."), sui_applied)
            or T(_("SimpleUI: to finish, apply \"Solar %1\" in SimpleUI → Style → Icons → Icon Packs."), style))
    end

    if self:zenOSEnabled() then
        local zen_dir = zenPackDir(style)
        installZenPack(self:sourceDir(style, "ZenOS Icons"), self:sourceDir(style, "KOReader Icons"), zen_dir,
            self:sourceDir(style, "Base Icons"), self:quickActionFilter())
        self.state:saveSetting("zen_dir", zen_dir)
        self:applyZenPluginIcons(style, self:zenOSDir())
        local zen_applied = applyZenPack("Solar_" .. style, style == "Colour")
        if zen_applied then self.state:saveSetting("zen_previous", zen_applied) end
        table.insert(parts, zen_applied
            and T(_("ZenOS: custom icons turned on and the \"Solar %1\" icon pack selected."), style)
            or T(_("ZenOS: to use the Solar icons, turn on Zen Settings → Interface → Custom icons, then choose \"Solar %1\" under Custom icon pack."), style))
    end

    local pt_dir = self:projectTitleDir()
    if pt_dir and self:projectTitleEnabled() then
        for __, record in ipairs(installFiles(self:sourceDir(style, "Project Title Icons") .. "/titlebar", koreaderIconsDir())) do
            table.insert(records, record)
        end
        self:applyPTImages(style, pt_dir)
        self.state:makeTrue("pt_installed")
        table.insert(parts, _("Project Title: its title bar icons and book and folder images have been replaced."))
    end

    if self:bookshelfEnabled() then
        local only_bookshelf = function(name) return name == "bookshelf.svg" end
        for __, record in ipairs(installFiles(self:sourceDir(style, "Base Icons"), koreaderIconsDir(), only_bookshelf)) do
            table.insert(records, record)
        end
    end

    self.state:saveSetting("files", records)
    self.state:saveSetting("style", style)
    self.state:saveSetting("installed_version", self.version)
    self.state:flush()

    table.insert(parts, 1, T(_("Solar %1 installed."), style))
    table.insert(parts, _("KOReader needs to restart to show the new icons."))
    UIManager:askForRestart(table.concat(parts, "\n\n"))
end

function SolarIcons:uninstall()
    self:uninstallFiles()
    UIManager:askForRestart(_("Solar turned off, and your previous icons restored.\n\nKOReader needs to restart to finish."))
end

-- Plugin updates

local USER_AGENT = "KOReader-SolarIconPack"

local function download(url, out_path)
    local http = require("socket.http")
    local socket = require("socket")
    local socketutil = require("socketutil")
    local file = io.open(out_path, "wb")
    if file then
        socketutil:set_timeout(socketutil.FILE_BLOCK_TIMEOUT, 120)
        local ok, code = pcall(function()
            return socket.skip(1, http.request{
                url = url,
                method = "GET",
                headers = { ["User-Agent"] = USER_AGENT },
                sink = socketutil.file_sink(file),
                redirect = true,
            })
        end)
        socketutil:reset_timeout()
        pcall(file.close, file)
        if ok and code == 200 then return true end
        logger.warn("solariconpack: download failed", url, code)
    end
    local status = os.execute("curl -sfL --connect-timeout 10 --max-time 120 -A "
        .. util.shell_escape({ USER_AGENT, "-o", out_path, url }))
    return status == 0 or status == true
end

local function fetchLatestRelease(repo)
    local path = DataStorage:getSettingsDir() .. "/solariconpack-release.json"
    local ok = download("https://api.github.com/repos/" .. repo .. "/releases/latest", path)
    local raw = ok and util.readFromFile(path, "rb")
    util.removeFile(path)
    local ok_json, release = pcall(require("json").decode, raw or "")
    if not ok_json or type(release) ~= "table" or type(release.tag_name) ~= "string" then return nil end
    for __, asset in ipairs(release.assets or {}) do
        if type(asset.name) == "string" and asset.name:match("koplugin.*%.zip$") then
            return release.tag_name:gsub("^v", ""), asset.browser_download_url
        end
    end
    return release.tag_name:gsub("^v", ""), nil
end

local function isNewer(latest, current)
    local a, b = {}, {}
    for n in tostring(latest):gmatch("%d+") do table.insert(a, tonumber(n)) end
    for n in tostring(current):gmatch("%d+") do table.insert(b, tonumber(n)) end
    for i = 1, math.max(#a, #b) do
        if (a[i] or 0) ~= (b[i] or 0) then return (a[i] or 0) > (b[i] or 0) end
    end
    return false
end

local function extractPlugin(zip_path, dest)
    local Archiver = require("ffi/archiver")
    local archive = Archiver.Reader:new()
    if not archive:open(zip_path) then return false end
    local ok = true
    for entry in archive:iterate() do
        local rel = entry.path:match("^[^/]+/(.+)$")
        if rel and entry.mode == "file" and not archive:extractToPath(entry.path, dest .. "/" .. rel) then
            ok = false
            break
        end
    end
    archive:close()
    return ok and util.fileExists(dest .. "/main.lua")
        and util.fileExists(dest .. "/_meta.lua")
end

local function removeDir(dir)
    if util.directoryExists(dir) then ffiutil.purgeDir(dir) end
end

function SolarIcons:installUpdate(url, version)
    UIManager:show(InfoMessage:new{ text = _("Downloading update…"), timeout = 1 })
    UIManager:scheduleIn(0.1, function()
        local zip_path = DataStorage:getSettingsDir() .. "/solariconpack-update.zip"
        local new_dir, old_dir = self.path .. ".new", self.path .. ".old"
        removeDir(new_dir)
        removeDir(old_dir)
        local ok = download(url, zip_path) and extractPlugin(zip_path, new_dir)
        util.removeFile(zip_path)
        if ok then
            ok = os.rename(self.path, old_dir) and true
            if ok and not os.rename(new_dir, self.path) then
                os.rename(old_dir, self.path)
                ok = false
            end
        end
        removeDir(new_dir)
        removeDir(old_dir)
        if not ok then
            UIManager:show(InfoMessage:new{ text = _("Couldn't update Solar Icon Pack. Please try again later.") })
            return
        end
        UIManager:askForRestart(T(_("Solar Icon Pack updated to v%1.\n\nKOReader needs to restart to finish. Afterwards, choose your Solar style again to install the latest icons."), version))
    end)
end

function SolarIcons:checkForUpdate()
    require("ui/network/manager"):runWhenConnected(function()
        UIManager:show(InfoMessage:new{ text = _("Checking for updates…"), timeout = 1 })
        UIManager:scheduleIn(0.1, function()
            local latest, url = fetchLatestRelease(self.github or "pxlflux/solariconpack.koplugin")
            if not latest then
                UIManager:show(InfoMessage:new{ text = _("Couldn't check for updates. Please try again later.") })
            elseif not isNewer(latest, self.version) then
                UIManager:show(InfoMessage:new{ text = T(_("Solar Icon Pack is up to date (v%1)."), self.version) })
            elseif not url then
                UIManager:show(InfoMessage:new{ text = T(_("Solar Icon Pack v%1 is available, but has no download yet. Please try again later."), latest) })
            else
                UIManager:show(ConfirmBox:new{
                    text = T(_("Solar Icon Pack v%1 is available.\n\nYou have v%2."), latest, self.version),
                    ok_text = _("Update"),
                    cancel_text = _("Later"),
                    ok_callback = function() self:installUpdate(url, latest) end,
                })
            end
        end)
    end)
end

-- Menu

function SolarIcons:addToMainMenu(menu_items)
    menu_items.solar_icons = {
        text = _("Solar Icon Pack"),
        sorting_hint = "tools",
        sub_item_table_func = function() return self:getSubMenu() end,
    }
end

function SolarIcons:getSubMenu()
    local items = {}
    for __, style in ipairs(STYLES) do
        table.insert(items, {
            text = T(_("Solar %1"), style),
            radio = true,
            checked_func = function() return self:installedStyle() == style end,
            callback = function()
                if self:installedStyle() == style then
                    UIManager:show(ConfirmBox:new{
                        text = T(_("Reinstall Solar %1?\n\nDo this after turning on SimpleUI, ZenOS or Project Title, or after updating Solar, to get the right icons."), style),
                        ok_text = _("Reinstall"),
                        ok_callback = function() self:install(style) end,
                    })
                    return
                end
                local switching = self:installedStyle() ~= nil
                UIManager:show(ConfirmBox:new{
                    text = switching
                        and T(_("Switch to Solar %1?"), style)
                        or T(_("Install Solar %1?\n\nAny icons it replaces are backed up, and choosing Off later restores them."), style),
                    ok_text = switching and _("Switch") or _("Install"),
                    ok_callback = function() self:install(style) end,
                })
            end,
        })
    end
    table.insert(items, {
        text = _("Off"),
        radio = true,
        checked_func = function() return self:installedStyle() == nil end,
        separator = true,
        callback = function()
            if self:installedStyle() == nil then return end
            UIManager:show(ConfirmBox:new{
                text = _("Turn off Solar and restore your previous icons?"),
                ok_text = _("Turn off"),
                ok_callback = function() self:uninstall() end,
            })
        end,
    })
    table.insert(items, {
        text = _("Check for updates"),
        keep_menu_open = true,
        callback = function() self:checkForUpdate() end,
    })
    table.insert(items, {
        text = _("About"),
        keep_menu_open = true,
        callback = function()
            UIManager:show(InfoMessage:new{
                text = T(_("Solar Icon Pack v%1\n\nModern, rounded icons for KOReader, SimpleUI, ZenOS and Project Title\n\nBased on the Solar Icon Set by 480 Design (CC BY 4.0).\n\nTo remove Solar, choose Off before removing this plugin, so your previous icons are restored.\n\ngithub.com/pxlflux/solariconpack.koplugin"), self.version or ""),
            })
        end,
    })
    return items
end

return SolarIcons
