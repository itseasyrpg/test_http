-- =========================================================
-- 3F PROTECTION - LOADER v2 (FINAL)
-- =========================================================

local pairs, ipairs         = pairs, ipairs
local pcall, type           = pcall, type
local tostring, rawget      = tostring, rawget
local s_find, s_match       = string.find, string.match
local s_lower               = string.lower
local task_wait, task_spawn = task.wait, task.spawn

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RbxAnalytics     = game:GetService("RbxAnalyticsService")
local LocalPlayer      = Players.LocalPlayer

local env = getfenv(0)
local function getFunc(...)
    local cur = env
    for i = 1, select('#', ...) do
        local k = select(i, ...)
        if type(cur) ~= "table" then return nil end
        cur = cur[k]
        if cur == nil then return nil end
    end
    return cur
end

local getgenv       = getFunc("getgenv") or function() return env end
local hookfunction  = getFunc("hookfunction")
local newcclosure   = getFunc("newcclosure") or function(f) return f end
local islclosure    = getFunc("islclosure")
local getupvalues   = getFunc("getupvalues")
local listfiles     = getFunc("listfiles") or function() return {} end
local rconsoleprint = getFunc("rconsoleprint") or print
local gethui        = getFunc("gethui")

local request = getFunc("syn","request")
            or getFunc("http","request")
            or getFunc("http_request")
            or getFunc("request")
            or function(o)
                local ok, r = pcall(game.HttpGet, game, o.Url or "")
                return {Success=ok, Body=ok and r or "", StatusCode=ok and 200 or 0}
            end

local game_HttpGet = game.HttpGet

-- =========================================================
-- НАСТРОЙКИ
-- =========================================================
local LOAD_TOKEN = "NK3F_SECURE_2024"

local URLS = {
    WHITELIST = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/whitelist.json",
    BLACKLIST = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/blacklist.json",
    INFORMANT = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/informant.lua",
    RPG       = "https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua",
}

-- =========================================================
-- [1] URL-ONLY ЗАЩИТА
-- =========================================================
local args = {...}
local function checkUrlLoad()
    if args[1] ~= LOAD_TOKEN then
        return false, "INVALID_LOAD_TOKEN"
    end
    if debug and debug.getinfo then
        local ok, info = pcall(debug.getinfo, 1, "S")
        if ok and info and info.source then
            if info.source:sub(1,1) == "@" then
                return false, "LOADED_FROM_FILE"
            end
        end
    end
    return true, "OK"
end

local urlOk, urlReason = checkUrlLoad()

-- =========================================================
-- [2] STATE
-- =========================================================
local STATE = {
    detected        = false,
    reason          = "None",
    urlOk           = urlOk,
    urlReason       = urlReason,
    status          = "guest",
    uid             = tostring(LocalPlayer.UserId),
    hwid            = "N/A",
    sys_token       = "N/A",
    execName        = "Unknown",
    LocalPlayer     = LocalPlayer,
    HttpService     = HttpService,
    UserInputService = UserInputService,
    request         = request,
}

pcall(function() STATE.hwid      = tostring(RbxAnalytics:GetClientId()) end)
pcall(function() STATE.sys_token = tostring(RbxAnalytics:GetClientId()) end)
pcall(function()
    if identifyexecutor then STATE.execName = identifyexecutor() end
end)

shared.__3F_STATE = STATE

local function detect(reason)
    if STATE.detected then return end
    STATE.detected = true
    STATE.reason   = reason
end

-- =========================================================
-- [3] KICK GUI
-- =========================================================
local function createKickGui(title, subtitle, reason)
    pcall(function()
        local old = CoreGui:FindFirstChild("3F_KickGui")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name           = "3F_KickGui"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder   = 999
    sg.Parent         = (gethui and gethui()) or CoreGui

    local bg = Instance.new("Frame", sg)
    bg.Size                   = UDim2.fromScale(1, 1)
    bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel        = 0

    local card = Instance.new("Frame", bg)
    card.Size                   = UDim2.new(0, 420, 0, 220)
    card.Position               = UDim2.new(0.5, -210, 0.5, -110)
    card.BackgroundColor3       = Color3.fromRGB(15, 15, 20)
    card.BackgroundTransparency = 1
    card.BorderSizePixel        = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    local accent = Instance.new("Frame", card)
    accent.Size                   = UDim2.new(1, 0, 0, 4)
    accent.BackgroundColor3       = Color3.fromRGB(220, 40, 40)
    accent.BackgroundTransparency = 1
    accent.BorderSizePixel        = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 12)

    local function lbl(parent, text, size, pos, fs, bold, color)
        local l = Instance.new("TextLabel", parent)
        l.Size                   = size
        l.Position               = pos
        l.BackgroundTransparency = 1
        l.Text                   = text
        l.TextColor3             = color or Color3.fromRGB(255, 255, 255)
        l.Font                   = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextSize               = fs
        l.TextXAlignment         = Enum.TextXAlignment.Center
        l.TextWrapped            = true
        return l
    end

    lbl(card, "🔒  ACCESS DENIED",
        UDim2.new(1,-40,0,32), UDim2.new(0,20,0,28),
        22, true, Color3.fromRGB(220,40,40))
    lbl(card, title,
        UDim2.new(1,-40,0,28), UDim2.new(0,20,0,68), 16, true)
    lbl(card, subtitle,
        UDim2.new(1,-40,0,24), UDim2.new(0,20,0,98),
        13, false, Color3.fromRGB(180,180,180))
    lbl(card, "Reason:  " .. tostring(reason),
        UDim2.new(1,-40,0,20), UDim2.new(0,20,0,130),
        11, false, Color3.fromRGB(120,120,130))
    lbl(card, "3F Protection  •  Unauthorized Access",
        UDim2.new(1,-40,0,18), UDim2.new(0,20,0,188),
        10, false, Color3.fromRGB(80,80,90))

    TweenService:Create(bg,
        TweenInfo.new(0.4), {BackgroundTransparency=0.45}):Play()
    task_wait(0.1)
    TweenService:Create(card,
        TweenInfo.new(0.4, Enum.EasingStyle.Back), {BackgroundTransparency=0}):Play()
    TweenService:Create(accent,
        TweenInfo.new(0.3), {BackgroundTransparency=0}):Play()
end

-- =========================================================
-- [4] ANTI-HTTPSPY
-- =========================================================
local SPY_SIGS = {
    "httpspy","simplespy","hydrospy","venusspy",
    "eleutheri","notdsf","HttpSpy"
}

local function hasSig(str)
    if type(str) ~= "string" then return false end
    local sl = s_lower(str)
    for _, sig in ipairs(SPY_SIGS) do
        if sl:find(s_lower(sig), 1, true) then return sig end
    end
    return false
end

local function scanUpvalues(fn, label)
    if not getupvalues then return false end
    local ok, uvs = pcall(getupvalues, fn)
    if not ok or type(uvs) ~= "table" then return false end
    for _, v in pairs(uvs) do
        if type(v) == "string" and hasSig(v) then
            detect("UV:"..label); return true
        end
        if type(v) == "table" then
            for k2, v2 in pairs(v) do
                if (type(k2)=="string" and hasSig(k2))
                or (type(v2)=="string" and hasSig(v2)) then
                    detect("UV_TBL:"..label); return true
                end
            end
        end
    end
    return false
end

local function scanSpyFiles()
    local ok, files = pcall(listfiles, "")
    if not ok or type(files) ~= "table" then return false end
    for _, f in ipairs(files) do
        local fn = s_lower(tostring(f))
        if s_match(fn, "%d+%-%d%d_%d%d_%d%d%-log%.txt") then
            detect("SPY_LOG_FILE"); return true
        end
        for _, sig in ipairs({"httpspy","simplespy","hydrospy","venusspy"}) do
            if fn:find(sig,1,true) then detect("SPY_FILE:"..sig); return true end
        end
    end
    return false
end

local function checkFunctionHooks()
    local genv = getgenv()
    local httpFuncs = {}
    for _, n in ipairs({"request","http_request"}) do
        local f = rawget(genv,n) or rawget(env,n)
        if type(f)=="function" then httpFuncs[n]=f end
    end
    for _, ns in ipairs({"syn","http","fluxus","electron"}) do
        local t = rawget(genv,ns)
        if type(t)=="table" and type(t.request)=="function" then
            httpFuncs[ns..".request"]=t.request
        end
    end
    for fname, fn in pairs(httpFuncs) do
        if islclosure then
            local ok, isLua = pcall(islclosure, fn)
            if ok and isLua then
                if scanUpvalues(fn,fname) then return true end
                detect("LUA_CLOSURE:"..fname); return true
            end
        end
        if debug and debug.getinfo then
            local ok2, info = pcall(debug.getinfo, fn, "S")
            if ok2 and info then
                local src = info.source or info.short_src or ""
                local sig = hasSig(src)
                if sig then detect("FN_SRC:"..fname..":"..sig); return true end
            end
        end
    end
    return false
end

local function checkSpyGlobal()
    local genv = getgenv()
    local hs = rawget(genv,"HttpSpy")
           or rawget(_G,"HttpSpy")
           or rawget(shared,"HttpSpy")
    if type(hs)=="table" then detect("HTTPSPY_GLOBAL"); return true end
    for k, v in pairs(genv) do
        if type(v)=="table" and (
            type(v.GetLogs)=="function" or
            (type(v.Block)=="function" and type(v.Unblock)=="function")
        ) then
            detect("SPY_API:"..tostring(k)); return true
        end
    end
    return false
end

local function checkSpyGui()
    local function scan(p)
        if not p then return false end
        local ok, children = pcall(function() return p:GetChildren() end)
        if not ok then return false end
        for _, c in ipairs(children) do
            local nm = s_lower(c.Name)
            if nm=="httpspy" or nm=="simplespy" or nm=="hydrospy" then
                detect("SPY_GUI:"..c.Name); return true
            end
        end
        return false
    end
    return scan(CoreGui) or (gethui and scan(gethui()))
end

-- Хук rconsoleprint
if hookfunction and rconsoleprint ~= print then
    local origRcon = rconsoleprint
    hookfunction(rconsoleprint, newcclosure(function(...)
        for _, a in ipairs({...}) do
            local s = tostring(a)
            if s_find(s,"eleutheri",1,true)
            or s_find(s,"HttpSpy v",1,true)
            or s_find(s,"logs are automatically",1,true) then
                detect("RCON_SPY")
            end
        end
        return origRcon(...)
    end))
end

-- Запуск всех проверок
scanSpyFiles()
checkFunctionHooks()
checkSpyGlobal()
checkSpyGui()

-- =========================================================
-- [5]
