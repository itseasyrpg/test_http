-- =============================================================
-- АНТИ HTTP СПАЙ / ФАКТОР 1 (ОТКРЫТЫЙ ИСХОДНИК)
-- ДЕТЕКТИТ HTTPSPY ДАЖЕ ЕСЛИ ОН ЗАПУЩЕН ДО НАШЕГО СКРИПТА
-- =============================================================

-- СОХРАНЯЕМ ОРИГИНАЛЫ В САМОМ НАЧАЛЕ (ДАЖЕ ЕСЛИ ОНИ УЖЕ ХУКНУТЫ, МЫ ПОЙМЁМ ЭТО ПО ФАЙЛАМ)
local pairs, ipairs    = pairs, ipairs
local tinsert, tconcat = table.insert, table.concat
local pcall, xpcall    = pcall, xpcall
local tostring, type   = tostring, type
local m_floor, m_random = math.floor, math.random
local s_find, s_sub, s_lower, s_match = string.find, string.sub, string.lower, string.match
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

-- БЕЗОПАСНЫЙ РЕЗОЛВ ФУНКЦИЙ
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

local getgenv      = getFunc("getgenv") or function() return env end
local getmetatable = getFunc("getmetatable")
local setmetatable = getFunc("setmetatable")
local loadstring   = getFunc("loadstring") or getFunc("load")
local readfile     = getFunc("readfile") or function() return "" end
local listfiles    = getFunc("listfiles") or function() return {} end
local gethui       = getFunc("gethui")
local writefile    = getFunc("writefile")
local appendfile   = getFunc("appendfile")
local rconsoleprint = getFunc("rconsoleprint") or print
local hookfunction  = getFunc("hookfunction")
local newcclosure   = getFunc("newcclosure") or function(f) return f end

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
local game_HttpGetAsync = game.HttpGetAsync

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

-- =============================================================
-- САМАЯ ПЕРВАЯ ПРОВЕРКА: ИЩЕМ ФАЙЛЫ ЛОГОВ КОТОРЫЕ СОЗДАЁТ HTTPSPY
-- ОН СОЗДАЁТ ИХ ДО ЗАПУСКА НАШЕГО СКРИПТА, ЕСЛИ ЗАПУЩЕН ПЕРВЫМ
-- =============================================================
local function scanForSpyFiles()
    local ok, files = pcall(listfiles, "")
    if ok and type(files) == "table" then
        for _, file in ipairs(files) do
            local fn = s_lower(tostring(file))
            -- HttpSpy сохраняет логи по шаблону: PlaceId-DD_MM_YY-log.txt
            -- На скриншоте файл назывался 123974602339071-11_07_26-log.txt
            if s_match(fn, "^%d+%-%d+_%d+_%d+%-log%.txt$") then
                detect("HTTPSPY_LOGFILE_EXISTS:"..tostring(file))
                return true
            end
            if fn:find("httpspy", 1, true)
            or fn:find("simplespy", 1, true)
            or fn:find("hydrospy", 1, true)
            or fn:find("venusspy", 1, true) then
                detect("SPY_LOGFILE:"..tostring(file))
                return true
            end
        end
    end
    return false
end
-- Сканируем файлы СРАЗУ после старта
scanForSpyFiles()
-- Сканируем ещё раз через 0.1 секунды, если файл был создан только что
if not SEC_STATE.detected then task_spawn(function() task_wait(0.1) scanForSpyFiles() end) end

-- =============================================================
-- ПРОВЕРКА НА ВЫВОД В КОНСОЛЬ ОТ HTTPSPY
-- Если спай запущен раньше нас он уже вывел строку "eleutheri.com" и "HttpSpy v" в rconsoleprint
-- Мы перехватываем rconsoleprint и если приходит любая строка с сигнатурой спая — детект
-- =============================================================
if not SEC_STATE.detected and hookfunction and rconsoleprint and rconsoleprint ~= print then
    local originalRcon = rconsoleprint
    hookfunction(rconsoleprint, newcclosure(function(...)
        local args = {...}
        for _, a in ipairs(args) do
            local str = tostring(a)
            -- Уникальные строки которые выводит ТОЛЬКО HttpSpy
            if s_find(str, "eleutheri.com", 1, true)
            or s_find(str, "HttpSpy v", 1, true)
            or s_find(str, "logs are automatically being saved", 1, true)
            or s_find(str, "SimpleSpy", 1, true)
            or s_find(str, "HydroSpy", 1, true) then
                detect("RCONSOLE_SPY_OUTPUT")
            end
        end
        return originalRcon(...)
    end))
end

-- =============================================================
-- ПРОВЕРКА ГУИ СПАЕВ
-- =============================================================
if not SEC_STATE.detected then
    local function scanGui(parent)
        if not parent then return false end
        local found = false
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                local nm = s_lower(child.Name)
                if nm == "httpspy" or nm == "simplespy" or nm == "hydrospy" then
                    detect("SPY_GUI:"..child.Name)
                    found = true
                    return
                end
            end
        end)
        return found
    end
    scanGui(CoreGui)
    if gethui then scanGui(gethui()) end
    scanGui(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
end

-- =============================================================
-- ПРОВЕРКА ГЛОБАЛОВ
-- =============================================================
if not SEC_STATE.detected then
    for _, tab in ipairs({getgenv(), shared, _G}) do
        pcall(function()
            for k in pairs(tab) do
                local ks = s_lower(tostring(k))
                if ks == "httpspy" or ks == "simplespy" or ks == "hydrospy" or ks == "venusspy" then
                    detect("SPY_GLOBAL_VAR:"..tostring(k))
                end
            end
        end)
        if SEC_STATE.detected then break end
    end
end

-- =============================================================
-- ЛОГГЕР: ОТПРАВЛЯЕМ ЛОГ ВСЕГДА, ЖДЁМ ОТПРАВКУ, КИКАЕМ ПОСЛЕ
-- =============================================================
local function sendLogAndKick()
    local okInf, srcInf = pcall(game_HttpGet, game, INFORMANT_URL)
    if okInf and type(srcInf) == "string" then
        local fnInf = loadstring(srcInf)
        if fnInf then
            task_spawn(fnInf, SEC_STATE)
            -- ЖДЁМ ПОЛТОРЫ СЕКУНДЫ ЧТОБЫ ЗАПРОС ТОЧНО УШЁЛ
            task_wait(1.5)
        end
    end
    if SEC_STATE.detected then
        pcall(function() LocalPlayer:Kick("Security error") end)
        while true do task_wait() end
    end
end
if SEC_STATE.detected then
    sendLogAndKick()
    return
end

task_spawn(sendLogAndKick)
task_wait(1.7)
if SEC_STATE.detected then return end

-- =============================================================
-- ФОНОВАЯ ЗАЩИТА
-- =============================================================
task_spawn(function()
    local lastFileCheck = 0
    while not SEC_STATE.detected do
        task_wait(0.5)
        -- Проверка на новые файлы логов раз в 2 секунды
        lastFileCheck = lastFileCheck + 0.5
        if lastFileCheck >= 2 then
            lastFileCheck = 0
            scanForSpyFiles()
        end
        -- Проверка изменения __namecall (если спай запустят после нас)
        if getmetatable then
            local ok, meta = pcall(getmetatable, game)
            if ok and meta and meta.__namecall then
                local islclosure = getFunc("islclosure")
                if islclosure then
                    local ok2, isLua = pcall(islclosure, meta.__namecall)
                    if ok2 and isLua then detect("LATE_NAMECALL_HOOK") end
                end
            end
        end
    end
    if SEC_STATE.detected then
        sendLogAndKick()
    end
end)

-- =============================================================
-- ЗАГРУЗКА RPG
-- =============================================================
local okRpg, srcRpg = pcall(game_HttpGet, game, RPG_URL)
if not okRpg or type(srcRpg) ~= "string" then
    pcall(function() LocalPlayer:Kick("Connection error") end)
    while true do task_wait() end
end
local fnRpg = loadstring(srcRpg)
if not fnRpg then
    pcall(function() LocalPlayer:Kick("Loader error") end)
    while true do task_wait() end
end
task_spawn(fnRpg, SEC_STATE)
