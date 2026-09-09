--[[ CarveWood v7.3 | Delta mobile | no login, no key ]]
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

getgenv().CW_AutoSeed = getgenv().CW_AutoSeed or false
getgenv().CW_AutoReroll = getgenv().CW_AutoReroll or false
getgenv().CW_Delay = getgenv().CW_Delay or 0.5
getgenv().CW_Grabbed = getgenv().CW_Grabbed or 0
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

local function fireCollectRemotes()
    local f = game:GetService("ReplicatedStorage"):FindFirstChild("REM", true)
    if not f then return end
    for _, d in pairs(f:GetChildren()) do
        if d:IsA("RemoteFunction") then
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
    getgenv().CW_Tries = (getgenv().CW_Tries or 0) + 1
    pcall(function() getgenv().CW_Last = p:GetFullName() end)
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

local hookedP = {}
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

local function watchPrompt(p)
    if hookedP[p] then return end
    hookedP[p] = true
    task.spawn(function()
        for _ = 1, 2 do
            if not getgenv().CW_AutoSeed or getgenv().CW_Farm then break end
            task.wait(0.5)
            if p.Parent and collectSeed(p) then
                getgenv().CW_Grabbed = getgenv().CW_Grabbed + 1
            end
        end
    end)
end

local function hookTycoon(ty)
    for _, d in pairs(ty:GetDescendants()) do
        trackPrompt(d)
        if seedPrompt(d) then watchPrompt(d) end
    end
    ty.DescendantAdded:Connect(function(d)
        pcall(function()
            trackPrompt(d)
            if seedPrompt(d) then watchPrompt(d) end
        end)
    end)
end

local function hookAll()
    local ty = myTycoon()
    if ty then pcall(hookTycoon, ty) end
end
pcall(hookAll)

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
local function shakeOn()
    pcall(function()
        local cc = ((gethui and gethui()) or game:GetService("CoreGui")):FindFirstChild("CenterCameraUI")
        if cc then cc:Destroy() end
    end)
    if getgenv().CenterCameraConnection then
        pcall(function() getgenv().CenterCameraConnection:Disconnect() end)
        getgenv().CenterCameraConnection = nil
    end
    smoothPos, smoothLook = nil, nil
    pcall(function() RunService:UnbindFromRenderStep("CW_AntiShake") end)
    RunService:BindToRenderStep("CW_AntiShake", Enum.RenderPriority.Last.Value + 1, function()
        if not getgenv().CW_AntiShake then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        if cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
        local cf = cam.CFrame
        local p = cf.Position
        local a = getgenv().CW_ShakeSmooth or 0.5
        if not smoothPos or (p - smoothPos).Magnitude > 25 then
            smoothPos, smoothLook = p, cf.LookVector
            return
        end
        smoothPos = smoothPos:Lerp(p, a)
        local lv = smoothLook:Lerp(cf.LookVector, a)
        if lv.Magnitude > 1e-4 then smoothLook = lv.Unit end
        cam.CFrame = CFrame.lookAt(smoothPos, smoothPos + smoothLook)
    end)
end
local function shakeOff()
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
local function stripInst(v)
    if inAvatar(v) then return end
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire")
        or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") then
        if v.Enabled then
            getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "Enabled", true }
            v.Enabled = false
        end
    elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
        if v.Enabled then
            getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "Enabled", true }
            v.Enabled = false
        end
        if v.Shadows then
            getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "Shadows", true }
            v.Shadows = false
        end
    elseif v:IsA("SurfaceAppearance") then
        if v.Transparency ~= 1 then
            getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "Transparency", v.Transparency }
            v.Transparency = 1
        end
    elseif v:IsA("MeshPart") then
        if v.RenderFidelity ~= Enum.RenderFidelity.Performance then
            getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "RenderFidelity", v.RenderFidelity }
            v.RenderFidelity = Enum.RenderFidelity.Performance
        end
    elseif v:IsA("BasePart") then
        if v.CastShadow then
            getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "CastShadow", true }
            v.CastShadow = false
        end
    end
end
local function lowQOn()
    if getgenv().CW_LowQBusy or getgenv().CW_LowQConn then return end
    getgenv().CW_LowQBusy = true
    getgenv().CW_LowQCache = {}
    local L = game:GetService("Lighting")
    if not getgenv().CW_LowQSaved then
        getgenv().CW_LowQSaved = { shadows = L.GlobalShadows }
    end
    L.GlobalShadows = false
    for _, v in pairs(L:GetChildren()) do
        if v:IsA("Clouds") then
            if v.Enabled then
                getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "Enabled", true }
                v.Enabled = false
            end
        elseif v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect")
            or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
            if v.Enabled then
                getgenv().CW_LowQCache[#getgenv().CW_LowQCache + 1] = { v, "Enabled", true }
                v.Enabled = false
            end
        end
    end
    if getgenv().CW_LowQSaved.it == nil then
        getgenv().CW_LowQSaved.it = workspace.InterpolationThrottling
    end
    pcall(function() workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled end)
    local T = workspace:FindFirstChildOfClass("Terrain")
    if T then
        local dec = true
        pcall(function() dec = T.Decoration end)
        getgenv().CW_LowQSaved.terr = { T.WaterWaveSize, T.WaterWaveSpeed, T.WaterReflectance, T.WaterTransparency, dec }
        T.WaterWaveSize = 0
        T.WaterWaveSpeed = 0
        T.WaterReflectance = 0
        T.WaterTransparency = 1
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
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.DistanceBased end)
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
    local s = getgenv().CW_LowQSaved
    if s then
        L.GlobalShadows = s.shadows
        if s.it ~= nil then pcall(function() workspace.InterpolationThrottling = s.it end) end
        if s.fog then L.FogEnd = s.fog end
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
    end
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
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
        if getgenv().CW_AutoSeed and not getgenv().CW_Farm then pcall(grabAll) end
        if getgenv().CW_AutoReroll and not getgenv().CW_Farm then pcall(doReroll) end
        pcall(function()
            local g = ((gethui and gethui()) or game:GetService("CoreGui")):FindFirstChild("CarveWoodUI")
            local f = g and g:FindFirstChild("CWFoot", true)
            if f then
                local el = math.floor((getgenv().CW_FarmTime or 0)
                    + (getgenv().CW_FarmSince and (os.clock() - getgenv().CW_FarmSince) or 0))
                local hh = math.floor(el / 3600)
                local mm = math.floor((el % 3600) / 60)
                local ss = el % 60
                local tstr = hh > 0 and string.format("%d:%02d:%02d", hh, mm, ss)
                    or string.format("%02d:%02d", mm, ss)
                local brk = getgenv().CW_LastBreak or ""
                f.Text = "Rerolls: " .. tostring(getgenv().CW_Rolls or 0) .. "  |  " .. tstr .. (brk ~= "" and "  |  " .. brk or "")
            end
        end)
        task.wait(getgenv().CW_Delay)
    end
end)

--[[ clean dark ui ]]
local parent = (gethui and gethui()) or game:GetService("CoreGui")
local old = parent:FindFirstChild("CarveWoodUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "CarveWoodUI"
gui.ResetOnSpawn = false
gui.Parent = parent

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, 260)
main.Position = UDim2.new(0.5, -220, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local side = Instance.new("Frame")
side.Size = UDim2.new(0, 130, 1, 0)
side.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
side.BorderSizePixel = 0
side.Parent = main
Instance.new("UICorner", side).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 44)
title.BackgroundTransparency = 1
title.Text = "CARVEWOOD"
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Parent = side

local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(1, 0, 0, 16)
ver.Position = UDim2.new(0, 0, 0, 40)
ver.BackgroundTransparency = 1
ver.Text = "v7.3  |  no key"
ver.Font = Enum.Font.Gotham
ver.TextSize = 11
ver.TextColor3 = Color3.fromRGB(130, 130, 150)
ver.Parent = side

local body = Instance.new("Frame")
body.Position = UDim2.new(0, 142, 0, 12)
body.Size = UDim2.new(1, -154, 1, -48)
body.BackgroundTransparency = 1
body.Parent = main

local function section(text, y)
    local s = Instance.new("TextLabel")
    s.Position = UDim2.new(0, 0, 0, y)
    s.Size = UDim2.new(1, 0, 0, 20)
    s.BackgroundTransparency = 1
    s.Text = "  |  " .. text
    s.Font = Enum.Font.GothamBold
    s.TextSize = 12
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.TextColor3 = Color3.fromRGB(150, 180, 255)
    s.Parent = body
end

local function toggle(text, y, get, set)
    local row = Instance.new("Frame")
    row.Position = UDim2.new(0, 0, 0, y)
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = body
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -56, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(225, 225, 235)
    l.Parent = row
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(1, -48, 0.5, -11)
    b.Size = UDim2.new(0, 48, 0, 22)
    b.Text = ""
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    b.BorderSizePixel = 0
    b.Parent = row
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
    dot.BorderSizePixel = 0
    dot.Parent = b
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local function paint()
        if get() then
            b.BackgroundColor3 = Color3.fromRGB(150, 180, 255)
            dot.Position = UDim2.new(1, -19, 0.5, -8)
            dot.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        else
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            dot.Position = UDim2.new(0, 3, 0.5, -8)
            dot.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
        end
    end
    b.MouseButton1Click:Connect(function() set(not get()) paint() end)
    paint()
end

section("FARM", 0)
toggle("Auto Farm Seeds", 24, function() return getgenv().CW_Farm end,
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
toggle("Auto Frenzy", 56, function() return getgenv().CW_Frenzy end,
    function(v) getgenv().CW_Frenzy = v end)
local afk = Instance.new("TextLabel")
afk.Position = UDim2.new(0, 0, 0, 88)
afk.Size = UDim2.new(1, 0, 0, 14)
afk.BackgroundTransparency = 1
afk.Text = "AntiAFK always on"
afk.Font = Enum.Font.Gotham
afk.TextSize = 11
afk.TextXAlignment = Enum.TextXAlignment.Left
afk.TextColor3 = Color3.fromRGB(110, 200, 130)
afk.Parent = body

section("PERF", 104)
toggle("Low Quality", 128, function() return getgenv().CW_LowQ end,
    function(v) getgenv().CW_LowQ = v if v then lowQOn() else lowQOff() end end)

local foot = Instance.new("TextLabel")
foot.Name = "CWFoot"
foot.Position = UDim2.new(0, 142, 1, -28)
foot.Size = UDim2.new(1, -154, 0, 16)
foot.BackgroundTransparency = 1
foot.Text = "Rerolls: 0  |  00:00"
foot.Font = Enum.Font.Gotham
foot.TextSize = 11
foot.TextXAlignment = Enum.TextXAlignment.Left
foot.TextColor3 = Color3.fromRGB(110, 200, 130)
foot.Parent = main

local btnMin = Instance.new("TextButton")
btnMin.AnchorPoint = Vector2.new(1, 0)
btnMin.Position = UDim2.new(1, -40, 0, 8)
btnMin.Size = UDim2.new(0, 26, 0, 26)
btnMin.Text = "–"
btnMin.Font = Enum.Font.GothamBold
btnMin.TextSize = 14
btnMin.TextColor3 = Color3.fromRGB(235, 235, 245)
btnMin.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
btnMin.BorderSizePixel = 0
btnMin.Parent = main
Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, 6)

local btnX = Instance.new("TextButton")
btnX.AnchorPoint = Vector2.new(1, 0)
btnX.Position = UDim2.new(1, -8, 0, 8)
btnX.Size = UDim2.new(0, 26, 0, 26)
btnX.Text = "X"
btnX.Font = Enum.Font.GothamBold
btnX.TextSize = 13
btnX.TextColor3 = Color3.fromRGB(255, 120, 120)
btnX.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
btnX.BorderSizePixel = 0
btnX.Parent = main
Instance.new("UICorner", btnX).CornerRadius = UDim.new(0, 6)

local collapsed = false
btnMin.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    side.Visible = not collapsed
    body.Visible = not collapsed
    foot.Visible = not collapsed
    btnMin.Text = collapsed and "+" or "–"
    main.Size = collapsed and UDim2.new(0, 190, 0, 42) or UDim2.new(0, 440, 0, 260)
end)
btnX.MouseButton1Click:Connect(function()
    getgenv().CW_AutoSeed = false
    getgenv().CW_AutoReroll = false
    getgenv().CW_AntiShake = false
    getgenv().CW_Farm = false
    getgenv().CW_Frenzy = false
    getgenv().CW_Running = false
    pcall(shakeOff)
    if getgenv().CW_LowQ then getgenv().CW_LowQ = false pcall(lowQOff) end
    gui:Destroy()
end)
