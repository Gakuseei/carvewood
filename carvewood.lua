--[[ CarveWood v9.2 | Delta mobile | no login, no key ]]
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
getgenv().CW_CollectCan = getgenv().CW_CollectCan or false
getgenv().CW_CollectFert = getgenv().CW_CollectFert or false
getgenv().CW_Trees = getgenv().CW_Trees or false
getgenv().CW_Fert = getgenv().CW_Fert or false
getgenv().CW_Prio1 = getgenv().CW_Prio1 or "Hyperwave"
getgenv().CW_Prio2 = getgenv().CW_Prio2 or "Voidstar"
getgenv().CW_Prio3 = getgenv().CW_Prio3 or "Birch"

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
    if nm == "CollectWateringCanPrompt" or nm == "CollectCompostFertilizerPrompt" then return false end
    if not (string.find(nm, "Grab", 1, true) or string.find(nm, "Collect", 1, true)) then return false end
    pcall(function() fireproximityprompt(p) end)
    return true
end

local seedList = {}
local seedSeen = {}
local seedPrompt, trackPrompt
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
    if n == 0 then
        for _, d in pairs(ty:GetDescendants()) do
            if typeof(d) == "Instance" and d:IsA("ProximityPrompt") and d.Enabled and seedPrompt(d) then
                trackPrompt(d)
                n = n + 1
                runCollect(d)
            end
        end
    end
    if n > 0 then
        local t0 = os.clock()
        while active > 0 and os.clock() - t0 < 0.4 do task.wait(0.02) end
    end
    return n
end

seedPrompt = function(p)
    if typeof(p) ~= "Instance" or not p:IsA("ProximityPrompt") then return false end
    local nm = p.Name
    if nm == "CollectWateringCanPrompt" or nm == "CollectCompostFertilizerPrompt" then return false end
    return string.find(nm, "Grab", 1, true) ~= nil or string.find(nm, "Collect", 1, true) ~= nil
end
trackPrompt = function(p)
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

local function hookTycoon(ty)
    for _, d in pairs(ty:GetDescendants()) do
        trackPrompt(d)
    end
    ty.DescendantAdded:Connect(function(d)
        pcall(function()
            trackPrompt(d)
        end)
    end)
end

local function hookAll()
    local ty = myTycoon()
    if ty then pcall(hookTycoon, ty) end
end
pcall(hookAll)

--[[ Feature 1: AutoCollect maxed-ready, parallel zu AutoFarm Seeds ]]
local CW_CAN_MAX_STAGE = 9
local CW_CAN_MAX_MULT = 256
local CW_CAN_FREE_LIMIT = 5
local CW_FERT_MAX_ITEM = "DiamondFertilizer"
local CW_FERT_MAX_STAGE = 4

local function countWateringCans(targetMult)
    local needle = targetMult and ("Watering Can [" .. tostring(targetMult) .. "x]") or "Watering Can"
    local n = 0
    pcall(function()
        for _, t in ipairs(LP.Backpack:GetChildren()) do
            if typeof(t) == "Instance" and string.find(t.Name, needle, 1, true) then n = n + 1 end
        end
        local ch = LP.Character
        if ch then
            for _, t in ipairs(ch:GetChildren()) do
                if t:IsA("Tool") and string.find(t.Name, needle, 1, true) then n = n + 1 end
            end
        end
    end)
    return n
end

local function hrp()
    local ch = LP.Character
    local h = ch and ch:FindFirstChild("HumanoidRootPart")
    if h and h:IsA("BasePart") then return h end
    return nil
end

-- Teleport zum Prompt, einsammeln, zurück. Nötig weil
-- WaterTower/CompostBin serverseitig Distanz validieren (PickupValidationPadding).
local function tpCollect(prompt)
    local h = hrp()
    if not h or typeof(prompt) ~= "Instance" or not prompt:IsA("ProximityPrompt") then return false end
    local anchor = prompt.Parent
    if not anchor then return false end
    local wp
    local ok = pcall(function()
        if anchor:IsA("Attachment") then wp = anchor.WorldPosition
        elseif anchor:IsA("BasePart") then wp = anchor.Position
        else wp = anchor:GetPivot().Position end
    end)
    if not ok or typeof(wp) ~= "Vector3" then return false end
    local save = h.CFrame
    pcall(function() h.CFrame = CFrame.new(wp + Vector3.new(3, 2, 3)) end)
    task.wait(0.35)
    if prompt.Enabled then pcall(function() fireproximityprompt(prompt) end) end
    task.wait(0.7)
    pcall(function() h.CFrame = save end)
    return true
end

local function collectMaxedCans()
    if countWateringCans(CW_CAN_MAX_MULT) >= CW_CAN_FREE_LIMIT then return 0 end
    local ty = myTycoon()
    if not ty then return 0 end
    local n = 0
    for _, d in ipairs(ty:GetDescendants()) do
        if typeof(d) == "Instance" and d:IsA("Model") and d.Name == "WateringCan" then
            local ready = d:GetAttribute("WateringCanReady")
            local stage = tonumber(d:GetAttribute("WateringCanStageIndex")) or 0
            local mult = tonumber(d:GetAttribute("WateringCanMultiplier")) or 0
            if ready == true and stage >= CW_CAN_MAX_STAGE and mult >= CW_CAN_MAX_MULT then
                local inner = d:FindFirstChild("Cylinder", true)
                local root = inner or d
                for _, p in ipairs(root:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.Name == "CollectWateringCanPrompt" and p.Enabled then
                        if tpCollect(p) then
                            n = n + 1
                            getgenv().CW_LastCollect = "can 256x " .. os.date("%H:%M:%S")
                        end
                        break
                    end
                end
            end
        end
    end
    return n
end

local function collectMaxedFert()
    local ty = myTycoon()
    if not ty then return 0 end
    local n = 0
    for _, d in ipairs(ty:GetDescendants()) do
        if typeof(d) == "Instance" then
            local stage = d:GetAttribute("CompostBinFertilizerStageIndex")
            if stage ~= nil then
                local ready = d:GetAttribute("CompostBinFertilizerReady")
                local item = tostring(d:GetAttribute("CompostBinFertilizerItemId") or "")
                if ready == true and tonumber(stage) == CW_FERT_MAX_STAGE and item == CW_FERT_MAX_ITEM then
                    for _, p in ipairs(d:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and p.Name == "CollectCompostFertilizerPrompt" and p.Enabled then
                            if tpCollect(p) then
                                n = n + 1
                                getgenv().CW_LastCollect = "diamond fert " .. os.date("%H:%M:%S")
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    return n
end

task.spawn(function()
    while getgenv().CW_Running and getgenv().CW_Gen == myGen do
        pcall(function()
            if getgenv().CW_CollectCan then collectMaxedCans() end
            if getgenv().CW_CollectFert then collectMaxedFert() end
        end)
        task.wait(5)
    end
end)

--[[ Feature 3: Trees — plant Prio1-3, chop mature prio trees, collect ]]
local CW_TREE_TYPES = {
    {"Oak","Common"},{"Birch","Common"},
    {"Pine","Uncommon"},{"Maple","Uncommon"},{"Palm","Uncommon"},
    {"Willow","Rare"},{"Acacia","Rare"},
    {"Sakura","Epic"},
    {"Bubble","Legendary"},
    {"Doom","Mythical"},{"NightBlossom","Mythical"},{"Redstar","Mythical"},
    {"Glow","Sacred"},{"MagicalPalm","Sacred"},
    {"Astral","Ethereal"},{"WitheredRose","Ethereal"},
    {"Lunar","Celestial"},{"Solar","Celestial"},
    {"Cloud","Secret"},{"Lightning","Secret"},{"Sunset","Secret"},
    {"Starfall","Cosmic"},{"NightmareBloom","Cosmic"},
    {"Voidstar","Transcendent"},{"Hyperwave","Transcendent"},
    {"Alien","Transcendent"},
    {"ScorchingMushroom","Super Secret"},{"Kelp","Super Secret"},
}
local CW_PlantUUID = nil
local function resolveRoute(route)
    local ok, mod = pcall(function()
        return require(game:GetService("ReplicatedFirst"):WaitForChild("Client"))
    end)
    if not ok or type(mod) ~= "table" or type(mod.CachedRemotes) ~= "table" then return nil end
    local salt = LP.Name .. tostring(game.PlaceVersion) .. "xdd"
    local sl = #salt
    for k, v in pairs(mod.CachedRemotes) do
        local ks = tostring(k)
        if #ks == #route then
            local d = {}
            for i = 1, #ks do
                d[i] = string.char(bit32.bxor(ks:byte(i), salt:byte((i - 1) % sl + 1)))
            end
            if table.concat(d) == route then return tostring(v) end
        end
    end
    return nil
end

local function findAxe()
    local ch = LP.Character
    local doom = ch and ch:FindFirstChild("Axe of Doom") or LP.Backpack:FindFirstChild("Axe of Doom")
    if doom then return doom end
    local function scan(root)
        for _, t in ipairs(root:GetChildren()) do
            if t:IsA("Tool") and string.find(t.Name, "Axe", 1, true) then return t end
        end
        return nil
    end
    return (ch and scan(ch)) or scan(LP.Backpack)
end

local function woodChips()
    local n = 0
    pcall(function()
        local ls = LP:FindFirstChild("leaderstats")
        local w = ls and ls:FindFirstChild("Wood Chips")
        if w then n = tonumber(w.Value) or 0 end
    end)
    return n
end

local function countLogs()
    local n = 0
    pcall(function()
        for _, t in ipairs(LP.Backpack:GetChildren()) do
            if typeof(t) == "Instance" and string.find(t.Name, " Log", 1, true) then n = n + 1 end
        end
    end)
    return n
end

-- Plant mit TP (Server verlangt Nähe). Gibt planted TreeType oder nil.
local function plantPrio(planter)
    local idx = planter:GetAttribute("PlanterIndex")
    if idx == nil or tonumber(idx) == 0 then return nil end
    local h = hrp()
    if not h then return nil end
    if not CW_PlantUUID then CW_PlantUUID = resolveRoute("PlantSeedFromInventory") end
    if not CW_PlantUUID then return nil end
    local rem = game:GetService("ReplicatedStorage"):FindFirstChild("REM", true)
    rem = rem and rem:FindFirstChild(CW_PlantUUID)
    if not rem then CW_PlantUUID = nil return nil end
    local ty = myTycoon()
    if not ty then return nil end
    local pp
    pcall(function() pp = planter:GetPivot().Position end)
    if typeof(pp) ~= "Vector3" then return nil end
    local dest = CFrame.new(pp + Vector3.new(0, 4, 6))
    -- Antwort-getrieben: bei "Move closer" neu TP + Retry, sonst Prio-Fallback.
    for _ = 1, 4 do
        if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
        if not h.Parent then return nil end
        pcall(function() h.CFrame = dest end)
        local needCloser = false
        for _, prio in ipairs({getgenv().CW_Prio1, getgenv().CW_Prio2, getgenv().CW_Prio3}) do
            if type(prio) == "string" and prio ~= "" then
                local ok, r = pcall(function()
                    return rem:InvokeServer({PlanterIndex = tonumber(idx), TreeType = prio, TycoonName = ty.Name})
                end)
                if ok and type(r) == "table" then
                    if r.Success == true then
                        getgenv().CW_LastTree = "planted " .. prio .. " " .. os.date("%H:%M:%S")
                        return prio
                    end
                    local msg = tostring(r.Error or r.Message or "")
                    if string.find(msg, "ccupied", 1, true) or string.find(msg, "nvalid", 1, true) then
                        return nil
                    end
                    if string.find(msg, "loser", 1, true) then
                        needCloser = true
                        break
                    end
                end
            end
        end
        if not needCloser then return nil end
        task.wait()
    end
    return nil
end

local CW_FertUUID = nil
local CW_FERT_ID = "DiamondFertilizer"
local function findFertTool()
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("FertilizerId") == CW_FERT_ID then return t end
    end
    local ch = LP.Character
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("FertilizerId") == CW_FERT_ID then return t end
        end
    end
    return nil
end

-- Fertilizable: Model mit TreePlanter, sichtbar, nicht constructing, kein Mega,
-- Status Empty/Growing/Mature, Fertilizer abgelaufen oder keiner gesetzt.
local function fertNeeded(d)
    if d:GetAttribute("TreePlanter") ~= true then return false end
    if d:GetAttribute("TreePlanterVisible") == false then return false end
    if d:GetAttribute("TreePlanterConstructing") == true then return false end
    if d:GetAttribute("TutorialTree") == true or d:GetAttribute("MegaPlanter") == true then return false end
    local idx = tonumber(d:GetAttribute("PlanterIndex"))
    if idx == nil or idx == 0 then return false end
    local st = d:GetAttribute("TreePlanterStatus")
    if st ~= "Empty" and st ~= "Growing" and st ~= "Mature" then return false end
    return os.time() >= (tonumber(d:GetAttribute("TreeFertilizerEndsAt")) or 0)
end

-- Fertilize mit TP (Server prüft Distanz UND ob das Tool equipped ist).
local function fertilizePlanter(planter)
    local idx = tonumber(planter:GetAttribute("PlanterIndex"))
    if not idx or idx == 0 then return false end
    local tool = findFertTool()
    if not tool then return false end
    local h = hrp()
    if not h then return false end
    if not CW_FertUUID then CW_FertUUID = resolveRoute("FertilizePlanter") end
    if not CW_FertUUID then return false end
    local rem = game:GetService("ReplicatedStorage"):FindFirstChild("REM", true)
    rem = rem and rem:FindFirstChild(CW_FertUUID)
    if not rem then CW_FertUUID = nil return false end
    local ty = myTycoon()
    if not ty then return false end
    local pp
    pcall(function() pp = planter:GetPivot().Position end)
    if typeof(pp) ~= "Vector3" then return false end
    local target = planter:FindFirstChildWhichIsA("BasePart", true) or planter
    local dest = CFrame.new(pp + Vector3.new(0, 4, 6))
    local ch = LP.Character
    local wasEquipped = tool.Parent == ch
    pcall(function() tool.Parent = ch end)
    local done = false
    for _ = 1, 4 do
        if not (getgenv().CW_Running and getgenv().CW_Fert) then break end
        if not h.Parent then break end
        pcall(function() h.CFrame = dest end)
        local ok, r = pcall(function()
            return rem:InvokeServer({
                PlanterIndex = idx,
                ItemId = CW_FERT_ID,
                DirectlyTargeted = true,
                TargetedInstance = target,
                TycoonName = ty.Name,
            })
        end)
        if not (ok and type(r) == "table") then break end
        if r.Success == true then
            getgenv().CW_LastTree = "fertilized #" .. tostring(idx) .. " " .. os.date("%H:%M:%S")
            done = true
            break
        end
        local msg = tostring(r.Code or r.Error or r.Message or "")
        if string.find(msg, "TooFar", 1, true) or string.find(msg, "loser", 1, true) then
            task.wait(0.4)
        elseif string.find(msg, "NotEquipped", 1, true) then
            pcall(function() tool.Parent = LP.Character end)
            task.wait(0.3)
        else
            break
        end
    end
    if not wasEquipped then
        pcall(function()
            if tool.Parent == LP.Character then tool.Parent = LP.Backpack end
        end)
    end
    return done
end

local function dropContainer()
    local c = nil
    pcall(function()
        c = workspace:FindFirstChild("ClientTreeDropEffects_" .. tostring(LP.UserId))
    end)
    return c
end

local function dropPos(d)
    local pos = nil
    pcall(function()
        if d:IsA("BasePart") then
            pos = d.Position
        elseif d:IsA("Model") then
            pos = d:GetPivot().Position
        else
            local p = d:FindFirstChild("Part", true) or d:FindFirstChildWhichIsA("BasePart", true)
            if p then pos = p.Position end
        end
    end)
    return pos
end

-- Chop: sauber neben dem Stamm (unanchored, Server ignoriert Anchored-Hits),
-- Position jeden Swing neu setzen. Swing-Takt folgt TreeChopSerial-Signal.
local function chopAndCollect(tree)
    local h = hrp()
    if not h then return false end
    local axe = findAxe()
    if not axe then return false end
    local tp
    pcall(function() tp = tree:GetPivot().Position end)
    if typeof(tp) ~= "Vector3" then return false end
    -- Unanchored lassen (Server ignoriert AxeHit bei Anchored-HRP).
    -- Sauber NEBEN dem Stamm stehen, Position jeden Swing neu setzen.
    local away = (h.Position - tp)
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 1 then away = Vector3.new(1, 0, 1) end
    local stand = tp + away.Unit * 5 + Vector3.new(0, 4, 0)
    local aim = tp + Vector3.new(0, 3, 0)
    pcall(function()
        h.Anchored = false
        h.CFrame = CFrame.lookAt(stand, aim)
    end)
    task.wait()
    local ch = LP.Character
    if axe.Parent ~= ch then
        pcall(function() axe.Parent = ch end)
        task.wait()
    end
    -- Nativ: nächster Swing erst nach registriertem Hit (TreeChopSerial).
    -- Tempo kalibriert sich pro Axt selbst (est). Keine festen Swing-Zeiten.
    local felled = false
    local est = 0.6
    local misses = 0
    while getgenv().CW_Running and getgenv().CW_Trees do
        if tree.Parent == nil or tree:GetAttribute("TreeFelling") == true then felled = true break end
        local serial0 = tree:GetAttribute("TreeChopSerial") or 0
        local tA = os.clock()
        pcall(function()
            h.CFrame = CFrame.lookAt(stand, aim)
            axe:Activate()
        end)
        local hit = false
        while os.clock() - tA < 2.5 do
            task.wait(0.05)
            if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
            if tree.Parent == nil or tree:GetAttribute("TreeFelling") == true then felled = true break end
            if (tree:GetAttribute("TreeChopSerial") or 0) ~= serial0 then hit = true break end
        end
        if felled then break end
        if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
        if hit then
            est = math.max(0.25, os.clock() - tA)
            misses = 0
        else
            misses = misses + 1
            if misses == 5 then
                pcall(function()
                    h.CFrame = CFrame.lookAt(stand, aim)
                    if axe.Parent ~= LP.Character then axe.Parent = LP.Character end
                end)
                task.wait()
            elseif misses >= 10 then
                break
            end
        end
        local gap = est * 0.9 - (os.clock() - tA)
        while gap > 0 do
            if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
            if tree.Parent == nil or tree:GetAttribute("TreeFelling") == true then felled = true break end
            task.wait(0.05)
            gap = est * 0.9 - (os.clock() - tA)
        end
        if felled then break end
    end
    if tree.Parent == nil or tree:GetAttribute("TreeFelling") == true then felled = true end
    if felled then
        -- Drops liegen in ClientTreeDropEffects_<uid> (*Drop-Models).
        -- Jedes einzeln per Position einsammeln bis der Container leer ist.
        local chips0, logs0 = woodChips(), countLogs()
        local names = {}
        local visited = {}
        -- Nativ: auf Drops warten, pro Drop warten bis er weg ist (eingesammelt).
        local tC0 = os.clock()
        while os.clock() - tC0 < 10 do
            local any = false
            pcall(function()
                local c = dropContainer()
                any = c and #c:GetChildren() > 0
            end)
            if any then break end
            if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
            task.wait(0.2)
        end
        for _ = 1, 40 do
            if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
            local target, pos = nil, nil
            pcall(function()
                local c = dropContainer()
                if c then
                    for _, d in ipairs(c:GetChildren()) do
                        if string.find(d.Name, "Drop", 1, true) then
                            local p = dropPos(d)
                            if p then
                                local seen = false
                                for _, v in ipairs(visited) do
                                    if (v - p).Magnitude < 7 then seen = true break end
                                end
                                if not seen then target, pos = d, p break end
                            end
                        end
                    end
                end
            end)
            if not target then break end
            if #names < 12 then names[#names + 1] = target.Name end
            visited[#visited + 1] = pos
            pcall(function() h.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end)
            local tG0 = os.clock()
            while os.clock() - tG0 < 3 do
                local gone = true
                pcall(function() gone = (not target.Parent) end)
                if gone then break end
                if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
                task.wait(0.1)
            end
        end
        local got = (woodChips() - chips0) + (countLogs() - logs0)
        getgenv().CW_LastTree = "chopped+" .. tostring(got) .. " [" .. table.concat(names, ",") .. "] " .. os.date("%H:%M:%S")
    end
    return felled
end

task.spawn(function()
    local planterCache = {}
    while getgenv().CW_Running and getgenv().CW_Gen == myGen do
        local didWork = false
        if getgenv().CW_Trees or getgenv().CW_Fert then
            local ty = nil
            pcall(function() ty = myTycoon() end)
            if ty then
                local prios = {}
                for _, p in ipairs({getgenv().CW_Prio1, getgenv().CW_Prio2, getgenv().CW_Prio3}) do
                    if type(p) == "string" and p ~= "" then prios[p] = true end
                end
                local h0 = hrp()
                local save = (h0 and h0.CFrame) or nil
                -- Planter-Cache (kein Full-Scan pro Zyklus)
                local fresh = true
                if #planterCache > 0 then
                    for _, pm in ipairs(planterCache) do
                        if not pm.Parent or pm:GetAttribute("TreePlanter") ~= true then fresh = false break end
                    end
                else
                    fresh = false
                end
                if not fresh then
                    planterCache = {}
                    pcall(function()
                        for _, d in ipairs(ty:GetDescendants()) do
                            if typeof(d) == "Instance" and d:GetAttribute("TreePlanter") == true then
                                planterCache[#planterCache + 1] = d
                            end
                        end
                    end)
                end
                if getgenv().CW_Trees then
                    pcall(function()
                        for _, d in ipairs(planterCache) do
                            if not getgenv().CW_Trees then break end
                            if d.Parent and d:GetAttribute("TreePlanterStatus") == "Empty" then
                                if plantPrio(d) then didWork = true end
                            end
                        end
                    end)
                    pcall(function()
                        local CS = game:GetService("CollectionService")
                        for _, t in ipairs(CS:GetTagged("ChoppableTree")) do
                            if not getgenv().CW_Trees then break end
                            if t:IsDescendantOf(ty) and t:GetAttribute("TreeMature") == true
                                and t:GetAttribute("TreeFelling") ~= true
                                and prios[tostring(t:GetAttribute("TreeType"))] then
                                if chopAndCollect(t) then didWork = true end
                                break
                            end
                        end
                    end)
                end
                if getgenv().CW_Fert then
                    pcall(function()
                        for _, d in ipairs(planterCache) do
                            if not getgenv().CW_Fert then break end
                            if d.Parent and fertNeeded(d) then
                                if fertilizePlanter(d) then didWork = true end
                            end
                        end
                    end)
                end
                if save then pcall(function() local h = hrp() if h then h.CFrame = save end end) end
            end
        end
        task.wait(didWork and 2 or 8)
    end
end)

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
local pillV = pill("v9.2", 212, ACCENT)
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
local treePage = makePage("Trees")
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
    if q ~= "" then
        for _, c in ipairs(allCards) do
            if c.root and c.page == currentPage and c.frame.Visible then
                c.root.Visible = true
                if c.open then c.open(true) end
            end
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

local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(169, 169, 169),
    ["Uncommon"] = Color3.fromRGB(63, 214, 105),
    ["Rare"] = Color3.fromRGB(63, 169, 255),
    ["Epic"] = Color3.fromRGB(180, 92, 255),
    ["Legendary"] = Color3.fromRGB(255, 158, 44),
    ["Mythical"] = Color3.fromRGB(255, 77, 109),
    ["Sacred"] = Color3.fromRGB(255, 225, 77),
    ["Ethereal"] = Color3.fromRGB(92, 242, 232),
    ["Celestial"] = Color3.fromRGB(207, 232, 255),
    ["Secret"] = Color3.fromRGB(46, 230, 168),
    ["Cosmic"] = Color3.fromRGB(255, 61, 242),
    ["Transcendent"] = Color3.fromRGB(255, 46, 77),
    ["Super Secret"] = Color3.fromRGB(255, 255, 255),
}

local DD2_LISTS = {}
local function closeDD2()
    for _, f in ipairs(DD2_LISTS) do
        pcall(function() f.Visible = false end)
    end
end

-- Expandable Card: Header mit Switch + Chevron, Klick klappt Body mit Sub-Rows auf.
local function expandCard(page, pageName, title, desc, order, h)
    local hh = h or 72
    local row = card(page, pageName, title, desc, order, hh)
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Position = UDim2.new(0, 0, 0, hh)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.BackgroundTransparency = 1
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Visible = false
    body.Parent = row
    local bl = Instance.new("UIListLayout", body)
    bl.Padding = UDim.new(0, 4)
    bl.SortOrder = Enum.SortOrder.LayoutOrder
    local bp = Instance.new("UIPadding", body)
    bp.PaddingTop = UDim.new(0, 6)
    bp.PaddingBottom = UDim.new(0, 12)
    local dv = Instance.new("Frame")
    dv.Size = UDim2.new(1, -40, 0, 1)
    dv.BackgroundColor3 = STROKE
    dv.BackgroundTransparency = 0.4
    dv.BorderSizePixel = 0
    dv.LayoutOrder = -10
    dv.Parent = body
    local open = false
    local function fit()
        row.Size = UDim2.new(1, 0, 0, open and (hh + body.AbsoluteSize.Y) or hh)
    end
    body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    local hb = Instance.new("TextButton")
    hb.Size = UDim2.new(1, -92, 0, hh)
    hb.BackgroundTransparency = 1
    hb.Text = ""
    hb.AutoButtonColor = false
    hb.Parent = row
    local chev = Instance.new("TextLabel")
    chev.AnchorPoint = Vector2.new(1, 0.5)
    chev.Position = UDim2.new(1, -2, 0.5, 0)
    chev.Size = UDim2.new(0, 20, 0, 20)
    chev.BackgroundTransparency = 1
    chev.Text = "▾"
    chev.Font = Enum.Font.GothamBold
    chev.TextSize = 15
    chev.TextColor3 = MUT
    chev.Parent = hb
    local function setOpen(v)
        open = v
        body.Visible = v
        chev.Text = v and "▴" or "▾"
        chev.TextColor3 = v and ACCENT or MUT
        if not v then
            for _, f in ipairs(DD2_LISTS) do
                if f:IsDescendantOf(body) then f.Visible = false end
            end
        end
        fit()
    end
    hb.MouseButton1Click:Connect(function() setOpen(not open) end)
    return { frame = row, body = body, setOpen = setOpen }
end

-- Sub-Row in einem Expand-Body: Punkt + Label, registriert für Suche.
local function subRow(body, pageName, title, rootCard, order)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, 0, 0, 46)
    r.BackgroundTransparency = 1
    r.LayoutOrder = order
    r.Parent = body
    local dt = Instance.new("Frame")
    dt.Size = UDim2.new(0, 6, 0, 6)
    dt.Position = UDim2.new(0, 22, 0.5, -3)
    dt.BackgroundColor3 = STROKE
    dt.BorderSizePixel = 0
    dt.Parent = r
    Instance.new("UICorner", dt).CornerRadius = UDim.new(1, 0)
    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 40, 0, 0)
    l.Size = UDim2.new(1, -250, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = title
    l.Font = Enum.Font.GothamBold
    l.TextSize = 15
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = TXT
    l.Parent = r
    allCards[#allCards + 1] = { frame = r, page = pageName, text = string.lower(title),
        root = rootCard.frame, open = rootCard.setOpen }
    return r
end

local function subToggle(body, pageName, title, rootCard, order, get, set)
    local r = subRow(body, pageName, title, rootCard, order)
    return toggle(r, get, set)
end

-- Sub-Dropdown: wie dropdown2, aber Row + Liste leben im Expand-Body.
local function subDropdown(body, pageName, title, rootCard, order, options, get, set)
    local r = subRow(body, pageName, title, rootCard, order)
    local b = Instance.new("TextButton")
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, -20, 0.5, 0)
    b.Size = UDim2.new(0, 190, 0, 32)
    b.BackgroundColor3 = CTRL
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextTruncate = Enum.TextTruncate.AtEnd
    b.Parent = r
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local function optOf(v)
        for _, o in ipairs(options) do
            if o.value == v then return o end
        end
        return nil
    end
    local function paint()
        local o = optOf(get())
        b.Text = (o and o.value or tostring(get())) .. "  ▾"
        b.TextColor3 = (o and RARITY_COLORS[o.rarity]) or TXT
    end
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -16, 0, 210)
    list.Position = UDim2.new(0, 8, 0, 0)
    list.BackgroundColor3 = SIDE
    list.BorderSizePixel = 0
    list.ClipsDescendants = true
    list.LayoutOrder = order + 1
    list.Visible = false
    list.Parent = body
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 10)
    local lst = Instance.new("UIStroke", list)
    lst.Color = STROKE
    lst.Thickness = 1
    lst.Transparency = 0.35
    lst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    DD2_LISTS[#DD2_LISTS + 1] = list
    local sc = Instance.new("ScrollingFrame")
    sc.Size = UDim2.new(1, -12, 1, -12)
    sc.Position = UDim2.new(0, 6, 0, 6)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 90)
    sc.CanvasSize = UDim2.new(0, 0, 0, 0)
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.Parent = list
    local ll = Instance.new("UIListLayout", sc)
    ll.Padding = UDim.new(0, 4)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    local cur = get()
    for i, opt in ipairs(options) do
        local col = RARITY_COLORS[opt.rarity] or TXT
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 34)
        ob.BackgroundColor3 = (opt.value == cur) and CTRL or SIDE
        ob.Text = ""
        ob.AutoButtonColor = true
        ob.LayoutOrder = i
        ob.BorderSizePixel = 0
        ob.Parent = sc
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 8)
        local dot4 = Instance.new("Frame")
        dot4.Size = UDim2.new(0, 10, 0, 10)
        dot4.Position = UDim2.new(0, 12, 0.5, -5)
        dot4.BackgroundColor3 = col
        dot4.BorderSizePixel = 0
        dot4.Parent = ob
        Instance.new("UICorner", dot4).CornerRadius = UDim.new(1, 0)
        local nm = Instance.new("TextLabel")
        nm.Position = UDim2.new(0, 32, 0, 0)
        nm.Size = UDim2.new(1, -42, 0, 20)
        nm.BackgroundTransparency = 1
        nm.Text = opt.value
        nm.Font = Enum.Font.GothamBold
        nm.TextSize = 14
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.TextTruncate = Enum.TextTruncate.AtEnd
        nm.TextColor3 = col
        nm.Parent = ob
        local rl = Instance.new("TextLabel")
        rl.Position = UDim2.new(0, 32, 0, 19)
        rl.Size = UDim2.new(1, -42, 0, 13)
        rl.BackgroundTransparency = 1
        rl.Text = opt.rarity
        rl.Font = Enum.Font.Gotham
        rl.TextSize = 11
        rl.TextXAlignment = Enum.TextXAlignment.Left
        rl.TextColor3 = MUT
        rl.Parent = ob
        ob.MouseButton1Click:Connect(function()
            set(opt.value)
            paint()
            list.Visible = false
        end)
    end
    b.MouseButton1Click:Connect(function()
        local was = list.Visible
        closeDD2()
        list.Visible = not was
    end)
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
do
    local ec = expandCard(farmPage, "Farm", "Auto Farm Seeds", "Reroll, wait, collect until empty.", 2, 72)
    toggle(ec.frame,
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
    subToggle(ec.body, "Farm", "Auto Frenzy — collect remotes each cycle, never Alien", ec, 10,
        function() return getgenv().CW_Frenzy end,
        function(v) getgenv().CW_Frenzy = v end)
    subToggle(ec.body, "Farm", "AutoCollect Can 256x — skips at 5+ held", ec, 20,
        function() return getgenv().CW_CollectCan end,
        function(v) getgenv().CW_CollectCan = v end)
    subToggle(ec.body, "Farm", "AutoCollect Diamond Fert — TP to bin, no limit", ec, 30,
        function() return getgenv().CW_CollectFert end,
        function(v) getgenv().CW_CollectFert = v end)
end

section(treePage, "TREES", 1)
do
    local ec = expandCard(treePage, "Trees", "Auto Trees", "Plant empty plots by priority, chop mature prio trees, collect.", 2, 72)
    toggle(ec.frame,
        function() return getgenv().CW_Trees end,
        function(v) getgenv().CW_Trees = v end)
    subToggle(ec.body, "Trees", "Auto Fertilize — Diamond 4x on every planter", ec, 10,
        function() return getgenv().CW_Fert end,
        function(v) getgenv().CW_Fert = v end)
    local opts = {}
    for _, e in ipairs(CW_TREE_TYPES) do
        opts[#opts + 1] = { value = e[1], rarity = e[2], label = e[1] .. " · " .. e[2] }
    end
    subDropdown(ec.body, "Trees", "Priority 1 — planted first", ec, 20, opts,
        function() return getgenv().CW_Prio1 end,
        function(v) getgenv().CW_Prio1 = v end)
    subDropdown(ec.body, "Trees", "Priority 2 — fallback", ec, 30, opts,
        function() return getgenv().CW_Prio2 end,
        function(v) getgenv().CW_Prio2 = v end)
    subDropdown(ec.body, "Trees", "Priority 3 — fallback", ec, 40, opts,
        function() return getgenv().CW_Prio3 end,
        function(v) getgenv().CW_Prio3 = v end)
end

local _oldApplySearch = applySearch
function applySearch()
    _oldApplySearch()
    closeDD2()
end

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
navItem("Trees", 3)
navItem("Performance", 4)
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
    getgenv().CW_CollectCan = false
    getgenv().CW_CollectFert = false
    getgenv().CW_Trees = false
    getgenv().CW_Fert = false
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
