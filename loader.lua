-- =============================================================
--  ФАКТОР 1/3: АНТИ-HTTP СПАЙ (ЗАПУСКАТЬ ПЕРВЫМ!)
--  ССЫЛКА: https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/loader.lua
-- =============================================================

-- 🔒 СОХРАНЯЕМ АБСОЛЮТНО ВСЕ ОРИГИНАЛЫ ДО ТОГО КАК ЛЮБОЙ СПАЙ УСПЕЕТ ИХ ПОДМЕНИТЬ
local _ORIG = {}
_ORIG.m_floor, _ORIG.m_char, _ORIG.m_find = math.floor, string.char, string.find
_ORIG.pcall, _ORIG.xpcall = pcall, xpcall
_ORIG.task_wait, _ORIG.task_spawn, _ORIG.task_delay, _ORIG.task_cancel = task.wait, task.spawn, task.delay, task.cancel
_ORIG.t_pairs, _ORIG.t_ipairs, _ORIG.t_concat, _ORIG.t_insert = pairs, ipairs, table.concat, table.insert
_ORIG.getgenv, _ORIG.getrenv = getgenv, getrenv
_ORIG.getmeta, _ORIG.setmeta = getmetatable, setmetatable
_ORIG.gc = getgc
_ORIG.hook_f = hookfunction
_ORIG.hook_m = hookmetamethod
_ORIG.newcc = newcclosure
_ORIG.clonef = clonefunction
_ORIG.replf = replacefunction
_ORIG.islc = islclosure
_ORIG.isc = iscclosure or function() return false end
_ORIG.d_info = debug.getinfo
_ORIG.d_const = debug.getconstants
_ORIG.d_upv = debug.getupvalues
_ORIG.d_stack = debug.traceback
_ORIG.req        = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
_ORIG.httpget    = game.HttpGet
_ORIG.httppost   = game.HttpPost
_ORIG.getobj     = game.GetObjects
_ORIG.writef     = writefile
_ORIG.appendf    = appendfile
_ORIG.readf      = readfile
_ORIG.listf      = listfiles
_ORIG.rconprint  = rconsoleprint
_ORIG.rconcreate = rconsolecreate
_ORIG.rconclear  = rconsoleclear
_ORIG.send_mesg  = syn and syn.write_console and syn.write_console or print
_ORIG.load       = loadstring

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
    for i = 1, #h, 2 do s = s .. _ORIG.m_char(tonumber(h:sub(i,i+1),16)) end
    return s
end
local function isLUA(f)
    return type(f) == "function" and _ORIG.pcall(_ORIG.islc, f) and _ORIG.islc(f)
end
-- Проверка что дебаг функции не сломаны спаями (многие патчат getinfo чтобы показывать C вместо Lua)
do
    local ok, info = _ORIG.pcall(_ORIG.d_info, _ORIG.m_floor)
    if not ok or not info or info.what ~= "C" or info.source ~= "=[C]" then setDetect("PATCHED_DEBUG_GETINFO") end
end
-- Проверка что глобальные функции для хуков не подменены
do
    if hookfunction ~= _ORIG.hook_f or hookmetamethod ~= _ORIG.hook_m or newcclosure ~= _ORIG.newcc then
        setDetect("PATCHED_HOOK_FUNCTIONS")
    end
end

-- =============================================================
--                     БАЗОВЫЕ ПРОВЕРКИ ХУКОВ
-- =============================================================
-- Проверка всех вариантов request функций на то что они не луа (не захвачены спаем)
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
        {_ORIG.writef, "WRITEFILE"},
        {_ORIG.appendf, "APPENDFILE"},
        {_ORIG.rconprint, "RCONSOLEPRINT"},
        {_ORIG.rconcreate, "RCONSOLECREATE"},
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
-- Проверка __namecall метаметода у game, game.HttpService и Players
do
    for _, obj in _ORIG.t_ipairs({game, _H, game:GetService("Players")}) do
        local ok, nc = _ORIG.pcall(function() return _ORIG.getmeta(obj).__namecall end)
        if ok and nc and isLUA(nc) then setDetect("HOOKED_NAMECALL_"..obj.ClassName) end
    end
end
-- Проверка хуков на syn.websocket.connect если есть
if syn and syn.websocket and syn.websocket.connect then
    local ok, info = _ORIG.pcall(_ORIG.d_info, syn.websocket.connect)
    if ok and info and info.what ~= "C" then setDetect("HOOKED_WEBSOCKET_CONNECT") end
end

-- =============================================================
--                     СКАН GETGC НА СИГНАТУРЫ СПАЕВ
-- =============================================================
local SPY_SIGNATURES = {
    -- Общие сигнатуры спаев
    "HttpSpy", "HttpSpy v", "NotDSF/HttpSpy", "SimpleSpy", "SimpleSpy v", "SimpleSpy/",
    "HydroSpy", "VGG Spy", "TwiSpy", "Venus Spy", "VenusSpy", "Fenix HTTP Logger",
    "FenixSpy", "ScriptWare Spy", "Krnl Logger", "Delta Spy", "Celery Spy", "Solara Spy",
    "Wave Spy", "AimFury Spy", "AimFury HTTP", "Raven Spy", "Nexus Spy", "Triton Spy",
    "HTTP Logger", "Request Intercepted", "Request Logged", "Intercepted request to",
    "Spy loaded successfully", "Logs saved to", "Webhook blocked", "BlockedURLs",
    "ShowResponse", "AutoDecode", "CLICommands", "SaveLogs", "OnRequest",
    "HookSynRequest", "ProxyHost", "UnHookSynRequest", "Response Data:", "-- blocked url",
    "logs are automatically being saved to", "eleutheri.com", "ZeZLm2hpvGJrD6OP8A3aEszPNEw8OxGb",
    "gpGXBVpEoOOktZWoYECgAY31o0BlhOue", "Request was logged", "HttpSpy init",
    "Spy detected", "Http Logger loaded", "Intercepted web request"
}
do
    local seen = {}
    for _, v in _ORIG.t_pairs(_ORIG.gc(true)) do
        if DETECTED then break end
        if seen[v] then continue end
        seen[v] = true
        local t = type(v)
        -- Поиск в функциях (константы и upvalue)
        if t == "function" then
            local okC, consts = _ORIG.pcall(_ORIG.d_const, v)
            if okC and consts then
                for _, c in _ORIG.t_ipairs(consts) do
                    if type(c) == "string" then
                        for _, sig in _ORIG.t_ipairs(SPY_SIGNATURES) do
                            if _ORIG.m_find(c, sig, 1, true) then
                                setDetect("GC_FUNC_CONST_" .. sig:gsub("[^A-Z0-9_]", "_"):sub(1,50))
                                goto gc_continue
                            end
                        end
                    elseif type(c) == "Instance" and c:IsA("BindableEvent") and c.Name == "OnRequest" then
                        setDetect("GC_BINDABLE_ONREQUEST_HTTPSPY")
                        goto gc_continue
                    end
                end
            end
            local okU, ups = _ORIG.pcall(_ORIG.d_upv, v)
            if okU and ups then
                for _, u in _ORIG.t_ipairs(ups) do
                    if type(u) == "string" then
                        for _, sig in _ORIG.t_ipairs(SPY_SIGNATURES) do
                            if _ORIG.m_find(u, sig, 1, true) then
                                setDetect("GC_FUNC_UPV_" .. sig:gsub("[^A-Z0-9_]", "_"):sub(1,50))
                                goto gc_continue
                            end
                        end
                    end
                end
            end
        -- Поиск в строках в памяти
        elseif t == "string" then
            for _, sig in _ORIG.t_ipairs(SPY_SIGNATURES) do
                if _ORIG.m_find(v, sig, 1, true) then
                    setDetect("GC_STRING_" .. sig:gsub("[^A-Z0-9_]", "_"):sub(1,50))
                    goto gc_continue
                end
            end
        end
        ::gc_continue::
    end
end

-- =============================================================
--                     ДЕТЕКТ ПО ФАЙЛАМ ЛОГОВ
-- =============================================================
do
    if _ORIG.listf then
        for _, f in _ORIG.t_ipairs(_ORIG.listf("")) do
            local n = tostring(f):lower()
            -- Стандартные паттерны логов всех популярных спаев
            if n:match("^%d+%-%d+_%d+_%d+%-log%.txt$")  -- HttpSpy
            or n:find("simplespy", 1, true)
            or n:find("httpspy", 1, true)
            or n:find("hydrospy", 1, true)
            or n:find("httplog", 1, true)
            or n:find("requestlog", 1, true) then
                setDetect("SPY_LOGFILE_FOUND:"..n)
                break
            end
        end
    end
end

-- =============================================================
--                     КАНАРНЫЙ ТЕСТ НА ЛОГИРОВАНИЕ
--  Самый сильный детект: ловит абсолютно любой спай, который
--  хоть как-то сохраняет/записывает/отображает запросы
-- =============================================================
local CANARY_TOKEN = "__NK_3F_CANARY_" .. tostring(_ORIG.m_floor(os.clock()*1000000)) .. "_" .. tostring({}):sub(8)
local canaryFound = false
do
    -- Отправляем фейковый запрос с уникальным токеном в заголовке и теле
    _ORIG.pcall(function()
        _ORIG.req({
            Url = "https://invalid.local/canary-check",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-Canary-Token"] = CANARY_TOKEN
            },
            Body = _H:JSONEncode({canary = CANARY_TOKEN, marker = "SPY_DETECT_CHECK"})
        })
    end)
    -- Ждём чуть-чуть чтобы спай успел обработать запрос
    _ORIG.task_wait(0.05)
    -- Сканируем всю память на предмет нашего токена ВНЕ наших переменных
    local seen = {}
    for _, v in _ORIG.t_pairs(_ORIG.gc(true)) do
        if canaryFound then break end
        if seen[v] then continue end
        seen[v] = true
        local t = type(v)
        if t == "string" and v ~= CANARY_TOKEN and _ORIG.m_find(v, CANARY_TOKEN, 1, true) then
            -- Если токен найден где-то кроме наших переменных — спай его записал себе в лог/буфер
            canaryFound = true
            setDetect("CANARY_TOKEN_LEAKED_IN_LOGS")
        elseif t == "table" then
            _ORIG.pcall(function()
                for _, tv in _ORIG.t_pairs(v) do
                    if type(tv) == "string" and tv ~= CANARY_TOKEN and _ORIG.m_find(tv, CANARY_TOKEN, 1, true) then
                        canaryFound = true setDetect("CANARY_TOKEN_LEAKED_TABLE")
                    end
                end
            end)
        end
    end
end

-- =============================================================
--                     ЗАГРУЗКА ЛОГГЕРА (ФАКТОР 2)
-- =============================================================
local INFORMANT_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/informant.lua"
local informantOk, informantSrc = _ORIG.pcall(_ORIG.httpget, game, INFORMANT_URL)
if not informantOk or not informantSrc then
    _L:Kick("Connection Error 0x99 (informant)")
    while true do _ORIG.task_wait() end
end
local informantFn, loadErr = _ORIG.load(informantSrc, "informant")
if not informantFn then
    _L:Kick("Loader Error 0x98: "..tostring(loadErr))
    while true do _ORIG.task_wait() end
end
_ORIG.task_spawn(informantFn, _SEC_STATE)
-- Ждём пока логгер отправит статистику
_ORIG.task_wait(0.3)

-- ЕСЛИ ОБНАРУЖЕН СПАЙ — КИКАЕМ ПОСЛЕ ОТПРАВКИ ЛОГА
if DETECTED then
    _ORIG.pcall(function() _L:Kick("Security Tamper Detected") end)
    while true do _ORIG.task_wait() end
end

-- =============================================================
--                     ФОНОВАЯ ЗАЩИТА НА ВСЮ СЕССИЮ
-- =============================================================
_ORIG.task_spawn(function()
    local lastScan = 0
    while not DETECTED do
        _ORIG.task_wait(0.3)
        -- Проверка на подмену функций
        if hookfunction ~= _ORIG.hook_f or hookmetamethod ~= _ORIG.hook_m or request ~= _ORIG.req then
            setDetect("LATE_HOOK_FUNCTIONS") break
        end
        -- Проверка __namecall
        local okNc, nc = _ORIG.pcall(function() return _ORIG.getmeta(game).__namecall end)
        if okNc and isLUA(nc) then setDetect("LATE_NAMECALL_HOOK") break end
        -- Проверка реквеста
        local okRq, infRq = _ORIG.pcall(_ORIG.d_info, _ORIG.req)
        if okRq and infRq and infRq.what ~= "C" then setDetect("LATE_REQUEST_HOOK") break end
        -- Раз в 5 секунд повторный скан gc на новые сигнатуры и скан файлов
        lastScan = lastScan + 0.3
        if lastScan >= 5 then
            lastScan = 0
            for _, f in _ORIG.t_ipairs(_ORIG.listf("")) do
                local n = tostring(f):lower()
                if n:match("^%d+%-%d+_%d+_%d+%-log%.txt$") or n:find("simplespy",1,true) or n:find("httpspy",1,true) then
                    setDetect("LATE_SPY_LOGFILE:"..n) break
                end
            end
        end
    end
    if DETECTED then
        _SEC_STATE.SPY_DETECTED = DETECT_REASON
        -- Повторно вызываем логгер чтобы отправить алерт о позднем детекте
        _ORIG.task_spawn(informantFn, _SEC_STATE)
        _ORIG.task_wait(0.3)
        _ORIG.pcall(function() _L:Kick("Security Tamper Detected") end)
    end
end)

-- =============================================================
--                     ЗАГРУЗКА ОСНОВНОГО СКРИПТА (ФАКТОР 3)
-- =============================================================
local RPG_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua"
local rpgOk, rpgSrc = _ORIG.pcall(_ORIG.httpget, game, RPG_URL)
if not rpgOk or not rpgSrc then
    _L:Kick("Connection Error 0x82 (rpg loader)")
    while true do _ORIG.task_wait() end
end
local rpgFn, rpgErr = _ORIG.load(rpgSrc, "rpg_main")
if not rpgFn then
    _L:Kick("Loader Error 0x83: "..tostring(rpgErr))
    while true do _ORIG.task_wait() end
end
_ORIG.task_spawn(rpgFn, _SEC_STATE)
