-- =============================================================
--  ФАКТОР 1/3: АНТИ-HTTP СПАЙ (ЗАПУСКАТЬ ПЕРВЫМ!)
--  ССЫЛКА: https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/loader.lua
-- =============================================================

-- БЕЗОПАСНЫЙ РЕЗОЛВ ВСЕХ ФУНКЦИЙ С ФОЛЛБЭКАМИ ПОД ЛЮБОЙ ЭКСПЛОЙТ
local _ORIG = {}
_ORIG.m_floor, _ORIG.m_char, _ORIG.m_find, _ORIG.m_sub, _ORIG.m_gsub, _ORIG.m_format = math.floor, string.char, string.find, string.sub, string.gsub, string.format
_ORIG.t_pairs, _ORIG.t_ipairs, _ORIG.t_concat, _ORIG.t_insert, _ORIG.t_find = pairs, ipairs, table.concat, table.insert, table.find
_ORIG.pcall, _ORIG.xpcall = pcall, xpcall
_ORIG.task_wait, _ORIG.task_spawn, _ORIG.task_delay, _ORIG.task_cancel = task.wait, task.spawn, task.delay, task.cancel
_ORIG.getgenv, _ORIG.getrenv = getgenv or getrenv, getrenv
_ORIG.getmeta, _ORIG.setmeta = getmetatable, setmetatable
_ORIG.to_str = tostring

-- Резолвим отладочные функции
_ORIG.d_info = debug.getinfo
do
    -- getconstants: есть с s на конце — используем, нет — собираем по одной
    _ORIG.d_const = debug.getconstants
    if not _ORIG.d_const then
        _ORIG.d_const = function(func)
            local out = {}
            local i = 1
            while true do
                local ok, val = pcall(debug.getconstant, func, i)
                if not ok then break end
                out[i] = val
                i = i + 1
            end
            return out
        end
    end
    -- getupvalues: аналогично
    _ORIG.d_upv = debug.getupvalues
    if not _ORIG.d_upv then
        _ORIG.d_upv = function(func)
            local out = {}
            local i = 1
            while true do
                local ok, val = pcall(debug.getupvalue, func, i)
                if not ok or not val then break end
                out[i] = val
                i = i + 1
            end
            return out
        end
    end
    -- islclosure / iscclosure
    _ORIG.islc = islclosure or is_lclosure or function(f)
        if type(f) ~= "function" then return false end
        local ok, info = pcall(debug.getinfo, f)
        return ok and info and info.what == "Lua"
    end
    _ORIG.isc  = iscclosure or is_cclosure or function(f)
        if type(f) ~= "function" then return false end
        local ok, info = pcall(debug.getinfo, f)
        return ok and info and info.what == "C"
    end
end
_ORIG.hook_f = hookfunction or hook_func
_ORIG.hook_m = hookmetamethod or hook_meta_method
_ORIG.newcc  = newcclosure or new_c_closure or function(f) return f end
_ORIG.clonef = clonefunction or clone_func or function(f) return f end
_ORIG.replf  = replaceclosure or replacefunction or replace_func or function() end
_ORIG.gc = getgc or get_gc or function() return {} end
_ORIG.req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
_ORIG.httpget  = game.HttpGet
_ORIG.httppost = game.HttpPost
_ORIG.getobj   = game.GetObjects
_ORIG.writef   = writefile or write_file
_ORIG.appendf  = appendfile or append_file
_ORIG.readf    = readfile or read_file
_ORIG.listf    = listfiles or list_files or function() return {} end
_ORIG.rconprint  = rconsoleprint or rcon_print or print
_ORIG.rconcreate = rconsolecreate or rcon_create or function() end
_ORIG.rconclear  = rconsoleclear or rcon_clear or function() end
_ORIG.load     = loadstring or load

-- СЕРВИСЫ
local _H   = game:GetService("HttpService")
local _L   = game:GetService("Players").LocalPlayer
local _CG  = game:GetService("CoreGui")
local _TS  = game:GetService("TestService")
local _RAS = game:GetService("RbxAnalyticsService")
local _UIS = game:GetService("UserInputService")

local DETECTED = false
local DETECT_REASON = nil
local _SEC_STATE = {ORIG = _ORIG, PLAYER = _L, HTTP = _H, RAS = _RAS, UIS = _UIS, TS = _TS, CG = _CG}
shared.__NK_3F_SEC = _SEC_STATE

-- =============================================================
--                     ВНУТРЕННИЕ УТИЛИТЫ
-- =============================================================
local function setDetect(reason)
    if DETECTED then return end
    DETECTED = true
    DETECT_REASON = reason
    _SEC_STATE.SPY_DETECTED = reason
end
local function encHex(str)
    local out = {}
    for i = 1, #str do _ORIG.t_insert(out, ("%02x"):format(_ORIG.m_floor(str:byte(i)))) end
    return _ORIG.t_concat(out)
end
local function decHex(h)
    local s = ""
    for i = 1, #h, 2 do
        local n = tonumber(_ORIG.m_sub(h,i,i+1),16)
        if n then s = s .. _ORIG.m_char(n) end
    end
    return s
end
local function isLUA(f)
    if type(f) ~= "function" then return false end
    local ok, res = _ORIG.pcall(_ORIG.islc, f)
    return ok and res
end
local function safePairsScan(v, callback)
    -- Безопасно итерирует любое значение, не падает на инстансах/защищённых таблицах
    if type(v) ~= "table" then return end
    _ORIG.pcall(function()
        for k, val in _ORIG.t_pairs(v) do
            callback(k, val)
        end
    end)
end

-- Проверка что дебаг не сломан
do
    local ok, info = _ORIG.pcall(_ORIG.d_info, _ORIG.m_floor)
    if not ok or not info or info.what ~= "C" or info.source ~= "=[C]" then setDetect("PATCHED_DEBUG_GETINFO") end
end
-- Проверка что хук-функции не подменены
do
    if _ORIG.hook_f and hookfunction ~= _ORIG.hook_f then setDetect("PATCHED_HOOK_FUNCTIONS") end
    if _ORIG.hook_m and hookmetamethod ~= _ORIG.hook_m then setDetect("PATCHED_HOOK_METAMETHOD") end
end

-- =============================================================
--                     БАЗОВЫЕ ПРОВЕРКИ ХУКОВ
-- =============================================================
do
    local targets = {
        {_ORIG.req, "SYN_REQUEST"},
        {request, "GLOBAL_REQUEST"},
        {http and http.request, "HTTP_REQUEST"},
        {syn and syn.request, "SYN_REQUEST_ALT"},
        {fluxus and fluxus.request, "FLUXUS_REQUEST"},
        {http_request, "HTTPREQUEST_ALIAS"},
        {_ORIG.httpget, "GAME_HTTPGET"},
        {game.HttpGetAsync, "GAME_HTTPGETASYNC"},
        {_ORIG.httppost, "GAME_HTTPPOST"},
        {game.HttpPostAsync, "GAME_HTTPPOSTASYNC"},
        {_ORIG.getobj, "GAME_GETOBJECTS"},
    }
    for _, t in _ORIG.t_ipairs(targets) do
        local f, name = t[1], t[2]
        if f then
            local ok, info = _ORIG.pcall(_ORIG.d_info, f)
            if not ok or not info then setDetect("ERR_INFO_"..name)
            elseif info.what ~= "C" or info.source ~= "=[C]" then setDetect("HOOKED_"..name) end
        end
    end
end
-- Проверка __namecall
for _, obj in _ORIG.t_ipairs({game, _H}) do
    local ok, nc = _ORIG.pcall(function() return _ORIG.getmeta(obj).__namecall end)
    if ok and nc and isLUA(nc) then setDetect("HOOKED_NAMECALL") end
end
-- Websocket хук
if syn and syn.websocket and syn.websocket.connect then
    local ok, info = _ORIG.pcall(_ORIG.d_info, syn.websocket.connect)
    if ok and info and info.what ~= "C" then setDetect("HOOKED_WEBSOCKET_CONNECT") end
end

-- =============================================================
--                     СКАН GETGC НА СИГНАТУРЫ
-- =============================================================
local SPY_SIGNATURES = {
    "HttpSpy", "HttpSpy v", "NotDSF/HttpSpy", "SimpleSpy", "SimpleSpy v",
    "HydroSpy", "VGG Spy", "TwiSpy", "Venus Spy", "VenusSpy", "Fenix HTTP Logger",
    "FenixSpy", "HTTP Logger", "Request Intercepted", "Request Logged",
    "BlockedURLs", "ShowResponse", "AutoDecode", "HookSynRequest", "ProxyHost",
    "Response Data:", "-- blocked url", "logs are automatically being saved to",
    "eleutheri.com", "ZeZLm2hpvGJrD6OP8A3aEszPNEw8OxGb",
    "gpGXBVpEoOOktZWoYECgAY31o0BlhOue"
}
do
    local seen = {}
    _ORIG.pcall(function()
        for _, v in _ORIG.t_pairs(_ORIG.gc(true)) do
            if DETECTED then break end
            if seen[v] then continue end
            seen[v] = true
            local t = type(v)
            if t == "function" then
                local okC, consts = _ORIG.pcall(_ORIG.d_const, v)
                if okC and consts then
                    for _, c in _ORIG.t_ipairs(consts) do
                        if type(c) == "string" then
                            for _, sig in _ORIG.t_ipairs(SPY_SIGNATURES) do
                                if _ORIG.m_find(c, sig, 1, true) then
                                    setDetect("GC_CONST_" .. _ORIG.m_gsub(sig, "[^A-Z0-9_]", "_"):sub(1,50))
                                    goto gc_next
                                end
                            end
                        elseif typeof and typeof(c) == "Instance" then
                            local okIsA, isBind = _ORIG.pcall(function() return c:IsA("BindableEvent") and c.Name == "OnRequest" end)
                            if okIsA and isBind then setDetect("GC_BINDABLE_HTTPSPY"); goto gc_next end
                        end
                    end
                end
                local okU, ups = _ORIG.pcall(_ORIG.d_upv, v)
                if okU and ups then
                    for _, u in _ORIG.t_ipairs(ups) do
                        if type(u) == "string" then
                            for _, sig in _ORIG.t_ipairs(SPY_SIGNATURES) do
                                if _ORIG.m_find(u, sig, 1, true) then
                                    setDetect("GC_UPV_" .. _ORIG.m_gsub(sig, "[^A-Z0-9_]", "_"):sub(1,50))
                                    goto gc_next
                                end
                            end
                        end
                    end
                end
            elseif t == "string" then
                for _, sig in _ORIG.t_ipairs(SPY_SIGNATURES) do
                    if _ORIG.m_find(v, sig, 1, true) then
                        setDetect("GC_STR_" .. _ORIG.m_gsub(sig, "[^A-Z0-9_]", "_"):sub(1,50))
                        goto gc_next
                    end
                end
            end
            ::gc_next::
        end
    end)
end

-- =============================================================
--                     СКАН ФАЙЛОВ
-- =============================================================
_ORIG.pcall(function()
    local files = _ORIG.listf("")
    if type(files) ~= "table" then return end
    for _, f in _ORIG.t_ipairs(files) do
        local n = _ORIG.to_str(f):lower()
        if _ORIG.m_find(n, "log%.txt$") and _ORIG.m_find(n, "^%d+%-%d+_%d+_%d+%-log")
        or _ORIG.m_find(n, "simplespy", 1, true)
        or _ORIG.m_find(n, "httpspy", 1, true)
        or _ORIG.m_find(n, "hydrospy", 1, true)
        or _ORIG.m_find(n, "httplog", 1, true) then
            setDetect("SPY_LOGFILE:"..n)
            break
        end
    end
end)

-- =============================================================
--                     КАНАРНЫЙ ТЕСТ
-- =============================================================
local CANARY_TOKEN = "__NK_3F_CANARY_" .. _ORIG.m_floor(os.clock()*1000000) .. "_" .. _ORIG.m_sub(tostring({}),8)
do
    _ORIG.pcall(function()
        _ORIG.req({
            Url = "https://invalid.local/canary",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["X-Canary"] = CANARY_TOKEN},
            Body = _H:JSONEncode({canary = CANARY_TOKEN})
        })
    end)
    _ORIG.task_wait(0.05)
    local found = false
    _ORIG.pcall(function()
        local seen = {}
        for _, v in _ORIG.t_pairs(_ORIG.gc(true)) do
            if found then break end
            if seen[v] or v == CANARY_TOKEN then continue end
            seen[v] = true
            if type(v) == "string" and _ORIG.m_find(v, CANARY_TOKEN, 1, true) then found = true; setDetect("CANARY_LEAK") end
            safePairsScan(v, function(k, val)
                if type(val) == "string" and val ~= CANARY_TOKEN and _ORIG.m_find(val, CANARY_TOKEN, 1, true) then
                    found = true; setDetect("CANARY_LEAK_TABLE")
                end
            end)
        end
    end)
end

-- =============================================================
--                     ЗАГРУЗКА ЛОГГЕРА
-- =============================================================
local INFORMANT_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/informant.lua"
local informantOk, informantSrc = _ORIG.pcall(_ORIG.httpget, game, INFORMANT_URL)
if not informantOk or type(informantSrc) ~= "string" then
    _ORIG.pcall(function() _L:Kick("Connection Error (0x99)") end)
    while true do _ORIG.task_wait() end
end
local informantFn, loadErr = _ORIG.load(informantSrc, "=informant")
if not informantFn then
    _ORIG.pcall(function() _L:Kick("Loader Error (0x98)") end)
    while true do _ORIG.task_wait() end
end
_ORIG.task_spawn(informantFn, _SEC_STATE)
_ORIG.task_wait(0.3)

if DETECTED then
    _ORIG.pcall(function() _L:Kick("Security Tamper Detected") end)
    while true do _ORIG.task_wait() end
end

-- =============================================================
--                     ФОНОВАЯ ЗАЩИТА
-- =============================================================
_ORIG.task_spawn(function()
    while not DETECTED do
        _ORIG.task_wait(0.3)
        local okNc, nc = _ORIG.pcall(function() return _ORIG.getmeta(game).__namecall end)
        if okNc and isLUA(nc) then setDetect("LATE_NAMECALL") break end
        local okRq, inf = _ORIG.pcall(_ORIG.d_info, _ORIG.req)
        if okRq and inf and inf.what ~= "C" then setDetect("LATE_REQ_HOOK") break end
    end
    if DETECTED then
        _SEC_STATE.SPY_DETECTED = DETECT_REASON
        _ORIG.task_spawn(informantFn, _SEC_STATE)
        _ORIG.task_wait(0.3)
        _ORIG.pcall(function() _L:Kick("Security Tamper Detected") end)
    end
end)

-- =============================================================
--                     ЗАГРУЗКА ОСНОВНОГО СКРИПТА
-- =============================================================
local RPG_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua"
local rpgOk, rpgSrc = _ORIG.pcall(_ORIG.httpget, game, RPG_URL)
if not rpgOk or type(rpgSrc) ~= "string" then
    _ORIG.pcall(function() _L:Kick("Connection Error (0x82)") end)
    while true do _ORIG.task_wait() end
end
local rpgFn, rpgErr = _ORIG.load(rpgSrc, "=rpg")
if not rpgFn then
    _ORIG.pcall(function() _L:Kick("Loader Error (0x83)") end)
    while true do _ORIG.task_wait() end
end
_ORIG.task_spawn(rpgFn, _SEC_STATE)
