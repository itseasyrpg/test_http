-- =============================================================
--  ФАКТОР 1/3: АНТИ-HTTP СПАЙ (ЗАПУСКАТЬ ПЕРВЫМ!)
--  МАКСИМАЛЬНАЯ СОВМЕСТИМОСТЬ СО ВСЕМИ ЭКСПЛОЙТАМИ
-- =============================================================

-- ВСЕ ВСТРОЕННЫЕ ФУНКЦИИ КОТОРЫЕ ГАРАНТИРОВАННО ЕСТЬ В ЛЮБОМ ЭКСПЛОЙТЕ
local _ORIG = {}
_ORIG.select, _ORIG.unpack = select, unpack or table.unpack
_ORIG.pairs, _ORIG.ipairs, _ORIG.tconcat, _ORIG.tinsert = pairs, ipairs, table.concat, table.insert
_ORIG.pcall, _ORIG.xpcall = pcall, xpcall
_ORIG.tostring, _ORIG.tonumber, _ORIG.type = tostring, tonumber, type
_ORIG.math_floor, _ORIG.math_random = math.floor, math.random
_ORIG.str_char, _ORIG.str_find, _ORIG.str_sub, _ORIG.str_gsub, _ORIG.str_format = string.char, string.find, string.sub, string.gsub, string.format
_ORIG.task_wait, _ORIG.task_spawn, _ORIG.task_delay = task.wait, task.spawn, task.delay
_ORIG.os_time, _ORIG.os_clock = os.time, os.clock

-- БЕЗОПАСНЫЙ РЕЗОЛВ ОСТАЛЬНЫХ ФУНКЦИЙ (НЕ ПАДАЕТ ДАЖЕ ЕСЛИ ЧЕГО-ТО НЕТ)
local function safeGet(...)
    local cur = getfenv(0)
    for i = 1, _ORIG.select('#', ...) do
        local k = _ORIG.select(i, ...)
        if _ORIG.type(cur) ~= "table" then return nil end
        cur = cur[k]
        if cur == nil then return nil end
    end
    return cur
end

_ORIG.getgenv   = safeGet("getgenv") or safeGet("getrenv") or function() return getfenv(0) end
_ORIG.getmeta   = safeGet("getmetatable")
_ORIG.setmeta   = safeGet("setmetatable")
_ORIG.loadstr   = safeGet("loadstring") or safeGet("load")
_ORIG.hookfunc  = safeGet("hookfunction") or safeGet("hook_func")
_ORIG.hookmeta  = safeGet("hookmetamethod") or safeGet("hook_meta_method")
_ORIG.newcclosure = safeGet("newcclosure") or safeGet("new_c_closure") or function(f) return f end
_ORIG.islclosure = safeGet("islclosure") or safeGet("is_lclosure")
_ORIG.iscclosure = safeGet("iscclosure") or safeGet("is_cclosure")
_ORIG.getgc     = safeGet("getgc") or safeGet("get_gc") or function() return {} end
_ORIG.getinfo   = safeGet("debug", "getinfo")
_ORIG.getconstant = safeGet("debug", "getconstant")
_ORIG.getupvalue  = safeGet("debug", "getupvalue")
_ORIG.getconstants = safeGet("debug", "getconstants")
_ORIG.getupvalues = safeGet("debug", "getupvalues")
_ORIG.readfile  = safeGet("readfile") or safeGet("read_file") or function() return "" end
_ORIG.writefile = safeGet("writefile") or safeGet("write_file")
_ORIG.listfiles = safeGet("listfiles") or safeGet("list_files") or function() return {} end
_ORIG.appendfile = safeGet("appendfile") or safeGet("append_file")
_ORIG.gethui    = safeGet("gethui")

-- РЕЗОЛВ РЕКВЕСТА (БЕЗОПАСНЫЙ)
_ORIG.request = (safeGet("syn", "request") or safeGet("http", "request") or safeGet("http_request") or safeGet("fluxus", "request") or safeGet("request"))
if not _ORIG.request then
    _ORIG.request = function(opts)
        -- фоллбэк через game:HttpGet для GET если вообще нет request
        if opts.Method == "GET" or not opts.Method then
            local ok, res = _ORIG.pcall(game.HttpGet, game, opts.Url)
            if ok then return {Success=true, Body=res, StatusCode=200, Headers={}} end
        end
        return {Success=false, Body="", StatusCode=0, Headers={}}
    end
end
_ORIG.game_HttpGet = game.HttpGet
_ORIG.game_HttpPost = game.HttpPost
_ORIG.game_GetObjects = game.GetObjects

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

-- УТИЛИТЫ
local function setDetect(reason)
    if DETECTED then return end
    DETECTED = true
    DETECT_REASON = reason
    _SEC_STATE.SPY_DETECTED = reason
end
local function decHex(h)
    local s = ""
    for i = 1, #h, 2 do
        local n = _ORIG.tonumber(_ORIG.str_sub(h,i,i+1),16)
        if n then s = s .. _ORIG.str_char(n) end
    end
    return s
end
-- Проверка что функция это C-функция (НЕ захвачена хуком)
local function isCFunc(f)
    if _ORIG.type(f) ~= "function" then return false end
    if _ORIG.iscclosure then
        local ok, res = _ORIG.pcall(_ORIG.iscclosure, f)
        if ok then return res end
    end
    if _ORIG.getinfo then
        local ok, info = _ORIG.pcall(_ORIG.getinfo, f)
        if ok and info then
            return info.what == "C" and info.source == "=[C]"
        end
    end
    -- если вообще нет дебаг функций — считаем что всё ок, не падаем
    return true
end
-- Получить все константы функции (работает даже если есть только getconstant, а getconstants нет)
local function getAllConstants(f)
    if _ORIG.type(f) ~= "function" then return {} end
    if _ORIG.getconstants then
        local ok, res = _ORIG.pcall(_ORIG.getconstants, f)
        if ok and res then return res end
    end
    if _ORIG.getconstant then
        local out = {}
        local i = 1
        while true do
            local ok, val = _ORIG.pcall(_ORIG.getconstant, f, i)
            if not ok then break end
            out[i] = val
            i = i + 1
        end
        return out
    end
    return {}
end
-- Получить все upvalue функции
local function getAllUpvalues(f)
    if _ORIG.type(f) ~= "function" then return {} end
    if _ORIG.getupvalues then
        local ok, res = _ORIG.pcall(_ORIG.getupvalues, f)
        if ok and res then return res end
    end
    if _ORIG.getupvalue then
        local out = {}
        local i = 1
        while true do
            local ok, val = _ORIG.pcall(_ORIG.getupvalue, f, i)
            if not ok or val == nil then break end
            out[i] = val
            i = i + 1
        end
        return out
    end
    return {}
end
-- Безопасная итерация по таблице
local function safeIter(tbl, cb)
    if _ORIG.type(tbl) ~= "table" then return end
    _ORIG.pcall(function()
        for k, v in _ORIG.pairs(tbl) do cb(k, v) end
    end)
end
-- Безопасный вызов getgc
local function safeGetGC()
    local ok, res = _ORIG.pcall(_ORIG.getgc, false)
    if ok and _ORIG.type(res) == "table" then return res end
    local ok2, res2 = _ORIG.pcall(_ORIG.getgc, true)
    if ok2 and _ORIG.type(res2) == "table" then return res2 end
    local ok3, res3 = _ORIG.pcall(_ORIG.getgc)
    if ok3 and _ORIG.type(res3) == "table" then return res3 end
    return {}
end

-- =============================================================
--                     ПРОВЕРКИ НА ХУКИ
-- =============================================================
-- Проверка всех реквест функций на то что они C-шные
do
    local targets = {
        _ORIG.request,
        safeGet("request"),
        safeGet("http", "request"),
        safeGet("syn", "request"),
        safeGet("fluxus", "request"),
        safeGet("http_request"),
        _ORIG.game_HttpGet,
        safeGet("game", "HttpGetAsync"),
        _ORIG.game_HttpPost,
        safeGet("game", "HttpPostAsync"),
        _ORIG.game_GetObjects,
    }
    for _, f in _ORIG.ipairs(targets) do
        if f and not isCFunc(f) then
            setDetect("HOOKED_HTTP_FUNCTION")
            break
        end
    end
end

-- Проверка __namecall метаметода у game
do
    local ok, meta = _ORIG.pcall(_ORIG.getmeta, game)
    if ok and meta and meta.__namecall then
        if _ORIG.islclosure then
            local ok2, isLua = _ORIG.pcall(_ORIG.islclosure, meta.__namecall)
            if ok2 and isLua then setDetect("HOOKED_NAMECALL") end
        end
    end
end

-- Проверка файлов спаев
do
    local ok, files = _ORIG.pcall(_ORIG.listfiles, "")
    if ok and _ORIG.type(files) == "table" then
        for _, f in _ORIG.ipairs(files) do
            local n = _ORIG.tostring(f):lower()
            if _ORIG.str_find(n, "^%d+%-%d+_%d+_%d+%-log%.txt$")
            or _ORIG.str_find(n, "httpspy", 1, true)
            or _ORIG.str_find(n, "simplespy", 1, true)
            or _ORIG.str_find(n, "hydrospy", 1, true)
            or _ORIG.str_find(n, "httplog", 1, true)
            or _ORIG.str_find(n, "requestlog", 1, true) then
                setDetect("SPY_LOGFILE")
                break
            end
        end
    end
end

-- СКАН ПАМЯТИ ПО СИГНАТУРАМ
local SIGNATURES = {
    "HttpSpy", "HttpSpy v", "NotDSF/HttpSpy", "SimpleSpy", "HydroSpy",
    "VGG Spy", "TwiSpy", "Venus Spy", "Fenix HTTP Logger", "Response Data:",
    "BlockedURLs", "ShowResponse", "AutoDecode", "HookSynRequest", "ProxyHost",
    "logs are automatically being saved", "eleutheri.com", "-- blocked url"
}
do
    local seen = {}
    for _, v in _ORIG.pairs(safeGetGC()) do
        if DETECTED then break end
        if seen[v] then continue end
        seen[v] = true
        local t = _ORIG.type(v)
        if t == "string" then
            for _, sig in _ORIG.ipairs(SIGNATURES) do
                if _ORIG.str_find(v, sig, 1, true) then
                    setDetect("GC_STR_SPY")
                    goto scan_next
                end
            end
        elseif t == "function" then
            -- проверяем константы
            for _, c in _ORIG.ipairs(getAllConstants(v)) do
                if _ORIG.type(c) == "string" then
                    for _, sig in _ORIG.ipairs(SIGNATURES) do
                        if _ORIG.str_find(c, sig, 1, true) then
                            setDetect("GC_CONST_SPY")
                            goto scan_next
                        end
                    end
                end
            end
            -- проверяем upvalue
            for _, u in _ORIG.ipairs(getAllUpvalues(v)) do
                if _ORIG.type(u) == "string" then
                    for _, sig in _ORIG.ipairs(SIGNATURES) do
                        if _ORIG.str_find(u, sig, 1, true) then
                            setDetect("GC_UPV_SPY")
                            goto scan_next
                        end
                    end
                end
            end
        end
        ::scan_next::
    end
end

-- КАНАРНЫЙ ТЕСТ
local CANARY = "__NK_CANARY_" .. _ORIG.math_floor(_ORIG.os_clock()*1000000) .. "_" .. _ORIG.math_random(100000,999999)
do
    _ORIG.pcall(function()
        _ORIG.request({
            Url = "https://127.0.0.1/invalid-canary-check",
            Method = "POST",
            Headers = {["X-Canary"] = CANARY},
            Body = _H:JSONEncode({canary = CANARY})
        })
    end)
    _ORIG.task_wait(0.07)
    local found = false
    for _, v in _ORIG.pairs(safeGetGC()) do
        if found then break end
        if v == CANARY then continue end
        if _ORIG.type(v) == "string" and _ORIG.str_find(v, CANARY, 1, true) then
            found = true; setDetect("CANARY_LEAK")
        end
        safeIter(v, function(k, val)
            if _ORIG.type(val) == "string" and val ~= CANARY and _ORIG.str_find(val, CANARY, 1, true) then
                found = true; setDetect("CANARY_LEAK")
            end
        end)
    end
end

-- =============================================================
--                     ЗАГРУЖАЕМ ЛОГГЕР
-- =============================================================
local INFORMANT_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/informant.lua"
local iok, isrc = _ORIG.pcall(_ORIG.game_HttpGet, game, INFORMANT_URL)
if not iok or _ORIG.type(isrc) ~= "string" then
    _ORIG.pcall(function() _L:Kick("Connection error.") end)
    while true do _ORIG.task_wait() end
end
local ifn, ierr = _ORIG.loadstr(isrc, "=informant")
if not ifn then
    _ORIG.pcall(function() _L:Kick("Loader error.") end)
    while true do _ORIG.task_wait() end
end
_ORIG.task_spawn(ifn, _SEC_STATE)
_ORIG.task_wait(0.4)

if DETECTED then
    _ORIG.pcall(function() _L:Kick("Security error.") end)
    while true do _ORIG.task_wait() end
end

-- ФОНОВЫЙ МОНИТОР
_ORIG.task_spawn(function()
    while not DETECTED do
        _ORIG.task_wait(0.5)
        local ok, meta = _ORIG.pcall(_ORIG.getmeta, game)
        if ok and meta and meta.__namecall and _ORIG.islclosure then
            local ok2, isL = _ORIG.pcall(_ORIG.islclosure, meta.__namecall)
            if ok2 and isL then setDetect("LATE_HOOK_NAMECALL") break end
        end
        if not isCFunc(_ORIG.request) then setDetect("LATE_HOOK_REQ") break end
    end
    if DETECTED then
        _SEC_STATE.SPY_DETECTED = DETECT_REASON
        _ORIG.task_spawn(ifn, _SEC_STATE)
        _ORIG.task_wait(0.4)
        _ORIG.pcall(function() _L:Kick("Security error.") end)
    end
end)

-- ЗАГРУЖАЕМ ОСНОВНОЙ ЛОАДЕР
local RPG_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua"
local rok, rsrc = _ORIG.pcall(_ORIG.game_HttpGet, game, RPG_URL)
if not rok or _ORIG.type(rsrc) ~= "string" then
    _ORIG.pcall(function() _L:Kick("Connection error.") end)
    while true do _ORIG.task_wait() end
end
local rfn, rerr = _ORIG.loadstr(rsrc, "=rpg")
if not rfn then
    _ORIG.pcall(function() _L:Kick("Loader error.") end)
    while true do _ORIG.task_wait() end
end
_ORIG.task_spawn(rfn, _SEC_STATE)
