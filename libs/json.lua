--[[
    curwe-code  │  libs/json.lua
    Минимальный JSON encode / decode для простых типов
    Поддерживает: string, number, boolean, nil/null, table (object + array)
    Использование:
        local json = require("nix/scripts/curwe-code/libs/json")
        local str  = json.stringify({key="val", num=42, arr={1,2,3}})
        local tbl  = json.parse(str)
--]]

local M = {}

-- ── Encode ────────────────────────────────────────────────────────
local function escape(s)
    return s:gsub('\\','\\\\')
              :gsub('"',  '\\"')
              :gsub('\n', '\\n')
              :gsub('\r', '\\r')
              :gsub('\t', '\\t')
end

function M.stringify(val)
    local t = type(val)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "number" then
        if val ~= val then return "null" end          -- NaN → null
        if val == math.huge  then return "null" end   -- Inf → null
        if val == -math.huge then return "null" end
        -- целое без дробной части
        if math.floor(val) == val and math.abs(val) < 1e15 then
            return string.format("%d", val)
        end
        return string.format("%.10g", val)
    elseif t == "string" then
        return '"' .. escape(val) .. '"'
    elseif t == "table" then
        -- определяем: массив или объект
        local is_array = true
        local count    = 0
        for k in pairs(val) do
            count = count + 1
            if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                is_array = false; break
            end
        end
        if is_array and count == #val then
            local parts = {}
            for _, v in ipairs(val) do
                parts[#parts+1] = M.stringify(v)
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(val) do
                parts[#parts+1] = '"' .. escape(tostring(k)) .. '":' .. M.stringify(v)
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

-- ── Decode ────────────────────────────────────────────────────────
local function parse_val(s, i)
    -- пропускаем пробелы
    while i <= #s and s:sub(i,i):match("%s") do i = i+1 end
    local c = s:sub(i,i)

    -- string
    if c == '"' then
        local j   = i+1
        local buf = {}
        while j <= #s do
            local ch = s:sub(j,j)
            if ch == '"' then break end
            if ch == '\\' then
                local nc = s:sub(j+1,j+1)
                if     nc == '"'  then buf[#buf+1] = '"'
                elseif nc == '\\' then buf[#buf+1] = '\\'
                elseif nc == '/'  then buf[#buf+1] = '/'
                elseif nc == 'n'  then buf[#buf+1] = '\n'
                elseif nc == 'r'  then buf[#buf+1] = '\r'
                elseif nc == 't'  then buf[#buf+1] = '\t'
                else               buf[#buf+1] = nc end
                j = j+2
            else
                buf[#buf+1] = ch; j = j+1
            end
        end
        return table.concat(buf), j+1

    -- object
    elseif c == '{' then
        local obj = {}; i = i+1
        while i <= #s do
            while i <= #s and s:sub(i,i):match("%s") do i=i+1 end
            if s:sub(i,i) == '}' then i=i+1; break end
            local k, ni = parse_val(s, i); i = ni
            while i <= #s and s:sub(i,i):match("[%s:]") do i=i+1 end
            local v, ni2 = parse_val(s, i); i = ni2
            if k ~= nil then obj[k] = v end
            while i <= #s and s:sub(i,i):match("[%s,}]") do
                local ch2 = s:sub(i,i)
                i = i+1
                if ch2 == '}' then return obj, i end
            end
        end
        return obj, i

    -- array
    elseif c == '[' then
        local arr = {}; i = i+1
        while i <= #s do
            while i <= #s and s:sub(i,i):match("%s") do i=i+1 end
            if s:sub(i,i) == ']' then i=i+1; break end
            local v, ni = parse_val(s, i); i = ni
            arr[#arr+1] = v
            while i <= #s and s:sub(i,i):match("[%s,%]]") do
                local ch2 = s:sub(i,i)
                i = i+1
                if ch2 == ']' then return arr, i end
            end
        end
        return arr, i

    -- literals
    elseif s:sub(i,i+3) == "true"  then return true,  i+4
    elseif s:sub(i,i+4) == "false" then return false, i+5
    elseif s:sub(i,i+3) == "null"  then return nil,   i+4

    -- number
    else
        local num_str = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", i)
        if num_str then return tonumber(num_str), i+#num_str end
    end
    return nil, i+1
end

function M.parse(s)
    if type(s) ~= "string" or s == "" then return nil end
    local ok, val = pcall(function()
        local v = parse_val(s, 1)
        return v
    end)
    return ok and val or nil
end

return M
