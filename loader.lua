-- =============================================================
-- АНТИ HTTP СПАЙ / ФАКТОР 1 (ОТКРЫТЫЙ ИСХОДНИК, БЕЗ ЛОЖНЫХ СРАБАТЫВАНИЙ)
-- =============================================================

-- СТАНДАРТНЫЕ ФУНКЦИИ (ГАРАНТИРОВАННО ЕСТЬ ВЕЗДЕ)
local pairs, ipairs    = pairs, ipairs
local tinsert, tconcat = table.insert, table.concat
local pcall, xpcall    = pcall, xpcall
local tostring, type   = tostring, type
local m_floor, m_random = math.floor, math.random
local s_find, s_sub, s_lower = string.find, string.sub, string.lower
local task_wait, task_spawn = task.wait, task.spawn
local os_clock = os.clock

-- СЕРВИСЫ
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local TestService      = game:GetService("TestService")
local RbxAnalytics     = game:GetService("RbxAnalyticsService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- БЕЗОПАСНЫЙ ПОИСК ФУНКЦИЙ
local env = getfenv(0)
local function getFunc(...)
    local cur = env
    for i = 1, select('#', ...) do
        local key = select(i, ...)
        if type(cur) ~= "table" then return nil end
        cur = cur[key]
        if not cur then return nil end
    end
    return cur
end

-- РЕЗОЛВ ФУНКЦИЙ ЭКСПЛОЙТА
local getgenv      = getFunc("getgenv") or function() return env end
local getmetatable = getFunc("getmetatable")
local setmetatable = getFunc("setmetatable")
local loadstring   = getFunc("loadstring") or getFunc("load")
local readfile     = getFunc("readfile") or function() return "" end
local listfiles    = getFunc("listfiles") or function() return {} end
local gethui       = getFunc("gethui")

-- РЕЗОЛВ РЕКВЕСТА
local request = getFunc("syn", "request")
           or getFunc("http", "request")
           or getFunc("http_request")
           or getFunc("fluxus", "request")
           or getFunc("request")
if not request then
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
local game_HttpPost = game.HttpPost

-- ССЫЛКИ
local INFORMANT_URL = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/informant.lua"
local RPG_URL       = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua"

-- СОСТОЯНИЕ
local SEC_STATE = {
    detected = false,
    reason = "None",
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
        s_lower = s_lower,
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

-- СОХРАНЯЕМ ОРИГИНАЛЬНУЮ ИНФУ О МЕТАТАБЛЕ GAME ЧТОБЫ ПОЙМАТЬ ПОЗДНИЙ ХУК
local originalGameMeta = nil
if getmetatable then
    local ok, meta = pcall(getmetatable, game)
    if ok then originalGameMeta = meta end
end

-- =============================================================
-- ПРОВЕРКИ (ТОЛЬКО 100% ДОСТОВЕРНЫЕ, НЕТ ЛОЖНЫХ СРАБАТЫВАНИЙ)
-- =============================================================

-- 1. Проверка файлов логов СПАЕВ (ТОЧНОЕ СОВПАДЕНИЕ ИМЕНИ ФАЙЛА, НЕ ЧАСТИЧНОЕ!)
do
    local ok, files = pcall(listfiles, "")
    if ok and type(files) == "table" then
        for _, file in ipairs(files) do
            local fn = s_lower(tostring(file))
            -- Только точные паттерны логов известных спаев:
            if fn:match("^%d+%-%d%d?_%d%d?_%d%d?%-log%.txt$") -- HttpSpy: PlaceId-DD_MM_YY-log.txt
            or fn == "simplespy_logs.txt"
            or fn == "hydrospy_logs.txt"
            or fn == "https.py_logs.txt" then
                detect("SPY_LOGFILE:"..tostring(file))
                break
            end
        end
    end
end

-- 2. Поиск GUI спаев в CoreGui/gethui (спаи не прячут свои окна в защищённые области)
do
    local function scanGui(parent)
        if not parent then return end
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                local nm = s_lower(child.Name)
                if nm == "httpspy" or nm == "simplespy" or nm == "hydrospy" or nm == "vgspy" or nm == "twispy" then
                    detect("SPY_GUI:"..child.Name)
                    return true
                end
                -- Сканируем на 1 уровень вглубь (не глубже, чтобы не ловить лишнее)
                for _, subchild in ipairs(child:GetChildren()) do
                    local snm = s_lower(subchild.Name)
                    if snm:find("spy", 1, true) and subchild:FindFirstChildWhichIsA("ScrollingFrame") then
                        detect("SPY_GUI_SUSPECT:"..child.Name.."/"..subchild.Name)
                        return true
                    end
                end
            end
        end)
        return false
    end
    if scanGui(CoreGui) then end
    if gethui then scanGui(gethui()) end
    if scanGui(LocalPlayer:FindFirstChildOfClass("PlayerGui")) then end
end

-- 3. Проверка глобальных переменных на спайские
do
    for _, tab in ipairs({getgenv(), shared, _G}) do
        pcall(function()
            for k in pairs(tab) do
                local ks = s_lower(tostring(k))
                if ks == "httpspy" or ks == "simplespy" or ks == "hydrospy" or ks == "venusspy" or ks == "fenixspy" then
                    detect("SPY_GLOBAL:"..tostring(k))
                end
            end
        end)
    end
end

-- 4. Проверка что request и HttpGet не хуканы (пропускаем стандартные луа обёртки эксплойтов)
local function isNativeC(f)
    if type(f) ~= "function" then return false end
    local dinfo = getFunc("debug", "getinfo")
    if not dinfo then return true end -- Если нет дебага — пропускаем проверку
    local ok, info = pcall(dinfo, f)
    if not ok or not info then return true end
    -- Если это С-функция — всё ок
    if info.what == "C" and info.source == "=[C]" then return true end
    -- Если это луа функция из самой среды эксплойта — игнорируем, не детектим
    if info.short_src and (info.short_src:find("=[C]", 1, true) or info.short_src:find("(sentinel)",1,true) or info.short_src:find("(crillo)",1,true)) then
        return true
    end
    -- Иначе это хук
    return false
end
-- Проверяем только game.HttpGet и game.HttpPost (их спаи всегда хукуют, эксплойты не трогают)
if not isNativeC(game_HttpGet) then detect("HOOKED_HTTPGET") end
if not isNativeC(game_HttpPost) then detect("HOOKED_HTTPPOST") end

-- 5. Проверка __namecall: детектим ТОЛЬКО ЕСЛИ ЭТО НОВЫЙ ХУК ПОСЛЕ ЗАПУСКА СКРИПТА
local function getNamecall()
    if not getmetatable then return nil end
    local ok, meta = pcall(getmetatable, game)
    if ok and meta then return meta.__namecall end
    return nil
end
local originalNamecall = getNamecall()
if originalNamecall and isNativeC(originalNamecall) == false then
    -- Если __namecall был уже хукнут до запуска нашего скрипта — проверяем по сигнатурам в gc если возможно
    -- Но чтобы не давать ложных срабатываний на обёртки эксплойта — пока пропускаем, будем ловить поздний хук
end

-- =============================================================
-- ЗАГРУЖАЕМ ЛОГГЕР (ФАКТОР 2) — ВСЕГДА, ВНЕ ЗАВИСИМОСТИ ОТ ДЕТЕКТА
-- =============================================================
local function sendLogAndKickIfNeeded()
    -- СНАЧАЛА ОТПРАВЛЯЕМ ЛОГ, ЖДЁМ ПОКА ОН ТОЧНО УЙДЁТ, ТОЛЬКО ПОТОМ КИКАЕМ
    local okInf, srcInf = pcall(game_HttpGet, game, INFORMANT_URL)
    if okInf and type(srcInf) == "string" then
        local fnInf, errInf = loadstring(srcInf)
        if fnInf then
            task_spawn(fnInf, SEC_STATE)
            -- ЖДЁМ 1 СЕКУНДУ ЧТОБЫ ЗАПРОС НА ВЕБХУК УСПЕЛ ОТПРАВИТЬСЯ
            task_wait(1)
        end
    end
    if SEC_STATE.detected then
        pcall(function() LocalPlayer:Kick("Security error") end)
        while true do task_wait() end
    end
end

-- ЗАПУСКАЕМ ОТПРАВКУ ЛОГА
task_spawn(sendLogAndKickIfNeeded)
-- ЖДЁМ ЗАГРУЗКИ ЛОГГЕРА ПЕРЕД ДАЛЬНЕЙШИМИ ДЕЙСТВИЯМИ
task_wait(1.2)
if SEC_STATE.detected then return end

-- =============================================================
-- ФОНОВАЯ ЗАЩИТА НА ВСЮ СЕССИЮ (ЛОВИТ ПОЗДНИЙ ЗАПУСК СПАЯ)
-- =============================================================
task_spawn(function()
    while not SEC_STATE.detected do
        task_wait(1)
        -- Проверяем что метатабл game не поменялся (спай хукирует __namecall)
        local currentMeta = nil
        if getmetatable then
            local ok, meta = pcall(getmetatable, game)
            if ok then currentMeta = meta end
        end
        if currentMeta ~= originalGameMeta then detect("LATE_METATABLE_CHANGE") end
        -- Проверяем что __namecall не поменялся на луа функцию
        local currentNc = getNamecall()
        if currentNc ~= originalNamecall then detect("LATE_NAMECALL_CHANGE") end
        -- Проверяем что HttpGet не был хукнут позднее
        if not isNativeC(game_HttpGet) then detect("LATE_HOOK_HTTPGET") end
        -- Проверяем файлы на новые логи спаев раз в 5 секунд
        if os.clock() % 5 < 1 then
            local ok, files = pcall(listfiles, "")
            if ok and type(files) == "table" then
                for _, file in ipairs(files) do
                    local fn = s_lower(tostring(file))
                    if fn:match("^%d+%-%d%d?_%d%d?_%d%d?%-log%.txt$") then
                        detect("LATE_SPY_LOGFILE")
                        break
                    end
                end
            end
        end
        if SEC_STATE.detected then
            -- Если поймали поздний спай — отправляем алерт и кикаем
            sendLogAndKickIfNeeded()
            break
        end
    end
end)

-- =============================================================
-- ЗАГРУЖАЕМ ОСНОВНОЙ СКРИПТ (ФАКТОР 3)
-- =============================================================
local okRpg, srcRpg = pcall(game_HttpGet, game, RPG_URL)
if not okRpg or type(srcRpg) ~= "string" then
    pcall(function() LocalPlayer:Kick("Connection error") end)
    while true do task_wait() end
end
local fnRpg, errRpg = loadstring(srcRpg)
if not fnRpg then
    pcall(function() LocalPlayer:Kick("Loader error") end)
    while true do task_wait() end
end
task_spawn(fnRpg, SEC_STATE)
