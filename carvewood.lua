--[[ CarveWood v9.0 | Delta mobile | no login, no key ]]
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

getgenv().CW_Delay = getgenv().CW_Delay or 0.5
getgenv().CW_Gen = (getgenv().CW_Gen or 0) + 1
local myGen = getgenv().CW_Gen
print("[CW] loaded, gen " .. tostring(myGen))
getgenv().CW_Running = true
getgenv().CW_Farm = getgenv().CW_Farm or false
getgenv().CW_Rolled = false
getgenv().CW_AntiShake = getgenv().CW_AntiShake or false
getgenv().CW_LowQ = getgenv().CW_LowQ or false
getgenv().CW_Rolls = 0
getgenv().CW_FarmTime = 0
getgenv().CW_FarmSince = nil
getgenv().CW_Frenzy = getgenv().CW_Frenzy or false

local cachedTy = nil
local function myTycoon()
    if cachedTy and cachedTy.Parent then
        local ok, mine = pcall(function()
            local o = cachedTy:FindFirstChild("Owner", true)
            return o and tostring(o.Value) == LP.Name
        end)
        if ok and mine then return cachedTy end
    end
    local folder = workspace:FindFirstChild("Tycoons")
    if not folder then return nil end
    for _, t in pairs(folder:GetChildren()) do
        local o = t:FindFirstChild("Owner", true)
        if o and tostring(o.Value) == LP.Name then cachedTy = t return t end
    end
    cachedTy = folder:FindFirstChild("Tycoon3")
    return cachedTy
end

local function firePrompt(p)
    if typeof(p) == "Instance" and p:IsA("ProximityPrompt") then
        pcall(function() fireproximityprompt(p) end)
        return true
    end
    return false
end

local CW_ALIEN_ROUTE = "ActivateAlienInvasion"
local function alienUUID()
    local ok, mod = pcall(function()
        return require(game:GetService("ReplicatedFirst"):WaitForChild("Client"))
    end)
    if not ok or type(mod) ~= "table" then return nil end
    local cr = mod.CachedRemotes
    if type(cr) ~= "table" then return nil end
    local salt = LP.Name .. tostring(game.PlaceVersion) .. "xdd"
    local sl = #salt
    for k, v in pairs(cr) do
        local ks = tostring(k)
        if #ks == #CW_ALIEN_ROUTE then
            local d = {}
            for i = 1, #ks do
                d[i] = string.char(bit32.bxor(ks:byte(i), salt:byte((i - 1) % sl + 1)))
            end
            if table.concat(d) == CW_ALIEN_ROUTE then return tostring(v) end
        end
    end
    return nil
end

local function fireCollectRemotes()
    local f = game:GetService("ReplicatedStorage"):FindFirstChild("REM", true)
    if not f then return end
    local bad = nil
    pcall(function() bad = alienUUID() end)
    if bad == nil then return end
    for _, d in pairs(f:GetChildren()) do
        if d:IsA("RemoteFunction") and d.Name ~= bad then
            task.spawn(function()
                pcall(function() d:InvokeServer({}) end)
            end)
        end
    end
end

local function collectSeed(p)
    if typeof(p) ~= "Instance" or not p:IsA("ProximityPrompt") then return false end
    if not p.Enabled then return false end
    local nm = p.Name
    if not (string.find(nm, "Grab", 1, true) or string.find(nm, "Collect", 1, true)) then return false end
    pcall(function() fireproximityprompt(p) end)
    return true
end

local seedList = {}
local seedSeen = {}
local active = 0
local function runCollect(p)
    active = active + 1
    task.spawn(function()
        pcall(collectSeed, p)
        active = active - 1
    end)
end

local function grabAll()
    local ty = myTycoon()
    if not ty then return 0 end
    local n = 0
    for i = #seedList, 1, -1 do
        local p = seedList[i]
        if not p.Parent then
            table.remove(seedList, i)
        elseif p.Enabled then
            n = n + 1
            runCollect(p)
        end
    end
    if n > 0 then
        local t0 = os.clock()
        while active > 0 and os.clock() - t0 < 0.4 do task.wait(0.02) end
    end
    return n
end

local function seedPrompt(p)
    if typeof(p) ~= "Instance" or not p:IsA("ProximityPrompt") then return false end
    local nm = p.Name
    return string.find(nm, "Grab", 1, true) ~= nil or string.find(nm, "Collect", 1, true) ~= nil
end
local function trackPrompt(p)
    if seedPrompt(p) and not seedSeen[p] then
        seedSeen[p] = true
        seedList[#seedList + 1] = p
    end
end
local function trackScan()
    local ty = myTycoon()
    if ty then
        for _, d in pairs(ty:GetDescendants()) do
            trackPrompt(d)
        end
    end
end

local function doReroll()
    local ty = myTycoon()
    if not ty then return end
    local root = ty:FindFirstChild("TycoonRoot", true)
    if not root then return end
    local reroll = root:FindFirstChild("Reroll", true)
    if not reroll then return end
    for _, d in pairs(reroll:GetDescendants()) do
        if d:IsA("ProximityPrompt") then firePrompt(d) end
    end
    getgenv().CW_Rolls = (getgenv().CW_Rolls or 0) + 1
end

local RunService = game:GetService("RunService")
local smoothPos, smoothLook = nil, nil
getgenv().CW_ShakeWD = (getgenv().CW_ShakeWD or 0) + 1
local shakeWD = getgenv().CW_ShakeWD
local function killGameCam()
    pcall(function()
        local cc = ((gethui and gethui()) or game:GetService("CoreGui")):FindFirstChild("CenterCameraUI")
        if cc then cc:Destroy() end
    end)
    if getgenv().CenterCameraConnection then
        pcall(function() getgenv().CenterCameraConnection:Disconnect() end)
        getgenv().CenterCameraConnection = nil
    end
end
local function gameShakeScale(v)
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local sh = rs:FindFirstChild("Shared", true)
        local ss = sh and sh:FindFirstChild("SettingsShared")
        if ss then
            require(ss).SetLocalValue("CameraShakeEnabled", v)
        end
    end)
end
local function shakeOn()
    killGameCam()
    gameShakeScale(false)
    smoothPos, smoothLook = nil, nil
    pcall(function() RunService:UnbindFromRenderStep("CW_AntiShake") end)
    local function smoothFn(dt)
        if not getgenv().CW_AntiShake then return end
        getgenv().CW_ShakeBeat = os.clock()
        local cam = workspace.CurrentCamera
        if not cam then return end
        if cam.CameraType == Enum.CameraType.Scriptable then
            smoothPos, smoothLook = nil, nil
            return
        end
        if cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
        local cf = cam.CFrame
        local p = cf.Position
        local lv = cf.LookVector
        if not smoothPos or (p - smoothPos).Magnitude > 25 then
            smoothPos, smoothLook = p, lv
            return
        end
        dt = math.max(dt or 0.016, 1 / 240)
        if (p - smoothPos).Magnitude > 1.5 then
            local a = 1 - math.exp(-30 * dt)
            smoothPos = smoothPos:Lerp(p, a)
            local nl = smoothLook:Lerp(lv, a)
            if nl.Magnitude > 1e-4 then smoothLook = nl.Unit end
        else
            local dot = math.clamp(smoothLook:Dot(lv), -1, 1)
            if math.acos(dot) > math.rad(1.5) then
                local a = 1 - math.exp(-25 * dt)
                local nl = smoothLook:Lerp(lv, a)
                if nl.Magnitude > 1e-4 then smoothLook = nl.Unit end
            end
        end
        cam.CFrame = CFrame.lookAt(smoothPos, smoothPos + smoothLook)
    end
    local bound = pcall(function()
        RunService:BindToRenderStep("CW_AntiShake", 3000, smoothFn)
    end)
    if not bound then
        pcall(function()
            RunService:BindToRenderStep("CW_AntiShake", Enum.RenderPriority.Last.Value + 1, smoothFn)
        end)
    end
end
local function shakeOff()
    gameShakeScale(nil)
    pcall(function() RunService:UnbindFromRenderStep("CW_AntiShake") end)
    smoothPos, smoothLook = nil, nil
    local cam = workspace.CurrentCamera
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end
end
if getgenv().CW_AntiShake then pcall(shakeOn) end
task.spawn(function()
    while getgenv().CW_ShakeWD == shakeWD and getgenv().CW_Running do
        if getgenv().CW_AntiShake then
            killGameCam()
            if os.clock() - (getgenv().CW_ShakeBeat or 0) > 2 then
                pcall(shakeOn)
            end
        end
        task.wait(1)
    end
end)

local function inAvatar(v)
    local p = v.Parent
    while p and p ~= workspace do
        if p:IsA("Model") then
            for _, pl in pairs(game:GetService("Players"):GetPlayers()) do
                if pl.Character == p then return true end
            end
            return false
        end
        p = p.Parent
    end
    return false
end
local function lowQPush(v, prop, val)
    local cur
    local ok = pcall(function() cur = v[prop] end)
    if ok and cur ~= val then
        getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, prop, cur }
        pcall(function() v[prop] = val end)
    end
end
local function inHead(v)
    local p = v.Parent
    return p ~= nil and string.lower(p.Name) == "head"
end
local function stripInst(v)
    if inAvatar(v) then return end
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire")
        or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") then
        lowQPush(v, "Enabled", false)
    elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
        lowQPush(v, "Enabled", false)
        lowQPush(v, "Shadows", false)
    elseif v:IsA("SurfaceAppearance") then
        lowQPush(v, "Transparency", 1)
    elseif v:IsA("Decal") or v:IsA("Texture") then
        if not inHead(v) then lowQPush(v, "Transparency", 1) end
    elseif v:IsA("MeshPart") then
        lowQPush(v, "RenderFidelity", Enum.RenderFidelity.Performance)
    elseif v:IsA("BasePart") then
        lowQPush(v, "Material", Enum.Material.SmoothPlastic)
        lowQPush(v, "CastShadow", false)
    elseif v:IsA("Sky") then
        lowQPush(v, "StarCount", 0)
        lowQPush(v, "CelestialBodiesShown", false)
    elseif v:IsA("Atmosphere") then
        lowQPush(v, "Density", 0)
        lowQPush(v, "Glare", 0)
        lowQPush(v, "Haze", 0)
    elseif v:IsA("Clouds") then
        lowQPush(v, "Enabled", false)
    elseif v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect")
        or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
        lowQPush(v, "Enabled", false)
    end
end
local function lowQOn()
    if getgenv().CW_LowQBusy or getgenv().CW_LowQConn then return end
    getgenv().CW_LowQBusy = true
    getgenv().CW_LowQCache = {}
    local S = getgenv().CW_LowQSaved or {}
    getgenv().CW_LowQSaved = S
    local L = game:GetService("Lighting")
    if S.shadows == nil then S.shadows = L.GlobalShadows end
    if S.fog == nil then S.fog = L.FogEnd end
    L.GlobalShadows = false
    L.FogEnd = 100000
    for _, v in pairs(L:GetChildren()) do
        pcall(stripInst, v)
    end
    pcall(function()
        local RS = settings():GetService("RenderSettings")
        if S.ql == nil then S.ql = RS.QualityLevel end
        if S.mdl == nil then S.mdl = RS.MeshPartDetailLevel end
        if S.ebe == nil then S.ebe = RS.EagerBulkExecution end
        RS.QualityLevel = Enum.QualityLevel.Level01
        RS.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        RS.EagerBulkExecution = false
    end)
    pcall(function()
        local UGS = UserSettings():GetService("UserGameSettings")
        if S.sql == nil then S.sql = UGS.SavedQualityLevel end
        UGS.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)
    if S.it == nil then S.it = workspace.InterpolationThrottling end
    pcall(function() workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled end)
    if S.lod == nil then S.lod = workspace.LevelOfDetail end
    pcall(function() workspace.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled end)
    local T = workspace:FindFirstChildOfClass("Terrain")
    if T then
        local dec = true
        pcall(function() dec = T.Decoration end)
        S.terr = { T.WaterWaveSize, T.WaterWaveSpeed, T.WaterReflectance, T.WaterTransparency, dec }
        T.WaterWaveSize = 0
        T.WaterWaveSpeed = 0
        T.WaterReflectance = 0
        T.WaterTransparency = 0
        pcall(function() T.Decoration = false end)
    end
    task.spawn(function()
        local all = {}
        pcall(function() all = workspace:GetDescendants() end)
        for i = 1, #all do
            if not getgenv().CW_LowQ then break end
            pcall(stripInst, all[i])
            if i % 200 == 0 then task.wait() end
        end
    end)
    if getgenv().CW_LowQConn then getgenv().CW_LowQConn:Disconnect() end
    getgenv().CW_LowQConn = workspace.DescendantAdded:Connect(function(v)
        if getgenv().CW_LowQ then pcall(stripInst, v) end
    end)
    getgenv().CW_LowQBusy = false
end
local function lowQOff()
    if getgenv().CW_LowQBusy then return end
    getgenv().CW_LowQBusy = true
    if getgenv().CW_LowQConn then
        getgenv().CW_LowQConn:Disconnect()
        getgenv().CW_LowQConn = nil
    end
    local L = game:GetService("Lighting")
    local s = getgenv().CW_LowQSaved or {}
    if s.shadows ~= nil then L.GlobalShadows = s.shadows end
    if s.fog ~= nil then L.FogEnd = s.fog end
    pcall(function()
        local RS = settings():GetService("RenderSettings")
        if s.ql ~= nil then RS.QualityLevel = s.ql end
        if s.mdl ~= nil then RS.MeshPartDetailLevel = s.mdl end
        if s.ebe ~= nil then RS.EagerBulkExecution = s.ebe end
    end)
    pcall(function()
        local UGS = UserSettings():GetService("UserGameSettings")
        if s.sql ~= nil then UGS.SavedQualityLevel = s.sql end
    end)
    if s.it ~= nil then pcall(function() workspace.InterpolationThrottling = s.it end) end
    if s.lod ~= nil then pcall(function() workspace.LevelOfDetail = s.lod end) end
    if s.terr then
        local T = workspace:FindFirstChildOfClass("Terrain")
        if T then
            T.WaterWaveSize = s.terr[1]
            T.WaterWaveSpeed = s.terr[2]
            T.WaterReflectance = s.terr[3]
            T.WaterTransparency = s.terr[4]
            pcall(function() T.Decoration = s.terr[5] end)
        end
    end
    local cache = getgenv().CW_LowQCache or {}
    getgenv().CW_LowQCache = {}
    task.spawn(function()
        for i = 1, #cache do
            local e = cache[i]
            pcall(function()
                if e[1] and e[1].Parent then e[1][e[2]] = e[3] end
            end)
            if i % 400 == 0 then task.wait() end
        end
        getgenv().CW_LowQBusy = false
    end)
end
if getgenv().CW_LowQ then pcall(lowQOn) end

if not getgenv().CW_AFK then
    getgenv().CW_AFK = true
    pcall(function()
        local VU = game:GetService("VirtualUser")
        LP.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end)
end

pcall(function()
    local rs = game:GetService("ReplicatedStorage")
    local function findEv(n)
        local f = rs:FindFirstChild("SeedReroll", true)
        if f then
            local e = f:FindFirstChild(n)
            if e then return e end
        end
        return rs:FindFirstChild(n, true)
    end
    local rr = findEv("RollResult")
    local started = findEv("RollStarted")
    if rr then
        getgenv().CW_HasRollEvent = true
        rr.OnClientEvent:Connect(function(data)
            if type(data) == "table" then
                local ty = myTycoon()
                local tn = ty and ty.Name or ""
                if (data.TycoonName ~= nil and data.TycoonName == tn)
                    or (data.TriggeredByUserId ~= nil and data.TriggeredByUserId == LP.UserId) then
                    local rv = tonumber(data.RollVersion) or 0
                    if rv >= (getgenv().CW_RollVersion or 0) then
                        getgenv().CW_RollVersion = rv
                        getgenv().CW_Need = tonumber(data.Count) or #(data.Results or {})
                        getgenv().CW_Rolled = true
                        getgenv().CW_TResult = os.clock()
                    end
                end
            end
        end)
    end
    if started then
        started.OnClientEvent:Connect(function()
            getgenv().CW_TStarted = os.clock()
        end)
    end
end)

local function seedCount()
    local c = 0
    local ty = myTycoon()
    if ty then
        for _, d in pairs(ty:GetDescendants()) do
            if d:IsA("Folder") and string.find(d.Name, "Generated", 1, true) then
                for _, s in pairs(d:GetChildren()) do
                    if string.find(s.Name, "GeneratedSeed", 1, true) then c = c + 1 end
                end
            end
        end
    end
    return c
end

task.spawn(function()
    while getgenv().CW_Running and getgenv().CW_Gen == myGen do
        if getgenv().CW_Farm then
            getgenv().CW_TFire = os.clock()
            getgenv().CW_Rolled = false
            getgenv().CW_Need = 0
            getgenv().CW_Phase = "reroll"
            pcall(doReroll)
            getgenv().CW_Cycles = (getgenv().CW_Cycles or 0) + 1
            if getgenv().CW_Cycles % 20 == 0 then pcall(trackScan) end
            local rt = os.clock()
            local rollCap = getgenv().CW_HasRollEvent and (getgenv().CW_RollTimeout or 3) or 0.3
            while not getgenv().CW_Rolled and os.clock() - rt < rollCap do
                if not (getgenv().CW_Farm and getgenv().CW_Running and getgenv().CW_Gen == myGen) then break end
                task.wait(0.05)
            end
            local tR = os.clock()
            pcall(trackScan)
            local tS = 0
            local t0 = os.clock()
            while os.clock() - t0 < (getgenv().CW_SpawnCap or 4) do
                if not (getgenv().CW_Farm and getgenv().CW_Running and getgenv().CW_Gen == myGen) then break end
                local c = 0
                pcall(function() c = seedCount() end)
                if c > 0 then tS = os.clock() break end
                task.wait(0.1)
            end
            local calm = 0
            local t1 = os.clock()
            if getgenv().CW_Frenzy then pcall(fireCollectRemotes) end
            while os.clock() - t1 < (getgenv().CW_CollectCap or 4) do
                if not (getgenv().CW_Farm and getgenv().CW_Running and getgenv().CW_Gen == myGen) then break end
                pcall(grabAll)
                local c = 0
                pcall(function() c = seedCount() end)
                getgenv().CW_Phase = "collect (" .. c .. ")"
                if c <= 0 then
                    calm = calm + 1
                    if calm >= 2 then break end
                else
                    calm = 0
                end
                task.wait(0.1)
            end
            local tF = getgenv().CW_TFire or tR
            if tS == 0 then tS = tR end
            getgenv().CW_LastBreak = string.format("srv %.1f spw %.1f col %.1f", tR - tF, tS - tR, os.clock() - tS)
        else
            task.wait(0.3)
        end
    end
end)

task.spawn(function()
    while getgenv().CW_Running and getgenv().CW_Gen == myGen do
        pcall(function()
            local g = ((gethui and gethui()) or game:GetService("CoreGui")):FindFirstChild("CarveWoodUI")
            if not g then return end
            local el = math.floor((getgenv().CW_FarmTime or 0)
                + (getgenv().CW_FarmSince and (os.clock() - getgenv().CW_FarmSince) or 0))
            local hh = math.floor(el / 3600)
            local mm = math.floor((el % 3600) / 60)
            local ss = el % 60
            local tstr = hh > 0 and string.format("%d:%02d:%02d", hh, mm, ss)
                or string.format("%02d:%02d", mm, ss)
            local brk = getgenv().CW_LastBreak or ""
            local ph = getgenv().CW_Phase or (getgenv().CW_Farm and "running" or "idle")
            local r = g:FindFirstChild("CWValRolls", true)
            if r then r.Text = tostring(getgenv().CW_Rolls or 0) end
            local t = g:FindFirstChild("CWValTime", true)
            if t then t.Text = tstr end
            local p = g:FindFirstChild("CWValPhase", true)
            if p then p.Text = tostring(ph) end
            local sb = g:FindFirstChild("CWSubPhase", true)
            if sb then sb.Text = brk end
        end)
        task.wait(getgenv().CW_Delay)
    end
end)

--[[ CarveWood v9.0 UI | reference style | green accent | 820x520 + mobile scale ]]
local parent = (gethui and gethui()) or game:GetService("CoreGui")
local old = parent:FindFirstChild("CarveWoodUI")
if old then old:Destroy() end

local ACCENT = Color3.fromRGB(111, 207, 127)
local ACCENT_D = Color3.fromRGB(63, 143, 79)
local BG = Color3.fromRGB(15, 15, 21)
local SIDE = Color3.fromRGB(20, 20, 28)
local CARD = Color3.fromRGB(33, 33, 47)
local CTRL = Color3.fromRGB(48, 48, 66)
local STROKE = Color3.fromRGB(62, 62, 84)
local TXT = Color3.fromRGB(238, 238, 248)
local MUT = Color3.fromRGB(180, 180, 200)
local GRN = Color3.fromRGB(140, 220, 150)

local gui = Instance.new("ScreenGui")
gui.Name = "CarveWoodUI"
gui.ResetOnSpawn = false
gui.Parent = parent

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 820, 0, 520)
main.Position = UDim2.new(0.5, -410, 0.5, -260)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

do
    local sc = Instance.new("UIScale")
    sc.Parent = main
    pcall(function()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local s = math.min(vp.X / 900, vp.Y / 620)
        if s > 1 then s = 1 end
        if s < 0.65 then s = 0.65 end
        sc.Scale = s
    end)
end

local collapsed = false
local sheenGrads = {}
local allCards = {}
local currentPage = "Home"
local addSheen

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = BG
header.BorderSizePixel = 0
header.Parent = main

local hline = Instance.new("Frame")
hline.Size = UDim2.new(1, 0, 0, 1)
hline.Position = UDim2.new(0, 0, 1, -1)
hline.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
hline.BorderSizePixel = 0
hline.Parent = header

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 12, 0, 12)
dot.Position = UDim2.new(0, 16, 0.5, -6)
dot.BackgroundColor3 = ACCENT
dot.BorderSizePixel = 0
dot.Parent = header
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 36, 0, 0)
title.Size = UDim2.new(0, 168, 1, 0)
title.BackgroundTransparency = 1
title.Text = "CarveWood"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = TXT
title.Parent = header

local function pill(text, x, color)
    local p = Instance.new("Frame")
    p.Position = UDim2.new(0, x, 0.5, -12)
    p.Size = UDim2.new(0, 64, 0, 24)
    p.BackgroundColor3 = Color3.fromRGB(33, 33, 47)
    p.BorderSizePixel = 0
    p.Parent = header
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, 8)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextColor3 = color
    l.Parent = p
    return p
end
local pillV = pill("v9.0", 212, ACCENT)
local pillK = pill("no key", 284, MUT)

local side = Instance.new("Frame")
side.Name = "Side"
side.Position = UDim2.new(0, 0, 0, 60)
side.Size = UDim2.new(0, 190, 1, -60)
side.BackgroundColor3 = SIDE
side.BorderSizePixel = 0
side.Parent = main

local sdiv = Instance.new("Frame")
sdiv.Size = UDim2.new(0, 1, 1, 0)
sdiv.Position = UDim2.new(1, -1, 0, 0)
sdiv.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
sdiv.BorderSizePixel = 0
sdiv.Parent = side

local search = Instance.new("TextBox")
search.Name = "Search"
search.Position = UDim2.new(0, 12, 0, 12)
search.Size = UDim2.new(1, -24, 0, 40)
search.BackgroundColor3 = CARD
search.Text = ""
search.PlaceholderText = "Search..."
search.PlaceholderColor3 = MUT
search.Font = Enum.Font.Gotham
search.TextSize = 14
search.TextXAlignment = Enum.TextXAlignment.Left
search.TextColor3 = TXT
search.BorderSizePixel = 0
search.ClearTextOnFocus = false
search.Parent = side
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 10)
do
    local sst = Instance.new("UIStroke", search)
    sst.Color = STROKE
    sst.Thickness = 1
    sst.Transparency = 0.55
    sst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end
local spad = Instance.new("UIPadding", search)
spad.PaddingLeft = UDim.new(0, 14)
spad.PaddingRight = UDim.new(0, 14)

local navHolder = Instance.new("Frame")
navHolder.Position = UDim2.new(0, 12, 0, 60)
navHolder.Size = UDim2.new(1, -24, 1, -72)
navHolder.BackgroundTransparency = 1
navHolder.Parent = side
local navList = Instance.new("UIListLayout", navHolder)
navList.Padding = UDim.new(0, 6)
navList.SortOrder = Enum.SortOrder.LayoutOrder

local navBtns = {}
local function navItem(name, order)
    local b = Instance.new("TextButton")
    b.Name = "Nav_" .. name
    b.Size = UDim2.new(1, 0, 0, 48)
    b.BackgroundColor3 = SIDE
    b.Text = ""
    b.BorderSizePixel = 0
    b.LayoutOrder = order
    b.AutoButtonColor = false
    b.Parent = navHolder
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local d = Instance.new("Frame")
    d.Name = "Dot"
    d.Size = UDim2.new(0, 10, 0, 10)
    d.Position = UDim2.new(0, 16, 0.5, -5)
    d.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
    d.BorderSizePixel = 0
    d.Parent = b
    Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 38, 0, 0)
    l.Size = UDim2.new(1, -48, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.Font = Enum.Font.GothamBold
    l.TextSize = 15
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = MUT
    l.Parent = b
    navBtns[name] = b
    addSheen(b)
    b.MouseButton1Click:Connect(function()
        currentPage = name
        paintNav()
        showPage()
        applySearch()
    end)
    return b
end

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.new(0, 190, 0, 60)
content.Size = UDim2.new(1, -190, 1, -60)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
local function makePage(name)
    local sc = Instance.new("ScrollingFrame")
    sc.Name = "Page_" .. name
    sc.Size = UDim2.new(1, 0, 1, 0)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 90)
    sc.CanvasSize = UDim2.new(0, 0, 0, 0)
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.Visible = false
    sc.Parent = content
    local pad = Instance.new("UIPadding", sc)
    pad.PaddingLeft = UDim.new(0, 20)
    pad.PaddingRight = UDim.new(0, 20)
    pad.PaddingTop = UDim.new(0, 16)
    pad.PaddingBottom = UDim.new(0, 16)
    local list = Instance.new("UIListLayout", sc)
    list.Padding = UDim.new(0, 14)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    pages[name] = sc
    return sc
end
local homePage = makePage("Home")
local farmPage = makePage("Farm")
local perfPage = makePage("Performance")

function paintNav()
    for name, b in pairs(navBtns) do
        local on = (name == currentPage)
        b.BackgroundColor3 = on and CARD or SIDE
        local d = b:FindFirstChild("Dot")
        if d then d.BackgroundColor3 = on and ACCENT or Color3.fromRGB(100, 100, 122) end
        local l = b:FindFirstChildOfClass("TextLabel")
        if l then l.TextColor3 = on and TXT or MUT end
    end
end
function showPage()
    for name, pg in pairs(pages) do
        pg.Visible = (name == currentPage)
    end
end
function applySearch()
    local q = string.lower(search.Text or "")
    for _, c in ipairs(allCards) do
        if c.page == currentPage then
            c.frame.Visible = (q == "" or string.find(c.text, q, 1, true) ~= nil)
        else
            c.frame.Visible = (q == "")
        end
    end
end
search:GetPropertyChangedSignal("Text"):Connect(applySearch)

addSheen = function(card, phase)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.34, 1),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(0.66, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    g.Rotation = 20
    g.Offset = Vector2.new(2, 0)
    g.Parent = card
    sheenGrads[#sheenGrads + 1] = g
end

local function section(page, text, order)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 24)
    s.BackgroundTransparency = 1
    s.LayoutOrder = order
    s.Parent = page
    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0, 0, 0, 4)
    bar.Size = UDim2.new(0, 4, 0, 16)
    bar.BackgroundColor3 = ACCENT
    bar.BorderSizePixel = 0
    bar.Parent = s
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 14, 0, 0)
    l.Size = UDim2.new(0, 220, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = TXT
    l.Parent = s
    local line = Instance.new("Frame")
    line.Position = UDim2.new(0, 200, 0.5, 0)
    line.Size = UDim2.new(1, -200, 0, 2)
    line.BackgroundColor3 = Color3.fromRGB(70, 70, 95)
    line.BorderSizePixel = 0
    line.Parent = s
    local lg = Instance.new("UIGradient", line)
    lg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
end

local function card(page, pageName, title, desc, order, h)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, h or 72)
    row.BackgroundColor3 = CARD
    row.BorderSizePixel = 0
    row.ClipsDescendants = true
    row.LayoutOrder = order
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 16)
    local st = Instance.new("UIStroke", row)
    st.Color = STROKE
    st.Thickness = 1
    st.Transparency = 0.45
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    addSheen(row)
    local t = Instance.new("TextLabel")
    t.Position = UDim2.new(0, 20, 0, 8)
    t.Size = UDim2.new(1, -250, 0, 24)
    t.BackgroundTransparency = 1
    t.Text = title
    t.Font = Enum.Font.GothamBold
    t.TextSize = 18
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = TXT
    t.Parent = row
    local d = Instance.new("TextLabel")
    d.Position = UDim2.new(0, 20, 0, 34)
    d.Size = UDim2.new(1, -250, 0, 30)
    d.BackgroundTransparency = 1
    d.Text = desc
    d.Font = Enum.Font.Gotham
    d.TextSize = 15
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextYAlignment = Enum.TextYAlignment.Top
    d.TextWrapped = true
    d.TextColor3 = MUT
    d.Parent = row
    allCards[#allCards + 1] = { frame = row, page = pageName, text = string.lower(title .. " " .. desc) }
    return row
end

local function toggle(row, get, set)
    local b = Instance.new("TextButton")
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, -20, 0.5, 0)
    b.Size = UDim2.new(0, 60, 0, 32)
    b.Text = ""
    b.AutoButtonColor = false
    b.BackgroundColor3 = CTRL
    b.BorderSizePixel = 0
    b.Parent = row
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local grad = Instance.new("UIGradient", b)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ACCENT),
        ColorSequenceKeypoint.new(1, ACCENT_D),
    })
    grad.Enabled = false
    local dot2 = Instance.new("Frame")
    dot2.Size = UDim2.new(0, 26, 0, 26)
    dot2.Position = UDim2.new(0, 3, 0.5, -13)
    dot2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot2.BorderSizePixel = 0
    dot2.Parent = b
    Instance.new("UICorner", dot2).CornerRadius = UDim.new(1, 0)
    local function paint()
        if get() then
            grad.Enabled = true
            dot2.Position = UDim2.new(1, -29, 0.5, -13)
        else
            grad.Enabled = false
            b.BackgroundColor3 = CTRL
            dot2.Position = UDim2.new(0, 3, 0.5, -13)
        end
    end
    b.MouseButton1Click:Connect(function() set(not get()) paint() end)
    paint()
    return { repaint = paint }
end

section(homePage, "STATS", 1)
do
    local statRow = Instance.new("Frame")
    statRow.Size = UDim2.new(1, 0, 0, 120)
    statRow.BackgroundTransparency = 1
    statRow.LayoutOrder = 2
    statRow.Parent = homePage
    local statList = Instance.new("UIListLayout", statRow)
    statList.FillDirection = Enum.FillDirection.Horizontal
    statList.Padding = UDim.new(0, 14)
    statList.SortOrder = Enum.SortOrder.LayoutOrder
    local function statTile(label, order, valName, valSize, valColor, subName, subText)
        local tile = Instance.new("Frame")
        tile.Size = UDim2.new(0.3333, -10, 1, 0)
        tile.BackgroundColor3 = CARD
        tile.BorderSizePixel = 0
        tile.ClipsDescendants = true
        tile.LayoutOrder = order
        tile.Parent = statRow
        Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 16)
        local sst = Instance.new("UIStroke", tile)
        sst.Color = STROKE
        sst.Thickness = 1
        sst.Transparency = 0.45
        sst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        addSheen(tile)
        local lab = Instance.new("TextLabel")
        lab.Position = UDim2.new(0, 16, 0, 10)
        lab.Size = UDim2.new(1, -32, 0, 16)
        lab.BackgroundTransparency = 1
        lab.Text = label
        lab.Font = Enum.Font.GothamBold
        lab.TextSize = 12
        lab.TextXAlignment = Enum.TextXAlignment.Left
        lab.TextColor3 = MUT
        lab.Parent = tile
        local val = Instance.new("TextLabel")
        val.Name = valName
        val.Position = UDim2.new(0, 16, 0, 30)
        val.Size = UDim2.new(1, -32, 0, 40)
        val.BackgroundTransparency = 1
        val.Text = "-"
        val.Font = Enum.Font.GothamBold
        val.TextSize = valSize
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.TextTruncate = Enum.TextTruncate.AtEnd
        val.TextColor3 = valColor
        val.Parent = tile
        local sub = Instance.new("TextLabel")
        sub.Name = subName
        sub.Position = UDim2.new(0, 16, 0, 74)
        sub.Size = UDim2.new(1, -32, 0, 20)
        sub.BackgroundTransparency = 1
        sub.Text = subText
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 12
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd
        sub.TextColor3 = MUT
        sub.Parent = tile
        allCards[#allCards + 1] = { frame = tile, page = "Home", text = string.lower(label .. " stats") }
    end
    statTile("REROLLS", 1, "CWValRolls", 28, GRN, "CWSubRolls", "seed rerolls")
    statTile("FARM TIME", 2, "CWValTime", 28, TXT, "CWSubTime", "active total")
    statTile("PHASE", 3, "CWValPhase", 22, TXT, "CWSubPhase", "")
end

section(farmPage, "FARM", 1)
toggle(card(farmPage, "Farm", "Auto Farm Seeds", "Reroll, wait, collect until empty.", 2),
    function() return getgenv().CW_Farm end,
    function(v)
        if v then getgenv().CW_FarmSince = os.clock()
        elseif getgenv().CW_FarmSince then
            getgenv().CW_FarmTime = (getgenv().CW_FarmTime or 0) + (os.clock() - getgenv().CW_FarmSince)
            getgenv().CW_FarmSince = nil
        end
        getgenv().CW_Farm = v
        if v then
            if not getgenv().CW_AntiShake then
                getgenv().CW_AutoShake = true
                getgenv().CW_AntiShake = true
                pcall(shakeOn)
            end
        elseif getgenv().CW_AutoShake then
            getgenv().CW_AutoShake = false
            getgenv().CW_AntiShake = false
            pcall(shakeOff)
        end
    end)
toggle(card(farmPage, "Farm", "Auto Frenzy", "Fire collect remotes each cycle. Never touches Alien.", 3),
    function() return getgenv().CW_Frenzy end,
    function(v) getgenv().CW_Frenzy = v end)

section(perfPage, "PERFORMANCE", 1)
toggle(card(perfPage, "Performance", "Low Quality", "Strip effects, lights, shadows. Restores exactly.", 2),
    function() return getgenv().CW_LowQ end,
    function(v) getgenv().CW_LowQ = v if v then lowQOn() else lowQOff() end end)

local bgSheen = Instance.new("Frame")
bgSheen.Name = "BgSheen"
bgSheen.Size = UDim2.new(1, 0, 1, 0)
bgSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bgSheen.BackgroundTransparency = 0
bgSheen.BorderSizePixel = 0
bgSheen.Active = false
bgSheen.ZIndex = 0
bgSheen.Parent = main
do
    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    bgGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.4, 1),
        NumberSequenceKeypoint.new(0.5, 0.88),
        NumberSequenceKeypoint.new(0.6, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    bgGrad.Rotation = 20
    bgGrad.Offset = Vector2.new(2, 0)
    bgGrad.Parent = bgSheen
    sheenGrads[#sheenGrads + 1] = bgGrad
end

local btnMin = Instance.new("TextButton")
btnMin.AnchorPoint = Vector2.new(1, 0.5)
btnMin.Position = UDim2.new(1, -58, 0.5, 0)
btnMin.Size = UDim2.new(0, 38, 0, 38)
btnMin.Text = "–"
btnMin.Font = Enum.Font.GothamBold
btnMin.TextSize = 18
btnMin.TextColor3 = TXT
btnMin.BackgroundColor3 = Color3.fromRGB(38, 38, 54)
btnMin.BorderSizePixel = 0
btnMin.AutoButtonColor = true
btnMin.Parent = header
Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, 12)
do
    local mst = Instance.new("UIStroke", btnMin)
    mst.Color = STROKE
    mst.Thickness = 1
    mst.Transparency = 0.5
    mst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local btnX = Instance.new("TextButton")
btnX.AnchorPoint = Vector2.new(1, 0.5)
btnX.Position = UDim2.new(1, -12, 0.5, 0)
btnX.Size = UDim2.new(0, 38, 0, 38)
btnX.Text = "X"
btnX.Font = Enum.Font.GothamBold
btnX.TextSize = 16
btnX.TextColor3 = Color3.fromRGB(255, 150, 150)
btnX.BackgroundColor3 = Color3.fromRGB(38, 38, 54)
btnX.BorderSizePixel = 0
btnX.AutoButtonColor = true
btnX.Parent = header
Instance.new("UICorner", btnX).CornerRadius = UDim.new(0, 12)
do
    local xst = Instance.new("UIStroke", btnX)
    xst.Color = STROKE
    xst.Thickness = 1
    xst.Transparency = 0.5
    xst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

navItem("Home", 1)
navItem("Farm", 2)
navItem("Performance", 3)
addSheen(search)
paintNav()
showPage()

btnMin.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    side.Visible = not collapsed
    content.Visible = not collapsed
    pillV.Visible = not collapsed
    pillK.Visible = not collapsed
    btnMin.Text = collapsed and "+" or "–"
    main.Size = collapsed and UDim2.new(0, 300, 0, 60) or UDim2.new(0, 820, 0, 520)
end)
btnX.MouseButton1Click:Connect(function()
    getgenv().CW_AntiShake = false
    getgenv().CW_Farm = false
    getgenv().CW_Frenzy = false
    getgenv().CW_Running = false
    pcall(shakeOff)
    if getgenv().CW_LowQ then getgenv().CW_LowQ = false pcall(lowQOff) end
    gui:Destroy()
end)

task.spawn(function()
    while gui.Parent do
        local paused = collapsed or getgenv().CW_LowQ
        local off
        if paused then
            off = Vector2.new(2, 0)
        else
            local t = (os.clock() / 7) % 1
            off = Vector2.new(1.5 - 3 * t, 0)
        end
        for _, gr in ipairs(sheenGrads) do
            pcall(function() gr.Offset = off end)
        end
        task.wait(0.06)
    end
end)
