--[[
╔══════════════════════════════════════════════════════════════════╗
║   curwe-code  │  Custom Menu System v2                           ║
║   Dark-purple glass UI  •  Nixware CS2 LuaJIT API               ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║   БЫСТРЫЙ СТАРТ                                                  ║
║   ─────────────                                                  ║
║   local curwe = dofile(get_game_directory()..                    ║
║       "\\nix\\scripts\\curwe_menu.lua")                          ║
║                                                                  ║
║   curwe.add_tab("Aimbot")                                        ║
║   curwe.add_section("Aimbot", "General")                         ║
║                                                                  ║
║   local aim_on  = curwe.checkbox("Enable", false)               ║
║   local aim_fov = curwe.slider_float("FOV",5.0,0.5,45,"%.1f°") ║
║   local aim_smt = curwe.slider_int("Smooth",10,1,100)           ║
║   local aim_bn  = curwe.dropdown("Bone",{"Head","Neck"},1)       ║
║   local aim_hb  = curwe.multidropdown("Hitbox",                  ║
║                       {"Head","Body","Arms"},{1})                ║
║   local aim_key = curwe.hotkey("Key", 0x02)                     ║
║                                                                  ║
║   curwe.add("Aimbot","General", aim_on)                         ║
║   curwe.add("Aimbot","General", aim_fov)                        ║
║   ...                                                            ║
║                                                                  ║
║   -- читать                                                      ║
║   aim_on.value    → bool                                         ║
║   aim_fov.value   → float                                        ║
║   aim_bn.value    → number (1-based)                             ║
║   aim_hb.value    → { [1]=true, [2]=false, ... }                ║
║   aim_key.value   → VK code  (0 = не задан)                     ║
║                                                                  ║
║   INSERT  →  показать / скрыть меню                              ║
╚══════════════════════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────────────────────────────
--  ШРИФТЫ
-- ─────────────────────────────────────────────────────────────────
local F_REG  = render.setup_font("C:/Windows/Fonts/verdana.ttf",  13, 0)
local F_BOLD = render.setup_font("C:/Windows/Fonts/verdanab.ttf", 13, 0)
local F_LOGO = render.setup_font("C:/Windows/Fonts/verdanab.ttf", 14, 0)
local F_NAV  = render.setup_font("C:/Windows/Fonts/verdanab.ttf", 12, 0)
local F_SM   = render.setup_font("C:/Windows/Fonts/verdana.ttf",  11, 0)
local F_CHIP = render.setup_font("C:/Windows/Fonts/verdana.ttf",  10, 0)
-- жирный 12px для HUD-индикаторов (пиксельный, чёткий)
local F_HUD  = render.setup_font("C:/Windows/Fonts/verdanab.ttf", 12, 0)
-- иконочный шрифт (gear и др.)
local F_ICONS = render.setup_font(get_game_directory().."\\nix\\scripts\\curwe-code\\others\\icons.ttf", 14, 0)
-- логотип из curwe-code/others/logo.png
local _LOGO_TEX = render.setup_texture(
    get_game_directory().."\\nix\\scripts\\curwe-code\\others\\logo.png")
local LOGO_SIZE = 28   -- размер квадратной иконки в пикселях

-- ─────────────────────────────────────────────────────────────────
--  ПАЛИТРА  (точно по переменным main.css)
-- ─────────────────────────────────────────────────────────────────
local function rgba(r,g,b,a) return color_t(r/255,g/255,b/255,a) end
local function hex(r,g,b)    return color_t(r/255,g/255,b/255,1) end

--                            r    g    b    a
local BG_BASE      = hex    ( 13,  11,  20)           -- #0d0b14
local BG_LAYER     = hex    ( 19,  15,  31)           -- #130f1f
local BG_CARD      = rgba   ( 26,  18,  46, 0.65)    -- rgba(26,18,46,.65)
local BG_CARD_HOV  = rgba   ( 36,  26,  62, 0.75)    -- rgba(36,26,62,.75)
local BG_INPUT     = rgba   ( 20,  14,  36, 0.80)    -- rgba(20,14,36,.8)
local BG_SIDEBAR   = rgba   ( 14,  10,  24, 0.85)    -- rgba(14,10,24,.85)

local GLASS_BRD    = rgba   (120,  80, 220, 0.18)    -- var(--glass-border)
local GLASS_SHINE  = rgba   (180, 140, 255, 0.07)    -- var(--glass-shine)

local P900 = hex( 30,  15,  60)   -- #1e0f3c
local P700 = hex( 76,  29, 149)   -- #4c1d95
local P600 = hex(109,  40, 217)   -- #6d28d9
local P500 = hex(124,  58, 237)   -- #7c3aed
local P400 = hex(139,  92, 246)   -- #8b5cf6  (= accent)
local P300 = hex(167, 139, 250)   -- #a78bfa
local P200 = hex(196, 181, 253)   -- #c4b5fd
local P100 = hex(237, 233, 254)   -- #ede9fe

local ACCENT      = P400
local ACCENT_BR   = hex(181, 123, 238)            -- #b57bee
local ACCENT_GLOW = rgba(139,  92, 246, 0.35)

local GREEN       = hex( 52, 211, 153)
local GREEN_GLOW  = rgba( 52, 211, 153, 0.25)
local RED         = hex(248, 113, 113)
local RED_GLOW    = rgba(248, 113, 113, 0.25)
local YELLOW      = hex(251, 191,  36)

local TXT_PRI  = hex(232, 224, 255)   -- #e8e0ff
local TXT_SEC  = hex(157, 142, 192)   -- #9d8ec0
local TXT_MUTE = hex( 90,  77, 122)   -- #5a4d7a

local CLR_NONE = color_t(0,0,0,0)
local CLR_WHT  = color_t(1,1,1,1)

-- ─────────────────────────────────────────────────────────────────
--  АНИМАЦИИ
-- ─────────────────────────────────────────────────────────────────
local _anims = {}
local function sm(key, target, spd)
    if _anims[key] == nil then _anims[key] = target end
    local dt = math.min(render.frame_time(), 0.05)
    _anims[key] = _anims[key] + (target - _anims[key]) * math.min(1, dt * spd)
    return _anims[key]
end
local function lp(a,b,t) t=math.max(0,math.min(1,t)); return a+(b-a)*t end
local function lpc(c1,c2,t)
    return color_t(lp(c1.r,c2.r,t),lp(c1.g,c2.g,t),
                   lp(c1.b,c2.b,t),lp(c1.a,c2.a,t))
end

-- ─────────────────────────────────────────────────────────────────
--  LIBS  (внешние модули из nix\scripts\curwe-code\libs\)
-- ─────────────────────────────────────────────────────────────────
local base64 = require("nix/scripts/curwe-code/libs/base64")
local json   = require("nix/scripts/curwe-code/libs/json")
local config = require("nix/scripts/curwe-code/libs/config")

-- ─────────────────────────────────────────────────────────────────
--  INPUT  (WinAPI через FFI)
-- ─────────────────────────────────────────────────────────────────
local ffi = require("ffi")
ffi.cdef[[
    short GetAsyncKeyState(int vKey);
    typedef struct { long x; long y; } PT_CW;
    int GetCursorPos(PT_CW* p);

    // WinHTTP для HTTP-запросов
    typedef void* HINTERNET;
    typedef unsigned short WCHAR;
    typedef const WCHAR* LPCWSTR;
    typedef unsigned long DWORD;
    typedef int BOOL;

    HINTERNET WinHttpOpen(LPCWSTR pszAgentW, DWORD dwAccessType,
        LPCWSTR pszProxyW, LPCWSTR pszProxyBypassW, DWORD dwFlags);
    HINTERNET WinHttpConnect(HINTERNET hSession, LPCWSTR pswzServerName,
        unsigned short nServerPort, DWORD dwReserved);
    HINTERNET WinHttpOpenRequest(HINTERNET hConnect, LPCWSTR pwszVerb,
        LPCWSTR pwszObjectName, LPCWSTR pwszVersion, LPCWSTR pwszReferrer,
        LPCWSTR* ppwszAcceptTypes, DWORD dwFlags);
    BOOL WinHttpSendRequest(HINTERNET hRequest, LPCWSTR pwszHeaders,
        DWORD dwHeadersLength, void* lpOptional, DWORD dwOptionalLength,
        DWORD dwTotalLength, uintptr_t dwContext);
    BOOL WinHttpReceiveResponse(HINTERNET hRequest, void* lpReserved);
    BOOL WinHttpQueryDataAvailable(HINTERNET hRequest, DWORD* lpdwNumberOfBytesAvailable);
    BOOL WinHttpReadData(HINTERNET hRequest, void* lpBuffer,
        DWORD dwNumberOfBytesToRead, DWORD* lpdwNumberOfBytesRead);
    BOOL WinHttpCloseHandle(HINTERNET hInternet);
]]
local U32    = ffi.load("user32")
local WHTTP  = ffi.load("winhttp")
local _pt    = ffi.new("PT_CW")


-- Конвертация Lua-строки в UTF-16 (нужно для WinHTTP)
local function to_wstr(s)
    local len = #s
    local buf = ffi.new("unsigned short[?]", len+1)
    for i=0,len-1 do buf[i] = string.byte(s, i+1) end
    buf[len] = 0
    return buf
end

-- Простой HTTP GET через WinHTTP
-- Возвращает тело ответа (string) или nil при ошибке
local function http_get(host, path)
    local ok, result = pcall(function()
        local session = WHTTP.WinHttpOpen(
            to_wstr("curwe/1.0"), 0,
            ffi.cast("unsigned short*", nil),
            ffi.cast("unsigned short*", nil), 0)
        if session == nil then return nil end

        local connect = WHTTP.WinHttpConnect(session, to_wstr(host), 443, 0)
        if connect == nil then WHTTP.WinHttpCloseHandle(session); return nil end

        -- WINHTTP_FLAG_SECURE = 0x00800000
        local request = WHTTP.WinHttpOpenRequest(connect,
            to_wstr("GET"), to_wstr(path),
            ffi.cast("unsigned short*", nil),
            ffi.cast("unsigned short*", nil),
            ffi.cast("void*", nil), 0x00800000)
        if request == nil then
            WHTTP.WinHttpCloseHandle(connect)
            WHTTP.WinHttpCloseHandle(session)
            return nil
        end

        WHTTP.WinHttpSendRequest(request,
            ffi.cast("unsigned short*", nil), 0,
            ffi.cast("void*", nil), 0, 0, 0)
        WHTTP.WinHttpReceiveResponse(request, nil)

        local body = ""
        local avail = ffi.new("unsigned long[1]")
        while true do
            avail[0] = 0
            WHTTP.WinHttpQueryDataAvailable(request, avail)
            if avail[0] == 0 then break end
            local buf  = ffi.new("uint8_t[?]", avail[0]+1)
            local read = ffi.new("unsigned long[1]")
            WHTTP.WinHttpReadData(request, buf, avail[0], read)
            body = body .. ffi.string(buf, read[0])
        end

        WHTTP.WinHttpCloseHandle(request)
        WHTTP.WinHttpCloseHandle(connect)
        WHTTP.WinHttpCloseHandle(session)
        return body
    end)
    if ok then return result else return nil end
end

local mouse     = {x=0, y=0}

-- ─────────────────────────────────────────────────────────────────
--  CLIPBOARD  (WinAPI)
-- ─────────────────────────────────────────────────────────────────
ffi.cdef[[
    int   OpenClipboard(void* hWndNewOwner);
    int   CloseClipboard(void);
    int   EmptyClipboard(void);
    void* GetClipboardData(unsigned int uFormat);
    void* SetClipboardData(unsigned int uFormat, void* hMem);
    void* GlobalAlloc(unsigned int uFlags, size_t dwBytes);
    void* GlobalLock(void* hMem);
    int   GlobalUnlock(void* hMem);
    void* GlobalFree(void* hMem);
    void* memcpy(void* dst, const void* src, size_t n);
]]
local CF_TEXT    = 1
local GMEM_MOVEABLE = 0x0002

local function clipboard_set(text)
    if not U32.OpenClipboard(nil) then return false end
    U32.EmptyClipboard()
    local len  = #text + 1
    local hmem = U32.GlobalAlloc(GMEM_MOVEABLE, len)
    if hmem == nil then U32.CloseClipboard(); return false end
    local ptr  = U32.GlobalLock(hmem)
    ffi.copy(ptr, text, len)
    U32.GlobalUnlock(hmem)
    U32.SetClipboardData(CF_TEXT, hmem)
    U32.CloseClipboard()
    return true
end

local function clipboard_get()
    if not U32.OpenClipboard(nil) then return "" end
    local hmem = U32.GetClipboardData(CF_TEXT)
    local result = ""
    if hmem ~= nil then
        local ptr = U32.GlobalLock(hmem)
        if ptr ~= nil then
            result = ffi.string(ptr)
            U32.GlobalUnlock(hmem)
        end
    end
    U32.CloseClipboard()
    return result
end
local lmb_now   = false
local lmb_last  = false
local lmb_click = false

local VK_LMB = 0x01
local VK_ESC = 0x1B

-- ─────────────────────────────────────────────────────────────────
--  INTERNAL SETTINGS  (управляются вкладкой Settings)
-- ─────────────────────────────────────────────────────────────────
local _cfg = {
    toggle_key = 0x2D,   -- INSERT по умолчанию
    _binding   = false,  -- ожидаем нажатие нового хоткея?
    dpi_scale  = 0,      -- 0=auto  50/100/150/200 = фиксированный %
}

-- ─────────────────────────────────────────────────────────────────
--  AUTH SYSTEM
--  Проверяет:
--    1. get_user_name() присутствует в pastebin USERS_URL (список ников)
--    2. Введённый пароль присутствует в pastebin PASS_URL  (список паролей)
--  Замени URL на свои Pastebin raw-ссылки.
-- ─────────────────────────────────────────────────────────────────
local AUTH = {
    -- ↓ замени на свои Pastebin raw URLs
    USERS_URL = "/raw/XXXXXXXX",   -- каждый ник на новой строке
    PASS_URL  = "/raw/YYYYYYYY",   -- каждый пароль на новой строке
    HOST      = "pastebin.com",

    state     = "loading",  -- "loading" | "need_pass" | "denied" | "ok"
    error_msg = "",

    -- текущий ввод пароля
    input_text  = "",
    input_focus = false,

    -- анимации
    _shake = 0,   -- тряска при неверном пароле
    _alpha = 0,   -- fade-in экрана
}

-- Асинхронная (на самом деле синхронная при первом вызове) проверка ника
-- Вызывается один раз при загрузке через корутину чтобы не фризить
local _auth_coro = nil

local function auth_check_user()
    local username = (get_user_name and get_user_name()) or ""
    if username == "" then
        AUTH.state     = "denied"
        AUTH.error_msg = "Cannot get username"
        return
    end

    -- bypass: empieza всегда проходит без пароля
    if username == "empieza" then
        AUTH.state = "ok"
        return
    end

    local body = http_get(AUTH.HOST, AUTH.USERS_URL)
    if not body then
        AUTH.state     = "denied"
        AUTH.error_msg = "No connection"
        return
    end

    -- ищем ник в списке (каждый на своей строке)
    local found = false
    for line in (body.."\n"):gmatch("([^\r\n]+)") do
        if line:match("^%s*(.-)%s*$") == username then
            found = true; break
        end
    end

    if not found then
        AUTH.state     = "denied"
        AUTH.error_msg = "User not whitelisted"
    else
        AUTH.state = "need_pass"
    end
end

local function auth_check_password(pass)
    local body = http_get(AUTH.HOST, AUTH.PASS_URL)
    if not body then
        AUTH.error_msg = "No connection"
        AUTH._shake    = 1
        return
    end

    local found = false
    for line in (body.."\n"):gmatch("([^\r\n]+)") do
        if line:match("^%s*(.-)%s*$") == pass then
            found = true; break
        end
    end

    if found then
        AUTH.state     = "ok"
        AUTH.error_msg = ""
    else
        AUTH.error_msg = "Wrong password"
        AUTH._shake    = 1
        AUTH.input_text = ""
    end
end

-- Запускаем проверку ника в корутине чтобы не блокировать первый кадр
_auth_coro = coroutine.create(function()
    auth_check_user()
end)
coroutine.resume(_auth_coro)

-- ─────────────────────────────────────────────────────────────────
local _vis = {
    -- настройки (правится из вкладки Visuals)
    show_curwe = true,   -- метка "curwe"
    show_dmg   = true,   -- min damage override
    show_state = true,   -- movement state (DEF/STAND/RUN/...)

    -- runtime-анимации
    _offset_x = 0,   -- сдвиг вправо при скопе, анимируется
    _alpha    = 1,   -- прозрачность, анимируется
}

local function kdn(vk) return bit.band(U32.GetAsyncKeyState(vk),0x8000)~=0 end
local function kpr(vk) return bit.band(U32.GetAsyncKeyState(vk),0x0001)~=0 end
local function mhit(x,y,w,h)
    return mouse.x>=x and mouse.x<=x+w and mouse.y>=y and mouse.y<=y+h
end

-- VK → display name
local KN = {}
local kn_pairs = {
    [0x01]="LMB",[0x02]="RMB",[0x04]="MMB",[0x08]="BS",[0x09]="TAB",
    [0x0D]="ENTER",[0x10]="SHIFT",[0x11]="CTRL",[0x12]="ALT",[0x14]="CAPS",
    [0x1B]="ESC",[0x20]="SPACE",[0x21]="PGUP",[0x22]="PGDN",[0x23]="END",
    [0x24]="HOME",[0x25]="LEFT",[0x26]="UP",[0x27]="RIGHT",[0x28]="DOWN",
    [0x2D]="INS",[0x2E]="DEL",
}
for k,v in pairs(kn_pairs) do KN[k]=v end
for i=0,9  do KN[0x30+i]=tostring(i) end
for i=0,25 do KN[0x41+i]=string.char(65+i) end
for i=1,12 do KN[0x6F+i]="F"..i end
for i=0,9  do KN[0x60+i]="NUM"..i end
local function vkn(vk) return KN[vk] or string.format("%02Xh",vk) end

-- ─────────────────────────────────────────────────────────────────
--  LAYOUT
-- ─────────────────────────────────────────────────────────────────
local MW       = 760   -- window width
local MH       = 520   -- window height
local TITLE_H  = 0    -- titlebar
local NAV_W    = 155   -- sidebar width
local CONT_PAD = 22    -- content padding
local CARD_R   = 10    -- border-radius card
local ITEM_H   = 28    -- row height
local ITEM_G   = 0     -- gap between rows
local SECT_G   = 20    -- gap between sections

-- ─────────────────────────────────────────────────────────────────
--  MENU STATE
-- ─────────────────────────────────────────────────────────────────
local M = {
    visible    = true,
    x=130, y=70,
    drag=false, dox=0, doy=0,
    active_tab = 1,
    tabs       = {},   -- {name, sections={}}
    open_dd    = nil,  -- открытый dropdown/multidropdown
    bind_elem  = nil,  -- ждёт хоткей (для обычных элементов)
    settings_tab_idx = nil,  -- индекс встроенной вкладки Settings
}
local _tabs  = {}   -- name → tab
local _sects = {}   -- "tab\0sect" → section

-- встроенная вкладка Settings добавляется позже, в конце файла,
-- чтобы всегда быть последней (после пользовательских вкладок)

-- ─────────────────────────────────────────────────────────────────
--  PROXY / ELEMENT FACTORY
-- ─────────────────────────────────────────────────────────────────

--[[
  Каждый элемент имеет методы:

  p:get()               → текущее значение (value)
                          для multidropdown возвращает таблицу {[i]=bool}
                          для hotkey возвращает VK-код (0 = не задан)

  p:set(v)              → установить значение
                          checkbox   : bool
                          slider_*   : number (clamp к min/max автоматически)
                          dropdown   : number (индекс 1-based)
                          multidropdown: table {[i]=bool} или число индекса (toggle)
                          hotkey     : VK-код

  p:visibility([state]) → без аргумента = вернуть текущую видимость (bool)
                          с аргументом  = установить видимость
                          state может быть: bool, или результат :get()
                          Примеры:
                            aim_fov:visibility(false)
                            aim_fov:visibility(aim_on:get())
                            aim_fov:visibility(aim_bone:get() == 1)
--]]

local function proxy(e)
    -- скрытые элементы не рендерятся и не занимают место
    e._visible = true

    local p = {_e = e}
    local mt = {}

    mt.__index = function(_, k)
        -- методы элемента
        if k == "set_settings" then
            return function(_, settings_proxy)
                -- привязываем элемент к шестерёнке
                e._settings_elem = settings_proxy._e
            end
        end
        if k == "get" then
            return function(_) return e.value end
        end
        if k == "set" then
            return function(_, v)
                if e.type == "slider_float" or e.type == "slider_int" then
                    v = math.max(e.min, math.min(e.max, v))
                    if e.type == "slider_int" then v = math.floor(v+0.5) end
                end
                e.value = v
            end
        end
        if k == "visibility" then
            return function(_, state)
                if state == nil then
                    -- getter
                    return e._visible
                else
                    -- setter: принимает bool, число, таблицу
                    -- любое truthy значение кроме false/0/nil = visible
                    if type(state) == "boolean" then
                        e._visible = state
                    elseif type(state) == "number" then
                        e._visible = (state ~= 0)
                    elseif type(state) == "table" then
                        -- multidropdown value-таблица: visible если хоть один выбран
                        local any = false
                        for _,v2 in pairs(state) do if v2 then any=true; break end end
                        e._visible = any
                    else
                        e._visible = (state ~= nil and state ~= false)
                    end
                end
            end
        end
        -- прямой доступ к полям элемента
        return e[k]
    end

    mt.__newindex = function(_, k, v)
        if k == "_e" then rawset(p, k, v) else e[k] = v end
    end

    setmetatable(p, mt)
    return p
end

local curwe = {}

-- ─────────────────────────────────────────────────────────────────
-- ── Config API wrappers ───────────────────────────────────────────
function curwe.cfg_register(key, proxy_ref)
    config.register(key, proxy_ref)
end
function curwe.autosave()
    config.autosave()
end
function curwe.get_loaded_config()
    return config.loaded_name
end


function curwe.checkbox(label, def)
    return proxy({type="checkbox",label=label,
                  value=def==nil and false or def, _a=0})
end
function curwe.slider_float(label, def, mn, mx, fmt)
    mn=mn or 0; mx=mx or 1
    return proxy({type="slider_float",label=label,
                  value=def or mn, min=mn, max=mx,
                  fmt=fmt or "%.2f", _drag=false})
end
function curwe.slider_int(label, def, mn, mx)
    mn=mn or 0; mx=mx or 100
    return proxy({type="slider_int",label=label,
                  value=def or mn, min=mn, max=mx, _drag=false})
end
function curwe.dropdown(label, opts, def)
    return proxy({type="dropdown",label=label,
                  options=opts or {}, value=def or 1})
end
function curwe.multidropdown(label, opts, defs)
    local sel={}
    if defs then for _,i in ipairs(defs) do sel[i]=true end end
    return proxy({type="multidropdown",label=label,
                  options=opts or {}, value=sel})
end
function curwe.hotkey(label, def_vk)
    return proxy({type="hotkey",label=label,
                  value=def_vk or 0, _binding=false})
end

-- ── list: одиночный выбор, отображается инлайн как вертикальный список
-- items: таблица строк или varargs
-- def: индекс выбранного по умолчанию (1-based)
function curwe.list(label, items, def)
    -- принимаем и таблицу и varargs
    if type(items) ~= "table" then items = {items} end
    return proxy({type="list", label=label,
                  options=items, value=def or 1})
end

-- ── listable: множественный выбор, отображается инлайн
-- defs: таблица индексов выбранных по умолчанию {1,3,...}
function curwe.listable(label, items, defs)
    if type(items) ~= "table" then items = {items} end
    local sel = {}
    if defs then for _,i in ipairs(defs) do sel[i]=true end end
    return proxy({type="listable", label=label,
                  options=items, value=sel})
end

-- ── button: кнопка с callback и опциональным alt-стилем
-- callback: функция, вызываемая при клике
-- alt_style: bool — альтернативный стиль (ghost вместо primary)
function curwe.button(label, callback, alt_style)
    return proxy({type="button", label=label,
                  callback=callback or function() end,
                  alt_style=alt_style or false,
                  value=false,
                  _press_t=0})
end

-- ── input: текстовый ввод
-- label: подпись, default_text: начальное значение
-- :get() → string,  :set("text") → установить,  :visibility() работает
function curwe.input(label, default_text)
    return proxy({type="input", label=label,
                  value=default_text or "",
                  _focus=false})
end
function curwe.set_toggle_key(vk) _cfg.toggle_key = vk end

function curwe.add_tab(name)
    if _tabs[name] then return end
    local t={name=name,sections={}}
    table.insert(M.tabs,t)
    _tabs[name]=t
end
function curwe.add_section(tab, sect)
    local t=_tabs[tab]; if not t then return end
    local k=tab.."\0"..sect
    if _sects[k] then return end
    local s={name=sect,elems={}}
    table.insert(t.sections,s)
    _sects[k]=s
end
function curwe.add(tab, sect, p)
    local s=_sects[tab.."\0"..sect]
    if s then table.insert(s.elems, p._e) end
end

-- ─────────────────────────────────────────────────────────────────
--  DRAW HELPERS
-- ─────────────────────────────────────────────────────────────────
local function v2(x,y)  return vec2_t(x,y) end

--  NOTIFICATION SYSTEM
-- ─────────────────────────────────────────────────────────────────
local _notifs = {}   -- { text, born, state }
-- state: "in" → "show" → "out"
local NOTIF_W        = 220   -- ширина тоста
local NOTIF_H        = 36    -- высота тоста
local NOTIF_PAD      = 8     -- отступ между тостами
local NOTIF_MARGIN   = 16    -- отступ от края экрана
local NOTIF_LIFE     = 180   -- кадров показа (3с при 60fps)
local NOTIF_ANIM     = 18    -- кадров на slide-in / slide-out

function curwe.notify_push(text)
    table.insert(_notifs, {
        text  = tostring(text),
        born  = render.frame_count(),
        ox    = 0,   -- анимируемый x-offset (slide от правого края)
        alpha = 0,   -- анимируемая прозрачность
    })
    -- не более 5 одновременно
    if #_notifs > 5 then table.remove(_notifs, 1) end
end

local function draw_notifications()
    if #_notifs == 0 then return end
    local scr   = render.screen_size()
    local now   = render.frame_count()
    local dt    = math.min(render.frame_time(), 0.05)

    local dead = {}
    local slot = 0   -- счётчик живых тостов для позиционирования

    for i, n in ipairs(_notifs) do
        local age = now - n.born

        -- определяем целевые значения анимации
        local target_ox, target_alpha
        if age < NOTIF_ANIM then
            -- slide in: едет справа
            target_ox    = 0
            target_alpha = 1
        elseif age < NOTIF_LIFE then
            -- показ
            target_ox    = 0
            target_alpha = 1
        elseif age < NOTIF_LIFE + NOTIF_ANIM then
            -- slide out: уезжает вправо
            target_ox    = NOTIF_W + NOTIF_MARGIN + 20
            target_alpha = 0
        else
            -- удалить
            table.insert(dead, i)
            goto continue
        end

        -- плавная интерполяция (скорость 12 = быстро но плавно)
        n.ox    = n.ox    + (target_ox    - n.ox)    * math.min(1, dt * 12)
        n.alpha = n.alpha + (target_alpha - n.alpha) * math.min(1, dt * 12)

        if n.alpha < 0.02 then goto continue end

        do
            local al  = n.alpha
            -- позиция: правый верхний угол, стек снизу вверх
            local nx  = scr.x - NOTIF_MARGIN - NOTIF_W + n.ox
            local ny  = NOTIF_MARGIN + slot * (NOTIF_H + NOTIF_PAD)
            slot = slot + 1

            -- тень
            render.rect_filled(
                v2(nx+4, ny+4), v2(nx+NOTIF_W+4, ny+NOTIF_H+4),
                color_t(0, 0, 0, 0.35 * al), 10)

            -- основной фон (bg_layer)
            render.rect_filled(
                v2(nx, ny), v2(nx+NOTIF_W, ny+NOTIF_H),
                color_t(19/255, 15/255, 31/255, 0.96 * al), 10)

            -- верхний shine
            render.rect_filled(
                v2(nx, ny), v2(nx+NOTIF_W, ny+1),
                color_t(180/255, 140/255, 255/255, 0.08 * al), 10)

            -- левая accent-полоска
            render.rect_filled(
                v2(nx, ny+5), v2(nx+3, ny+NOTIF_H-5),
                color_t(P400.r, P400.g, P400.b, al), 3)

            -- рамка
            render.rect(
                v2(nx, ny), v2(nx+NOTIF_W, ny+NOTIF_H),
                color_t(139/255, 92/255, 246/255, 0.30 * al), 10, 1)

            -- progress bar снизу (показывает оставшееся время)
            local progress = 1 - math.max(0, math.min(1,
                (age - NOTIF_ANIM) / (NOTIF_LIFE - NOTIF_ANIM)))
            if progress > 0 and age >= NOTIF_ANIM then
                local bar_w = math.floor((NOTIF_W - 6) * progress)
                if bar_w > 2 then
                    render.rect_filled(
                        v2(nx+3, ny+NOTIF_H-2), v2(nx+3+bar_w, ny+NOTIF_H-1),
                        color_t(P400.r, P400.g, P400.b, 0.50 * al), 99)
                end
            end

            -- иконка "·" слева
            local icon_x = nx + 12
            local icon_y = ny + NOTIF_H * 0.5
            render.circle_filled(v2(icon_x, icon_y), 3, 12,
                color_t(P300.r, P300.g, P300.b, al))

            -- текст — клипуем чтобы не вылезал
            render.push_clip_rect(v2(nx+22, ny), v2(nx+NOTIF_W-8, ny+NOTIF_H), true)
            render.text(n.text, F_SM,
                v2(nx+22, ny+(NOTIF_H-11)*.5),
                color_t(TXT_PRI.r, TXT_PRI.g, TXT_PRI.b, al))
            render.pop_clip_rect()
        end

        ::continue::
    end

    -- удаляем мёртвые в обратном порядке
    for i = #dead, 1, -1 do
        table.remove(_notifs, dead[i])
    end
end

local function tsz(s,f)
    local r=render.calc_text_size(s,f)
    return r and r.x or 0, r and r.y or 13
end
local function tmid(s,f,cx,cy,c)
    local w,h=tsz(s,f)
    render.text(s,f,v2(cx-w*.5,cy-h*.5),c)
end
local function tright(s,f,rx,cy,c)
    local w,h=tsz(s,f)
    render.text(s,f,v2(rx-w,cy-h*.5),c)
end

-- glass card  (bg_card + shine highlight + border)
local function draw_card(x,y,w,h,r,hov_t)
    r=r or CARD_R; hov_t=hov_t or 0
    -- bg
    render.rect_filled(v2(x,y),v2(x+w,y+h),
        lpc(BG_CARD,BG_CARD_HOV,hov_t), r)
    -- top shine line  (card::before — 1px gradient)
    render.rect_filled(v2(x,y),v2(x+w,y+1), GLASS_SHINE, r)
    -- border
    local brd = hov_t>0.05
        and rgba(139,92,246, lp(0.18,0.25,hov_t))
        or  GLASS_BORDER
    render.rect(v2(x,y),v2(x+w,y+h), brd, r, 1)
end

-- window background with radial gradient simulation
local function draw_window(x,y,w,h)
    -- base fill
    render.rect_filled(v2(x,y),v2(x+w,y+h), BG_BASE, 18)
    -- radial top glow
    render.rect_filled_fade(
        v2(x,y), v2(x+w, y+h*0.55),
        rgba(90,40,160,0.22), rgba(90,40,160,0.22),
        CLR_NONE, CLR_NONE
    )
    -- bottom-right secondary glow
    render.rect_filled_fade(
        v2(x+w*0.55, y+h*0.55), v2(x+w, y+h),
        CLR_NONE, CLR_NONE,
        rgba(60,20,120,0.15), rgba(60,20,120,0.15)
    )
    -- window border
    render.rect(v2(x,y),v2(x+w,y+h), GLASS_BRD, 18, 1)
end
-- alias (make sure GLASS_BORDER is defined as GLASS_BRD)
GLASS_BORDER = GLASS_BRD

-- ─────────────────────────────────────────────────────────────────
--  ELEMENT RENDERERS
-- ─────────────────────────────────────────────────────────────────

-- Форвардер: вызывается из draw_gear_and_settings.
-- Заполняется ПОСЛЕ объявления всех r_* функций (см. ниже).
local _render_elem = nil

-- ── Шестерёнка: рисуем gear-иконку и управляем открытием панели ──
local _open_settings_elem = nil   -- какой элемент открыл панель
-- позиция popup'а (заполняется при открытии, используется overlay'ем)
local _settings_popup = { e=nil, x=0, y=0, w=0 }

local function draw_gear_and_settings(e, x, y, w)
    if not e._settings_elem then return 0 end  -- нет attached элемента — ничего

    local GEAR_SZ = 16
    local gx = x + w - GEAR_SZ - 2
    local gy = y + (ITEM_H - GEAR_SZ) * 0.5
    local is_open = (_open_settings_elem == e)
    local id = "gear"..tostring(e)
    local gt = sm(id, is_open and 1 or 0, 10)

    -- hover area
    local ghov = mhit(gx - 2, gy - 2, GEAR_SZ + 4, GEAR_SZ + 4)

    -- hover/active circle background
    local bg_a = lp(ghov and 0.10 or 0, 0.20, gt)
    if bg_a > 0.01 then
        render.circle_filled(
            v2(gx + GEAR_SZ * 0.5, gy + GEAR_SZ * 0.5),
            GEAR_SZ * 0.5 + 3, 20,
            rgba(139, 92, 246, bg_a))
    end

    -- иконка шестерёнки из шрифта: глиф "A" в icons.ttf = gear icon
    local icon_char = "D"
    local gc = lpc(TXT_MUTE, ACCENT, gt)
    if ghov and gt < 0.5 then gc = lpc(TXT_SEC, ACCENT, gt) end
    local iw, ih = tsz(icon_char, F_ICONS)
    render.text(icon_char, F_ICONS,
        v2(gx + (GEAR_SZ - iw) * 0.5, gy + (GEAR_SZ - ih) * 0.5),
        gc)

    -- клик: запоминаем координаты для overlay-попапа
    if ghov and lmb_click then
        if is_open then
            -- закрываем
            _open_settings_elem = nil
            _settings_popup.e   = nil
            -- сброс анимации для следующего открытия
            _anims["sppop"..tostring(e)] = 0
        else
            -- открываем: сначала сбрасываем анимацию в 0, потом target=1
            _anims["sppop"..tostring(e)] = 0
            _open_settings_elem  = e
            local popup_w = w
            local popup_h = ITEM_H + 8
            _settings_popup.e  = e
            _settings_popup.x  = x
            -- Y — над строкой (выше y на высоту попапа + отступ)
            _settings_popup.y  = y - popup_h - 4
            _settings_popup.w  = popup_w
            _settings_popup.h  = popup_h
        end
    end

    -- НЕ возвращаем дополнительную высоту — панель floating, не двигает layout
    return 0
end

-- ── checkbox / toggle-switch ──────────────────────────────────────
local function r_checkbox(e, x, y, w)
    local has_sett = e._settings_elem ~= nil
    local eff_w    = has_sett and (w - 20) or w

    local hov = mhit(x,y,eff_w,ITEM_H)
    if hov and lmb_click then e.value = not e.value end

    local id = tostring(e)
    e._a = sm(id..'t', e.value and 1 or 0, 12)

    if hov then
        render.rect_filled(v2(x-6,y),v2(x+w+6,y+ITEM_H),
            rgba(139,92,246,0.06),6)
    end

    render.text(e.label, F_REG, v2(x, y+(ITEM_H-13)*.5), TXT_PRI)

    local TW,TH = 34,18
    local tx = x+eff_w-TW
    local ty = y+(ITEM_H-TH)*.5
    local t  = e._a

    local tr_col = lpc(rgba(255,255,255,0.08), rgba(139,92,246,0.40), t)
    render.rect_filled(v2(tx,ty),v2(tx+TW,ty+TH), tr_col, 99)
    local tr_brd = lpc(GLASS_BRD, rgba(139,92,246,0.50), t)
    render.rect(v2(tx,ty),v2(tx+TW,ty+TH), tr_brd, 99, 1)

    local R = 6
    local thumb_x = tx + lp(3, TW-3-R*2, t) + R
    local thumb_y = ty + TH*.5
    if t > 0.05 then
        render.circle_filled(v2(thumb_x,thumb_y), R+3, 20,
            rgba(139,92,246, 0.22*t))
    end
    render.circle_filled(v2(thumb_x,thumb_y), R, 20, CLR_WHT)

    return draw_gear_and_settings(e, x, y, w)
end

-- ── slider ────────────────────────────────────────────────────────
local function r_slider(e, x, y, w, is_float)
    local hov = mhit(x,y,w,ITEM_H)
    local id  = tostring(e)

    local bx = x
    local by = y + ITEM_H - 8
    local bw = w
    local bh = 4

    if e._drag then
        if not kdn(VK_LMB) then e._drag=false
        else
            local raw = math.max(0,math.min(1,(mouse.x-bx)/bw))
            if is_float then
                e.value = math.floor((e.min+raw*(e.max-e.min))*100+.5)/100
            else
                e.value = math.floor(e.min+raw*(e.max-e.min)+.5)
            end
        end
    elseif hov and kdn(VK_LMB) and mhit(bx,by-5,bw,bh+10) then
        e._drag = true
    end

    if hov or e._drag then
        render.rect_filled(v2(x-6,y),v2(x+w+6,y+ITEM_H),
            rgba(139,92,246,0.06),6)
    end

    -- label
    render.text(e.label, F_REG, v2(x, y+4), TXT_SEC)

    -- value  (chip style)
    local vs = is_float and string.format(e.fmt,e.value) or tostring(e.value)
    local vw = tsz(vs,F_CHIP)+10
    local vx = x+w-vw; local vy = y+2
    render.rect_filled(v2(vx,vy),v2(vx+vw,vy+14), rgba(139,92,246,0.10),99)
    render.rect(v2(vx,vy),v2(vx+vw,vy+14), rgba(139,92,246,0.20),99,1)
    render.text(vs, F_CHIP, v2(vx+5,vy+2), P300)

    -- track bg
    render.rect_filled(v2(bx,by),v2(bx+bw,by+bh), BG_INPUT, 99)

    -- fill  gradient p600 → p400
    local t_fill = math.max(0,math.min(1,(e.value-e.min)/(e.max-e.min)))
    local fw = bw*t_fill
    if fw > 2 then
        render.rect_filled_fade(
            v2(bx,by), v2(bx+fw,by+bh),
            P600, P400, P400, P600
        )
        -- glow above bar
        render.rect_filled(v2(bx,by-1),v2(bx+fw,by+bh+1),
            rgba(139,92,246,0.18),99)
    end

    -- thumb
    local tx2 = bx+fw; local ty2 = by+bh*.5
    render.circle_filled(v2(tx2,ty2),7,20, rgba(139,92,246,0.28))   -- glow
    render.circle_filled(v2(tx2,ty2),5,20, ACCENT)                  -- body
    render.circle(v2(tx2,ty2),5,20, ACCENT_BR,1)                    -- ring

    return draw_gear_and_settings(e, x, y, w)
end

-- ── dropdown ──────────────────────────────────────────────────────
local function r_dropdown(e, x, y, w)
    local hov    = mhit(x,y,w,ITEM_H)
    local is_open = (M.open_dd==e)
    if hov and lmb_click then
        M.open_dd = is_open and nil or e
        is_open = (M.open_dd==e)
    end
    local id = tostring(e)
    local ht = sm(id.."h",(hov or is_open) and 1 or 0, 10)

    -- container  (form-input style)
    render.rect_filled(v2(x,y),v2(x+w,y+ITEM_H), BG_INPUT, 8)
    local brd = is_open and rgba(139,92,246,0.50) or GLASS_BRD
    render.rect(v2(x,y),v2(x+w,y+ITEM_H), brd, 8, 1)
    -- focus glow
    if ht>0.05 then
        render.rect_filled(v2(x-1,y-1),v2(x+w+1,y+ITEM_H+1),
            rgba(139,92,246,0.08*ht),9)
    end

    -- label
    render.text(e.label, F_REG, v2(x+10,y+(ITEM_H-13)*.5), TXT_SEC)
    -- selected
    tright(e.options[e.value] or "—", F_REG, x+w-22, y+ITEM_H*.5, TXT_PRI)

    -- chevron
    local cv=x+w-12; local ch2=y+ITEM_H*.5
    local cc = is_open and ACCENT or TXT_MUTE
    if is_open then
        render.line(v2(cv-4,ch2+2),v2(cv,  ch2-2),cc,1.5)
        render.line(v2(cv,  ch2-2),v2(cv+4,ch2+2),cc,1.5)
    else
        render.line(v2(cv-4,ch2-2),v2(cv,  ch2+2),cc,1.5)
        render.line(v2(cv,  ch2+2),v2(cv+4,ch2-2),cc,1.5)
    end
    e._dx=x; e._dy=y+ITEM_H; e._dw=w

    return draw_gear_and_settings(e, x, y, w)
end

-- ── multi-dropdown ────────────────────────────────────────────────
local function r_multidropdown(e, x, y, w)
    local hov    = mhit(x,y,w,ITEM_H)
    local is_open = (M.open_dd==e)
    if hov and lmb_click then
        M.open_dd = is_open and nil or e
        is_open = (M.open_dd==e)
    end

    render.rect_filled(v2(x,y),v2(x+w,y+ITEM_H), BG_INPUT, 8)
    local brd = is_open and rgba(139,92,246,0.50) or GLASS_BRD
    render.rect(v2(x,y),v2(x+w,y+ITEM_H), brd, 8, 1)

    render.text(e.label, F_REG, v2(x+10,y+(ITEM_H-13)*.5), TXT_SEC)

    local parts={}
    for i=1,#e.options do if e.value[i] then table.insert(parts,e.options[i]) end end
    local summary = #parts==0 and "None"
                 or #parts==#e.options and "All"
                 or #parts.." selected"
    tright(summary, F_REG, x+w-22, y+ITEM_H*.5, TXT_PRI)

    local cv=x+w-12; local ch2=y+ITEM_H*.5
    local cc = is_open and ACCENT or TXT_MUTE
    if is_open then
        render.line(v2(cv-4,ch2+2),v2(cv,ch2-2),cc,1.5)
        render.line(v2(cv,ch2-2),v2(cv+4,ch2+2),cc,1.5)
    else
        render.line(v2(cv-4,ch2-2),v2(cv,ch2+2),cc,1.5)
        render.line(v2(cv,ch2+2),v2(cv+4,ch2-2),cc,1.5)
    end
    e._dx=x; e._dy=y+ITEM_H; e._dw=w

    return draw_gear_and_settings(e, x, y, w)
end

-- ── hotkey ────────────────────────────────────────────────────────
local function r_hotkey(e, x, y, w)
    local hov     = mhit(x,y,w,ITEM_H)
    local is_bind = (M.bind_elem==e)

    if hov and lmb_click and not is_bind then
        M.bind_elem = e; e._binding=true
    end
    if is_bind then
        for vk=1,0xFE do
            if vk~=VK_LMB and kpr(vk) then
                e.value = (vk==VK_ESC) and 0 or vk
                M.bind_elem=nil; e._binding=false
                break
            end
        end
    end

    if hov then
        render.rect_filled(v2(x-6,y),v2(x+w+6,y+ITEM_H),
            rgba(139,92,246,0.06),6)
    end
    render.text(e.label, F_REG, v2(x,y+(ITEM_H-13)*.5), TXT_PRI)

    -- key badge
    local BW=68; local BH=ITEM_H-8
    local bx=x+w-BW; local by=y+4
    local bg_c = is_bind and rgba(139,92,246,0.30) or BG_INPUT
    local br_c = is_bind and rgba(139,92,246,0.60) or GLASS_BRD
    render.rect_filled(v2(bx,by),v2(bx+BW,by+BH), bg_c, 6)
    render.rect(v2(bx,by),v2(bx+BW,by+BH), br_c, 6, 1)

    local ks = is_bind and "..." or (e.value==0 and "None" or vkn(e.value))
    local kc = is_bind and ACCENT or TXT_PRI
    tmid(ks, F_CHIP, bx+BW*.5, by+BH*.5, kc)
end

-- ── button ────────────────────────────────────────────────────────
local function r_button(e, x, y, w)
    local hov   = mhit(x, y, w, ITEM_H)
    local id    = tostring(e)

    -- сбрасываем value (кнопка = одноразовый импульс)
    e.value = false

    if hov and lmb_click then
        e.value    = true
        e._press_t = 1.0
        e.callback()
    end

    -- анимация нажатия: плавно затухает
    e._press_t = sm(id.."bp", 0, 6)
    local pt   = e._press_t

    -- ── стили: primary (default) и alt/ghost ─────────────────────
    -- primary: gradient p600→p500, glow при hover
    -- alt:     ghost — прозрачный с рамкой
    local is_alt = e.alt_style

    local bg_col, br_col, tx_col

    if is_alt then
        -- ghost style (.btn-ghost)
        bg_col = rgba(139,92,246, lp(0.08, 0.18, pt) + (hov and 0.06 or 0))
        br_col = rgba(139,92,246, lp(0.15, 0.50, pt))
        tx_col = color_t(P300.r, P300.g, P300.b, 1)
    else
        -- primary style (.btn-primary) — gradient bg
        -- имитируем gradient через rect_filled_fade
        bg_col = nil   -- рисуем через fade отдельно
        br_col = rgba(139,92,246, lp(0.30, 0.60, pt))
        tx_col = CLR_WHT
    end

    local BH  = ITEM_H - 6
    local bx  = x
    local by2 = y + 3
    local bw  = w
    local BR  = 99   -- pill-style радиус

    if is_alt then
        render.rect_filled(v2(bx,by2), v2(bx+bw,by2+BH), bg_col, BR)
    else
        local g_alpha = lp(0.85, 1.0, pt) + (hov and 0.08 or 0)
        render.rect_filled_fade(
            v2(bx,by2), v2(bx+bw,by2+BH),
            rgba(109,40,217, g_alpha), rgba(124,58,237, g_alpha),
            rgba(124,58,237, g_alpha), rgba(109,40,217, g_alpha)
        )
        if hov or pt > 0.05 then
            render.rect_filled(v2(bx-1,by2-1), v2(bx+bw+1,by2+BH+1),
                rgba(109,40,217, 0.18 * lp(hov and 0.6 or 0, 1, pt)), BR)
        end
    end

    render.rect(v2(bx,by2), v2(bx+bw,by2+BH), br_col, BR, 1)

    -- press flash (белый overlay мигает при клике)
    if pt > 0.05 then
        render.rect_filled(v2(bx,by2), v2(bx+bw,by2+BH),
            rgba(255,255,255, 0.10*pt), 6)
    end

    -- label по центру
    local tw2 = tsz(e.label, F_REG)
    local tx2 = math.floor(bx + (bw-tw2)*.5)
    local ty2 = math.floor(by2 + (BH-13)*.5)
    render.text(e.label, F_REG, v2(tx2, ty2), tx_col)
end

-- ── input ─────────────────────────────────────────────────────────
-- Таблица: VK → символ (shift=false)
local _vk_chars = {}
for i=0,9 do _vk_chars[0x30+i] = tostring(i) end
for i=0,25 do _vk_chars[0x41+i] = string.char(97+i) end
_vk_chars[0x20]=" " _vk_chars[0xBD]="-" _vk_chars[0xBE]="."
_vk_chars[0xBF]="/" _vk_chars[0xBA]=";" _vk_chars[0xBB]="="
_vk_chars[0xDB]="[" _vk_chars[0xDD]="]" _vk_chars[0xDC]="\\"
_vk_chars[0xDE]="'" _vk_chars[0xBC]="," _vk_chars[0x6D]="-"
for i=0,9 do _vk_chars[0x60+i]=tostring(i) end  -- numpad

local _input_last = {}   -- предыдущее состояние клавиш для edge-detect

local function r_input(e, x, y, w)
    local hov = mhit(x, y, w, ITEM_H)

    -- клик по полю — фокус
    if hov and lmb_click then
        e._focus = true
    elseif lmb_click and not hov then
        e._focus = false
    end

    -- ввод клавиш если в фокусе
    if e._focus then
        local shift = kdn(0x10)   -- SHIFT
        -- backspace
        if kpr(0x08) and #e.value > 0 then
            e.value = e.value:sub(1, -2)
        end
        -- ESC — снять фокус
        if kpr(0x1B) then e._focus = false end
        -- обычные символы
        for vk, ch in pairs(_vk_chars) do
            local cur = kdn(vk)
            if cur and not _input_last[vk] then
                if shift and ch:match("%a") then ch = ch:upper()
                elseif shift then
                    local shift_map = {["1"]="!",["2"]="@",["3"]="#",
                        ["4"]="$",["5"]="%",["6"]="^",["7"]="&",
                        ["8"]="*",["9"]="(",["0"]=")",["="]="+",["-"]="_",
                        ["["]="{",["]"]="}",[";"]=":",[","]="<",["."]=">",["/"]="?"}
                    ch = shift_map[ch] or ch
                end
                if #e.value < 64 then e.value = e.value .. ch end
            end
            _input_last[vk] = cur
        end
    end

    local id  = tostring(e)
    local ft  = sm(id.."if", e._focus and 1 or 0, 10)

    -- фон поля
    local bg_col = lpc(BG_INPUT, rgba(20,14,36,0.95), ft)
    render.rect_filled(v2(x,y), v2(x+w,y+ITEM_H), bg_col, 6)
    -- рамка: ярче при фокусе
    local brd_col = lpc(GLASS_BRD, rgba(139,92,246,0.55), ft)
    render.rect(v2(x,y), v2(x+w,y+ITEM_H), brd_col, 6, 1)
    -- focus glow
    if ft > 0.05 then
        render.rect_filled(v2(x-1,y-1), v2(x+w+1,y+ITEM_H+1),
            rgba(139,92,246, 0.08*ft), 7)
    end

    -- label слева
    render.text(e.label, F_CHIP, v2(x+8, y+4), TXT_MUTE)

    -- значение или placeholder
    local display = e.value == "" and (e._focus and "" or "...") or e.value
    local tc = e.value == "" and TXT_MUTE or TXT_PRI
    -- курсор мигает в конце
    if e._focus then
        local blink = math.floor(render.frame_count() / 30) % 2 == 0
        display = e.value .. (blink and "|" or " ")
        tc = TXT_PRI
    end

    local dw = tsz(display, F_REG)
    -- клип чтобы текст не вылезал
    render.push_clip_rect(v2(x+6,y), v2(x+w-6,y+ITEM_H), true)
    render.text(display, F_REG, v2(x+w-dw-6, y+(ITEM_H-13)*.5), tc)
    render.pop_clip_rect()
end

-- ── list  (одиночный выбор, инлайн) ──────────────────────────────
-- Высота элемента = label(ITEM_H) + N строк по LIST_ROW каждая
local LIST_ROW = 22

local function list_elem_h(e)
    return ITEM_H + #e.options * LIST_ROW + 4
end

local function r_list(e, x, y, w)
    -- лейбл секции списка
    render.text(e.label, F_REG, v2(x, y + (ITEM_H-13)*.5), TXT_SEC)

    -- разделитель под лейблом
    render.rect_filled(v2(x, y+ITEM_H-1), v2(x+w, y+ITEM_H),
        GLASS_BRD, 0)

    local iy = y + ITEM_H + 2

    for i, opt in ipairs(e.options) do
        local is_sel = (e.value == i)
        local hov    = mhit(x, iy, w, LIST_ROW)

        local id = tostring(e).."li"..i
        local ht = sm(id, is_sel and 1 or 0, 12)

        -- hover / selected bg
        if ht > 0.01 then
            render.rect_filled_fade(
                v2(x, iy), v2(x+w, iy+LIST_ROW),
                rgba(109,40,217, 0.22*ht), rgba(139,92,246, 0.12*ht),
                rgba(139,92,246, 0.12*ht), rgba(109,40,217, 0.22*ht)
            )
        elseif hov then
            render.rect_filled(v2(x,iy), v2(x+w,iy+LIST_ROW),
                rgba(139,92,246,0.07), 4)
        end

        -- левая акцент-полоска выбранного
        if ht > 0.01 then
            render.rect_filled(v2(x, iy+3), v2(x+3, iy+LIST_ROW-3),
                rgba(ACCENT.r, ACCENT.g, ACCENT.b, ht), 2)
        end

        -- текст
        local tc = is_sel and P200 or (hov and TXT_PRI or TXT_SEC)
        render.text(opt, F_REG, v2(x+10, iy+(LIST_ROW-13)*.5), tc)

        -- нижний разделитель (кроме последнего)
        if i < #e.options then
            render.rect_filled(v2(x+6, iy+LIST_ROW-1), v2(x+w-6, iy+LIST_ROW),
                GLASS_BRD, 0)
        end

        if hov and lmb_click then e.value = i end

        iy = iy + LIST_ROW
    end
end

-- ── listable  (множественный выбор, инлайн) ───────────────────────
local function r_listable(e, x, y, w)
    render.text(e.label, F_REG, v2(x, y + (ITEM_H-13)*.5), TXT_SEC)
    render.rect_filled(v2(x, y+ITEM_H-1), v2(x+w, y+ITEM_H), GLASS_BRD, 0)

    -- счётчик выбранных справа от лейбла
    local cnt = 0
    for _,v2_ in pairs(e.value) do if v2_ then cnt=cnt+1 end end
    if cnt > 0 then
        local cs = tostring(cnt)
        local cw = tsz(cs, F_CHIP)+10
        local cx2 = x+w-cw; local cy2 = y+4
        render.rect_filled(v2(cx2,cy2), v2(cx2+cw,cy2+14),
            rgba(139,92,246,0.20), 99)
        render.rect(v2(cx2,cy2), v2(cx2+cw,cy2+14),
            rgba(139,92,246,0.35), 99, 1)
        render.text(cs, F_CHIP, v2(cx2+5, cy2+2), P300)
    end

    local iy = y + ITEM_H + 2

    for i, opt in ipairs(e.options) do
        local is_sel = (e.value[i] == true)
        local hov    = mhit(x, iy, w, LIST_ROW)

        local id = tostring(e).."lb"..i
        local ht = sm(id, is_sel and 1 or 0, 12)

        if ht > 0.01 then
            render.rect_filled_fade(
                v2(x, iy), v2(x+w, iy+LIST_ROW),
                rgba(109,40,217, 0.20*ht), rgba(139,92,246, 0.10*ht),
                rgba(139,92,246, 0.10*ht), rgba(109,40,217, 0.20*ht)
            )
        elseif hov then
            render.rect_filled(v2(x,iy), v2(x+w,iy+LIST_ROW),
                rgba(139,92,246,0.07), 4)
        end

        -- mini checkbox справа
        local bx2 = x+w-14; local by2 = iy+(LIST_ROW-10)*.5
        local bg2  = is_sel and rgba(139,92,246, 0.35+0.25*ht) or rgba(255,255,255,0.07)
        render.rect_filled(v2(bx2,by2), v2(bx2+10,by2+10), bg2, 3)
        render.rect(v2(bx2,by2), v2(bx2+10,by2+10),
            rgba(120,80,220, 0.20+0.30*ht), 3, 1)
        if ht > 0.05 then
            render.line(v2(bx2+2,by2+5),v2(bx2+4,by2+8),
                rgba(ACCENT.r,ACCENT.g,ACCENT.b,ht),1.5)
            render.line(v2(bx2+4,by2+8),v2(bx2+8,by2+2),
                rgba(ACCENT.r,ACCENT.g,ACCENT.b,ht),1.5)
        end

        -- текст
        local tc = is_sel and P200 or (hov and TXT_PRI or TXT_SEC)
        render.text(opt, F_REG, v2(x+10, iy+(LIST_ROW-13)*.5), tc)

        if i < #e.options then
            render.rect_filled(v2(x+6, iy+LIST_ROW-1), v2(x+w-6, iy+LIST_ROW),
                GLASS_BRD, 0)
        end

        if hov and lmb_click then e.value[i] = not e.value[i] end

        iy = iy + LIST_ROW
    end
end

-- Заполняем форвардер после объявления всех рендереров
_render_elem = function(e, x, y, w)
    if not e then return end
    if     e.type == "checkbox"      then r_checkbox(e, x, y, w)
    elseif e.type == "slider_float"  then r_slider(e, x, y, w, true)
    elseif e.type == "slider_int"    then r_slider(e, x, y, w, false)
    elseif e.type == "dropdown"      then r_dropdown(e, x, y, w)
    elseif e.type == "multidropdown" then r_multidropdown(e, x, y, w)
    elseif e.type == "hotkey"        then r_hotkey(e, x, y, w)
    elseif e.type == "input"         then r_input(e, x, y, w)
    end
end

-- ─────────────────────────────────────────────────────────────────
--  DROPDOWN POPUP  (рисуется поверх всего)
-- ─────────────────────────────────────────────────────────────────
local function draw_dd_overlay()
    local e = M.open_dd; if not e or not e._dx then return end
    local ox=e._dx; local oy=e._dy; local ow=e._dw
    local IH = 26
    local n  = #e.options
    local oh = n*IH+8

    -- shadow
    render.rect_filled(v2(ox+5,oy+5),v2(ox+ow+5,oy+oh+5),
        rgba(0,0,0,0.50),CARD_R)
    -- bg  (bg_layer)
    render.rect_filled(v2(ox,oy),v2(ox+ow,oy+oh), BG_LAYER, CARD_R)
    -- top shine
    render.rect_filled(v2(ox,oy),v2(ox+ow,oy+1), GLASS_SHINE, CARD_R)
    -- border accent
    render.rect(v2(ox,oy),v2(ox+ow,oy+oh), rgba(139,92,246,0.35), CARD_R, 1)

    for i,opt in ipairs(e.options) do
        local iy = oy+4+(i-1)*IH
        local hov = mhit(ox+4,iy,ow-8,IH)
        local is_sel = (e.type=="dropdown") and (e.value==i)
                    or (e.type=="multidropdown" and e.value[i]==true)

        if is_sel then
            -- active item  (nav-item.active style: gradient bg)
            render.rect_filled_fade(
                v2(ox+4,iy), v2(ox+ow-4,iy+IH),
                rgba(109,40,217,0.25), rgba(139,92,246,0.15),
                rgba(139,92,246,0.15), rgba(109,40,217,0.25)
            )
            render.rect(v2(ox+4,iy),v2(ox+ow-4,iy+IH),
                rgba(139,92,246,0.20),6,1)
            -- left accent bar  (nav-item.active::before)
            render.rect_filled(v2(ox+4,iy+5),v2(ox+7,iy+IH-5), ACCENT, 3)
        elseif hov then
            render.rect_filled(v2(ox+4,iy),v2(ox+ow-4,iy+IH),
                rgba(139,92,246,0.08),6)
        end

        local tc = is_sel and P200 or (hov and TXT_PRI or TXT_SEC)
        render.text(opt, F_REG, v2(ox+16, iy+(IH-13)*.5), tc)

        -- multidropdown checkbox
        if e.type=="multidropdown" then
            local cx2=ox+ow-20; local cy2=iy+(IH-10)*.5
            local bg2 = is_sel and rgba(139,92,246,0.35) or rgba(255,255,255,0.08)
            render.rect_filled(v2(cx2,cy2),v2(cx2+10,cy2+10), bg2, 3)
            render.rect(v2(cx2,cy2),v2(cx2+10,cy2+10), GLASS_BRD, 3, 1)
            if is_sel then
                render.line(v2(cx2+2,cy2+5),v2(cx2+4,cy2+8),ACCENT,1.5)
                render.line(v2(cx2+4,cy2+8),v2(cx2+8,cy2+2),ACCENT,1.5)
            end
        end

        if hov and lmb_click then
            if e.type=="dropdown" then
                e.value=i; M.open_dd=nil
            else
                e.value[i]=not e.value[i]
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────
--  DPI DROPDOWN OVERLAY  (рисуется поверх всего)
-- ─────────────────────────────────────────────────────────────────
local function draw_dpi_dd_overlay()
    if not M._dpi_dd_open then return end
    local ox = M._dpi_dd_x; if not ox then return end
    local oy = M._dpi_dd_y
    local ow = M._dpi_dd_w

    local dpi_opts   = { 0,   50,  100, 150, 200 }
    local dpi_labels = { "Auto", "50%", "100%", "150%", "200%" }

    local IH = 26
    local oh = #dpi_opts * IH + 8

    -- shadow
    render.rect_filled(v2(ox+5,oy+5), v2(ox+ow+5,oy+oh+5), rgba(0,0,0,0.50), CARD_R)
    -- bg
    render.rect_filled(v2(ox,oy), v2(ox+ow,oy+oh), BG_LAYER, CARD_R)
    -- shine
    render.rect_filled(v2(ox,oy), v2(ox+ow,oy+1), GLASS_SHINE, CARD_R)
    -- border
    render.rect(v2(ox,oy), v2(ox+ow,oy+oh), rgba(139,92,246,0.35), CARD_R, 1)

    for i, val in ipairs(dpi_opts) do
        local iy     = oy + 4 + (i-1)*IH
        local hov    = mhit(ox+4, iy, ow-8, IH)
        local is_sel = (_cfg.dpi_scale == val)

        if is_sel then
            render.rect_filled_fade(
                v2(ox+4,iy), v2(ox+ow-4,iy+IH),
                rgba(109,40,217,0.25), rgba(139,92,246,0.15),
                rgba(139,92,246,0.15), rgba(109,40,217,0.25))
            render.rect(v2(ox+4,iy), v2(ox+ow-4,iy+IH), rgba(139,92,246,0.20), 6, 1)
            render.rect_filled(v2(ox+4,iy+5), v2(ox+7,iy+IH-5), ACCENT, 3)
        elseif hov then
            render.rect_filled(v2(ox+4,iy), v2(ox+ow-4,iy+IH), rgba(139,92,246,0.08), 6)
        end

        local tc = is_sel and P200 or (hov and TXT_PRI or TXT_SEC)
        render.text(dpi_labels[i], F_REG, v2(ox+16, iy+(IH-13)*.5), tc)

        if hov and lmb_click then
            _cfg.dpi_scale    = val
            M._dpi_dd_open    = false
        end
    end

    -- клик вне списка — закрыть
    if lmb_click then
        local inside  = mhit(ox, oy, ow, oh)
        local on_ctrl = mhit(ox, oy - ITEM_H, ow, ITEM_H)
        if not inside and not on_ctrl then
            M._dpi_dd_open = false
        end
    end
end

-- ─────────────────────────────────────────────────────────────────
--  SETTINGS POPUP OVERLAY  (рисуется поверх всего, как dropdown)
-- ─────────────────────────────────────────────────────────────────
local function draw_settings_popup_overlay()
    local sp = _settings_popup
    if not sp.e then return end

    local se = sp.e._settings_elem
    if not se then return end

    local ox = sp.x
    local ow = sp.w
    local oh = sp.h or (ITEM_H + 8)

    -- анимация появления: target=1 когда открыт, target=0 когда закрыт
    local is_open = (_open_settings_elem == sp.e)
    local id  = "sppop"..tostring(sp.e)
    local at  = sm(id, is_open and 1 or 0, 14)

    -- полностью схлопнулся — больше не рисуем и сбрасываем ref
    if at < 0.01 and not is_open then
        _settings_popup.e = nil
        return
    end

    -- позиция: над строкой, слегка выезжает снизу вверх при появлении
    local oy = sp.y + (1 - at) * 6

    -- clamp: не выходить за верхний край экрана
    if oy < 4 then oy = 4 end

    -- ── тень ─────────────────────────────────────────────────────
    render.rect_filled(
        v2(ox + 4, oy + 4), v2(ox + ow + 4, oy + oh + 4),
        rgba(0, 0, 0, 0.55 * at), CARD_R)

    -- ── фон ──────────────────────────────────────────────────────
    render.rect_filled(
        v2(ox, oy), v2(ox + ow, oy + oh),
        color_t(19/255, 15/255, 31/255, 0.97 * at), CARD_R)

    -- ── верхняя shine-линия ──────────────────────────────────────
    render.rect_filled(
        v2(ox, oy), v2(ox + ow, oy + 1),
        rgba(180, 140, 255, 0.10 * at), CARD_R)

    -- ── левая accent-полоска ─────────────────────────────────────
    render.rect_filled(
        v2(ox, oy + 5), v2(ox + 3, oy + oh - 5),
        rgba(139, 92, 246, at), 3)

    -- ── рамка ────────────────────────────────────────────────────
    render.rect(
        v2(ox, oy), v2(ox + ow, oy + oh),
        rgba(139, 92, 246, 0.40 * at), CARD_R, 1)

    -- ── треугольник-хвостик внизу (указывает на шестерёнку) ──────
    local arrow_x = ox + ow - 14
    local arrow_y = oy + oh
    local arrow_sz = 5
    -- заливка фоном чтобы скрыть рамку за хвостиком
    render.line(v2(arrow_x - arrow_sz + 1, arrow_y),
                v2(arrow_x + arrow_sz - 1, arrow_y),
                color_t(19/255, 15/255, 31/255, 0.97 * at), arrow_sz * 2)
    -- контур хвостика
    local ac = rgba(139, 92, 246, 0.40 * at)
    render.line(v2(arrow_x - arrow_sz, arrow_y),
                v2(arrow_x,            arrow_y + arrow_sz), ac, 1)
    render.line(v2(arrow_x,            arrow_y + arrow_sz),
                v2(arrow_x + arrow_sz, arrow_y), ac, 1)

    -- ── содержимое ───────────────────────────────────────────────
    if at > 0.05 then
        render.push_clip_rect(
            v2(ox + 1, oy + 1),
            v2(ox + ow - 1, oy + oh - 1),
            true)
        _render_elem(se, ox + 10, oy + 4, ow - 20)
        render.pop_clip_rect()
    end

    -- ── клик вне попапа — закрыть ────────────────────────────────
    if lmb_click and is_open then
        -- gear-зона: (ox + ow - 20) .. (ox + ow), (sp.y + oh + 4) .. (sp.y + oh + 4 + ITEM_H)
        local gear_hov = mhit(ox + ow - 20, sp.y + oh + 4, 20, ITEM_H)
        local inside   = mhit(ox, oy, ow, oh)
        if not inside and not gear_hov then
            _open_settings_elem            = nil
            -- анимация схлопывается (target→0), ref уберётся когда at<0.01
        end
    end
end

-- ─────────────────────────────────────────────────────────────────
--  СЕКЦИЯ  (flat-стиль — без card, как на референсе)
-- ─────────────────────────────────────────────────────────────────
local SECT_TITLE_H = 22   -- высота заголовка секции

local function sect_h(s)
    local h = SECT_TITLE_H
    for _, e in ipairs(s.elems) do
        if e._visible ~= false then
            if e.type == "list" or e.type == "listable" then
                h = h + list_elem_h(e) + ITEM_G
            else
                h = h + ITEM_H + ITEM_G
            end
        end
    end
    return h
end

local function draw_section(s, x, y, w)
    local h = sect_h(s)

    local title_str = string.upper(s.name)
    render.text(title_str, F_CHIP, v2(x, y+5), TXT_MUTE)
    local tw3 = tsz(title_str, F_CHIP)
    render.rect_filled(v2(x+tw3+8, y+10), v2(x+w, y+11), GLASS_BRD, 0)

    local ey = y + SECT_TITLE_H
    local ex = x
    local ew = w

    for _, e in ipairs(s.elems) do
        if e._visible ~= false then
            local row_h = (e.type=="list" or e.type=="listable")
                and list_elem_h(e) or ITEM_H

            if     e.type=="checkbox"      then r_checkbox(e,ex,ey,ew)
            elseif e.type=="slider_float"  then r_slider(e,ex,ey,ew,true)
            elseif e.type=="slider_int"    then r_slider(e,ex,ey,ew,false)
            elseif e.type=="dropdown"      then r_dropdown(e,ex,ey,ew)
            elseif e.type=="multidropdown" then r_multidropdown(e,ex,ey,ew)
            elseif e.type=="hotkey"        then r_hotkey(e,ex,ey,ew)
            elseif e.type=="button"        then r_button(e,ex,ey,ew)
            elseif e.type=="input"         then r_input(e,ex,ey,ew)
            elseif e.type=="list"          then r_list(e,ex,ey,ew)
            elseif e.type=="listable"      then r_listable(e,ex,ey,ew)
            end

            -- разделитель снизу строки
            render.rect_filled(
                v2(ex, ey+row_h-1), v2(ex+ew, ey+row_h),
                GLASS_BRD, 0
            )

            ey = ey + row_h + ITEM_G
        end
    end

    return h
end

-- ─────────────────────────────────────────────────────────────────
--  VISUALS — ИНДИКАТОРЫ ПОД ПРИЦЕЛОМ
--
--  Дизайн: вертикальная колонка строк, каждая строка —
--  узкий прямоугольник:
--    ┌──────────────────────┐
--    │ curwe                │   ← бренд / заголовок, accent цвет
--    ├──────────────────────┤
--    │ dmg    24            │   ← лейбл + значение
--    └──────────────────────┘
--
--  Размер адаптивный: базовый 1/40 высоты экрана на строку,
--  ограничен min=14px / max=22px.
--  Шрифт тот же F_CHIP (10px) — пиксельный, жирный ощущение
--  достигается за счёт uppercase меток и высокого контраста.
-- ─────────────────────────────────────────────────────────────────

local function draw_visuals_hud()
    -- скрываем пока зажат TAB
    if kdn(0x09) then
        _anims["vis_ox"] = 0
        _anims["vis_al"] = 1
        _vis._offset_x   = 0
        _vis._alpha      = 1
        return
    end

    if not (_vis.show_curwe or _vis.show_dmg or _vis.show_state) then return end

    -- ── Определяем скоп ──────────────────────────────────────────
    local pawn = entitylist.get_local_player_pawn()
    local is_scoped = false
    if pawn then
        local ok, sc = pcall(function() return pawn.m_bIsScoped end)
        if ok then is_scoped = sc == true end
    end

    local scr = render.screen_size()
    local SCX = scr.x * 0.5
    local SCY = scr.y * 0.5

    -- ── Анимация alpha (плавный fade при смене режима) ────────────
    _vis._alpha = sm("vis_al", 1.0, 9)
    local alpha = _vis._alpha
    if alpha < 0.02 then return end

    -- ── Читаем dmg ───────────────────────────────────────────────
    local dmg_val = "—"
    if _vis.show_dmg and pawn then
        pcall(function()
            local ws  = pawn.m_pWeaponServices; if not ws  then return end
            local wep = ws.m_hActiveWeapon;     if not wep then return end
            local vd  = wep.m_pWeaponData;      if not vd  then return end
            local d   = vd.m_nDamage
            if type(d) == "number" then dmg_val = tostring(d) end
        end)
    end

    -- ── Читаем состояние движения ─────────────────────────────────
    -- Флаги из m_fFlags:
    --   FL_ONGROUND    = 0x0001
    --   FL_DUCKING     = 0x0002
    -- Скорость из m_vecVelocity для различения стоя/идёт/бежит
    local state_label = nil
    if _vis.show_state and pawn then
        local flags   = 0
        local vel_len = 0
        local ducking = false

        local ok_f, fl  = pcall(function() return pawn.m_fFlags end)
        local ok_v = pcall(function()
            local off = engine.get_netvar_offset("client.dll", "C_BaseEntity", "m_vecVelocity")
            if off and off > 0 then
                local vx = ffi.cast("float*", pawn[off])[0]
                local vy = ffi.cast("float*", pawn[off])[1]
                vel_len = math.sqrt(vx*vx + vy*vy)
            end
        end)
        if ok_f and type(fl) == "number" then flags = fl end

        -- m_bDucking как bool
        local ok_d, dck = pcall(function() return pawn.m_bDucking end)
        if ok_d and dck then ducking = (dck == true) end

        local on_ground = (bit.band(flags, 0x0001) ~= 0)
        local fl_duck   = (bit.band(flags, 0x0002) ~= 0) or ducking

        -- скоростные пороги (единицы Source: 250 = норм.ходьба, 64 = медл.)
        local WALK_MIN = 5      -- минимум чтобы считать движением
        local WALK_MAX = 130    -- walk / standing boundary

        -- slowwalk: читаем из меню чита (ragebot slow walk toggle)
        local is_slowwalk = false
        pcall(function()
            local sw_elem = menu.ragebot_slow_walk
            if sw_elem ~= nil then
                is_slowwalk = (sw_elem.value == true) or (sw_elem == true)
            end
        end)

        if not on_ground then
            if fl_duck then
                state_label = "AIR+C"
            else
                state_label = "AIR"
            end
        elseif fl_duck then
            if vel_len < WALK_MIN then
                state_label = "DUCK"
            else
                state_label = "SNEAK"
            end
        else
            if vel_len < WALK_MIN then
                state_label = "STAND"
            elseif is_slowwalk then
                state_label = "SLOWWALK"
            elseif vel_len <= WALK_MAX then
                state_label = "WALK"
            else
                state_label = "RUN"
            end
        end

        -- fallback: если не удалось прочесть флаги
        if state_label == nil then state_label = "DEF" end
    end

    -- ── Список строк ─────────────────────────────────────────────
    local lines = {}
    if _vis.show_curwe then table.insert(lines, { txt="curwe",    col=ACCENT }) end
    if state_label      then table.insert(lines, { txt=state_label, col=TXT_PRI }) end
    if _vis.show_dmg    then table.insert(lines, { txt="dmg "..dmg_val, col=TXT_PRI }) end
    if #lines == 0 then return end

    local FONT   = F_HUD
    local LINE_H = 15   -- 12px шрифт + 3px gap

    local CROSS_HALF = 6    -- px от центра до края прицела
    local GAP_CROSS  = 10   -- отступ от края прицела

    -- ── Ширина самой широкой строки ───────────────────────────────
    local max_w = 0
    for _, row in ipairs(lines) do
        local w = tsz(row.txt, FONT)
        if w > max_w then max_w = w end
    end

    -- ── Целевые позиции двух режимов ─────────────────────────────
    -- Y всегда одинаковый — под прицелом, не меняется
    local base_y = math.floor(SCY + CROSS_HALF + GAP_CROSS)

    -- Не в прицеле: блок центрирован по X
    local center_base_x = math.floor(SCX - max_w * 0.5)

    -- В прицеле: блок уходит вправо от прицела
    -- левый край = центр + CROSS_HALF + GAP_CROSS
    local scoped_base_x = math.floor(SCX + CROSS_HALF + GAP_CROSS)

    -- ── Плавная анимация только по X (speed=7 ≈ ~0.15с при 60fps) ─
    local anim_x  = sm("vis_bx", is_scoped and scoped_base_x or center_base_x, 7)
    -- scope_t: 0 = центр (каждая строка центрируется), 1 = правее (left-align от anim_x)
    local scope_t = sm("vis_st", is_scoped and 1 or 0, 7)

    -- ── Цвет строки состояния в зависимости от значения ──────────
    local state_colors = {
        DEF      = TXT_MUTE,
        STAND    = TXT_SEC,
        SLOWWALK = YELLOW,
        WALK     = TXT_PRI,
        RUN      = GREEN,
        DUCK     = P300,
        SNEAK    = YELLOW,
        AIR      = rgba(100, 200, 255, 1),
        ["AIR+C"]= rgba(100, 200, 255, 1),
    }

    -- ── Вспомогательная: текст с обводкой 8 направлений ─────────
    local function draw_outlined(str, x, y, col, oa)
        local oc = color_t(0, 0, 0, oa)
        render.text(str, FONT, v2(x-1, y-1), oc)
        render.text(str, FONT, v2(x,   y-1), oc)
        render.text(str, FONT, v2(x+1, y-1), oc)
        render.text(str, FONT, v2(x-1, y  ), oc)
        render.text(str, FONT, v2(x+1, y  ), oc)
        render.text(str, FONT, v2(x-1, y+1), oc)
        render.text(str, FONT, v2(x,   y+1), oc)
        render.text(str, FONT, v2(x+1, y+1), oc)
        render.text(str, FONT, v2(x,   y  ), col)
    end

    -- ── Рендер ───────────────────────────────────────────────────
    for i, row in ipairs(lines) do
        local tw = tsz(row.txt, FONT)

        -- X: плавно между "центрированным для этой строки" и "левый край блока"
        local tx_center = math.floor(SCX - tw * 0.5)
        local tx_scoped = math.floor(anim_x)
        local tx = math.floor(lp(tx_center, tx_scoped, scope_t))

        local ty = math.floor(base_y + (i - 1) * LINE_H)

        -- Цвет: если задан явный (curwe = ACCENT), иначе по таблице состояний
        local base_col = state_colors[row.txt] or row.col or TXT_PRI
        local col = color_t(base_col.r, base_col.g, base_col.b, alpha)

        draw_outlined(row.txt, tx, ty, col, 0.92 * alpha)
    end
end

-- ─────────────────────────────────────────────────────────────────
--  VISUALS PAGE  (вкладка меню)
-- ─────────────────────────────────────────────────────────────────
local function draw_visuals_page(cx, cy, cw)
    -- page header
    render.text("Visuals", F_BOLD, v2(cx, cy), TXT_PRI)
    render.text("Crosshair indicators", F_SM, v2(cx, cy+18), TXT_SEC)
    local sep_y = cy+36
    render.rect_filled(v2(cx,sep_y), v2(cx+cw,sep_y+1), GLASS_BRD, 0)

    local card_y = sep_y+12
    local card_w = cw

    -- ── карточка INDICATORS ──────────────────────────────────────
    local toggles = {
        { label="curwe label",  desc="Brand header row",          key="show_curwe" },
        { label="movement state", desc="DEF/STAND/RUN/DUCK/AIR…", key="show_state" },
        { label="dmg",          desc="Min damage override value", key="show_dmg"   },
    }

    local ROW_H2  = 42
    local card_h  = 28 + #toggles * ROW_H2 + 10
    draw_card(cx, card_y, card_w, card_h, CARD_R)

    render.text("INDICATORS", F_CHIP, v2(cx+14, card_y+8), TXT_MUTE)
    local stw = tsz("INDICATORS", F_CHIP)
    render.rect_filled(
        v2(cx+14+stw+8, card_y+14), v2(cx+card_w-14, card_y+15),
        GLASS_BRD, 0
    )

    local ry = card_y + 28
    for i, tog in ipairs(toggles) do
        local is_last = (i == #toggles)
        local hov = mhit(cx+14, ry, card_w-28, ROW_H2)

        if hov then
            render.rect_filled(
                v2(cx+10, ry), v2(cx+card_w-10, ry+ROW_H2),
                rgba(139,92,246, 0.06), 6
            )
        end

        render.text(tog.label, F_REG,  v2(cx+18, ry+8),  TXT_PRI)
        render.text(tog.desc,  F_CHIP, v2(cx+18, ry+23), TXT_MUTE)

        -- toggle switch
        local TW,TH = 34,18
        local tx2 = cx+card_w-18-TW
        local ty2 = ry+(ROW_H2-TH)*.5
        local id2 = "vis_tog_"..tog.key
        local at2 = sm(id2, _vis[tog.key] and 1 or 0, 12)

        render.rect_filled(v2(tx2,ty2), v2(tx2+TW,ty2+TH),
            lpc(rgba(255,255,255,0.08), rgba(139,92,246,0.40), at2), 99)
        render.rect(v2(tx2,ty2), v2(tx2+TW,ty2+TH),
            lpc(GLASS_BRD, rgba(139,92,246,0.50), at2), 99, 1)

        local R3 = 6
        local thx = tx2 + lp(3, TW-3-R3*2, at2) + R3
        local thy = ty2 + TH*.5
        if at2 > 0.05 then
            render.circle_filled(v2(thx,thy), R3+3, 20,
                rgba(139,92,246, 0.22*at2))
        end
        render.circle_filled(v2(thx,thy), R3, 20, CLR_WHT)

        if hov and lmb_click then
            _vis[tog.key] = not _vis[tog.key]
        end

        if not is_last then
            render.rect_filled(
                v2(cx+18, ry+ROW_H2-1), v2(cx+card_w-18, ry+ROW_H2),
                GLASS_BRD, 0
            )
        end
        ry = ry + ROW_H2
    end

    -- ── note ─────────────────────────────────────────────────────
    local note_y = card_y + card_h + 10
    render.text("Indicators visible only when cheat menu is open.",
        F_CHIP, v2(cx, note_y), TXT_MUTE)
    render.text("Slide right automatically when scoped.",
        F_CHIP, v2(cx, note_y+14), TXT_MUTE)
end

-- ─────────────────────────────────────────────────────────────────
--  SETTINGS PAGE  (встроенная, не через секции/элементы)
-- ─────────────────────────────────────────────────────────────────
local function draw_settings_page(cx, cy, cw)

    -- ── page title (общий стиль) ──────────────────────────────────
    render.text("Settings", F_BOLD, v2(cx, cy), TXT_PRI)
    render.text("Menu preferences", F_SM, v2(cx, cy+18), TXT_SEC)
    local sep_y = cy+36
    render.rect_filled(v2(cx,sep_y), v2(cx+cw,sep_y+1), GLASS_BRD, 0)

    -- ── единственная карточка: Menu Toggle Key ───────────────────
    local card_y = sep_y+12
    local card_w = cw
    local card_h = 70

    draw_card(cx, card_y, card_w, card_h, CARD_R)

    -- section-title внутри карточки
    render.text("KEYBINDS", F_CHIP, v2(cx+14, card_y+8), TXT_MUTE)
    local stw = tsz("KEYBINDS", F_CHIP)
    render.rect_filled(v2(cx+14+stw+8, card_y+14),
                       v2(cx+card_w-14, card_y+15), GLASS_BRD, 0)

    -- строка: "Menu Toggle Key"  [  INS  ]
    local row_y  = card_y+28
    local row_x  = cx+14
    local row_w  = card_w-28
    local is_bind = _cfg._binding

    -- hover подсветка строки
    local hov_row = mhit(row_x-4, row_y, row_w+8, ITEM_H)
    if hov_row then
        render.rect_filled(v2(row_x-6,row_y), v2(row_x+row_w+6,row_y+ITEM_H),
            rgba(139,92,246,0.06), 6)
    end

    -- label
    render.text("Menu Toggle Key", F_REG,
        v2(row_x, row_y+(ITEM_H-13)*.5), TXT_PRI)

    -- key badge
    local BW,BH = 80, ITEM_H-8
    local bx = row_x+row_w-BW
    local by = row_y+4

    -- состояния: обычный / hover / binding
    local bg_c, br_c
    if is_bind then
        bg_c = rgba(139,92,246,0.30)
        br_c = rgba(139,92,246,0.70)
    elseif hov_row then
        bg_c = rgba(139,92,246,0.14)
        br_c = rgba(139,92,246,0.40)
    else
        bg_c = BG_INPUT
        br_c = GLASS_BRD
    end

    render.rect_filled(v2(bx,by), v2(bx+BW,by+BH), bg_c, 6)
    render.rect(v2(bx,by), v2(bx+BW,by+BH), br_c, 6, 1)

    -- текст внутри бейджа
    local ks = is_bind and "Press key..." or vkn(_cfg.toggle_key)
    local kc = is_bind and ACCENT or TXT_PRI
    tmid(ks, is_bind and F_CHIP or F_CHIP, bx+BW*.5, by+BH*.5, kc)

    -- пульсирующая рамка во время ожидания
    if is_bind then
        local pulse = math.abs(math.sin(render.frame_count()*0.07))
        render.rect(v2(bx-1,by-1), v2(bx+BW+1,by+BH+1),
            rgba(139,92,246, 0.25+pulse*0.40), 7, 1)
    end

    -- клик по строке → начать бинд
    if hov_row and lmb_click and not is_bind then
        _cfg._binding = true
    end

    -- ожидание нажатия
    if is_bind then
        for vk=1,0xFE do
            if vk~=VK_LMB and kpr(vk) then
                if vk==VK_ESC then
                    -- ESC = отмена (ключ не меняем)
                else
                    _cfg.toggle_key = vk
                end
                _cfg._binding = false
                break
            end
        end
    end

    -- hint под карточкой
    local hint_y = card_y+card_h+8
    render.text("Click the key badge to rebind. Press ESC to cancel.",
        F_CHIP, v2(cx, hint_y), TXT_MUTE)

    -- ── карточка DPI SCALE ───────────────────────────────────────
    local dpi_card_y = hint_y + 22
    local dpi_card_h = 28 + ITEM_H + 16   -- header + dropdown row + padding
    draw_card(cx, dpi_card_y, card_w, dpi_card_h, CARD_R)

    -- заголовок секции
    render.text("DISPLAY", F_CHIP, v2(cx+14, dpi_card_y+8), TXT_MUTE)
    local dtw = tsz("DISPLAY", F_CHIP)
    render.rect_filled(
        v2(cx+14+dtw+8, dpi_card_y+14), v2(cx+card_w-14, dpi_card_y+15),
        GLASS_BRD, 0)

    -- ── DPI dropdown ─────────────────────────────────────────────
    local dpi_opts   = { 0,   50,  100, 150, 200 }
    local dpi_labels = { "Auto", "50%", "100%", "150%", "200%" }

    -- найти текущий индекс (1-based)
    local dpi_idx = 1
    for i, v in ipairs(dpi_opts) do
        if v == _cfg.dpi_scale then dpi_idx = i; break end
    end

    -- размеры
    local dd_x  = cx + 18
    local dd_y  = dpi_card_y + 28 + (ITEM_H - ITEM_H) * 0.5
    local dd_w  = card_w - 36
    local dd_h  = ITEM_H
    local dd_id = "dpi_dd"

    local dd_open = (M._dpi_dd_open == true)
    local dd_hov  = mhit(dd_x, dd_y, dd_w, dd_h)

    -- клик по полю
    if dd_hov and lmb_click then
        M._dpi_dd_open = not dd_open
        dd_open = M._dpi_dd_open
    end

    -- анимация hover/open
    local dd_ht = sm(dd_id.."h", (dd_hov or dd_open) and 1 or 0, 10)

    -- фон поля
    render.rect_filled(v2(dd_x,dd_y), v2(dd_x+dd_w,dd_y+dd_h), BG_INPUT, 8)
    local dd_brd = dd_open and rgba(139,92,246,0.50) or lpc(GLASS_BRD, rgba(139,92,246,0.35), dd_ht)
    render.rect(v2(dd_x,dd_y), v2(dd_x+dd_w,dd_y+dd_h), dd_brd, 8, 1)
    -- focus glow
    if dd_ht > 0.05 then
        render.rect_filled(v2(dd_x-1,dd_y-1), v2(dd_x+dd_w+1,dd_y+dd_h+1),
            rgba(139,92,246, 0.07*dd_ht), 9)
    end

    -- label слева
    render.text("DPI Scale", F_REG, v2(dd_x+10, dd_y+(dd_h-13)*.5), TXT_SEC)

    -- выбранное значение справа
    tright(dpi_labels[dpi_idx], F_REG, dd_x+dd_w-20, dd_y+dd_h*.5, TXT_PRI)

    -- chevron
    local cv_x = dd_x + dd_w - 10
    local cv_y = dd_y + dd_h * 0.5
    local cv_c = dd_open and ACCENT or TXT_MUTE
    if dd_open then
        render.line(v2(cv_x-4, cv_y+2), v2(cv_x,   cv_y-2), cv_c, 1.5)
        render.line(v2(cv_x,   cv_y-2), v2(cv_x+4, cv_y+2), cv_c, 1.5)
    else
        render.line(v2(cv_x-4, cv_y-2), v2(cv_x,   cv_y+2), cv_c, 1.5)
        render.line(v2(cv_x,   cv_y+2), v2(cv_x+4, cv_y-2), cv_c, 1.5)
    end

    -- сохраняем позицию для overlay-листа
    M._dpi_dd_x = dd_x
    M._dpi_dd_y = dd_y + dd_h
    M._dpi_dd_w = dd_w

    -- hint под карточкой
    local hint2_y = dpi_card_y + dpi_card_h + 8
end

-- ─────────────────────────────────────────────────────────────────
--  AUTH SCREEN  (показывается вместо меню пока не авторизован)
-- ─────────────────────────────────────────────────────────────────
local function draw_auth_screen()
    local scr = render.screen_size()
    local W, H = 320, 220
    local ax = math.floor(scr.x*.5 - W*.5)
    local ay = math.floor(scr.y*.5 - H*.5)

    -- плавный fade-in
    AUTH._alpha = sm("auth_al", 1, 5)
    local al = AUTH._alpha

    -- тряска при неверном пароле
    local shake_x = 0
    if AUTH._shake > 0.01 then
        AUTH._shake = sm("auth_sh", 0, 8)
        shake_x = math.floor(math.sin(render.frame_count()*0.8) * AUTH._shake * 6)
    end
    local ax2 = ax + shake_x

    -- затемнение фона
    render.rect_filled(v2(0,0), v2(scr.x,scr.y), rgba(0,0,0, 0.60*al))

    -- карточка
    render.rect_filled(v2(ax2,ay), v2(ax2+W,ay+H),
        color_t(19/255,15/255,31/255, 0.97*al), 16)
    render.rect_filled(v2(ax2,ay), v2(ax2+W,ay+1),
        rgba(180,140,255, 0.08*al), 16)
    render.rect(v2(ax2,ay), v2(ax2+W,ay+H),
        rgba(139,92,246, 0.30*al), 16, 1)

    -- лого
    render.text("curwe", F_LOGO, v2(ax2+18, ay+18), rgba(P300.r,P300.g,P300.b,al))
    local lw2 = tsz("curwe", F_LOGO)
    render.text("-code", F_LOGO, v2(ax2+18+lw2, ay+18), rgba(TXT_MUTE.r,TXT_MUTE.g,TXT_MUTE.b,al))

    -- разделитель
    render.rect_filled(v2(ax2+14,ay+40), v2(ax2+W-14,ay+41), rgba(120,80,220,0.18*al), 0)

    if AUTH.state == "loading" then
        -- спиннер (вращающийся arc)
        local t = render.frame_count() * 0.05
        render.arc(v2(ax2+W*.5, ay+H*.5), 18,
            t, t+2.2, 32, rgba(139,92,246,al), 2)
        render.text("Checking...", F_REG,
            v2(ax2+W*.5 - tsz("Checking...",F_REG)*.5, ay+H*.5+28),
            rgba(TXT_SEC.r,TXT_SEC.g,TXT_SEC.b,al))

    elseif AUTH.state == "denied" then
        -- иконка X
        local cx3 = ax2+W*.5; local cy3 = ay+90
        render.circle(v2(cx3,cy3), 20, 32, rgba(RED.r,RED.g,RED.b,0.3*al), 1)
        render.line(v2(cx3-8,cy3-8),v2(cx3+8,cy3+8),rgba(RED.r,RED.g,RED.b,al),2)
        render.line(v2(cx3+8,cy3-8),v2(cx3-8,cy3+8),rgba(RED.r,RED.g,RED.b,al),2)

        local msg = AUTH.error_msg
        render.text(msg, F_REG,
            v2(ax2+W*.5 - tsz(msg,F_REG)*.5, cy3+32),
            rgba(RED.r,RED.g,RED.b,al))
        render.text("Contact the script author.",
            F_CHIP, v2(ax2+W*.5 - tsz("Contact the script author.",F_CHIP)*.5, cy3+50),
            rgba(TXT_MUTE.r,TXT_MUTE.g,TXT_MUTE.b,al*0.7))

    elseif AUTH.state == "need_pass" then
        -- подзаголовок
        local sub = "Enter password to continue"
        render.text(sub, F_SM,
            v2(ax2+W*.5 - tsz(sub,F_SM)*.5, ay+52),
            rgba(TXT_SEC.r,TXT_SEC.g,TXT_SEC.b,al))

        -- поле ввода пароля
        local fx = ax2+18; local fy = ay+80; local fw = W-36; local fh = 32
        local foc = AUTH.input_focus

        -- клик по полю
        if mhit(fx,fy,fw,fh) and lmb_click then AUTH.input_focus = true
        elseif lmb_click then AUTH.input_focus = false end

        -- ввод символов
        if AUTH.input_focus then
            local shift = kdn(0x10)
            if kpr(0x08) and #AUTH.input_text > 0 then
                AUTH.input_text = AUTH.input_text:sub(1,-2)
            end
            if kpr(0x1B) then AUTH.input_focus = false end
            if kpr(0x0D) then  -- ENTER → проверяем пароль
                auth_check_password(AUTH.input_text)
            end
            for vk, ch in pairs(_vk_chars) do
                if kpr(vk) then
                    if shift and ch:match("%a") then ch=ch:upper() end
                    if #AUTH.input_text < 32 then
                        AUTH.input_text = AUTH.input_text .. ch
                    end
                end
            end
        end

        -- рендер поля
        local bg2 = foc and rgba(30,18,55,0.98) or BG_INPUT
        local br2 = foc and rgba(139,92,246,0.55) or rgba(120,80,220,0.25)
        render.rect_filled(v2(fx,fy), v2(fx+fw,fy+fh), bg2, 8)
        render.rect(v2(fx,fy), v2(fx+fw,fy+fh), br2, 8, 1)

        -- маскированный текст (звёздочки)
        local masked = string.rep("•", #AUTH.input_text)
        local blink2  = math.floor(render.frame_count()/30)%2==0
        local disp2   = AUTH.input_focus and (masked..(blink2 and "|" or " ")) or masked
        if AUTH.input_text=="" and not AUTH.input_focus then disp2="Password" end
        local tc2 = AUTH.input_text=="" and TXT_MUTE or TXT_PRI
        render.text(disp2, F_REG, v2(fx+10, fy+(fh-13)*.5), rgba(tc2.r,tc2.g,tc2.b,al))

        -- кнопка Login
        local bx3=ax2+18; local by3=fy+fh+12; local bw3=W-36; local bh3=28
        local bhov = mhit(bx3,by3,bw3,bh3)
        if bhov and lmb_click then auth_check_password(AUTH.input_text) end
        local g_al = bhov and 1.0 or 0.85
        render.rect_filled_fade(v2(bx3,by3),v2(bx3+bw3,by3+bh3),
            rgba(109,40,217,g_al*al), rgba(124,58,237,g_al*al),
            rgba(124,58,237,g_al*al), rgba(109,40,217,g_al*al))
        render.rect(v2(bx3,by3),v2(bx3+bw3,by3+bh3), rgba(139,92,246,0.4*al), 99, 1)
        local login_str = "Login"
        tmid(login_str, F_BOLD, bx3+bw3*.5, by3+bh3*.5, rgba(1,1,1,al))

        -- сообщение об ошибке
        if AUTH.error_msg ~= "" then
            render.text(AUTH.error_msg, F_CHIP,
                v2(ax2+W*.5 - tsz(AUTH.error_msg,F_CHIP)*.5, by3+bh3+8),
                rgba(RED.r,RED.g,RED.b,al))
        end
    end
end

-- ─────────────────────────────────────────────────────────────────
--  CONFIG PAGE
-- ─────────────────────────────────────────────────────────────────
local function draw_config_page(cx, cy, cw)
    -- заголовок
    render.text("CONFIG", F_BOLD, v2(cx, cy), TXT_PRI)
    render.rect_filled(v2(cx,cy+18),v2(cx+cw,cy+19), GLASS_BRD, 0)

    local y = cy + 28
    local half = math.floor((cw - 10) * 0.5)

    -- ── левая колонка: управление ──────────────────────────────────
    local lx = cx

    -- SECTION: File
    render.text("FILE", F_CHIP, v2(lx, y), TXT_MUTE)
    local tw0 = tsz("FILE", F_CHIP)
    render.rect_filled(v2(lx+tw0+6,y+5),v2(lx+half,y+6), GLASS_BRD, 0)
    y = y + 18

    -- input: config name
    -- рисуем вручную (не через draw_section)
    local inp_h = ITEM_H
    local inp_focused = config._name_focus or false
    if mhit(lx,y,half,inp_h) and lmb_click then
        config._name_focus = true
    elseif lmb_click then
        config._name_focus = false
    end
    if config._name_focus then
        if kpr(0x08) and #(config._name_input or "") > 0 then
            config._name_input = config._name_input:sub(1,-2)
        end
        if kpr(0x1B) then config._name_focus = false end
        for vk, ch in pairs(_vk_chars) do
            if kpr(vk) then
                local shift = kdn(0x10)
                if shift and ch:match("%a") then ch=ch:upper() end
                if #(config._name_input or "") < 32 then
                    config._name_input = (config._name_input or "") .. ch
                end
            end
        end
    end
    config._name_input = config._name_input or ""

    local ft2 = sm("cfg_ninf", (config._name_focus and 1 or 0), 10)
    render.rect_filled(v2(lx,y),v2(lx+half,y+inp_h), BG_INPUT, 6)
    render.rect(v2(lx,y),v2(lx+half,y+inp_h),
        lpc(GLASS_BRD,rgba(139,92,246,0.55),ft2), 6, 1)
    render.text("Name", F_CHIP, v2(lx+8, y+4), TXT_MUTE)
    local disp_name = config._name_input
    if config._name_focus then
        local bl = math.floor(render.frame_count()/30)%2==0
        disp_name = disp_name .. (bl and "|" or " ")
    end
    if disp_name == "" and not config._name_focus then disp_name = "config name..." end
    local dn_col = (config._name_input == "") and TXT_MUTE or TXT_PRI
    render.push_clip_rect(v2(lx+4,y),v2(lx+half-4,y+inp_h),true)
    render.text(disp_name, F_REG, v2(lx+half-tsz(disp_name,F_REG)-6, y+(inp_h-13)*.5), dn_col)
    render.pop_clip_rect()
    y = y + inp_h + 4

    -- buttons row: Save | Load
    local bh = 24
    local bw2 = math.floor(half*.5) - 3
    local function draw_btn_small(label, bx2, by2, bw3, alt, onclick)
        local hov = mhit(bx2,by2,bw3,bh)
        if hov and lmb_click then onclick() end
        local id3 = "cfgbtn"..label
        local pt = sm(id3, (hov and lmb_click) and 1 or 0, 8)
        local BR2 = 99  -- pill
        if alt then
            local bc = lpc(BG_INPUT, rgba(30,18,55,0.95), pt+(hov and 0.3 or 0))
            render.rect_filled(v2(bx2,by2),v2(bx2+bw3,by2+bh), bc, BR2)
            render.rect(v2(bx2,by2),v2(bx2+bw3,by2+bh),
                rgba(139,92,246, 0.25 + pt*0.3), BR2, 1)
        else
            -- primary: сплошной фиолетовый с hover осветлением, radius 99
            local g_alpha = 0.85 + (hov and 0.10 or 0) + pt*0.08
            render.rect_filled(v2(bx2,by2),v2(bx2+bw3,by2+bh),
                rgba(109,40,217, g_alpha), BR2)
            render.rect(v2(bx2,by2),v2(bx2+bw3,by2+bh),
                rgba(139,92,246,0.40), BR2, 1)
        end
        if pt > 0.05 then
            render.rect_filled(v2(bx2,by2),v2(bx2+bw3,by2+bh),
                rgba(255,255,255,0.08*pt), BR2)
        end
        local lbl_c = alt and P300 or CLR_WHT
        tmid(label, F_CHIP, bx2+bw3*.5, by2+bh*.5, lbl_c)
    end

    -- Save
    draw_btn_small("Save", lx, y, bw2, false, function()
        local name = config._name_input or ""
        config.save(name)
        if name ~= "" then curwe.notify_push("Saved: " .. name) end
    end)
    -- Load
    draw_btn_small("Load", lx+bw2+3, y, bw2, false, function()
        local sel_name = config.list[config.selected] or ""
        config._name_input = sel_name
        config.load(sel_name)
        if sel_name ~= "" then curwe.notify_push("Loaded: " .. sel_name) end
    end)
    y = y + bh + 3

    -- Refresh | Delete
    draw_btn_small("Refresh", lx, y, bw2, true, function()
        config.refresh()
        config.status_msg = "List refreshed"
        config.status_t   = render.frame_count()
        curwe.notify_push("Config list refreshed")
    end)
    draw_btn_small("Delete", lx+bw2+3, y, bw2, true, function()
        local sel_name = config.list[config.selected] or ""
        config.delete(sel_name)
        if sel_name ~= "" then curwe.notify_push("Deleted: " .. sel_name) end
    end)
    y = y + bh + 12

    -- SECTION: Clipboard
    render.text("CLIPBOARD", F_CHIP, v2(lx, y), TXT_MUTE)
    local tw1 = tsz("CLIPBOARD", F_CHIP)
    render.rect_filled(v2(lx+tw1+6,y+5),v2(lx+half,y+6), GLASS_BRD, 0)
    y = y + 18

    -- Copy to clipboard
    draw_btn_small("Copy to clipboard", lx, y, half, true, function()
        clipboard_set(config.export())
        config.status_msg = "Copied to clipboard!"
        config.status_t   = render.frame_count()
        curwe.notify_push("Config copied to clipboard")
    end)
    y = y + bh + 3

    -- Import from clipboard
    draw_btn_small("Import from clipboard", lx, y, half, true, function()
        local data = clipboard_get()
        if data ~= "" then
            config.import(data)
            config.status_msg = "Imported from clipboard!"
            config.status_t   = render.frame_count()
            curwe.notify_push("Config imported from clipboard")
        else
            config.status_msg = "Clipboard is empty!"
            config.status_t   = render.frame_count()
            curwe.notify_push("Clipboard is empty!")
        end
    end)
    y = y + bh + 12

    -- статус сообщение (исчезает через 3 секунды)
    if config.status_msg ~= "" then
        local elapsed = render.frame_count() - config.status_t
        local fade = 1 - math.max(0, (elapsed - 120) / 60)
        if fade > 0 then
            local is_err = config.status_msg:find("fail") or config.status_msg:find("empty")
            local sc = is_err and RED or GREEN
            render.text(config.status_msg, F_SM,
                v2(lx, y),
                rgba(sc.r, sc.g, sc.b, fade))
        else
            config.status_msg = ""
        end
    end

    -- ── правая колонка: список конфигов ───────────────────────────
    local rx = cx + half + 10
    local ry = cy + 28

    render.text("CONFIGS", F_CHIP, v2(rx, ry), TXT_MUTE)
    local tw2 = tsz("CONFIGS", F_CHIP)
    render.rect_filled(v2(rx+tw2+6,ry+5),v2(rx+half,ry+6), GLASS_BRD, 0)
    ry = ry + 18

    local LIST_R = 22
    local max_rows = math.floor((cy + (MH - CONT_PAD) - ry) / LIST_R)

    if #config.list == 0 then
        render.text("No configs found", F_REG,
            v2(rx+6, ry+6), TXT_MUTE)
    else
        for i, name in ipairs(config.list) do
            if i > max_rows then break end
            local iy = ry + (i-1)*LIST_R
            local is_sel = (config.selected == i)
            local hov    = mhit(rx, iy, half, LIST_R)
            local id4    = "cfgl"..i
            local ht     = sm(id4, is_sel and 1 or 0, 12)

            if ht > 0.01 then
                render.rect_filled_fade(
                    v2(rx,iy), v2(rx+half,iy+LIST_R),
                    rgba(109,40,217,0.22*ht), rgba(139,92,246,0.12*ht),
                    rgba(139,92,246,0.12*ht), rgba(109,40,217,0.22*ht))
            elseif hov then
                render.rect_filled(v2(rx,iy),v2(rx+half,iy+LIST_R),
                    rgba(139,92,246,0.07),4)
            end

            if is_sel and ht > 0.01 then
                render.rect_filled(v2(rx,iy+3),v2(rx+3,iy+LIST_R-3),
                    rgba(ACCENT.r,ACCENT.g,ACCENT.b,ht),2)
            end

            local is_loaded = (config.loaded_name == name)

            -- имя: чёрный жирный если loaded, иначе обычный
            local tc
            if is_loaded then
                tc = color_t(0, 0, 0, 1)
            elseif is_sel then
                tc = P200
            elseif hov then
                tc = TXT_PRI
            else
                tc = TXT_SEC
            end
            render.text(name, F_REG, v2(rx+10, iy+(LIST_R-13)*.5), tc)

            -- " - loaded" чёрным мелким, только если loaded (то есть нажата кнопка Load)
            if is_loaded then
                local nw     = tsz(name, F_REG)
                local suffix = " - loaded"
                render.text(suffix, F_CHIP,
                    v2(rx+10+nw, iy+(LIST_R-10)*.5),
                    color_t(0, 0, 0, 0.85))
            end

            if i < #config.list then
                render.rect_filled(v2(rx+4,iy+LIST_R-1),v2(rx+half-4,iy+LIST_R),GLASS_BRD,0)
            end

            if hov and lmb_click then
                config.selected    = i
                config._name_input = name
                -- простой клик — не считается загрузкой
                -- loaded_name НЕ меняем, только Load кнопка его ставит
            end
            -- двойной клик = загрузить
            if hov and lmb_now then
                config._click_t = config._click_t or 0
                if render.frame_count() - config._click_t < 15 and config._click_i == i then
                    config.load(name)
                end
                config._click_t = render.frame_count()
                config._click_i = i
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────
--  ГЛАВНЫЙ РЕНДЕР ОКНА
-- ─────────────────────────────────────────────────────────────────
local function draw_menu()
    local mx=M.x; local my=M.y
    local mw=MW;  local mh=MH

    -- ── DPI scale ───────────────────────────────────────────────
    -- Пересчитываем каждый кадр чтобы реагировать на смену настройки
    do
        local scr = render.screen_size()
        local factor
        if _cfg.dpi_scale == 0 then
            -- auto: целевая высота меню = 62% высоты экрана, но не меньше 0.5 и не больше 2.5
            factor = math.max(0.5, math.min(2.5, scr.y * 0.62 / MH))
        else
            factor = _cfg.dpi_scale / 100
        end
        -- плавная анимация смены масштаба
        factor = sm("dpi_f", factor, 10)
        mw = math.floor(MW * factor)
        mh = math.floor(MH * factor)
    end


    -- ── drag — за весь сайдбар ───────────────────────────────────
    if M.drag then
        if not kdn(VK_LMB) then M.drag=false
        else mx=mouse.x-M.dox; my=mouse.y-M.doy; M.x=mx; M.y=my end
    elseif mhit(mx,my,NAV_W,mh) and kdn(VK_LMB) and lmb_click then
        M.drag=true; M.dox=mouse.x-mx; M.doy=mouse.y-my
    end

    -- ── window bg ────────────────────────────────────────────────
    draw_window(mx,my,mw,mh)

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    --  SIDEBAR  (полная высота, без отдельного titlebar)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    local sx=mx; local sy=my
    local sw=NAV_W; local sh=mh

    render.rect_filled(v2(sx,sy), v2(sx+sw,sy+sh), BG_SIDEBAR, 0)
    -- скруглённые левые углы совпадают с окном
    render.rect_filled(v2(sx+sw-1,sy), v2(sx+sw,sy+sh), GLASS_BRD, 0)
    -- фиолетовый glow сверху
    render.rect_filled_fade(
        v2(sx,sy), v2(sx+sw,sy+sh*0.45),
        rgba(109,40,217,0.18), rgba(109,40,217,0.18),
        CLR_NONE, CLR_NONE
    )

    render.push_clip_rect(v2(sx,sy),v2(sx+sw,sy+sh),true)

    -- ── логотип вверху сайдбара ───────────────────────────────────
    local logo_y = sy+20
    render.text("curwe", F_LOGO, v2(sx+16, logo_y), P300)
    local lw = tsz("curwe", F_LOGO)
    render.text("-code", F_LOGO, v2(sx+16+lw, logo_y), TXT_MUTE)

    -- разделитель под логотипом
    render.rect_filled(v2(sx+10, logo_y+20), v2(sx+sw-10, logo_y+21), GLASS_BRD, 0)

    -- ── nav items ─────────────────────────────────────────────────
    local ny = logo_y + 32
    for i,tab in ipairs(M.tabs) do
        local act = (M.active_tab==i)
        local hov = mhit(sx+8, ny, sw-16, 34)
        if hov and lmb_click then M.active_tab=i; M.open_dd=nil end

        local id2 = "ni"..i
        local ht2 = sm(id2.."h", hov and 1 or 0, 10)
        local at2 = sm(id2.."a", act and 1 or 0, 10)

        if act and at2>0.05 then
            render.rect_filled_fade(
                v2(sx+8,ny), v2(sx+sw-8,ny+34),
                rgba(109,40,217,0.28*at2), rgba(139,92,246,0.16*at2),
                rgba(139,92,246,0.16*at2), rgba(109,40,217,0.28*at2)
            )
            render.rect(v2(sx+8,ny), v2(sx+sw-8,ny+34),
                rgba(139,92,246,0.22*at2), 8, 1)
            -- левая accent-полоска
            render.rect_filled(v2(sx+8,ny+7), v2(sx+11,ny+27),
                rgba(P400.r,P400.g,P400.b,at2), 3)
        elseif ht2>0.02 then
            render.rect_filled(v2(sx+8,ny), v2(sx+sw-8,ny+34),
                rgba(139,92,246,0.09*ht2), 8)
        end

        local tc = act and P200 or (hov and TXT_PRI or TXT_SEC)
        render.text(tab.name, F_NAV, v2(sx+22, ny+(34-13)*.5), tc)
        ny = ny+38
    end

    -- ── статус внизу сайдбара ─────────────────────────────────────
    local st_y = my+mh-58
    render.rect_filled(v2(sx+8,st_y), v2(sx+sw-8,st_y+40), BG_CARD, 10)
    render.rect(v2(sx+8,st_y), v2(sx+sw-8,st_y+40), GLASS_BRD, 10, 1)
    render.circle_filled(v2(sx+22,st_y+20), 7, 16, rgba(52,211,153,0.20))
    render.circle_filled(v2(sx+22,st_y+20), 4, 16, GREEN)
    render.text("Connected", F_SM,   v2(sx+32,st_y+8),  TXT_PRI)
    local uname = (get_user_name and get_user_name()) or "user"
    render.text(uname,       F_CHIP, v2(sx+32,st_y+23), TXT_MUTE)

    render.pop_clip_rect()

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    --  CONTENT
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    local cx = mx+NAV_W+CONT_PAD
    local cy = my+CONT_PAD
    local cw = mw-NAV_W-CONT_PAD*2
    local ch = mh-CONT_PAD*2

    local ctab = M.tabs[M.active_tab]
    if not ctab then return end

    render.push_clip_rect(v2(cx,cy), v2(cx+cw,cy+ch), true)

    -- ── логотип в правом верхнем углу content-области ────────────
    if _LOGO_TEX then
        local lsz = LOGO_SIZE
        local lx  = cx + cw - lsz
        local ly  = cy
        render.texture(_LOGO_TEX, v2(lx, ly), v2(lx+lsz, ly+lsz))
    end

    -- ── встроенные страницы ───────────────────────────────────────
    if ctab._is_settings then
        draw_settings_page(cx, cy, cw)
    elseif ctab._is_visuals then
        draw_visuals_page(cx, cy, cw)
    elseif ctab._is_config then
        draw_config_page(cx, cy, cw)
    else
        -- ── обычная вкладка ───────────────────────────────────────

        -- крупный заголовок страницы (как "VISUAL SETTINGS" на скрине)
        local page_title = string.upper(ctab.name)
        render.text(page_title, F_BOLD, v2(cx, cy), TXT_PRI)
        -- подчёркивание под заголовком
        local ptw = tsz(page_title, F_BOLD)
        render.rect_filled(v2(cx, cy+18), v2(cx+cw, cy+19), GLASS_BRD, 0)

        local content_y = cy + 28

        -- две колонки если секций > 1
        local n_s  = #ctab.sections
        local cols = n_s>1 and 2 or 1
        local colw = cols==2 and math.floor((cw-24)*.5) or cw
        local col_y = {content_y, content_y}

        for i,sect in ipairs(ctab.sections) do
            local col  = ((i-1)%cols)+1
            local sx2  = cx + (col-1)*(colw+24)
            local sy2  = col_y[col]
            local sh2  = draw_section(sect, sx2, sy2, colw)
            col_y[col] = sy2+sh2+SECT_G
        end
    end

    render.pop_clip_rect()

    -- dropdown overlay (поверх всего)
    draw_dd_overlay()
    -- settings popup overlay (поверх всего, включая dropdown)
    -- dpi dropdown overlay
    draw_dpi_dd_overlay()
    draw_settings_popup_overlay()
end

-- ─────────────────────────────────────────────────────────────────
--  CALLBACKS
-- ─────────────────────────────────────────────────────────────────

-- Первый коллбек: только input/логика (без рендера).
-- Регистрируется раньше — выполняется раньше.
register_callback("paint", function()
    U32.GetCursorPos(_pt)
    mouse.x = _pt.x
    mouse.y = _pt.y

    lmb_now   = kdn(VK_LMB)
    lmb_click = lmb_now and not lmb_last
    lmb_last  = lmb_now

    -- тогл меню только когда меню чита открыто и нет биндинга
    if kpr(_cfg.toggle_key) and not _cfg._binding
       and ui.is_menu_opened() then
        M.visible  = not M.visible
        M.open_dd  = nil
        M.bind_elem = nil
        -- закрыть settings popup при скрытии меню
        _open_settings_elem = nil
        _settings_popup.e   = nil
    end

    -- click outside dropdown → close
    if lmb_click and M.open_dd then
        local e = M.open_dd
        if e._dx then
            local oh = #e.options * 26 + 8
            if not mhit(e._dx, e._dy, e._dw, oh) and
               not mhit(e._dx, e._dy - ITEM_H, e._dw, ITEM_H) then
                M.open_dd = nil
            end
        end
    end
end)

-- Второй коллбек: только рендер.
register_callback("paint", function()
    if AUTH.state ~= "ok" then
        -- пока не авторизованы — показываем только экран входа
        draw_auth_screen()
        return
    end
    if M.visible then draw_menu() end
    draw_visuals_hud()
    draw_notifications()
end)

register_callback("unload", function()
    M.open_dd=nil; M.bind_elem=nil
    _open_settings_elem=nil; _settings_popup.e=nil
    -- автосохранение при выгрузке скрипта
    config.autosave()
end)

-- ─────────────────────────────────────────────────────────────────
--  ВСТРОЕННЫЕ ВКЛАДКИ: Visuals  +  Settings
--  Всегда в конце, после пользовательских.
--  add_tab переопределён: снимает обе, добавляет юзер-таб, кладёт обратно.
-- ─────────────────────────────────────────────────────────────────
local _config_tab   = { name="Config",   sections={}, _is_config=true   }
local _visuals_tab  = { name="Visuals",  sections={}, _is_visuals=true  }
local _settings_tab = { name="Settings", sections={}, _is_settings=true }

table.insert(M.tabs, _config_tab)
table.insert(M.tabs, _visuals_tab)
table.insert(M.tabs, _settings_tab)

local _orig_add_tab = curwe.add_tab
function curwe.add_tab(name)
    while M.tabs[#M.tabs] == _settings_tab
       or M.tabs[#M.tabs] == _visuals_tab
       or M.tabs[#M.tabs] == _config_tab do
        table.remove(M.tabs)
    end
    _orig_add_tab(name)
    table.insert(M.tabs, _config_tab)
    table.insert(M.tabs, _visuals_tab)
    table.insert(M.tabs, _settings_tab)
    M.settings_tab_idx = #M.tabs
end

-- ─────────────────────────────────────────────────────────────────
--  TESTS TAB  —  демонстрация :get() / :set() / :visibility()
-- ─────────────────────────────────────────────────────────────────
do
    curwe.add_tab("Tests")
    curwe.add_section("Tests", "Visibility demo")
    curwe.add_section("Tests", "Value demo")
    curwe.add_section("Tests", "List demo")
    curwe.add_section("Tests", "Button demo")
    curwe.add_section("Tests", "Settings demo")

    -- ── Секция 1: visibility ──────────────────────────────────────

    -- Мастер-переключатель. Если выключен — все остальные прячутся.
    local master = curwe.checkbox("Master toggle", true)

    -- Этот слайдер виден только когда master = true
    local fov = curwe.slider_float("FOV", 10.0, 1.0, 45.0, "%.1f°")

    -- Этот dropdown виден только когда master = true
    local bone = curwe.dropdown("Target bone", {"Head", "Neck", "Chest"}, 1)

    -- Этот слайдер виден только когда bone = "Chest" (индекс 3)
    local chest_pad = curwe.slider_int("Chest offset", 0, -20, 20)

    -- Мультидропдаун виден только когда fov > 15
    local hb = curwe.multidropdown("Hitboxes", {"Head","Body","Arms","Legs"}, {1})

    curwe.add("Tests", "Visibility demo", master)
    curwe.add("Tests", "Visibility demo", fov)
    curwe.add("Tests", "Visibility demo", bone)
    curwe.add("Tests", "Visibility demo", chest_pad)
    curwe.add("Tests", "Visibility demo", hb)

    -- ── Секция 2: get / set ───────────────────────────────────────

    -- Hotkey — если назначен, показываем слайдер "sensitivity"
    local fire_key = curwe.hotkey("Fire key", 0x02)  -- RMB по умолчанию
    local sens     = curwe.slider_float("Sensitivity", 1.0, 0.1, 5.0, "%.2f")
    local mode     = curwe.dropdown("Mode", {"Safe","Moderate","Rage"}, 1)
    -- Этот чекбокс виден только в Rage mode (индекс 3)
    local rage_chk = curwe.checkbox("Auto-fire", false)

    curwe.add("Tests", "Value demo", fire_key)
    curwe.add("Tests", "Value demo", sens)
    curwe.add("Tests", "Value demo", mode)
    curwe.add("Tests", "Value demo", rage_chk)

    -- ── Секция 3: list / listable ─────────────────────────────────

    -- list = одиночный выбор (как radio-group)
    local bone_list = curwe.list("Target bone", {
        "first_list_item",
        "second_l_item",
        "etc...",
    }, 1)

    -- listable = множественный выбор
    local hb_list = curwe.listable("Hitboxes", {
        "Head",
        "Neck",
        "Chest",
        "Stomach",
        "Arms",
    }, {1, 2})

    curwe.add("Tests", "List demo", bone_list)
    curwe.add("Tests", "List demo", hb_list)

    -- ── Секция 4: button ─────────────────────────────────────────

    -- primary кнопка (default стиль — фиолетовый gradient)
    local btn_apply = curwe.button("Apply config", function()
        engine.chat_print("[curwe] Config applied!")
    end)

    -- alt/ghost кнопка (прозрачная с рамкой)
    local btn_reset = curwe.button("Reset to default", function()
        engine.chat_print("[curwe] Config reset!")
    end, true)  -- true = alt_style

    curwe.add("Tests", "Button demo", btn_apply)
    curwe.add("Tests", "Button demo", btn_reset)

    -- ── Секция 5: set_settings ────────────────────────────────────
    --
    -- Если элемент имеет :set_settings(other_elem), то рядом с его
    -- toggle/значением появляется шестерёнка ⚙.
    -- Клик по шестерёнке раскрывает панель с other_elem внутри.
    -- other_elem НЕ нужно добавлять через curwe.add — он живёт в панели.

    -- Пример 1: checkbox с dropdown в шестерёнке
    local sett_aimbot = curwe.checkbox("Aimbot", false)
    local sett_bone   = curwe.dropdown("Target bone", {"Head","Neck","Chest","Stomach"}, 1)
    sett_aimbot:set_settings(sett_bone)  -- ← шестерёнка у "Aimbot", внутри — dropdown

    -- Пример 2: slider с hotkey в шестерёнке
    local sett_fov    = curwe.slider_float("FOV", 15.0, 1.0, 45.0, "%.1f°")
    local sett_key    = curwe.hotkey("Override key", 0)
    sett_fov:set_settings(sett_key)      -- ← шестерёнка у "FOV", внутри — hotkey

    -- Пример 3: checkbox с slider в шестерёнке
    local sett_aa     = curwe.checkbox("Anti-aim", false)
    local sett_pitch  = curwe.slider_int("Pitch", 0, -180, 180)
    sett_aa:set_settings(sett_pitch)     -- ← шестерёнка у "Anti-aim", внутри — slider

    curwe.add("Tests", "Settings demo", sett_aimbot)
    curwe.add("Tests", "Settings demo", sett_fov)
    curwe.add("Tests", "Settings demo", sett_aa)

    -- ── Обновляем видимость каждый кадр ─────────────────────────
    register_callback("paint", function()
        -- Секция 1
        local m = master:get()           -- bool
        fov:visibility(m)
        bone:visibility(m)
        -- chest_pad виден только если master on И выбран Chest (bone==3)
        chest_pad:visibility(m and bone:get() == 3)
        -- hb виден только если master on И fov > 15
        hb:visibility(m and fov:get() > 15)

        -- Секция 2
        -- sens виден только если fire_key назначен (не 0)
        sens:visibility(fire_key:get() ~= 0)
        -- rage_chk виден только в режиме Rage
        rage_chk:visibility(mode:get() == 3)
    end)
end


-- ═════════════════════════════════════════════════════════════════
--  ANTI-AIM TAB
--
--  Сейчас: только Pitch per-stand.
--  Stand select + Enabled + Pitch dropdown → menu.ragebot_anti_aim_pitch
--  Все остальные настройки будут добавлены позже.
-- ═════════════════════════════════════════════════════════════════

do
    curwe.add_tab("Anti-Aim")
    curwe.add_section("Anti-Aim", "Configuration")

    -- ── Стенды ───────────────────────────────────────────────────
    local STAND_NAMES = {
        "Default",
        "Standing",
        "Slowwalking",
        "Running",
        "Ducking",
        "Sneaking",
        "In Air",
        "In Air & Ducking",
    }
    local STAND_IDS = {
        "default", "standing", "slowwalk", "running",
        "ducking", "sneaking", "air",      "air_duck",
    }

    -- ── Pitch опции (0-based, напрямую как в чите) ───────────────
    -- menu.ragebot_anti_aim_pitch = 0|1|2  (None|Down|Fake)
    local PITCH_OPTS = { "None", "Down", "Fake" }

    -- ── UI-элементы (одна строка dropdown + checkbox + pitch) ────
    local stand_select  = curwe.dropdown("Stand",   STAND_NAMES, 1)
    local stand_enabled = curwe.checkbox("Enabled", true)
    local pitch         = curwe.dropdown("Pitch",   PITCH_OPTS,  1)

    curwe.add("Anti-Aim", "Configuration", stand_select)
    curwe.add("Anti-Aim", "Configuration", stand_enabled)
    curwe.add("Anti-Aim", "Configuration", pitch)

    -- ── Хранилище значений каждого стенда ────────────────────────
    -- stands[id] = { enabled, pitch }
    local stands = {}
    for _, id in ipairs(STAND_IDS) do
        stands[id] = {
            enabled = (id == "default"),  -- только Default включён по умолчанию
            pitch   = 0,                  -- None (0-based)
        }
    end
    stands["default"].enabled = true     -- Default всегда включён

    local _prev_stand_idx = 1

    -- ── Сохранить UI → стенд ─────────────────────────────────────
    local function save_to_stand(id)
        local s = stands[id]; if not s then return end
        s.enabled = stand_enabled:get()
        s.pitch   = pitch:get() - 1    -- сохраняем 0-based
    end

    -- ── Загрузить стенд → UI ─────────────────────────────────────
    local function load_to_ui(id)
        local s = stands[id]; if not s then return end
        stand_enabled:set((id == "default") and true or s.enabled)
        pitch:set(s.pitch + 1)          -- set принимает 1-based
    end

    -- ── Определение физического стенда ───────────────────────────
    local function get_active_stand_id()
        local pawn = entitylist.get_local_player_pawn()
        if not pawn then return "default" end

        local flags   = 0
        local vel_len = 0
        local ducking = false

        local ok_f, fl = pcall(function() return pawn.m_fFlags end)
        if ok_f and type(fl) == "number" then flags = fl end

        pcall(function()
            local off = engine.get_netvar_offset("client.dll", "C_BaseEntity", "m_vecVelocity")
            if off and off > 0 then
                local vx = ffi.cast("float*", pawn[off])[0]
                local vy = ffi.cast("float*", pawn[off])[1]
                vel_len  = math.sqrt(vx*vx + vy*vy)
            end
        end)

        local ok_d, dck = pcall(function() return pawn.m_bDucking end)
        if ok_d and dck then ducking = (dck == true) end

        local on_ground = (bit.band(flags, 0x0001) ~= 0)
        local fl_duck   = (bit.band(flags, 0x0002) ~= 0) or ducking

        local is_slowwalk = false
        pcall(function()
            local sw = menu.ragebot_slow_walk
            if sw ~= nil then
                is_slowwalk = (sw.value == true) or (sw == true)
            end
        end)

        if not on_ground then
            return fl_duck and "air_duck" or "air"
        elseif fl_duck then
            return vel_len < 5 and "ducking" or "sneaking"
        else
            if     vel_len < 5  then return "standing"
            elseif is_slowwalk  then return "slowwalk"
            else                     return "running"
            end
        end
    end

    -- ── Применить pitch активного физического стенда в чит ─────────
    -- menu.ragebot_anti_aim_pitch — plain number (0=None,1=Down,2=Fake)
    -- Присваивается напрямую: menu.ragebot_anti_aim_pitch = value
    local function apply_pitch_to_cheat()
        local phys_id = get_active_stand_id()
        local s       = stands[phys_id]

        -- Если стенд выключен — откатываем на Default
        if not s or (not s.enabled and phys_id ~= "default") then
            s = stands["default"]
        end

        pcall(function()
            menu.ragebot_anti_aim_pitch = s.pitch
        end)
    end

    -- ── Основной callback ─────────────────────────────────────────
    register_callback("paint", function()
        local cur_idx = stand_select:get()
        local cur_id  = STAND_IDS[cur_idx] or "default"

        -- ── Переключение стенда: сохраняем старый, грузим новый ──
        if cur_idx ~= _prev_stand_idx then
            save_to_stand(STAND_IDS[_prev_stand_idx] or "default")
            load_to_ui(cur_id)
            _prev_stand_idx = cur_idx
        else
            -- Каждый кадр сохраняем UI → хранилище текущего стенда
            save_to_stand(cur_id)
        end

        -- Default нельзя выключить
        if cur_id == "default" then
            stand_enabled:set(true)
            stands["default"].enabled = true
        end

        -- Pitch виден только если стенд включён
        pitch:visibility(stand_enabled:get())

        -- Применяем pitch физически активного стенда в чит
        apply_pitch_to_cheat()
    end)
end

-- ─────────────────────────────────────────────────────────────────
return curwe
