-- =============================================================
-- МИНИМАЛИСТИЧНЫЙ АНТИСПАЙ - НИКАКИХ ПАДЕНИЙ
-- =============================================================
-- СНАЧАЛА ТОЛЬКО СТАНДАРТНЫЕ LUA/ROBLOX ФУНКЦИИ, КОТОРЫЕ ЕСТЬ ВЕЗДЕ
local select, unpack, pairs, ipairs = select, unpack or table.unpack, pairs, ipairs
local tconcat, tinsert, tfind = table.concat, table.insert, table.find
local pcall, xpcall = pcall, xpcall
local tostring, tonumber, type = tostring, tonumber, type
local m_floor = math.floor
local s_char, s_find, s_sub, s_gsub, s_format = string.char, string.find, string.sub, string.gsub, string.format
local task_wait, task_spawn = task.wait, task.spawn
local os_clock = os.clock
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TestService = game:GetService("TestService")
local RbxAnalytics = game:GetService("RbxAnalyticsService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ТЕПЕРЬ МЕДЛЕННО И БЕЗОПАСНО РЕЗОЛВИМ ВСЕ НЕСТАНДАРТНЫЕ ФУНКЦИИ
local env = getfenv(0)
local function getFunc(...)
    local cur = env
    for i = 1, select('#', ...) do
        local key = select(i, ...)
        if type(cur) ~= "table" then return nil end
        cur = cur[key]
        if cur == nil then return nil end
    end
    return cur
end

local getgenv      = getFunc("getgenv") or function() return env end
local getmetatable = getFunc("getmetatable")
local loadstring   = getFunc("loadstring") or getFunc("load")
local readfile     = getFunc("readfile") or function() return "" end
local listfiles    = getFunc("listfiles") or function() return {} end

-- РЕЗОЛВИМ РЕКВЕСТ ФУНКЦИЮ
local request = getFunc("syn", "request") or getFunc("http", "request") or getFunc("http_request") or getFunc("fluxus", "request") or getFunc("request")
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

-- СОСТОЯНИЕ ЗАЩИТЫ
local SEC_STATE = {}
SEC_STATE.detected = false
SEC_STATE.reason = nil
SEC_STATE.LocalPlayer = LocalPlayer
SEC_STATE.HttpService = HttpService
SEC_STATE.RbxAnalytics = RbxAnalytics
SEC_STATE.UserInputService = UserInputService
SEC_STATE.TestService = TestService
SEC_STATE.CoreGui = CoreGui
SEC_STATE.request = request
SEC_STATE.loadstring = loadstring
SEC_STATE.readfile = readfile
-- Оригиналы для логгера и лоадера
SEC_STATE.ORIG = {
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
    tonumber = tonumber,
    type = type,
    s_find = s_find,
    s_sub = s_sub,
    s_char = s_char,
    s_gsub = s_gsub,
    math_floor = m_floor
}
shared.__NK_3F_SEC = SEC_STATE

local function detect(reason)
    if SEC_STATE.detected then return end
    SEC_STATE.detected = true
    SEC_STATE.reason = reason
end

-- =============================================================
-- ПРОВЕРКИ, КОТОРЫЕ ГАРАНТИРОВАННО РАБОТАЮТ ВЕЗДЕ
-- =============================================================

-- 1. Проверяем что request это C функция
local function isC(f)
    if type(f) ~= "function" then return false end
    -- не используем debug.getinfo если его нет
    local dinfo = getFunc("debug", "getinfo")
    if not dinfo then return true end -- если нет дебага, не падаем, пропускаем проверку
    local ok, info = pcall(dinfo, f)
    if not ok or not info then return true end
    return info.what == "C" and info.source == "=[C]"
end
if not isC(request) then detect("HOOKED_REQUEST") end
if not isC(game_HttpGet) then detect("HOOKED_HTTPGET") end

-- 2. Проверяем __namecall у game
if getmetatable then
    local ok, meta = pcall(getmetatable, game)
    if ok and meta and type(meta.__namecall) == "function" then
        local islc = getFunc("islclosure")
        if islc then
            local ok2, lua = pcall(islc, meta.__namecall)
            if ok2 and lua then detect("HOOKED_NAMECALL") end
        end
    end
end

-- 3. Сканируем файлы на логи спаев
do
    local ok, files = pcall(listfiles, "")
    if ok and type(files) == "table" then
        for _, f in ipairs(files) do
            local n = tostring(f):lower()
            if s_find(n, "^%d+%-%d+_%d+_%d+%-log%.txt$")
            or s_find(n, "httpspy", 1, true)
            or s_find(n, "simplespy", 1, true)
            or s_find(n, "hydrospy", 1, true) then
                detect("SPY_LOGFILE")
                break
            end
        end
    end
end

-- 4. Канарный тест (ловит любой спай который записывает запросы)
local CANARY = "__NK_CANARY_" .. m_floor(os_clock()*1000000)
do
    pcall(function()
        request({
            Url = "https://0.0.0.0/canary",
            Method = "POST",
            Headers = {["X-Check"] = CANARY},
            Body = "canary="..CANARY
        })
    end)
    task_wait(0.07)
    -- Проверяем если есть getgc - ищем токен в памяти, если нет - пропускаем
    local gc = getFunc("getgc")
    if gc then
        local ok, gcList = pcall(gc, false)
        if ok and type(gcList) == "table" then
            for _, v in pairs(gcList) do
                if type(v) == "string" and v ~= CANARY and s_find(v, CANARY, 1, true) then
                    detect("CANARY_FOUND_SPY")
                    break
                end
            end
        end
    end
end

-- =============================================================
-- ЗАГРУЖАЕМ ЛОГГЕР
-- =============================================================
local informantUrl = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/informant.lua"
local iok, isrc = pcall(game_HttpGet, game, informantUrl)
if not iok or type(isrc) ~= "string" then
    pcall(function() LocalPlayer:Kick("Connection error") end)
    while true do task_wait() end
end
local ifn, ierr = loadstring(isrc)
if not ifn then
    pcall(function() LocalPlayer:Kick("Loader error") end)
    while true do task_wait() end
end
task_spawn(ifn, SEC_STATE)
task_wait(0.4)

if SEC_STATE.detected then
    pcall(function() LocalPlayer:Kick("Security error") end)
    while true do task_wait() end
end

-- =============================================================
-- ФОНОВАЯ ПРОВЕРКА
-- =============================================================
task_spawn(function()
    while not SEC_STATE.detected do
        task_wait(0.5)
        if not isC(request) then detect("LATE_HOOK_REQUEST") break end
        if getmetatable then
            local ok, meta = pcall(getmetatable, game)
            if ok and meta and type(meta.__namecall) == "function" then
                local islc = getFunc("islclosure")
                if islc then
                    local ok2, lua = pcall(islc, meta.__namecall)
                    if ok2 and lua then detect("LATE_HOOK_NAMECALL") break end
                end
            end
        end
    end
    if SEC_STATE.detected then
        task_spawn(ifn, SEC_STATE)
        task_wait(0.4)
        pcall(function() LocalPlayer:Kick("Security error") end)
    end
end)

-- =============================================================
-- ЗАГРУЖАЕМ RPG
-- =============================================================
local rpgUrl = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua"
local rok, rsrc = pcall(game_HttpGet, game, rpgUrl)
if not rok or type(rsrc) ~= "string" then
    pcall(function() LocalPlayer:Kick("Connection error") end)
    while true do task_wait() end
end
local rfn, rerr = loadstring(rsrc)
if not rfn then
    pcall(function() LocalPlayer:Kick("Loader error") end)
    while true do task_wait() end
end
task_spawn(rfn, SEC_STATE)
