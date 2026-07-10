local function _0xH(h)
    local s = ""
    for i = 1, #h, 2 do s = s .. string.char(tonumber(h:sub(i, i+1), 16)) end
    return s
end

local _req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local _L = game:GetService("Players").LocalPlayer

local function _DETECT()
    if not _req then return false end
    
    -- 1. Проверка нативного кода (C-Closure)
    local ok, info = pcall(debug.getinfo, _req)
    if ok and info and (info.source ~= "=[C]" or info.what ~= "C") then return "HOOKED_REQ" end
    
    local ok2, info2 = pcall(debug.getinfo, game.HttpGet)
    if ok2 and info2 and info2.source ~= "=[C]" then return "HOOKED_HTTP" end

    -- 2. Детект NotDSF HttpSpy (проверка метатаблицы)
    local mt = getrawmetatable(game)
    local nc = mt.__namecall
    local ok3, info3 = pcall(debug.getinfo, nc)
    if ok3 and info3 and info3.source:lower():find("spy") then return "NC_SPY" end

    -- 3. Проверка CoreGui и глобалок
    local cg = game:GetService("CoreGui")
    local env = getgenv()
    for _, n in ipairs({"SimpleSpy", "HttpSpy", "HydroSpy", "VGG Spy", "TwiSpy", "NotDSF"}) do
        if cg:FindFirstChild(n) or env[n] then return "SPY_NAME_" .. n end
    end
    
    return false
end

local _se = _DETECT()
if _se then
    local _A = _0xH("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531383333343033353838383138313237312F733164313841767532456D57707A547254306A4E49686A543665314A3537595837304F58484D567878637975535377364C366E7242416A7756737067612D4C37534E4B4F")
    pcall(function()
        _req({
            Url = _A, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode({
                embeds = {{
                    title = "Security Alert: Advanced Spy Detected",
                    color = 16711680,
                    fields = {
                        {name = "Player", value = _L.Name, inline = true},
                        {name = "Detection", value = tostring(_se), inline = true}
                    }
                }}
            })
        })
    end)
    _L:Kick("Security Violation 0xSPY")
    while true do end return
end

local _TS = game:GetService("TestService")
local _ST = _TS:FindFirstChild("__NK_RUNTIME") or Instance.new("Folder", _TS)
_ST.Name = "__NK_RUNTIME"
local _AU = Instance.new("StringValue", _ST)
_AU.Name = _L.Name
_AU.Value = "V8_AUTHORIZED"
shared._NK_AUTH = "V8_AUTHORIZED"

local _G = _0xH("68747470733A2F2F7261772E67697468756275736572636F6E74656E742E636F6D2F697473656173797270672F727067672F726566732F68656164732F6D61696E2F727067")
local ok, res = pcall(function() return game:HttpGet(_G) end)
if ok and res then
    local f = loadstring(res)
    if f then task.spawn(f) end
else
    _L:Kick("Error 0x82")
end
