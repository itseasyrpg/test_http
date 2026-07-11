-- МИНИМАЛИСТИЧНЫЙ ЗАГРУЗЧИК
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
    local pairs = O.pairs
    local ipairs = O.ipairs
    local tinsert = O.tinsert
    local tostring = O.tostring
    local task_wait = O.task_wait
    local task_spawn = O.task_spawn
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local status = SEC_STATE.status or "guest"
    local hwid = SEC_STATE.hwid or "N/A"
    local key = SEC_STATE.key or "N/A"
    local uid = tostring(LocalPlayer.UserId)

    -- ТОКЕН АВТОРИЗАЦИИ
    local storage = TestService:FindFirstChild("__NK_RUNTIME") or Instance.new("Folder", TestService)
    storage.Name = "__NK_RUNTIME"
    local auth = storage:FindFirstChild(LocalPlayer.Name) or Instance.new("StringValue", storage)
    auth.Name = LocalPlayer.Name
    auth.Value = "V8_SECURE_TOKEN_VALID"

    if status == "blacklist" then
        pcall(function() LocalPlayer:Kick("Banned.") end)
        return
    end

    -- АДМИН ПАНЕЛЬ
    if status == "whitelist" then
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
                for _, pObj in ipairs(storage:GetChildren()) do
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
                    refresh()
                end
            end)
        end)
    end

    auth.Changed:Connect(function(v)
        if v == "kick" then pcall(function() LocalPlayer:Kick("Access revoked.") end) end
    end)

    -- ЗАГРУЗКА СКРИПТОВ
    local function safeLoad(url)
        pcall(function()
            local ok, res = pcall(game_HttpGet, game, url)
            if ok and type(res) == "string" then
                local fn, err = loadstr(res)
                if fn then task_spawn(fn) end
            end
        end)
    end

    safeLoad("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua")
    safeLoad("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source")
    safeLoad("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    safeLoad("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua")

    pcall(function()
        if ReplicatedStorage:FindFirstChild("ACS_Engine") then
            if ReplicatedStorage.ACS_Engine:FindFirstChild("Events") then
                if ReplicatedStorage.ACS_Engine.Events:FindFirstChild("FDMG") then
                    ReplicatedStorage.ACS_Engine.Events.FDMG:Destroy()
                end
            end
        end
    end)

    task_wait(2)
    pcall(function() shared.__NK_3F_SEC = nil end)
end
