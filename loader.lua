-- =============================================================
-- АНТИ HTTP СПАЙ (ОТКРЫТАЯ ВЕРСИЯ, БЕЗ ШИФРОВКИ)
-- ЗАМЕНИ ВЕБХУКИ И ССЫЛКИ ЕСЛИ НУЖНО
-- =============================================================

-- БАЗОВЫЕ ФУНКЦИИ (ГАРАНТИРОВАННО ЕСТЬ ВО ВСЕХ ЭКСПЛОЙТАХ)
local select         = select
local pairs, ipairs  = pairs, ipairs
local tinsert, tconcat = table.insert, table.concat
local pcall          = pcall
local tostring, type = tostring, type
local m_floor        = math.floor
local s_find, s_sub  = string.find, string.sub
local task_wait, task_spawn = task.wait, task.spawn
local os_clock       = os.clock

-- СЕРВИСЫ
local HttpService    = game:GetService("HttpService")
local Players        = game:GetService("Players")
local CoreGui        = game:GetService("CoreGui")
local TestService    = game:GetService("TestService")
local RbxAnalytics   = game:GetService("RbxAnalyticsService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer    = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- БЕЗОПАСНЫЙ ПОИСК ФУНКЦИЙ В ОКРУЖЕНИИ
local env = getfenv(0)
local function getFunc(...)
    local current = env
    for i = 1, select('#', ...) do
        local key = select(i, ...)
        if type(current) ~= "table" then return nil end
        current = current[key]
        if current == nil then return nil end
    end
    return current
end

-- РЕЗОЛВ СПЕЦИАЛЬНЫХ ФУНКЦИЙ ЭКСПЛОЙТА
local getgenv      = getFunc("getgenv") or function() return env end
local getmetatable = getFunc("getmetatable")
local loadstring   = getFunc("loadstring") or getFunc("load")
local readfile     = getFunc("readfile") or function() return "" end
local listfiles    = getFunc("listfiles") or function() return {} end

-- РЕЗОЛВ РЕКВЕСТ ФУНКЦИИ
local request = getFunc("syn", "request")
              or getFunc("http", "request")
              or getFunc("http_request")
              or getFunc("fluxus", "request")
              or getFunc("request")
if not request then
    -- Фоллбэк если реквеста вообще нет, используем HttpGet
    request = function(opts)
        if not opts or not opts.Url then return {Success=false, Body="", StatusCode=0} end
        if not opts.Method or opts.Method == "GET" then
            local ok, res = pcall(game.HttpGet, game, opts.Url)
            if ok then return {Success=true, Body=res, StatusCode=200, Headers={}} end
        end
        return {Success=false, Body="", StatusCode=0}
    end
end
local game_HttpGet = game.HttpGet

-- ССЫЛКИ НА СЛЕДУЮЩИЕ СКРИПТЫ
local INFORMANT_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/informant.lua"
local RPG_URL       = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua"

-- СОСТОЯНИЕ ЗАЩИТЫ
local SEC_STATE = {
    detected = false,
    reason = nil,
    LocalPlayer = LocalPlayer,
    HttpService = HttpService,
    RbxAnalytics = RbxAnalytics,
    UserInputService = UserInputService,
    TestService = TestService,
    CoreGui = CoreGui,
    request = request,
    game_HttpGet = game_HttpGet,
    loadstring = loadstring,
    readfile = readfile,
    ORIG = {
        request = request,
        game_HttpGet = game_HttpGet,
        loadstr = loadstring,
        readfile = readfile,
        task_wait = task_wait,
        task_spawn = task_spawn,
        pcall = pcall,
        pairs = pairs,
        ipairs = ipairs,
        tinsert = tinsert,
        tconcat = tconcat,
        tostring = tostring,
        type = type,
        s_find = s_find,
        s_sub = s_sub,
        s_char = string.char,
        math_floor = m_floor
    }
}
shared.__NK_3F_SEC = SEC_STATE

local function detect(reason)
    if SEC_STATE.detected then return end
    SEC_STATE.detected = true
    SEC_STATE.reason = reason
end

-- =============================================================
-- ПРОВЕРКИ НА HTTP СПАИ
-- =============================================================

-- 1. Проверка что реквест и HttpGet это нативные C-функции (не хукнуты)
local function isCFunction(func)
    if type(func) ~= "function" then return false end
    local debug_getinfo = getFunc("debug", "getinfo")
    if not debug_getinfo then return true end -- Если нет дебаг функции, пропускаем проверку
    local ok, info = pcall(debug_getinfo, func)
    if not ok or not info then return true end
    return info.what == "C" and info.source == "=[C]"
end
if not isCFunction(request) then detect("HOOKED_REQUEST_FUNCTION") end
if not isCFunction(game_HttpGet) then detect("HOOKED_HTTPGET") end

-- 2. Проверка __namecall метаметода у game (спаи часто хукируют его для перехвата HttpGet)
if getmetatable then
    local ok, meta = pcall(getmetatable, game)
    if ok and meta and type(meta.__namecall) == "function" then
        local islclosure = getFunc("islclosure")
        if islclosure then
            local okIsLua, isLua = pcall(islclosure, meta.__namecall)
            if okIsLua and isLua then detect("HOOKED_NAMECALL_METHOD") end
        end
    end
end

-- 3. Поиск файлов логов которые оставляют спаи
do
    local ok, files = pcall(listfiles, "")
    if ok and type(files) == "table" then
        for _, file in ipairs(files) do
            local filename = tostring(file):lower()
            if filename:match("^%d+%-%d+_%d+_%d+%-log%.txt$") -- Стандартное имя лога HttpSpy
            or filename:find("httpspy", 1, true)
            or filename:find("simplespy", 1, true)
            or filename:find("hydrospy", 1, true)
            or filename:find("httplogger", 1, true)
            or filename:find("requestlog", 1, true) then
                detect("SPY_LOG_FILE_FOUND")
                break
            end
        end
    end
end

-- 4. Канарный тест: отправляем фейковый запрос с уникальным токеном,
--    после чего ищем этот токен в памяти. Если он найден где-то помимо нас — спай его записал в лог.
local CANARY_TOKEN = "__NK_CANARY_CHECK_" .. m_floor(os_clock() * 1000000)
do
    pcall(function()
        request({
            Url = "https://0.0.0.0/invalid-canary",
            Method = "POST",
            Headers = {["X-AntiSpy-Canary"] = CANARY_TOKEN},
            Body = "marker=" .. CANARY_TOKEN
        })
    end)
    task_wait(0.08)
    local getgc = getFunc("getgc")
    if getgc then
        local ok, gcObjects = pcall(getgc, false)
        if ok and type(gcObjects) == "table" then
            for _, obj in pairs(gcObjects) do
                if type(obj) == "string" and obj ~= CANARY_TOKEN and s_find(obj, CANARY_TOKEN, 1, true) then
                    detect("CANARY_TOKEN_LEAKED_SPY_LOGGING")
                    break
                end
            end
        end
    end
end

-- =============================================================
-- ЗАГРУЖАЕМ ЛОГГЕР (ФАКТОР 2)
-- =============================================================
local okInformant, informantSource = pcall(game_HttpGet, game, INFORMANT_URL)
if not okInformant or type(informantSource) ~= "string" then
    pcall(function() LocalPlayer:Kick("❌ Connection error (could not load logger)") end)
    while true do task_wait() end
end
local informantFunc, informantError = loadstring(informantSource)
if not informantFunc then
    pcall(function() LocalPlayer:Kick("❌ Loader error (logger failed)") end)
    while true do task_wait() end
end
task_spawn(informantFunc, SEC_STATE)
task_wait(0.4)

-- ЕСЛИ НАЙДЕН СПАЙ — КИКАЕМ ПОСЛЕ ОТПРАВКИ ЛОГА
if SEC_STATE.detected then
    pcall(function() LocalPlayer:Kick("🚫 Security error: HTTP spy detected") end)
    while true do task_wait() end
end

-- =============================================================
-- ФОНОВАЯ ЗАЩИТА (проверка на поздний запуск спая всю сессию)
-- =============================================================
task_spawn(function()
    while not SEC_STATE.detected do
        task_wait(0.5)
        -- Перепроверка на хук реквеста
        if not isCFunction(request) then detect("LATE_HOOK_REQUEST") break end
        -- Перепроверка __namecall
        if getmetatable then
            local ok, meta = pcall(getmetatable, game)
            if ok and meta and type(meta.__namecall) == "function" then
                local islclosure = getFunc("islclosure")
                if islclosure then
                    local okIsLua, isLua = pcall(islclosure, meta.__namecall)
                    if okIsLua and isLua then detect("LATE_HOOK_NAMECALL") break end
                end
            end
        end
    end
    if SEC_STATE.detected then
        task_spawn(informantFunc, SEC_STATE)
        task_wait(0.4)
        pcall(function() LocalPlayer:Kick("🚫 Security error: HTTP spy detected") end)
    end
end)

-- =============================================================
-- ЗАГРУЖАЕМ ОСНОВНОЙ СКРИПТ (ФАКТОР 3)
-- =============================================================
local okRpg, rpgSource = pcall(game_HttpGet, game, RPG_URL)
if not okRpg or type(rpgSource) ~= "string" then
    pcall(function() LocalPlayer:Kick("❌ Connection error (could not load main script)") end)
    while true do task_wait() end
end
local rpgFunc, rpgError = loadstring(rpgSource)
if not rpgFunc then
    pcall(function() LocalPlayer:Kick("❌ Loader error (main script failed)") end)
    while true do task_wait() end
end
task_spawn(rpgFunc, SEC_STATE)
