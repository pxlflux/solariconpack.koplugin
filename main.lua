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

-- Paths

local function koreaderIconsDir()
    return DataStorage:getDataDir() .. "/icons"
end

local function simpleuiDir()
    return DataStorage:getSettingsDir() .. "/simpleui"
end

local function suiIconsDir()
    return simpleuiDir() .. "/sui_icons"
end

-- True only while SimpleUI is running
local function simpleUIActive()
    return package.loaded["features/sui_style"] ~= nil
end

-- True if SimpleUI has been used, even if now disabled
local function simpleUIFolderExists()
    return lfs.attributes(simpleuiDir(), "mode") == "directory"
end

-- e.g. "Solar Colour/KOReader Icons (Colour)"
function SolarIcons:sourceDir(style, part)
    return string.format("%s/Solar %s/%s (%s)", self.path, style, part, style)
end

-- Files

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

-- Copies icons into dst_dir, backing up any file they replace
local function installFiles(src_dir, dst_dir)
    local records = {}
    util.makePath(dst_dir)
    local backup_dir = dst_dir .. "/" .. BACKUP_DIRNAME
    for __, name in ipairs(listFiles(src_dir, isIconFile)) do
        local dest = dst_dir .. "/" .. name
        local record = { dest = dest }
        if lfs.attributes(dest, "mode") == "file" then
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

-- SimpleUI

-- SimpleUI's setting name for each slot in pack.lua
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

-- Returns the number of icons applied, or nil
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

-- Saves the user's current SimpleUI icons so they can be restored
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

-- Restores slots still using our pack; leaves ones the user has changed since
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

-- State

-- Once per session (the plugin loads in both the file browser and the reader)
local update_notice_shown = false

function SolarIcons:init()
    self.state = LuaSettings:open(DataStorage:getSettingsDir() .. "/solariconpack.lua")
    self.ui.menu:registerToMainMenu(self)
    UIManager:nextTick(function() self:checkForUpdatedIcons() end)
end

-- After a plugin update, offer to reinstall the icons (once per version)
function SolarIcons:checkForUpdatedIcons()
    local style = self:installedStyle()
    local current = self.version
    if update_notice_shown or not style or not current then return end
    if self.state:readSetting("installed_version") == current
            or self.state:readSetting("notified_version") == current then
        return
    end
    update_notice_shown = true
    self.state:saveSetting("notified_version", current)
    self.state:flush()
    UIManager:show(ConfirmBox:new{
        text = T(_("Solar Icon Pack has been updated to version %1.\n\nReinstall Solar %2 to get the latest icons?"), current, style),
        ok_text = _("Reinstall"),
        cancel_text = _("Later"),
        ok_callback = function() self:install(style) end,
    })
end

function SolarIcons:installedStyle()
    return self.state:readSetting("style")
end

-- Install / uninstall

function SolarIcons:uninstallFiles()
    local records = self.state:readSetting("files") or {}
    for i = #records, 1, -1 do
        local record = records[i]
        util.removeFile(record.dest)
        if record.backup and lfs.attributes(record.backup, "mode") == "file" then
            os.rename(record.backup, record.dest)
        end
    end
    local pack_dir = self.state:readSetting("pack_dir")
    if pack_dir and lfs.attributes(pack_dir, "mode") == "directory" then
        restoreSimpleUI(pack_dir, pack_dir .. "/pack.lua", self.state:readSetting("simpleui_previous"))
        ffiutil.purgeDir(pack_dir)
    end
    removeDirIfEmpty(koreaderIconsDir() .. "/" .. BACKUP_DIRNAME)
    removeDirIfEmpty(suiIconsDir() .. "/" .. BACKUP_DIRNAME)
    self.state:delSetting("files")
    self.state:delSetting("pack_dir")
    self.state:delSetting("simpleui_previous")
    self.state:delSetting("installed_version")
    self.state:delSetting("notified_version")
    self.state:delSetting("style")
    self.state:flush()
end

function SolarIcons:install(style)
    if self:installedStyle() then
        self:uninstallFiles()
    end

    local records = installFiles(self:sourceDir(style, "KOReader Icons"), koreaderIconsDir())
    local active = simpleUIActive()
    local saved_for_later = not active and simpleUIFolderExists()
    local applied

    -- Copy SimpleUI files if it's running or disabled; only a running SimpleUI can apply them
    if active or saved_for_later then
        local pack_dir = suiIconsDir() .. "/packs/Solar " .. style
        if lfs.attributes(pack_dir, "mode") == "directory" then
            ffiutil.purgeDir(pack_dir)
        end
        util.makePath(pack_dir)
        local pack_src = self:sourceDir(style, "Pack Icons")
        for __, name in ipairs(listFiles(pack_src)) do
            copyFile(pack_src .. "/" .. name, pack_dir .. "/" .. name)
        end
        self.state:saveSetting("pack_dir", pack_dir)

        for __, record in ipairs(installFiles(self:sourceDir(style, "Supplementary Icons"), suiIconsDir())) do
            table.insert(records, record)
        end
        if active then
            self.state:saveSetting("simpleui_previous", snapshotSimpleUI(pack_dir .. "/pack.lua"))
            applied = applySimpleUIPack(pack_dir)
        end
    end

    self.state:saveSetting("files", records)
    self.state:saveSetting("style", style)
    self.state:saveSetting("installed_version", self.version)
    self.state:delSetting("notified_version")
    self.state:flush()

    local message
    if active and applied then
        message = T(_("Solar %1 installed, and the SimpleUI pack applied (%2 icons).\n\nKOReader needs to restart to show the new icons."), style, applied)
    elseif active then
        message = T(_("Solar %1 installed.\n\nTo finish, apply \"Solar %1\" in SimpleUI → Style → Icons → Icon Packs, then restart KOReader."), style)
    elseif saved_for_later then
        message = T(_("Solar %1 installed.\n\nSimpleUI isn't active, so its icon pack has been saved for later. If you turn SimpleUI back on, apply \"Solar %1\" in SimpleUI → Style → Icons → Icon Packs.\n\nKOReader needs to restart to show the new icons."), style)
    else
        message = T(_("Solar %1 installed.\n\nKOReader needs to restart to show the new icons.\n\nTip: Solar also includes icons for the SimpleUI plugin. If you install SimpleUI later, choose Solar %1 again in Tools → Solar Icon Pack to add them."), style)
    end
    UIManager:askForRestart(message)
end

function SolarIcons:uninstall()
    self:uninstallFiles()
    UIManager:askForRestart(_("Solar turned off, and your previous icons restored.\n\nKOReader needs to restart to finish."))
end

-- Updates

local USER_AGENT = "KOReader-SolarIconPack"

local function shellQuote(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- Downloads url to out_path, using KOReader's own HTTP and falling back to curl
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
    local status = os.execute(string.format("curl -sfL --connect-timeout 10 --max-time 120 -A %s -o %s %s",
        shellQuote(USER_AGENT), shellQuote(out_path), shellQuote(url)))
    return status == 0 or status == true
end

-- Returns the latest version and its plugin zip URL, or nil
local function fetchLatestRelease(repo)
    local path = DataStorage:getSettingsDir() .. "/solariconpack-release.json"
    local ok = download("https://api.github.com/repos/" .. repo .. "/releases/latest", path)
    local file = ok and io.open(path, "rb")
    local raw = file and file:read("*a")
    if file then file:close() end
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

-- Unzips the plugin into dest, dropping the zip's top folder
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
    return ok and lfs.attributes(dest .. "/main.lua", "mode") == "file"
        and lfs.attributes(dest .. "/_meta.lua", "mode") == "file"
end

local function removeDir(dir)
    if lfs.attributes(dir, "mode") == "directory" then ffiutil.purgeDir(dir) end
end

-- Swaps in the new plugin folder; the icons themselves are reinstalled after the restart
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
        UIManager:askForRestart(T(_("Solar Icon Pack updated to v%1.\n\nKOReader needs to restart to finish."), version))
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
                    -- Tapping the active style reinstalls it
                    UIManager:show(ConfirmBox:new{
                        text = T(_("Reinstall Solar %1?\n\nThis adds any parts that are missing, such as SimpleUI icons if you've installed SimpleUI since."), style),
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
                text = T(_("Solar Icon Pack v%1\n\nModern, rounded icons for KOReader and SimpleUI\n\nBased on the Solar Icon Set by 480 Design (CC BY 4.0).\n\nTo remove Solar, choose Off before removing this plugin, so your previous icons are restored.\n\ngithub.com/pxlflux/solariconpack.koplugin"), self.version or ""),
            })
        end,
    })
    return items
end

return SolarIcons
