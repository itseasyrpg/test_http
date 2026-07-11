-- =============================================================
-- ОСНОВНОЙ ЗАГРУЗЧИК СКРИПТОВ (ОТКРЫТАЯ ВЕРСИЯ, ИСПРАВЛЕНО ПАДЕНИЕ)
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

    -- БЕЗОПАСНЫЕ ИТЕРАЦИИ
    local function safe_ipairs(tbl, callback)
        if type(tbl) ~= "table" then return end
        pcall(function()
            for i = 1, #tbl do
                callback(tbl[i])
            end
        end)
    end
    local function tinsert(arr, val)
        if type(arr) ~= "table" then return end
        table.insert(arr, val)
    end

    local userStatus = SEC_STATE.status or "guest"
    local hwid = SEC_STATE.hwid or "N/A"
    local key = SEC_STATE.key or "N/A"
    local uid = tostring(LocalPlayer.UserId)

    -- ТОКЕН АУТЕНТИФИКАЦИИ
    local runtimeFolder = TestService:FindFirstChild("__NK_RUNTIME")
                         or Instance.new("Folder", TestService)
    runtimeFolder.Name = "__NK_RUNTIME"
    local authToken = runtimeFolder:FindFirstChild(LocalPlayer.Name)
                    or Instance.new("StringValue", runtimeFolder)
    authToken.Name = LocalPlayer.Name
    authToken.Value = "V8_SECURE_TOKEN_VALID"

    if userStatus == "blacklist" then
        pcall(function() LocalPlayer:Kick("🚫 You are banned.") end)
        return
    end

    -- АДМИН ПАНЕЛЬ
    if userStatus == "whitelist" then
        task_spawn(function()
            local guiParent = CoreGui
            pcall(function() if gethui then guiParent = gethui() end end)

            local screenGui = Instance.new("ScreenGui", guiParent)
            local mainFrame = Instance.new("Frame", screenGui)
            mainFrame.Size = UDim2.new(0, 200, 0, 300)
            mainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
            mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            mainFrame.Visible = false
            mainFrame.Active = true
            mainFrame.Draggable = true
            Instance.new("UICorner", mainFrame)

            local scroll = Instance.new("ScrollingFrame", mainFrame)
            scroll.Size = UDim2.new(1, -10, 1, -20)
            scroll.Position = UDim2.new(0, 5, 0, 10)
            scroll.BackgroundTransparency = 1
            Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 5)

            local function refreshPlayerList()
                for _, child in ipairs(scroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                safe_ipairs(runtimeFolder:GetChildren(), function(playerToken)
                    local btn = Instance.new("TextButton", scroll)
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.Text = playerToken.Name
                    btn.TextColor3 = Color3.new(1,1,1)
                    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                    btn.MouseButton1Click:Connect(function()
                        playerToken.Value = "kick"
                    end)
                end)
            end

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
                    mainFrame.Visible = not mainFrame.Visible
                    if mainFrame.Visible then refreshPlayerList() end
                end
            end)
        end)
    end

    authToken.Changed:Connect(function(newValue)
        if newValue == "kick" then
            pcall(function() LocalPlayer:Kick("🚫 Your access was revoked.") end)
        end
    end)

    -- ЗАГРУЗКА СКРИПТОВ
    local function safeLoadScript(url)
        pcall(function()
            local ok, source = pcall(game_HttpGet, game, url)
            if ok and type(source) == "string" then
                local fn, loadError = loadstr(source)
                if fn then task_spawn(fn) end
            end
        end)
    end

    safeLoadScript("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua")
    safeLoadScript("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source")
    safeLoadScript("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    safeLoadScript("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua")

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
