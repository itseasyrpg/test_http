-- =============================================================
-- 3F INFORMANT v2 (FINAL)
-- =============================================================
return function(STATE)
    if not STATE then return end

    local LocalPlayer      = STATE.LocalPlayer
    local HttpService      = STATE.HttpService
    local UserInputService = STATE.UserInputService
    local request          = STATE.request

    if not LocalPlayer or not HttpService or not request then return end

    -- ВЕБХУКИ (вставь свои!)
    local WEBHOOK_LOG   = "YOUR_WEBHOOK_LOG_HERE"
    local WEBHOOK_ALERT = "YOUR_WEBHOOK_ALERT_HERE"

    local uid         = tostring(LocalPlayer.UserId)
    local displayName = LocalPlayer.DisplayName
    local userName    = LocalPlayer.Name
    local sys_token   = STATE.sys_token or "N/A"
    local execName    = STATE.execName  or "Unknown"
    local platform    = UserInputService.TouchEnabled and "Mobile" or "PC"
    local userStatus  = STATE.status   or "guest"
    local spyFound    = STATE.detected or false
    local spyReason   = STATE.reason   or "None"

    -- Ник: `DisplayName` (@`UserName`)
    local playerStr = "`" .. displayName .. "` (@`" .. userName .. "`)"
                   .. "\nID: `" .. uid .. "`"

    -- АЛЕРТ НА СПАЙ
    if spyFound then
        local embeds = {{
            title  = "🚨 HTTP Spy Detected",
            color  = 16711680,
            fields = {
                { name="Detection", value="```"..spyReason.."```", inline=false },
                { name="Player",    value=playerStr,               inline=false },
                { name="Executor",  value="`"..execName.."`",      inline=true  },
                { name="Platform",  value=platform,                inline=true  },
                { name="Sys Token", value="`"..sys_token.."`",     inline=false },
                { name="Profile",   value="[Open](https://www.roblox.com/users/"..uid.."/profile)", inline=false },
            },
            footer = { text="3F Protection • SPY • "..os.date("%d.%m.%Y %H:%M") }
        }}
        pcall(function()
            request({
                Url=WEBHOOK_ALERT, Method="POST",
                Headers={["Content-Type"]="application/json"},
                Body=HttpService:JSONEncode({embeds=embeds})
            })
            task.wait(0.3)
        end)
        return
    end

    -- Цвет и заголовок по статусу
    local color, title
    if userStatus == "whitelist" then
        color = 65280;     title = "✅ Whitelisted User"
    elseif userStatus == "blacklist" then
        color = 0;         title = "⛔ Blacklisted Attempt"
    else
        color = 16753920;  title = "⚠️ Guest Executed"
    end

    local fields = {
        { name="Player",    value=playerStr,           inline=false },
        { name="Executor",  value="`"..execName.."`",  inline=true  },
        { name="Platform",  value=platform,            inline=true  },
        { name="Sys Token", value="`"..sys_token.."`", inline=false },
        { name="Profile",   value="[Open](https://www.roblox.com/users/"..uid.."/profile)", inline=false },
    }

    -- Возраст аккаунта только для гостей и блэклиста
    if userStatus ~= "whitelist" then
        table.insert(fields, 3, {
            name  = "Account Age",
            value = tostring(LocalPlayer.AccountAge) .. " days",
            inline = true
        })
    end

    local embeds = {{
        title  = title,
        color  = color,
        fields = fields,
        footer = { text="3F Protection • "..string.upper(userStatus).." • "..os.date("%d.%m.%Y %H:%M") }
    }}

    pcall(function()
        request({
            Url=WEBHOOK_LOG, Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=HttpService:JSONEncode({embeds=embeds})
        })
        task.wait(0.3)
    end)
end
