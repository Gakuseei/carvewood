--[[ CarveWood v2.5 | Delta mobile | kein login, kein key ]]
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

getgenv().CW_AutoSeed = getgenv().CW_AutoSeed or false
getgenv().CW_AutoReroll = getgenv().CW_AutoReroll or false
getgenv().CW_Delay = getgenv().CW_Delay or 0.5
getgenv().CW_Grabbed = getgenv().CW_Grabbed or 0
getgenv().CW_Running = true
getgenv().CW_Farm = getgenv().CW_Farm or false
getgenv().CW_Rolled = false
getgenv().CW_AntiShake = getgenv().CW_AntiShake or false

local function myTycoon()
    local folder = workspace:FindFirstChild("Tycoons")
    if not folder then return nil end
    for _, t in pairs(folder:GetChildren()) do
        local o = t:FindFirstChild("Owner", true)
        if o and tostring(o.Value) == LP.Name then return t end
    end
    return folder:FindFirstChild("Tycoon3")
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
            pcall(function() d:InvokeServer({}) end)
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
    pcall(fireCollectRemotes)
    return true
end

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
    for _, d in pairs(ty:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local nm = d.Name
            if string.find(nm, "Grab", 1, true) or string.find(nm, "Collect", 1, true) then
                n = n + 1
                runCollect(d)
            end
        end
    end
    local t0 = os.clock()
    while active > 0 and os.clock() - t0 < 1 do task.wait(0.05) end
    return n
end

local hookedP = {}
local function seedPrompt(p)
    if typeof(p) ~= "Instance" or not p:IsA("ProximityPrompt") then return false end
    local nm = p.Name
    return string.find(nm, "Grab", 1, true) ~= nil or string.find(nm, "Collect", 1, true) ~= nil
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
        if seedPrompt(d) then watchPrompt(d) end
    end
    ty.DescendantAdded:Connect(function(d)
        pcall(function()
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
end

local RunService = game:GetService("RunService")
local function shakeOn()
    pcall(function()
        local cc = ((gethui and gethui()) or game:GetService("CoreGui")):FindFirstChild("CenterCameraUI")
        if cc then cc:Destroy() end
    end)
    if getgenv().CenterCameraConnection then
        pcall(function() getgenv().CenterCameraConnection:Disconnect() end)
        getgenv().CenterCameraConnection = nil
    end
    if getgenv().CW_ShakeConn then getgenv().CW_ShakeConn:Disconnect() end
    getgenv().CW_ShakeConn = RunService.RenderStepped:Connect(function()
        if not getgenv().CW_AntiShake then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local cam = workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Scriptable
                cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(30, -4, 0), root.Position)
            end
        end
    end)
end
local function shakeOff()
    if getgenv().CW_ShakeConn then
        getgenv().CW_ShakeConn:Disconnect()
        getgenv().CW_ShakeConn = nil
    end
    local cam = workspace.CurrentCamera
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end
end
if getgenv().CW_AntiShake then shakeOn() end

pcall(function()
    local rs = game:GetService("ReplicatedStorage")
    local rr = rs:FindFirstChild("RollResult", true)
    if rr then
        rr.OnClientEvent:Connect(function(data)
            if type(data) == "table" then
                local ty = myTycoon()
                local tn = ty and ty.Name or ""
                if (data.TycoonName ~= nil and data.TycoonName == tn)
                    or (data.TriggeredByUserId ~= nil and data.TriggeredByUserId == LP.UserId) then
                    getgenv().CW_Rolled = true
                end
            end
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

local function waitSeedsReady()
    local last, stable = -1, 0
    local t0 = os.clock()
    while os.clock() - t0 < 8 do
        if not (getgenv().CW_Farm and getgenv().CW_Running) then break end
        if getgenv().CW_Rolled then return "rolled" end
        local c = 0
        pcall(function() c = seedCount() end)
        if c > 0 and c == last then
            stable = stable + 1
            if stable >= 3 then return "stable" end
        else
            stable = 0
        end
        last = c
        getgenv().CW_Phase = "warte (" .. c .. ")"
        task.wait(0.2)
    end
    return "empty"
end

task.spawn(function()
    while getgenv().CW_Running do
        if getgenv().CW_Farm then
            getgenv().CW_Phase = "reroll"
            pcall(doReroll)
            task.wait(1)
            if getgenv().CW_Farm then
                getgenv().CW_Phase = "collect"
                pcall(grabAll)
            end
        else
            task.wait(0.3)
        end
    end
end)

task.spawn(function()
    while getgenv().CW_Running do
        if getgenv().CW_AutoSeed and not getgenv().CW_Farm then pcall(grabAll) end
        if getgenv().CW_AutoReroll and not getgenv().CW_Farm then pcall(doReroll) end
        pcall(function()
            local g = ((gethui and gethui()) or game:GetService("CoreGui")):FindFirstChild("CarveWoodUI")
            local f = g and g:FindFirstChild("CWFoot", true)
            if f then
                local last = tostring(getgenv().CW_Last or "-")
                local ph = getgenv().CW_Farm and ("[" .. tostring(getgenv().CW_Phase or "-") .. "] ") or ""
                f.Text = "● " .. ph .. "tries: " .. tostring(getgenv().CW_Tries or 0) .. " | " .. (last:match("[^.]+$") or last)
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
main.Size = UDim2.new(0, 440, 0, 340)
main.Position = UDim2.new(0.5, -220, 0.5, -170)
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
ver.Text = "v2.5  |  no key"
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

section("SEEDS", 0)
toggle("Auto Grab Seeds", 24, function() return getgenv().CW_AutoSeed end,
    function(v) getgenv().CW_AutoSeed = v end)
toggle("Auto Reroll Lever", 60, function() return getgenv().CW_AutoReroll end,
    function(v) getgenv().CW_AutoReroll = v end)
toggle("Auto Farm (loop)", 96, function() return getgenv().CW_Farm end,
    function(v) getgenv().CW_Farm = v end)

section("SPEED", 140)
local dRow = Instance.new("Frame")
dRow.Position = UDim2.new(0, 0, 0, 164)
dRow.Size = UDim2.new(1, 0, 0, 32)
dRow.BackgroundTransparency = 1
dRow.Parent = body
local dLabel = Instance.new("TextLabel")
dLabel.Size = UDim2.new(1, -110, 1, 0)
dLabel.BackgroundTransparency = 1
dLabel.Text = "Delay"
dLabel.Font = Enum.Font.Gotham
dLabel.TextSize = 13
dLabel.TextXAlignment = Enum.TextXAlignment.Left
dLabel.TextColor3 = Color3.fromRGB(225, 225, 235)
dLabel.Parent = dRow
local dVal = Instance.new("TextLabel")
dVal.Position = UDim2.new(1, -110, 0, 0)
dVal.Size = UDim2.new(0, 44, 1, 0)
dVal.BackgroundTransparency = 1
dVal.Text = string.format("%.1fs", getgenv().CW_Delay)
dVal.Font = Enum.Font.Gotham
dVal.TextSize = 13
dVal.TextColor3 = Color3.fromRGB(150, 180, 255)
dVal.Parent = dRow
local minus = Instance.new("TextButton")
minus.Position = UDim2.new(1, -62, 0.5, -11)
minus.Size = UDim2.new(0, 28, 0, 22)
minus.Text = "-"
minus.Font = Enum.Font.GothamBold
minus.TextSize = 14
minus.TextColor3 = Color3.fromRGB(235, 235, 245)
minus.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
minus.BorderSizePixel = 0
minus.Parent = dRow
Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)
local plus = Instance.new("TextButton")
plus.Position = UDim2.new(1, -30, 0.5, -11)
plus.Size = UDim2.new(0, 28, 0, 22)
plus.Text = "+"
plus.Font = Enum.Font.GothamBold
plus.TextSize = 14
plus.TextColor3 = Color3.fromRGB(235, 235, 245)
plus.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
plus.BorderSizePixel = 0
plus.Parent = dRow
Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)
minus.MouseButton1Click:Connect(function()
    getgenv().CW_Delay = math.clamp(getgenv().CW_Delay - 0.1, 0.1, 5)
    dVal.Text = string.format("%.1fs", getgenv().CW_Delay)
end)
plus.MouseButton1Click:Connect(function()
    getgenv().CW_Delay = math.clamp(getgenv().CW_Delay + 0.1, 0.1, 5)
    dVal.Text = string.format("%.1fs", getgenv().CW_Delay)
end)

section("CAMERA", 212)
toggle("Anti Shake", 236, function() return getgenv().CW_AntiShake end,
    function(v) getgenv().CW_AntiShake = v if v then shakeOn() else shakeOff() end end)

local foot = Instance.new("TextLabel")
foot.Name = "CWFoot"
foot.Position = UDim2.new(0, 142, 1, -28)
foot.Size = UDim2.new(1, -154, 0, 16)
foot.BackgroundTransparency = 1
foot.Text = "● ready  |  Tycoon3"
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
    main.Size = collapsed and UDim2.new(0, 190, 0, 42) or UDim2.new(0, 440, 0, 300)
end)
btnX.MouseButton1Click:Connect(function()
    getgenv().CW_AutoSeed = false
    getgenv().CW_AutoReroll = false
    getgenv().CW_AntiShake = false
    getgenv().CW_Running = false
    pcall(shakeOff)
    gui:Destroy()
end)
