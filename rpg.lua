-- =============================================================
-- ОСНОВНОЙ ЗАГРУЗЧИК / ФАКТОР 3 (ОТКРЫТЫЙ ИСХОДНИК)
-- =============================================================
return function(SEC_STATE)
    if not SEC_STATE or not SEC_STATE.ORIG then return end
    local O = SEC_STATE.ORIG
    local LocalPlayer = SEC_STATE.LocalPlayer
    local HttpService = SEC_STATE.HttpService
    local TestService = SEC_STATE.TestService
    local CoreGui = SEC_STATE.CoreGui
    local UserInputService = SEC_STATE.UserInputService
    local request = O.request
    local game_HttpGet = O.game_HttpGet
    local loadstr = O.loadstr
    local pcall = O.pcall
    local type = O.type
    local tostring = O.tostring
    local task_wait = O.task_wait
    local task_spawn = O.task_spawn
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local userStatus = SEC_STATE.status or "guest"
    local hwid = SEC_STATE.hwid or "N/A"
    local key = SEC_STATE.key or "N/A"
    local uid = tostring(LocalPlayer.UserId)

    -- ТОКЕН АУТЕНТИФИКАЦИИ
    local runtimeFolder = TestService:FindFirstChild("__NK_RUNTIME") or Instance.new("Folder", TestService)
    runtimeFolder.Name = "__NK_RUNTIME"
    local authToken = runtimeFolder:FindFirstChild(LocalPlayer.Name) or Instance.new("StringValue", runtimeFolder)
    authToken.Name = LocalPlayer.Name
    authToken.Value = "V8_SECURE_TOKEN_VALID"

    if userStatus == "blacklist" then
        pcall(function() LocalPlayer:Kick("🚫 You are banned.") end)
        return
    end

    -- АДМИН ПАНЕЛЬ (INSERT) ДЛЯ ВАЙТЛИСТА
    if userStatus == "whitelist" then
        task_spawn(function()
            local parent = CoreGui
            pcall(function() if gethui then parent = gethui() end end)
            local sg = Instance.new("ScreenGui", parent)
            local f = Instance.new("Frame", sg)
            f.Size = UDim2.new(0, 200, 0, 300)
            f.Position = UDim2.new(0.5,-100,0.5,-150)
            f.BackgroundColor3 = Color3.fromRGB(30,30,35)
            f.Visible = false
            f.Active = true
            f.Draggable = true
            Instance.new("UICorner", f)
            local s = Instance.new("ScrollingFrame", f)
            s.Size = UDim2.new(1,-10,1,-20)
            s.Position = UDim2.new(0,5,0,10)
            s.BackgroundTransparency = 1
            Instance.new("UIListLayout", s).Padding = UDim.new(0,5)
            local function refresh()
                for _, v in ipairs(s:GetChildren()) do
                    if v:IsA("TextButton") then v:Destroy() end
                end
                for _, pObj in ipairs(runtimeFolder:GetChildren()) do
                    local b = Instance.new("TextButton", s)
                    b.Size = UDim2.new(1,0,0,30)
                    b.Text = pObj.Name
                    b.TextColor3 = Color3.new(1,1,1)
                    b.BackgroundColor3 = Color3.fromRGB(45,45,50)
                    b.MouseButton1Click:Connect(function() pObj.Value = "kick" end)
                end
            end
            UserInputService.InputBegan:Connect(function(k, g)
                if not g and k.KeyCode == Enum.KeyCode.Insert then
                    f.Visible = not f.Visible
                    if f.Visible then refresh() end
                end
            end)
        end)
    end

    authToken.Changed:Connect(function(v)
        if v == "kick" then pcall(function() LocalPlayer:Kick("🚫 Access revoked.") end) end
    end)

    -- ЗАГРУЗКА СКРИПТОВ
    local function loadScript(url)
        pcall(function()
            local ok, src = pcall(game_HttpGet, game, url)
            if ok and type(src) == "string" then
                local fn = loadstr(src)
                if fn then task_spawn(fn) end
            end
        end)
    end

    loadScript("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua")
    loadScript("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source")
    loadScript("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    loadScript("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua")

    pcall(function()
        if ReplicatedStorage:FindFirstChild("ACS_Engine")
        and ReplicatedStorage.ACS_Engine:FindFirstChild("Events")
        and ReplicatedStorage.ACS_Engine.Events:FindFirstChild("FDMG") then
            ReplicatedStorage.ACS_Engine.Events.FDMG:Destroy()
        end
    end)

    task_wait(2)
    pcall(function() shared.__NK_3F_SEC = nil end)
end
