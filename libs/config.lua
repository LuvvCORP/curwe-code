--[[
    curwe-code  │  libs/config.lua
    Файловая конфиг-система для curwe-code
    Конфиги хранятся по пути:
        <game_dir>\nix\scripts\curwe-code\configs\<name>.txt
    Формат файла: base64( json({key: value, ...}) )

    Использование:
        local config = require("nix/scripts/curwe-code/libs/config")

        -- регистрируем элементы (вызывать после curwe.add(...))
        config.register("aim_fov",  aim_fov_proxy)
        config.register("aim_on",   aim_on_proxy)

        -- API
        config.save("myconfig")       -- сохранить
        config.load("myconfig")       -- загрузить
        config.delete("myconfig")     -- удалить
        config.refresh()              -- пересканировать папку
        config.autosave()             -- сохранить в loaded_name (если есть)

        config.list          → { "name1", "name2", ... }
        config.selected      → number (индекс в list)
        config.loaded_name   → string (имя текущего загруженного)
        config.status_msg    → string
        config.status_t      → number (frame_count момента статуса)
--]]

local base64 = require("nix/scripts/curwe-code/libs/base64")
local json   = require("nix/scripts/curwe-code/libs/json")

local M = {
    dir         = nil,
    list        = {},
    selected    = 1,
    loaded_name = "",
    status_msg  = "",
    status_t    = 0,
    _elems      = {},   -- { key, proxy }
}

-- ── Путь к папке конфигов ─────────────────────────────────────────
local function get_dir()
    if M.dir then return M.dir end
    local base = (get_game_directory and get_game_directory()) or "."
    M.dir = base .. "\\nix\\scripts\\curwe-code\\configs"
    return M.dir
end

local function ensure_dir()
    os.execute('mkdir "' .. get_dir() .. '" 2>nul')
end

-- ── Статус ────────────────────────────────────────────────────────
local function set_status(msg)
    M.status_msg = msg
    M.status_t   = render.frame_count()
end

-- ── Сканирование папки ────────────────────────────────────────────
function M.refresh()
    ensure_dir()
    M.list = {}
    local h = io.popen('dir /b "' .. get_dir() .. '\\*.txt" 2>nul')
    if h then
        for line in h:lines() do
            local name = line:match("^(.-)%.txt$")
            if name and name ~= "" then
                M.list[#M.list+1] = name
            end
        end
        h:close()
    end
    if M.selected > #M.list then
        M.selected = math.max(1, #M.list)
    end
end

-- ── Регистрация элемента ─────────────────────────────────────────
function M.register(key, proxy_ref)
    M._elems[#M._elems+1] = { key=key, proxy=proxy_ref }
end

-- ── Сериализация ─────────────────────────────────────────────────
local function to_string()
    local data = {}
    for _, entry in ipairs(M._elems) do
        local e = entry.proxy._e
        local t = e.type
        local val
        if t == "checkbox" then
            val = e.value
        elseif t == "slider_float" or t == "slider_int"
            or t == "dropdown"     or t == "list"
            or t == "hotkey" then
            val = e.value
        elseif t == "multidropdown" or t == "listable" then
            local arr = {}
            for i, v in pairs(e.value) do
                if v then arr[#arr+1] = tonumber(i) end
            end
            table.sort(arr)
            val = arr
        elseif t == "input" then
            val = e.value
        else
            val = e.value
        end
        data[entry.key] = val
    end
    local ok, result = pcall(function()
        return base64.encode(json.stringify(data))
    end)
    return ok and result or ""
end

-- ── Десериализация ────────────────────────────────────────────────
local function from_string(raw)
    local data
    -- пробуем base64 + json
    local ok1, decoded = pcall(base64.decode, raw)
    if ok1 and decoded and decoded ~= "" then
        local ok2, parsed = pcall(json.parse, decoded)
        if ok2 and type(parsed) == "table" then
            data = parsed
        end
    end
    -- fallback: старый plain key=value формат
    if not data then
        data = {}
        for line in (raw.."\n"):gmatch("([^\r\n]+)") do
            local k, v = line:match("^([^=]+)=(.*)$")
            if k then data[k] = v end
        end
    end
    -- применяем
    for _, entry in ipairs(M._elems) do
        local val = data[entry.key]
        if val ~= nil then
            local e = entry.proxy._e
            local t = e.type
            if t == "checkbox" then
                if type(val) == "boolean" then e.value = val
                else e.value = (val == "1" or val == true) end
            elseif t == "slider_float" then
                local n = tonumber(val)
                if n then e.value = math.max(e.min, math.min(e.max, n)) end
            elseif t == "slider_int" then
                local n = tonumber(val)
                if n then e.value = math.max(e.min, math.min(e.max, math.floor(n+.5))) end
            elseif t == "dropdown" or t == "list" then
                local n = tonumber(val)
                if n then e.value = math.floor(n) end
            elseif t == "multidropdown" or t == "listable" then
                e.value = {}
                if type(val) == "table" then
                    for _, idx in ipairs(val) do
                        e.value[tonumber(idx)] = true
                    end
                else
                    for idx in tostring(val):gmatch("(%d+)") do
                        e.value[tonumber(idx)] = true
                    end
                end
            elseif t == "hotkey" then
                local n = tonumber(val)
                if n then e.value = math.floor(n) end
            elseif t == "input" then
                e.value = tostring(val)
            end
        end
    end
end

-- ── Публичные функции ─────────────────────────────────────────────
function M.save(name)
    if not name or name == "" then set_status("Empty name!"); return end
    ensure_dir()
    local path = get_dir() .. "\\" .. name .. ".txt"
    local f = io.open(path, "w")
    if not f then set_status("Save failed!"); return end
    f:write(to_string())
    f:close()
    -- loaded_name не меняем — только load() его устанавливает
    set_status("Saved: " .. name)
    M.refresh()
end

function M.load(name)
    if not name or name == "" then set_status("Select a config!"); return end
    local path = get_dir() .. "\\" .. name .. ".txt"
    local f = io.open(path, "r")
    if not f then set_status("Not found!"); return end
    local data = f:read("*a")
    f:close()
    from_string(data)
    M.loaded_name = name
    set_status("Loaded: " .. name)
end

function M.delete(name)
    if not name or name == "" then set_status("Select a config!"); return end
    os.remove(get_dir() .. "\\" .. name .. ".txt")
    if M.loaded_name == name then M.loaded_name = "" end
    set_status("Deleted: " .. name)
    M.refresh()
end

function M.autosave()
    if M.loaded_name ~= "" then
        M.save(M.loaded_name)
    end
end

-- Экспорт конфига в строку (для clipboard)
function M.export()
    return to_string()
end

-- Импорт конфига из строки (из clipboard)
function M.import(raw)
    if not raw or raw == "" then set_status("Empty data!"); return end
    from_string(raw)
    set_status("Imported!")
end

-- ── Инициализация ─────────────────────────────────────────────────
M.refresh()
if #M.list > 0 then
    M.load(M.list[1])
end

return M
