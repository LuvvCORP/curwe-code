--[[
    curwe-code  │  libs/base64.lua
    Чистая Lua реализация Base64 encode / decode
    Использование:
        local base64 = require("nix/scripts/curwe-code/libs/base64")
        local encoded = base64.encode("hello world")
        local decoded = base64.decode(encoded)
--]]

local M = {}

local _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function M.encode(data)
    if type(data) ~= "string" then data = tostring(data) end
    local result = {}
    local pad = #data % 3
    data = data .. string.rep("\0", (3 - pad) % 3)
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i), data:byte(i+1), data:byte(i+2)
        local n = a*65536 + b*256 + c
        result[#result+1] = _chars:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
        result[#result+1] = _chars:sub(math.floor(n/4096)%64+1,   math.floor(n/4096)%64+1)
        result[#result+1] = _chars:sub(math.floor(n/64)%64+1,     math.floor(n/64)%64+1)
        result[#result+1] = _chars:sub(n%64+1, n%64+1)
    end
    if pad == 1 then result[#result-1] = "="; result[#result] = "="
    elseif pad == 2 then result[#result] = "=" end
    return table.concat(result)
end

function M.decode(data)
    if type(data) ~= "string" then return "" end
    data = data:gsub("[^".._chars.."=]", "")
    local result = {}
    for i = 1, #data, 4 do
        local a = (_chars:find(data:sub(i,i))   or 1) - 1
        local b = (_chars:find(data:sub(i+1,i+1)) or 1) - 1
        local c = (_chars:find(data:sub(i+2,i+2)) or 65) - 1
        local d = (_chars:find(data:sub(i+3,i+3)) or 65) - 1
        local n = a*262144 + b*4096 + c*64 + d
        result[#result+1] = string.char(math.floor(n/65536)%256)
        if data:sub(i+2,i+2) ~= "=" then
            result[#result+1] = string.char(math.floor(n/256)%256)
        end
        if data:sub(i+3,i+3) ~= "=" then
            result[#result+1] = string.char(n%256)
        end
    end
    return table.concat(result)
end

return M
