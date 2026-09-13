--[[ CarveWood v10.0 | Delta mobile | no login, no key ]]
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
getgenv().CW_Chopped = getgenv().CW_Chopped or 0
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
getgenv().CW_Shop = getgenv().CW_Shop or false
getgenv().CW_ShopRoll = getgenv().CW_ShopRoll or false
getgenv().CW_ShopPay = getgenv().CW_ShopPay or "Gems"
getgenv().CW_ShopFloor = getgenv().CW_ShopFloor or 0
getgenv().CW_ShopPick = getgenv().CW_ShopPick or {}
getgenv().CW_ShopStay = getgenv().CW_ShopStay or false
getgenv().CW_ShopBought = 0
getgenv().CW_ShopRolls = 0

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
            if type(prio) == "string" and prio ~= "" and prio ~= "None" then
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
    if felled then getgenv().CW_Chopped = (getgenv().CW_Chopped or 0) + 1 end
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

local CW_SHOP_ITEMS = {
    {id = "DiamondFertilizer", name = "Diamond Fertilizer", price = 80, rarity = "Mythical"},
    {id = "GoldenFertilizer", name = "Golden Fertilizer", price = 20, rarity = "Legendary"},
    {id = "WateringCan64x", name = "64x Watering Can", price = 30, rarity = "Mythical"},
    {id = "WateringCan16x", name = "16x Watering Can", price = 10, rarity = "Legendary"},
    {id = "ChargedEnergyCapsule", name = "Charged Energy Capsule", price = 150, rarity = "Rare"},
    {id = "Recall", name = "Seed Recall", price = 5, rarity = "Common"},
}
local shopPicked
do
    local CW_SHOP_PRICE = {}
    for _, it in ipairs(CW_SHOP_ITEMS) do CW_SHOP_PRICE[it.id] = it.price end
    local CW_ROLL_GEMS = 100
    local CW_SHOP_ROUTES = {
        buy = "PurchaseGemStoreStock",
        gems = "RefreshGemStoreStockWithGems",
        chips = "RefreshGemStoreStockWithWoodChips",
    }
    local CW_ShopUUID = {}
    local function shopRemote(key)
        if not CW_ShopUUID[key] then CW_ShopUUID[key] = resolveRoute(CW_SHOP_ROUTES[key]) end
        if not CW_ShopUUID[key] then return nil end
        local rem = game:GetService("ReplicatedStorage"):FindFirstChild("REM", true)
        rem = rem and rem:FindFirstChild(CW_ShopUUID[key])
        if not rem then CW_ShopUUID[key] = nil end
        return rem
    end

    local function gemCount()
        local ls = LP:FindFirstChild("leaderstats")
        local d = ls and ls:FindFirstChild("Diamonds")
        return (d and tonumber(d.Value)) or 0
    end

    local function gemStore()
        local ty = myTycoon()
        local gs = ty and ty:FindFirstChild("GemStore", true)
        if gs and gs:FindFirstChild("Pedestals") then return gs end
        return nil
    end

    local function shopSlots(gs)
        local out = {}
        for _, ped in ipairs(gs.Pedestals:GetChildren()) do
            local d = ped:FindFirstChild("DailyStockDisplay")
            if d then
                out[#out + 1] = { pedestal = ped, display = d,
                    slot = d:GetAttribute("GemStoreStockSlot"),
                    id = tostring(d:GetAttribute("GemStoreStockItemId")),
                    left = tonumber(d:GetAttribute("GemStoreStockRemaining")) or 0 }
            end
        end
        return out
    end

    shopPicked = function(id)
        local pick = getgenv().CW_ShopPick
        return type(pick) == "table" and pick[id] == true
    end

    local shopHalted = false
    local function gemBudget(cost)
        if gemCount() - cost >= (tonumber(getgenv().CW_ShopFloor) or 0) then return true end
        shopHalted = true
        return false
    end

    -- Model-Pivots im Store zeigen teils ins Nirgendwo, darum immer ein echtes Part.
    local function shopStand(inst)
        local pos
        pcall(function()
            local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
            pos = part and part.Position
        end)
        if typeof(pos) ~= "Vector3" then return nil end
        return pos
    end

    local function shopTP(pos)
        local h = hrp()
        if not h then return false end
        pcall(function() h.CFrame = CFrame.new(pos + Vector3.new(0, 3, 5), pos) end)
        task.wait(0.25)
        return true
    end

    -- Kauft einen Slot leer. Server misst die Distanz pro Pedestal, darum TP je Versuch.
    local function buySlot(entry)
        local rem = shopRemote("buy")
        local pos = shopStand(entry.pedestal)
        if not rem or not pos then return 0 end
        local bought = 0
        local placed = false
        for _ = 1, 10 do
            if not (getgenv().CW_Running and getgenv().CW_Shop) then break end
            if (tonumber(entry.display:GetAttribute("GemStoreStockRemaining")) or 0) <= 0 then break end
            if not gemBudget(CW_SHOP_PRICE[entry.id] or 0) then break end
            if not placed then
                shopTP(pos)
                placed = true
            end
            local ok, r = pcall(function()
                return rem:InvokeServer({ Slot = entry.slot, ItemId = entry.id,
                    PeriodIndex = entry.display:GetAttribute("GemStoreStockPeriod") })
            end)
            if not ok or type(r) ~= "table" then break end
            if r.Success == true then
                bought = bought + 1
                getgenv().CW_ShopBought = (getgenv().CW_ShopBought or 0) + 1
            elseif tostring(r.Code) == "NotEnoughGems" then
                shopHalted = true
                break
            elseif tostring(r.Code) == "TooFar" then
                placed = false
            else
                break
            end
        end
        return bought
    end

    local function refreshStock(gs)
        local chips = getgenv().CW_ShopPay == "Wood Chips"
        if not chips and not gemBudget(CW_ROLL_GEMS) then return false end
        local rem = shopRemote(chips and "chips" or "gems")
        local btn = gs:FindFirstChild("RerollStockButton")
        local pos = btn and shopStand(btn)
        if not rem or not pos then return false end
        shopTP(pos)
        local ok, r = pcall(function()
            return rem:InvokeServer({ PeriodIndex = gs:GetAttribute("GemStoreStockPeriod"),
                RollIndex = gs:GetAttribute("GemStoreStockRollIndex") })
        end)
        if ok and type(r) == "table" and r.Success == true then
            getgenv().CW_ShopRolls = (getgenv().CW_ShopRolls or 0) + 1
            task.wait(0.35)
            return true
        end
        return false
    end

    task.spawn(function()
        while getgenv().CW_Running and getgenv().CW_Gen == myGen do
            local didWork = false
            if getgenv().CW_Shop or getgenv().CW_ShopRoll then
                local gs = gemStore()
                if gs then
                    local h = hrp()
                    local save = h and h.CFrame
                    shopHalted = false
                    if getgenv().CW_Shop then
                        for _, e in ipairs(shopSlots(gs)) do
                            if shopPicked(e.id) and e.left > 0 and not shopHalted then
                                if buySlot(e) > 0 then didWork = true end
                            end
                        end
                    end
                    if getgenv().CW_ShopRoll and not shopHalted then
                        local waiting = false
                        for _, e in ipairs(shopSlots(gs)) do
                            if shopPicked(e.id) and e.left > 0 then waiting = true end
                        end
                        if not waiting and refreshStock(gs) then didWork = true end
                    end
                    if save and not getgenv().CW_ShopStay then
                        pcall(function() local h2 = hrp() if h2 then h2.CFrame = save end end)
                    end
                end
            end
            task.wait(didWork and 0.1 or 1.5)
        end
    end)
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
    local lastRolls, lastAt = getgenv().CW_Rolls or 0, os.clock()
    while getgenv().CW_Running and getgenv().CW_Gen == myGen do
        pcall(function()
            local g = ((gethui and gethui()) or game:GetService("CoreGui")):FindFirstChild("CarveWoodUI")
            if not g then return end
            local now = os.clock()
            if now - lastAt >= 5 then
                getgenv().CW_RollsPerMin = ((getgenv().CW_Rolls or 0) - lastRolls) / (now - lastAt) * 60
                lastRolls, lastAt = getgenv().CW_Rolls or 0, now
            end
            local el = math.floor((getgenv().CW_FarmTime or 0)
                + (getgenv().CW_FarmSince and (now - getgenv().CW_FarmSince) or 0))
            local dd = math.floor(el / 86400)
            local hh = math.floor((el % 86400) / 3600)
            local mm = math.floor((el % 3600) / 60)
            local ss = el % 60
            local tstr
            if dd > 0 then tstr = string.format("%dd %dh %dm", dd, hh, mm)
            elseif hh > 0 then tstr = string.format("%dh %02dm", hh, mm)
            elseif mm > 0 then tstr = string.format("%dm %02ds", mm, ss)
            else tstr = string.format("%ds", ss) end
            local ph = getgenv().CW_Phase
            local pstr
            if ph == "reroll" then pstr = "Rerolling seeds"
            elseif type(ph) == "string" and string.sub(ph, 1, 7) == "collect" then
                local n = tonumber(string.match(ph, "%((%d+)%)")) or 0
                pstr = n > 0 and ("Collecting " .. n .. (n == 1 and " seed" or " seeds")) or "Finishing collection"
            elseif getgenv().CW_Farm then pstr = "Starting up"
            else pstr = "Idle" end
            if getgenv().CW_Trees and getgenv().CW_Farm then pstr = pstr .. " · trees active"
            elseif getgenv().CW_Trees then pstr = "Tending trees" end
            getgenv().CW_PhaseText = pstr
            local r = g:FindFirstChild("CWValRolls", true)
            if r then r.Text = tostring(getgenv().CW_Rolls or 0) end
            local t = g:FindFirstChild("CWValTime", true)
            if t then t.Text = tstr end
            local p = g:FindFirstChild("CWValPhase", true)
            if p then p.Text = pstr end
            local tr = g:FindFirstChild("CWValTrees", true)
            if tr then tr.Text = tostring(getgenv().CW_Chopped or 0) end
            local bu = g:FindFirstChild("CWValBuys", true)
            if bu then bu.Text = tostring(getgenv().CW_ShopBought or 0) end
            local sb = g:FindFirstChild("CWSubPhase", true)
            if sb then sb.Text = getgenv().CW_Farm and "Farm seeds is running" or "Farm seeds is off" end
        end)
        task.wait(getgenv().CW_Delay)
    end
end)

--[[ CarveWood v9.0 UI | reference style | green accent | 820x520 + mobile scale ]]
do
local parent = (gethui and gethui()) or game:GetService("CoreGui")
local old = parent:FindFirstChild("CarveWoodUI")
if old then old:Destroy() end

local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local ACCENT = Color3.fromRGB(94, 226, 162)
local BG = Color3.fromRGB(11, 13, 12)
local SIDE = Color3.fromRGB(14, 16, 15)
local CARD = Color3.fromRGB(20, 23, 21)
local CTRL = Color3.fromRGB(32, 36, 34)
local STROKE = Color3.fromRGB(33, 38, 35)
local TXT = Color3.fromRGB(233, 239, 235)
local MUT = Color3.fromRGB(135, 148, 141)
local SELECTED = Color3.fromRGB(18, 35, 27)
local HOVER = Color3.fromRGB(25, 29, 27)
-- Legacy Enum.Font spreizt Glyphen, die FontFace-Familien kernen sauber.
local W = Enum.FontWeight
local face
do
    local ui = "rbxasset://fonts/families/Inter.json"
    local display = "rbxasset://fonts/families/BuilderSans.json"
    face = function(weight, useDisplay)
        return Font.new(useDisplay and display or ui, weight or W.Medium)
    end
end
local connections, painters, responsive = {}, {}, {}
local collapsed, compact = false, false
local allCards, navBtns, pages = {}, {}, {}
local currentPage = "Home"
local closeDD2, showPage, applySearch

local function make(class, props, owner)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = owner
    return obj
end
local function round(obj, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, obj)
end
local function outline(obj, color)
    return make("UIStroke", { Color = color or STROKE, Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, obj)
end
local function frame(owner, name, size, pos, color)
    return make("Frame", { Name = name, Size = size, Position = pos or UDim2.new(),
        BackgroundColor3 = color or CARD, BackgroundTransparency = color and 0 or 1,
        BorderSizePixel = 0 }, owner)
end
local function text(owner, name, value, size, pos, fontSize, color, bold, display)
    return make("TextLabel", { Name = name, Text = value, Size = size, Position = pos,
        BackgroundTransparency = 1, FontFace = face(bold and W.SemiBold or W.Regular, display),
        TextSize = fontSize or 15, TextColor3 = color or TXT, LineHeight = 1.08,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, owner)
end
local function button(owner, name, size, pos, color)
    return make("TextButton", { Name = name, Size = size, Position = pos or UDim2.new(),
        Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        BackgroundColor3 = color or CARD, BackgroundTransparency = color and 0 or 1 }, owner)
end
local function connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end
local function animate(obj, props, dur, style)
    Tween:Create(obj, TweenInfo.new(dur or 0.16, style or Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out), props):Play()
end
local function hover(obj, base, over)
    connect(obj.MouseEnter, function() animate(obj, { BackgroundColor3 = over or CTRL }) end)
    connect(obj.MouseLeave, function() animate(obj, { BackgroundColor3 = base }) end)
end
local SHEET_A = "rbxassetid://136559788074258"
local SHEET_B = "rbxassetid://70895076374895"
-- Lucide-Sprites statt gezeichneter Linien, sonst krisseln alle Schrägen.
local ICONS = {
    Home = {SHEET_A, 975, 50},
    Farm = {SHEET_A, 925, 625},
    Trees = {SHEET_B, 250, 25},
    ["Sell Zone"] = {SHEET_A, 925, 975},
    Shop = {SHEET_A, 550, 925},
    Performance = {SHEET_A, 825, 700},
    Search = {SHEET_A, 475, 950},
    Check = {SHEET_A, 325, 300},
    Close = {SHEET_B, 275, 200},
    Plus = {SHEET_A, 650, 650},
    Minus = {SHEET_A, 275, 875},
    Chevron = {SHEET_A, 100, 525},
    Arrow = {SHEET_A, 225, 75},
    Brand = {SHEET_A, 350, 0},
}
local function icon(owner, name, pos, color, size)
    local sprite = ICONS[name] or ICONS.Home
    return make("ImageLabel", { Name = "Icon", Size = UDim2.fromOffset(size or 20, size or 20),
        Position = pos, BackgroundTransparency = 1, Image = sprite[1],
        ImageRectOffset = Vector2.new(sprite[2], sprite[3]), ImageRectSize = Vector2.new(24, 24),
        ImageColor3 = color or MUT }, owner)
end
local function tintIcon(box, color)
    if box and box:IsA("ImageLabel") then box.ImageColor3 = color end
end
local function stack(owner, gap)
    return make("UIListLayout", { Padding = UDim.new(0, gap or 8),
        SortOrder = Enum.SortOrder.LayoutOrder }, owner)
end
local function padding(owner, left, top, right, bottom)
    return make("UIPadding", { PaddingLeft = UDim.new(0, left), PaddingRight = UDim.new(0, right or left),
        PaddingTop = UDim.new(0, top), PaddingBottom = UDim.new(0, bottom or top) }, owner)
end
local gui = make("ScreenGui", { Name = "CarveWoodUI", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50 }, parent)
local main = frame(gui, "Main", UDim2.fromOffset(624, 436), UDim2.fromScale(0.5, 0.5), BG)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Active = true
main.ClipsDescendants = true
local mainCorner = round(main, 10)
outline(main)
local header = frame(main, "Header", UDim2.new(1, 0, 0, 48), nil, SIDE)
local dragHandle = button(header, "DragHandle", UDim2.new(1, -84, 1, 0))
local brand = icon(header, "Brand", UDim2.fromOffset(16, 14), ACCENT, 20)
local title = text(header, "Title", "CarveWood", UDim2.fromOffset(140, 20), UDim2.fromOffset(44, 14), 17, TXT, true, true)
local version = text(header, "Version", "10.0", UDim2.fromOffset(40, 16), UDim2.fromOffset(140, 16), 12, MUT, true)
local side = frame(main, "Side", UDim2.new(0, 172, 1, -74), UDim2.fromOffset(0, 48), SIDE)
local searchWrap = frame(side, "SearchWrap", UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 12), CARD)
round(searchWrap, 6)
local searchBorder = outline(searchWrap)
icon(searchWrap, "Search", UDim2.fromOffset(9, 8), MUT, 16)
local search = make("TextBox", { Name = "Search", Size = UDim2.new(1, -32, 1, 0),
    Position = UDim2.fromOffset(30, 0), Text = "", PlaceholderText = "Search",
    PlaceholderColor3 = MUT, TextColor3 = TXT, BackgroundTransparency = 1,
    FontFace = face(W.Regular), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false }, searchWrap)
padding(search, 0, 0, 8, 0)
connect(search.Focused, function() searchBorder.Color = ACCENT end)
connect(search.FocusLost, function() searchBorder.Color = STROKE end)
local smallSearch = button(side, "SearchButton", UDim2.fromOffset(36, 36), UDim2.fromOffset(8, 10), CARD)
round(smallSearch, 6)
icon(smallSearch, "Search", UDim2.fromOffset(10, 10), MUT, 16)
smallSearch.Visible = false
local navHolder = make("ScrollingFrame", { Name = "Navigation", Position = UDim2.fromOffset(8, 52),
    Size = UDim2.new(1, -16, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, side)
stack(navHolder, 2)
local footer = frame(main, "Footer", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 1, -26), SIDE)
local footHint = text(footer, "Hint", UIS.TouchEnabled and "Drag the header to move" or "Right Shift to minimize",
    UDim2.new(1, -32, 1, 0), UDim2.fromOffset(16, 0), 12, MUT)
-- Eingeklappt: eine Pille mit Markenzeichen, Laufstatus und Aufklapp-Pfeil.
local mini, paintMini
do
    mini = frame(main, "Mini", UDim2.new(1, 0, 1, 0), nil, SIDE)
    mini.Visible = false
    mini.ZIndex = 6
    mini.Active = true
    icon(mini, "Brand", UDim2.fromOffset(14, 15), ACCENT, 18)
    text(mini, "Title", "CarveWood", UDim2.fromOffset(130, 17), UDim2.fromOffset(40, 8), 14, TXT, true, true)
    local dot = frame(mini, "Dot", UDim2.fromOffset(6, 6), UDim2.fromOffset(41, 29), MUT)
    round(dot, 3)
    local status = text(mini, "Status", "Idle", UDim2.new(1, -108, 0, 15), UDim2.fromOffset(52, 25), 11, MUT)
    local expand = button(mini, "Expand", UDim2.fromOffset(30, 30), UDim2.new(1, -8, 0.5, 0), CARD)
    expand.AnchorPoint = Vector2.new(1, 0.5)
    expand.ZIndex = 7
    round(expand, 9)
    local expandIcon = icon(expand, "Chevron", UDim2.fromOffset(7, 7), MUT, 16)
    expandIcon.Rotation = 180
    connect(expand.MouseEnter, function()
        animate(expand, { BackgroundColor3 = SELECTED }, 0.14)
        tintIcon(expandIcon, ACCENT)
    end)
    connect(expand.MouseLeave, function()
        animate(expand, { BackgroundColor3 = CARD }, 0.14)
        tintIcon(expandIcon, MUT)
    end)
    local pulse
    paintMini = function(running, label)
        status.Text = label
        dot.BackgroundColor3 = running > 0 and ACCENT or MUT
        if running > 0 and not pulse then
            pulse = Tween:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.55 })
            pulse:Play()
        elseif running == 0 and pulse then
            pulse:Cancel()
            pulse = nil
            dot.BackgroundTransparency = 0
        end
    end
end
local content = frame(main, "Content", UDim2.new(1, -172, 1, -74), UDim2.fromOffset(172, 48))
local pageHead = frame(content, "PageHeader", UDim2.new(1, -32, 0, 56), UDim2.fromOffset(16, 0))
local pageTitle = text(pageHead, "Title", "Overview", UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 12), 20, TXT, true, true)
local pageDesc = text(pageHead, "Description", "", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 36), 12, MUT)
local PAGE_INFO = {
    {"Home", "Overview", "Your session at a glance."},
    {"Farm", "Seed farming", "Reroll seeds and collect what is ready."},
    {"Trees", "Trees", "Planting priorities and tree care."},
    {"Sell Zone", "Sell Zone", ""},
    {"Shop", "Shop", "Buy and reroll stock at Moon's gem store."},
    {"Performance", "Performance", "Keep the game focused on what matters."},
}
local function makePage(name)
    local sc = make("ScrollingFrame", { Name = "Page_" .. name, Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = STROKE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, content)
    padding(sc, 16, 4, 16, 16)
    stack(sc, 6)
    pages[name] = sc
    return sc
end
for _, info in ipairs(PAGE_INFO) do makePage(info[1]) end
local homePage, farmPage, treePage, shopPage, perfPage = pages.Home, pages.Farm, pages.Trees, pages.Shop, pages.Performance
local searchPage = makePage("Search")
local noResults = text(searchPage, "NoResults", "No matching features.", UDim2.new(1, 0, 0, 48), UDim2.new(), 14, MUT)
noResults.Visible = false
-- Ein Marker für alle Einträge, er fährt zum aktiven Punkt statt zu springen.
local navSlider = frame(side, "NavSlider", UDim2.fromOffset(2, 16), UDim2.fromOffset(6, 60), ACCENT)
round(navSlider, 2)
navSlider.ZIndex = 3
navSlider.Visible = false
local function paintNav()
    local active = nil
    for name, b in pairs(navBtns) do
        local on = name == currentPage and search.Text == ""
        animate(b, { BackgroundColor3 = on and SELECTED or SIDE })
        b.Label.TextColor3 = on and TXT or MUT
        tintIcon(b.Icon, on and ACCENT or MUT)
        if on then active = b end
    end
    if not active then
        navSlider.Visible = false
        return
    end
    local y = active.AbsolutePosition.Y - side.AbsolutePosition.Y + 10
    if navSlider.Visible then
        animate(navSlider, { Position = UDim2.fromOffset(6, y) })
    else
        navSlider.Position = UDim2.fromOffset(6, y)
        navSlider.Visible = true
    end
end
showPage = function()
    for name, pg in pairs(pages) do
        local on = name == currentPage
        pg.Visible = on
        if on then
            pg.Position = UDim2.fromOffset(0, 66)
            animate(pg, { Position = UDim2.fromOffset(0, 56) }, 0.22)
        end
    end
    for _, info in ipairs(PAGE_INFO) do
        if info[1] == currentPage then
            pageTitle.Text = info[2]
            pageDesc.Text = info[3]
        end
    end
    paintNav()
end
local function navigate(name)
    if closeDD2 then closeDD2() end
    currentPage = name
    search.Text = ""
    search:ReleaseFocus()
    if compact then searchWrap.Visible = false end
    showPage()
end
local function navItem(info, order)
    local name = info[1]
    local b = button(navHolder, "Nav_" .. name, UDim2.new(1, 0, 0, 36), nil, SIDE)
    b.LayoutOrder = order
    round(b, 7)
    icon(b, name, UDim2.fromOffset(10, 9), MUT, 18)
    text(b, "Label", name, UDim2.new(1, -42, 1, 0), UDim2.fromOffset(36, 0), 14, MUT, true)
    navBtns[name] = b
    connect(b.Activated, function() navigate(name) end)
    connect(b.MouseEnter, function() if name ~= currentPage then animate(b, { BackgroundColor3 = CARD }) end end)
    connect(b.MouseLeave, paintNav)
end

local function section(page, value, order)
    local row = frame(page, "Section", UDim2.new(1, 0, 0, 22))
    row.LayoutOrder = order
    text(row, "Label", value, UDim2.new(1, 0, 1, 0), UDim2.new(), 12, MUT, true)
    return row
end

local function card(page, pageName, value, desc, order, h)
    local row = frame(page, value:gsub("%W", ""), UDim2.new(1, 0, 0, h or 56), nil, CARD)
    row.LayoutOrder = order
    row.ClipsDescendants = true
    round(row, 8)
    outline(row)
    local t = text(row, "Heading", value, UDim2.new(1, -120, 0, 20), UDim2.fromOffset(14, 9), 14, TXT, true)
    local d = text(row, "Description", desc, UDim2.new(1, -120, 0, 26), UDim2.fromOffset(14, 28), 12, MUT)
    d.LineHeight = 1.12
    d.TextWrapped = true
    d.TextTruncate = Enum.TextTruncate.None
    d.TextYAlignment = Enum.TextYAlignment.Top
    local function fit()
        local narrow = row.AbsoluteSize.X < 360
        local height = narrow and 92 or (h or 56)
        t.Size = UDim2.new(1, narrow and -28 or -120, 0, 20)
        d.Size = UDim2.new(1, narrow and -28 or -120, 0, 26)
        if not row:FindFirstChild("Body") then row.Size = UDim2.new(1, 0, 0, height) end
        row:SetAttribute("HeaderHeight", height)
    end
    connect(row:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    allCards[#allCards + 1] = { frame = row, page = pageName, title = value,
        text = string.lower(pageName .. " " .. value .. " " .. desc) }
    connect(row.MouseEnter, function()
        if not row:FindFirstChild("Body") then animate(row, { BackgroundColor3 = HOVER }, 0.18) end
    end)
    connect(row.MouseLeave, function()
        if not row:FindFirstChild("Body") then animate(row, { BackgroundColor3 = CARD }, 0.18) end
    end)
    return row
end

local function toggle(row, get, set, rightInset)
    local b = button(row, "Toggle", UDim2.fromOffset(70, 36), UDim2.new(1, rightInset or -14, 0.5, 0))
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.ZIndex = 3
    local state = text(b, "State", "", UDim2.fromOffset(30, 36), UDim2.new(), 12, MUT, true)
    local track = frame(b, "Track", UDim2.fromOffset(36, 20), UDim2.fromOffset(34, 8), CTRL)
    round(track, 10)
    local knob = frame(track, "Knob", UDim2.fromOffset(14, 14), UDim2.fromOffset(3, 3), MUT)
    round(knob, 7)
    local previous
    local function paint()
        local on = get() == true
        if on == previous then return end
        previous = on
        b:SetAttribute("Value", on)
        state.Text = on and "On" or "Off"
        state.TextColor3 = on and ACCENT or MUT
        animate(track, { BackgroundColor3 = on and ACCENT or CTRL }, 0.18)
        animate(knob, { Position = UDim2.fromOffset(on and 19 or 3, 3),
            BackgroundColor3 = on and BG or MUT }, 0.24)
    end
    local function fit()
        local stacked = row.AbsoluteSize.X < 360 and row.AbsoluteSize.Y >= 80
        b.Position = stacked and UDim2.new(1, rightInset or -14, 1, -26) or UDim2.new(1, rightInset or -14, 0.5, 0)
    end
    connect(row:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    connect(b.Activated, function() set(not get()) paint() end)
    painters[#painters + 1] = paint
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
closeDD2 = function()
    for _, f in ipairs(DD2_LISTS) do f.Visible = false end
end

-- Panel: Kopfzeile mit Schalter und Pfeil, darunter die aufklappbaren Zeilen.
local function panel(page, pageName, value, desc, order, h)
    local row = card(page, pageName, value, desc, order, h)
    local head = frame(row, "Head", UDim2.new(1, 0, 0, h or 56))
    local body = frame(row, "Body", UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, h or 56))
    body.AutomaticSize = Enum.AutomaticSize.Y
    stack(body, 2)
    padding(body, 14, 2, 14, 10)
    local divider = frame(body, "Divider", UDim2.new(1, 0, 0, 1), nil, STROKE)
    divider.BackgroundTransparency = 0.3
    divider.LayoutOrder = -10
    local chevronBtn = button(head, "Expand", UDim2.fromOffset(28, 36), UDim2.new(1, -16, 0.5, 0))
    chevronBtn.AnchorPoint = Vector2.new(1, 0.5)
    chevronBtn.ZIndex = 4
    local chevron = icon(chevronBtn, "Chevron", UDim2.fromOffset(6, 10), MUT, 16)
    local hit = button(head, "Hit", UDim2.new(1, -140, 1, 0))
    hit.ZIndex = 3
    local open, ready = true, false
    local function fit(instant)
        local hh = row:GetAttribute("HeaderHeight") or h or 56
        head.Size = UDim2.new(1, 0, 0, hh)
        body.Position = UDim2.fromOffset(0, hh)
        local target = UDim2.new(1, 0, 0, hh + (open and body.AbsoluteSize.Y or 0))
        if instant then row.Size = target else animate(row, { Size = target }, 0.22) end
        local narrow = row.AbsoluteSize.X < 380
        chevronBtn.Position = narrow and UDim2.new(1, -14, 1, -26) or UDim2.new(1, -14, 0.5, 0)
    end
    local function setOpen(v, instant)
        open = v
        row:SetAttribute("Expanded", v)
        if v then body.Visible = true end
        if instant then chevron.Rotation = v and 180 or 0
        else animate(chevron, { Rotation = v and 180 or 0 }, 0.22) end
        tintIcon(chevron, v and ACCENT or MUT)
        if not v then closeDD2() end
        fit(instant)
        if not v then
            task.delay(0.24, function() if not open then body.Visible = false end end)
        end
    end
    connect(body:GetPropertyChangedSignal("AbsoluteSize"), function() fit(not ready) end)
    connect(row:GetAttributeChangedSignal("HeaderHeight"), function() fit(not ready) end)
    connect(chevronBtn.Activated, function() setOpen(not open) end)
    connect(hit.Activated, function() setOpen(not open) end)
    connect(hit.MouseEnter, function() animate(row, { BackgroundColor3 = HOVER }, 0.18) end)
    connect(hit.MouseLeave, function() animate(row, { BackgroundColor3 = CARD }, 0.18) end)
    setOpen(true, true)
    task.defer(function() ready = true end)
    return { frame = row, body = body, head = head, setOpen = setOpen }
end

-- Zeile im Panel-Body, registriert für die Suche.
local function subRow(body, pageName, value, rootCard, order)
    local r = frame(body, value:gsub("%W", ""), UDim2.new(1, 0, 0, 42))
    r.LayoutOrder = order
    text(r, "Label", value, UDim2.new(1, -110, 1, 0), UDim2.new(), 13, TXT)
    allCards[#allCards + 1] = { frame = r, page = pageName, title = value,
        text = string.lower(pageName .. " " .. value), root = rootCard.frame, open = rootCard.setOpen }
    return r
end

local function subToggle(body, pageName, value, rootCard, order, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local function fit()
        local narrow = r.AbsoluteSize.X < 320
        r.Size = UDim2.new(1, 0, 0, narrow and 72 or 42)
        r.Label.Size = UDim2.new(1, narrow and -28 or -110, 0, narrow and 32 or 42)
        local t = r:FindFirstChild("Toggle")
        if t then t.Position = narrow and UDim2.new(1, -2, 1, -24) or UDim2.new(1, -2, 0.5, 0) end
    end
    local result = toggle(r, get, set, -2)
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    return result
end

-- Listen fahren auf ihre Inhaltshöhe aus, statt als Block zu erscheinen.
local function listOpener(list, height)
    return function(vis)
        if vis then
            list.Size = UDim2.new(1, 0, 0, 0)
            list.Visible = true
            animate(list, { Size = UDim2.new(1, 0, 0, height) }, 0.2)
        else
            animate(list, { Size = UDim2.new(1, 0, 0, 0) }, 0.14)
            task.delay(0.16, function()
                if list.Size.Y.Offset <= 2 then list.Visible = false end
            end)
        end
    end
end

-- Dropdown: Zeile mit Auswahlfeld, Liste klappt darunter auf.
local function subDropdown(body, pageName, value, rootCard, order, options, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local b = button(r, "Dropdown", UDim2.fromOffset(188, 34), UDim2.new(1, -2, 0.5, 0), SIDE)
    b.AnchorPoint = Vector2.new(1, 0.5)
    round(b, 8)
    local border = outline(b)
    local selected = text(b, "Value", "", UDim2.new(1, -42, 0, 17), UDim2.fromOffset(11, 3), 13, TXT, true)
    local rarity = text(b, "Rarity", "", UDim2.new(1, -42, 0, 13), UDim2.fromOffset(11, 19), 11, MUT)
    local arrow = icon(b, "Chevron", UDim2.new(1, -26, 0.5, -7), MUT, 14)
    local listHeight = math.min(224, 52 + #options * 40)
    local list = frame(body, "Options_" .. order, UDim2.new(1, 0, 0, listHeight), nil, SIDE)
    list.LayoutOrder = order + 1
    list.Visible = false
    local setList = listOpener(list, listHeight)
    list.ClipsDescendants = true
    round(list, 8)
    outline(list)
    DD2_LISTS[#DD2_LISTS + 1] = list
    local filterWrap = frame(list, "Filter", UDim2.new(1, -16, 0, 30), UDim2.fromOffset(8, 8), CARD)
    round(filterWrap, 6)
    icon(filterWrap, "Search", UDim2.fromOffset(9, 8), MUT, 14)
    local filter = make("TextBox", { Name = "Search", Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.fromOffset(28, 0), Text = "", PlaceholderText = "Search a tree or rarity",
        PlaceholderColor3 = MUT, TextColor3 = TXT, BackgroundTransparency = 1,
        ClearTextOnFocus = false, FontFace = face(W.Regular), TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left }, filterWrap)
    local sc = make("ScrollingFrame", { Name = "Options", Position = UDim2.fromOffset(8, 44),
        Size = UDim2.new(1, -16, 1, -52), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = STROKE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, list)
    stack(sc, 2)
    padding(sc, 2, 1, 7, 1)
    local empty = text(sc, "Empty", "No matching trees.", UDim2.new(1, 0, 0, 48), UDim2.new(), 14, MUT)
    empty.Visible = false
    local optionButtons = {}
    local function paint()
        local cur = get()
        selected.Text = tostring(cur)
        rarity.Text = ""
        for i, opt in ipairs(options) do
            local active = opt.value == cur
            local ob = optionButtons[i]
            ob.BackgroundColor3 = active and SELECTED or SIDE
            ob.SelectionMark.Visible = active
            if active then
                rarity.Text = opt.rarity
                rarity.TextColor3 = RARITY_COLORS[opt.rarity] or MUT
            end
        end
    end
    for i, opt in ipairs(options) do
        local ob = button(sc, "Option_" .. opt.value, UDim2.new(1, 0, 0, 38), nil, SIDE)
        ob.LayoutOrder = i
        round(ob, 6)
        local dot = frame(ob, "RarityDot", UDim2.fromOffset(4, 4), UDim2.fromOffset(10, 17), RARITY_COLORS[opt.rarity] or MUT)
        round(dot, 2)
        text(ob, "Name", opt.value, UDim2.new(1, -84, 0, 17), UDim2.fromOffset(24, 4), 13, TXT, true)
        text(ob, "Rarity", opt.rarity, UDim2.new(1, -84, 0, 14), UDim2.fromOffset(24, 21), 11, MUT)
        local mark = text(ob, "SelectionMark", "Selected", UDim2.fromOffset(64, 38), UDim2.new(1, -72, 0, 0), 11, ACCENT)
        mark.TextXAlignment = Enum.TextXAlignment.Right
        optionButtons[i] = ob
        connect(ob.Activated, function() set(opt.value) paint() filter:ReleaseFocus() setList(false) end)
        connect(ob.MouseEnter, function() if get() ~= opt.value then animate(ob, { BackgroundColor3 = HOVER }, 0.12) end end)
        connect(ob.MouseLeave, paint)
    end
    connect(filter:GetPropertyChangedSignal("Text"), function()
        local q = string.lower(filter.Text)
        local count = 0
        for i, opt in ipairs(options) do
            local match = string.find(string.lower(opt.value .. " " .. opt.rarity), q, 1, true) ~= nil
            optionButtons[i].Visible = match
            if match then count = count + 1 end
        end
        empty.Visible = count == 0
        sc.CanvasPosition = Vector2.zero
    end)
    connect(list:GetPropertyChangedSignal("Visible"), function()
        arrow.Rotation = list.Visible and 180 or 0
        border.Color = list.Visible and ACCENT or STROKE
        if not list.Visible then filter:ReleaseFocus() end
    end)
    connect(b.Activated, function()
        local was = list.Visible
        closeDD2()
        setList(not was)
        if not was then
            filter.Text = ""
            paint()
            task.defer(function()
                if not gui.Parent or not list.Visible then return end
                local pg = pages[pageName]
                local overflow = list.AbsolutePosition.Y + list.AbsoluteSize.Y - pg.AbsolutePosition.Y - pg.AbsoluteSize.Y
                if overflow > 0 then
                    local top = r.AbsolutePosition.Y - pg.AbsolutePosition.Y + pg.CanvasPosition.Y
                    pg.CanvasPosition = Vector2.new(0, math.max(0, math.min(top, pg.CanvasPosition.Y + overflow + 12)))
                end
            end)
        end
    end)
    local function fit()
        local narrow = r.AbsoluteSize.X < 340
        r.Size = UDim2.new(1, 0, 0, narrow and 74 or 46)
        r.Label.Size = UDim2.new(1, narrow and -24 or -200, 0, narrow and 30 or 46)
        b.Size = narrow and UDim2.new(1, -16, 0, 34) or UDim2.fromOffset(188, 34)
        b.Position = narrow and UDim2.new(1, -2, 1, -26) or UDim2.new(1, -2, 0.5, 0)
    end
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    paint()
    return { repaint = paint }
end

-- Zeile mit zwei Wahlknöpfen, für Optionen die keine Liste brauchen.
-- Dropdown mit Mehrfachauswahl: Liste bleibt offen, jede Zeile hakt sich einzeln an.
local function subMulti(body, pageName, value, rootCard, order, options, isOn, setOn)
    local r = subRow(body, pageName, value, rootCard, order)
    local b = button(r, "Dropdown", UDim2.fromOffset(188, 34), UDim2.new(1, -2, 0.5, 0), SIDE)
    b.AnchorPoint = Vector2.new(1, 0.5)
    round(b, 8)
    local border = outline(b)
    local selected = text(b, "Value", "", UDim2.new(1, -42, 0, 17), UDim2.fromOffset(11, 3), 13, TXT, true)
    local summary = text(b, "Summary", "", UDim2.new(1, -42, 0, 13), UDim2.fromOffset(11, 19), 11, MUT)
    local arrow = icon(b, "Chevron", UDim2.new(1, -26, 0.5, -7), MUT, 14)
    local listHeight = math.min(224, 14 + #options * 40)
    local list = frame(body, "Picks_" .. order, UDim2.new(1, 0, 0, listHeight), nil, SIDE)
    list.LayoutOrder = order + 1
    list.Visible = false
    local setList = listOpener(list, listHeight)
    list.ClipsDescendants = true
    round(list, 8)
    outline(list)
    DD2_LISTS[#DD2_LISTS + 1] = list
    local sc = make("ScrollingFrame", { Name = "Options", Position = UDim2.fromOffset(8, 7),
        Size = UDim2.new(1, -16, 1, -14), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = STROKE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, list)
    stack(sc, 2)
    padding(sc, 2, 1, 7, 1)
    local optionButtons = {}
    local function paint()
        local picked = {}
        for i, opt in ipairs(options) do
            local on = isOn(opt.value) == true
            local ob = optionButtons[i]
            ob.BackgroundColor3 = on and SELECTED or SIDE
            ob.Box.BackgroundColor3 = on and ACCENT or SIDE
            ob.Box.Mark.Visible = on
            ob.Box.BoxStroke.Color = on and ACCENT or STROKE
            if on then picked[#picked + 1] = opt.label or opt.value end
        end
        if #picked == 0 then
            selected.Text = "Nothing picked"
            selected.TextColor3 = MUT
            summary.Text = "Tap to choose items"
        else
            selected.Text = #picked == 1 and picked[1] or (#picked .. " items")
            selected.TextColor3 = TXT
            summary.Text = table.concat(picked, ", ")
        end
    end
    for i, opt in ipairs(options) do
        local ob = button(sc, "Pick_" .. opt.value, UDim2.new(1, 0, 0, 38), nil, SIDE)
        ob.LayoutOrder = i
        round(ob, 6)
        local box = frame(ob, "Box", UDim2.fromOffset(16, 16), UDim2.fromOffset(10, 11), SIDE)
        round(box, 4)
        local boxStroke = outline(box)
        boxStroke.Name = "BoxStroke"
        local mark = icon(box, "Check", UDim2.fromOffset(2, 2), BG, 12)
        mark.Name = "Mark"
        text(ob, "Name", opt.value, UDim2.new(1, -80, 0, 17), UDim2.fromOffset(34, 3), 13, TXT, true)
        text(ob, "Note", opt.note or "", UDim2.new(1, -80, 0, 14), UDim2.fromOffset(34, 20), 11, MUT)
        optionButtons[i] = ob
        connect(ob.Activated, function() setOn(opt.value, not isOn(opt.value)) paint() end)
        connect(ob.MouseEnter, function() if not isOn(opt.value) then animate(ob, { BackgroundColor3 = HOVER }, 0.12) end end)
        connect(ob.MouseLeave, paint)
    end
    connect(list:GetPropertyChangedSignal("Visible"), function()
        arrow.Rotation = list.Visible and 180 or 0
        border.Color = list.Visible and ACCENT or STROKE
    end)
    connect(b.Activated, function()
        local was = list.Visible
        closeDD2()
        setList(not was)
        if not was then
            paint()
            task.defer(function()
                if not gui.Parent or not list.Visible then return end
                local pg = pages[pageName]
                local overflow = list.AbsolutePosition.Y + list.AbsoluteSize.Y - pg.AbsolutePosition.Y - pg.AbsoluteSize.Y
                if overflow > 0 then
                    local top = r.AbsolutePosition.Y - pg.AbsolutePosition.Y + pg.CanvasPosition.Y
                    pg.CanvasPosition = Vector2.new(0, math.max(0, math.min(top, pg.CanvasPosition.Y + overflow + 12)))
                end
            end)
        end
    end)
    local function fit()
        local narrow = r.AbsoluteSize.X < 340
        r.Size = UDim2.new(1, 0, 0, narrow and 74 or 46)
        r.Label.Size = UDim2.new(1, narrow and -24 or -200, 0, narrow and 30 or 46)
        b.Size = narrow and UDim2.new(1, -16, 0, 34) or UDim2.fromOffset(188, 34)
        b.Position = narrow and UDim2.new(1, -2, 1, -26) or UDim2.new(1, -2, 0.5, 0)
    end
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    paint()
    return { repaint = paint }
end

local function subChoice(body, pageName, value, rootCard, order, options, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local wrap = frame(r, "Choice", UDim2.fromOffset(188, 34), UDim2.new(1, -2, 0.5, 0), SIDE)
    wrap.AnchorPoint = Vector2.new(1, 0.5)
    round(wrap, 8)
    outline(wrap)
    local entries = {}
    local function paint()
        for _, e in ipairs(entries) do
            local on = e.value == get()
            e.button.BackgroundColor3 = on and SELECTED or SIDE
            e.label.TextColor3 = on and ACCENT or MUT
        end
    end
    for i, opt in ipairs(options) do
        local b = button(wrap, "Choice_" .. i, UDim2.new(0.5, -5, 1, -6), UDim2.new((i - 1) * 0.5, 3, 0, 3), SIDE)
        round(b, 5)
        local l = text(b, "Label", opt.label or opt.value, UDim2.new(1, 0, 1, 0), UDim2.new(), 12, MUT, true)
        l.TextXAlignment = Enum.TextXAlignment.Center
        entries[#entries + 1] = { value = opt.value, button = b, label = l }
        connect(b.Activated, function() set(opt.value) paint() end)
    end
    local function fit()
        local narrow = r.AbsoluteSize.X < 340
        r.Size = UDim2.new(1, 0, 0, narrow and 74 or 46)
        r.Label.Size = UDim2.new(1, narrow and -24 or -200, 0, narrow and 30 or 46)
        wrap.Size = narrow and UDim2.new(1, -16, 0, 34) or UDim2.fromOffset(188, 34)
        wrap.Position = narrow and UDim2.new(1, -2, 1, -26) or UDim2.new(1, -2, 0.5, 0)
    end
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    painters[#painters + 1] = paint
    paint()
    return { repaint = paint }
end

-- Zeile mit Zahlenfeld, nimmt nur Ziffern.
local function subNumber(body, pageName, value, rootCard, order, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local box = make("TextBox", { Name = "Input", Size = UDim2.fromOffset(236, 48),
        Position = UDim2.new(1, -4, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = SIDE, BorderSizePixel = 0, Text = tostring(get() or 0),
        PlaceholderText = "0", PlaceholderColor3 = MUT, TextColor3 = TXT,
        FontFace = face(W.SemiBold), TextSize = 13, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left }, r)
    round(box, 8)
    local border = outline(box)
    padding(box, 11, 0, 11, 0)
    connect(box.Focused, function() border.Color = ACCENT end)
    connect(box.FocusLost, function()
        border.Color = STROKE
        local n = tonumber((string.gsub(box.Text, "%D", ""))) or 0
        set(n)
        box.Text = tostring(n)
    end)
    local function fit()
        local narrow = r.AbsoluteSize.X < 340
        r.Size = UDim2.new(1, 0, 0, narrow and 74 or 46)
        r.Label.Size = UDim2.new(1, narrow and -24 or -200, 0, narrow and 30 or 46)
        box.Size = narrow and UDim2.new(1, -16, 0, 34) or UDim2.fromOffset(188, 34)
        box.Position = narrow and UDim2.new(1, -2, 1, -26) or UDim2.new(1, -2, 0.5, 0)
    end
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    return { repaint = function() if not box:IsFocused() then box.Text = tostring(get() or 0) end end }
end

section(homePage, "This session", 1)
do
    local strip = frame(homePage, "Stats", UDim2.new(1, 0, 0, 62), nil, CARD)
    strip.LayoutOrder = 2
    round(strip, 8)
    outline(strip)
    local cells = {}
    for i, d in ipairs({{"Runtime", "CWValTime", "0s"}, {"Rerolls", "CWValRolls", "0"},
        {"Chopped", "CWValTrees", "0"}, {"Bought", "CWValBuys", "0"}}) do
        local cell = frame(strip, d[2] .. "Cell", UDim2.new(0.25, 0, 1, 0), UDim2.new((i - 1) / 4, 0, 0, 0))
        text(cell, "Label", d[1], UDim2.new(1, -18, 0, 14), UDim2.fromOffset(14, 12), 11, MUT)
        text(cell, d[2], d[3], UDim2.new(1, -18, 0, 24), UDim2.fromOffset(14, 28), 18, i == 1 and ACCENT or TXT, true, true)
        if i > 1 then
            local sep = frame(cell, "Sep", UDim2.fromOffset(1, 30), UDim2.fromOffset(0, 16), STROKE)
            sep.BackgroundTransparency = 0.4
        end
        cells[i] = cell
    end
    local function fit()
        local narrow = strip.AbsoluteSize.X < 400
        strip.Size = UDim2.new(1, 0, 0, narrow and 124 or 62)
        for i, cell in ipairs(cells) do
            cell.Size = narrow and UDim2.new(0.5, 0, 0, 62) or UDim2.new(0.25, 0, 1, 0)
            cell.Position = narrow and UDim2.new(((i - 1) % 2) * 0.5, 0, 0, math.floor((i - 1) / 2) * 62)
                or UDim2.new((i - 1) / 4, 0, 0, 0)
            local sep = cell:FindFirstChild("Sep")
            if sep then sep.Visible = not narrow or i % 2 == 0 end
        end
    end
    connect(strip:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
end
section(homePage, "Workflows", 5)
for i, data in ipairs({{"Farm", "Seed farming", "Rerolls, frenzy and collection", "CW_Farm"},
    {"Trees", "Tree management", "Planting, priorities and fertilizer", "CW_Trees"},
    {"Shop", "Gem store", "Buying picked items and restocking", "CW_Shop"}}) do
    local row = button(homePage, "Open_" .. data[1], UDim2.new(1, 0, 0, 52), nil, CARD)
    row.LayoutOrder = i + 5
    round(row, 8)
    outline(row)
    icon(row, data[1], UDim2.fromOffset(14, 17), ACCENT, 18)
    text(row, "Title", data[2], UDim2.new(1, -150, 0, 18), UDim2.fromOffset(42, 9), 14, TXT, true)
    local desc = text(row, "Description", data[3], UDim2.new(1, -150, 0, 16), UDim2.fromOffset(42, 27), 12, MUT)
    local state = text(row, "State", "", UDim2.fromOffset(60, 52), UDim2.new(1, -70, 0, 0), 12, MUT)
    state.TextXAlignment = Enum.TextXAlignment.Right
    icon(row, "Arrow", UDim2.new(1, -30, 0.5, -7), MUT, 14)
    hover(row, CARD)
    connect(row.Activated, function() navigate(data[1]) end)
    painters[#painters + 1] = function()
        local on = getgenv()[data[4]] == true
        state.Text = on and "Running" or "Off"
        state.TextColor3 = on and ACCENT or MUT
        desc.Visible = row.AbsoluteSize.X >= 320
    end
end

section(farmPage, "Seed cycle", 1)
do
    local ec = panel(farmPage, "Farm", "Auto farm seeds", "Reroll seeds, wait for results, then collect.", 2, 56)
    toggle(ec.head, function() return getgenv().CW_Farm end,
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
        end, -52)
    subToggle(ec.body, "Farm", "Auto frenzy", ec, 10,
        function() return getgenv().CW_Frenzy end,
        function(v) getgenv().CW_Frenzy = v end)
end
section(farmPage, "Collection", 3)
toggle(card(farmPage, "Farm", "Watering cans", "Collect ready 256x cans. Skip when the limit is reached.", 4),
    function() return getgenv().CW_CollectCan end,
    function(v) getgenv().CW_CollectCan = v end)
toggle(card(farmPage, "Farm", "Diamond fertilizer", "Collect only fully grown diamond fertilizer.", 5),
    function() return getgenv().CW_CollectFert end,
    function(v) getgenv().CW_CollectFert = v end)

section(treePage, "Planting and care", 1)
do
    local ec = panel(treePage, "Trees", "Auto trees", "Plant by priority, chop mature trees and collect drops.", 2, 56)
    toggle(ec.head,
        function() return getgenv().CW_Trees end,
        function(v) getgenv().CW_Trees = v end, -52)
    subToggle(ec.body, "Trees", "Auto fertilize", ec, 10,
        function() return getgenv().CW_Fert end,
        function(v) getgenv().CW_Fert = v end)
    local opts = {}
    opts[#opts + 1] = { value = "None", rarity = "Off" }
    for _, e in ipairs(CW_TREE_TYPES) do
        opts[#opts + 1] = { value = e[1], rarity = e[2], label = e[1] .. " · " .. e[2] }
    end
    subDropdown(ec.body, "Trees", "Priority 1", ec, 20, opts,
        function() return getgenv().CW_Prio1 end,
        function(v) getgenv().CW_Prio1 = v end)
    subDropdown(ec.body, "Trees", "Priority 2", ec, 30, opts,
        function() return getgenv().CW_Prio2 end,
        function(v) getgenv().CW_Prio2 = v end)
    subDropdown(ec.body, "Trees", "Priority 3", ec, 40, opts,
        function() return getgenv().CW_Prio3 end,
        function(v) getgenv().CW_Prio3 = v end)
end
local priorityHelp = text(treePage, "PriorityHelp", "Priority 1 is planted first. If those seeds run out, priority 2 takes over, then priority 3.",
    UDim2.new(1, 0, 0, 44), UDim2.new(), 14, MUT)
priorityHelp.LayoutOrder = 3
priorityHelp.TextWrapped = true
priorityHelp.TextTruncate = Enum.TextTruncate.None

section(shopPage, "Gem store", 1)
do
    local ec = panel(shopPage, "Shop", "Auto buy", "Empty every picked slot, then wait for new stock.", 2, 56)
    toggle(ec.head,
        function() return getgenv().CW_Shop end,
        function(v) getgenv().CW_Shop = v end, -52)
    local opts = {}
    local byName = {}
    for _, it in ipairs(CW_SHOP_ITEMS) do
        opts[#opts + 1] = { value = it.name, note = it.price .. " gems" }
        byName[it.name] = it.id
    end
    subMulti(ec.body, "Shop", "Items to buy", ec, 10, opts,
        function(name) return shopPicked(byName[name]) end,
        function(name, on)
            local pick = getgenv().CW_ShopPick
            if type(pick) ~= "table" then
                pick = {}
                getgenv().CW_ShopPick = pick
            end
            pick[byName[name]] = on or nil
        end)
end
section(shopPage, "Restock", 3)
do
    local ec = panel(shopPage, "Shop", "Auto refresh", "Roll fresh stock once nothing picked is left, then buy again.", 4, 56)
    toggle(ec.head,
        function() return getgenv().CW_ShopRoll end,
        function(v) getgenv().CW_ShopRoll = v end, -52)
    subChoice(ec.body, "Shop", "Pay rolls with", ec, 10,
        {{ value = "Gems", label = "Gems (100)" }, { value = "Wood Chips", label = "Chips (5000)" }},
        function() return getgenv().CW_ShopPay end,
        function(v) getgenv().CW_ShopPay = v end)
    subNumber(ec.body, "Shop", "Keep at least this many gems", ec, 20,
        function() return getgenv().CW_ShopFloor end,
        function(v) getgenv().CW_ShopFloor = v end)
    subToggle(ec.body, "Shop", "Stay at the store", ec, 30,
        function() return getgenv().CW_ShopStay end,
        function(v) getgenv().CW_ShopStay = v end)
end
local shopHelp = text(shopPage, "ShopHelp", "Buying and rolling teleport you to the store and back. Once gems hit the limit every gem purchase stops, wood chip rolls keep running.",
    UDim2.new(1, 0, 0, 44), UDim2.new(), 14, MUT)
shopHelp.LayoutOrder = 5
shopHelp.TextWrapped = true
shopHelp.TextTruncate = Enum.TextTruncate.None

section(perfPage, "Rendering", 1)
toggle(card(perfPage, "Performance", "Low quality mode", "Reduce effects, lights and shadows. Everything is restored when you turn it off.", 2),
    function() return getgenv().CW_LowQ end,
    function(v) getgenv().CW_LowQ = v if v then lowQOn() else lowQOff() end end)

for i, info in ipairs(PAGE_INFO) do navItem(info, i) end
local results = {}
for i, entry in ipairs(allCards) do
    local b = button(searchPage, "Result_" .. i, UDim2.new(1, 0, 0, 64), nil, CARD)
    b.LayoutOrder = i
    round(b, 6)
    outline(b)
    text(b, "Title", entry.title, UDim2.new(1, -58, 0, 26), UDim2.fromOffset(18, 11), 16, TXT, true)
    text(b, "Page", entry.page, UDim2.new(1, -58, 0, 20), UDim2.fromOffset(18, 39), 13, MUT)
    icon(b, "Arrow", UDim2.new(1, -28, 0.5, -7), MUT, 14)
    hover(b, CARD)
    connect(b.Activated, function()
        navigate(entry.page)
        if entry.open then entry.open(true) end
        task.defer(function()
            if not gui.Parent then return end
            local pg = pages[entry.page]
            pg.CanvasPosition = Vector2.new(0, math.max(0, pg.CanvasPosition.Y + entry.frame.AbsolutePosition.Y - pg.AbsolutePosition.Y - 16))
        end)
    end)
    results[i] = b
end
applySearch = function()
    closeDD2()
    local q = string.lower(search.Text):match("^%s*(.-)%s*$")
    if q == "" then showPage() return end
    for name, pg in pairs(pages) do pg.Visible = name == "Search" end
    local count = 0
    for i, entry in ipairs(allCards) do
        local match = string.find(entry.text, q, 1, true) ~= nil
        results[i].Visible = match
        if match then count = count + 1 end
    end
    noResults.Visible = count == 0
    searchPage.CanvasPosition = Vector2.zero
    pageTitle.Text = "Search results"
    pageDesc.Text = tostring(count) .. (count == 1 and " feature found" or " features found")
    paintNav()
end
connect(search:GetPropertyChangedSignal("Text"), applySearch)

local btnMin = button(header, "Minimize", UDim2.fromOffset(34, 34), UDim2.new(1, -76, 0, 7), SIDE)
round(btnMin, 6)
local minIcon = icon(btnMin, "Minus", UDim2.fromOffset(9, 9), MUT, 16)
local plusIcon = icon(btnMin, "Plus", UDim2.fromOffset(9, 9), MUT, 16)
plusIcon.Visible = false
plusIcon.Visible = false
hover(btnMin, SIDE)
local btnX = button(header, "Close", UDim2.fromOffset(34, 34), UDim2.new(1, -40, 0, 7), SIDE)
round(btnX, 6)
icon(btnX, "Close", UDim2.fromOffset(9, 9), MUT, 16)
hover(btnX, SIDE, Color3.fromRGB(57, 35, 37))
-- Vier Ecken ziehen die Größe, jede merkt sich ihre Richtung als Attribut.
local resizeGrips = {}
for _, corner in ipairs({{"TopLeft", -1, -1}, {"TopRight", 1, -1}, {"BottomLeft", -1, 1}, {"BottomRight", 1, 1}}) do
    local dx, dy = corner[2], corner[3]
    local grip = button(main, "Resize" .. corner[1], UDim2.fromOffset(UIS.TouchEnabled and 40 or 30, UIS.TouchEnabled and 40 or 30),
        UDim2.new(dx > 0 and 1 or 0, dx > 0 and (UIS.TouchEnabled and -40 or -30) or 0,
            dy > 0 and 1 or 0, dy > 0 and (UIS.TouchEnabled and -40 or -30) or 0))
    grip.ZIndex = 12
    grip:SetAttribute("DirX", dx)
    grip:SetAttribute("DirY", dy)
    local arm = frame(grip, "ArmX", UDim2.fromOffset(11, 2), UDim2.fromOffset(dx > 0 and 11 or 8, dy > 0 and 20 or 8), MUT)
    local armY = frame(grip, "ArmY", UDim2.fromOffset(2, 11), UDim2.fromOffset(dx > 0 and 20 or 8, dy > 0 and 11 or 8), MUT)
    arm.BackgroundTransparency = 0.55
    armY.BackgroundTransparency = 0.55
    round(arm, 1)
    round(armY, 1)
    connect(grip.MouseEnter, function()
        animate(arm, { BackgroundColor3 = ACCENT, BackgroundTransparency = 0 }, 0.12)
        animate(armY, { BackgroundColor3 = ACCENT, BackgroundTransparency = 0 }, 0.12)
    end)
    connect(grip.MouseLeave, function()
        animate(arm, { BackgroundColor3 = MUT, BackgroundTransparency = 0.55 }, 0.12)
        animate(armY, { BackgroundColor3 = MUT, BackgroundTransparency = 0.55 }, 0.12)
    end)
    resizeGrips[#resizeGrips + 1] = grip
end
local modal = button(main, "ConfirmClose", UDim2.fromScale(1, 1), nil, BG)
modal.BackgroundTransparency = 0.12
modal.ZIndex = 20
modal.Visible = false
modal.Modal = true
local dialog = frame(modal, "Dialog", UDim2.fromOffset(390, 212), UDim2.fromScale(0.5, 0.5), CARD)
dialog.AnchorPoint = Vector2.new(0.5, 0.5)
round(dialog, 10)
outline(dialog)
text(dialog, "Title", "End this session?", UDim2.new(1, -40, 0, 30), UDim2.fromOffset(22, 26), 21, TXT, true)
local warning = text(dialog, "Description", "All automations will stop and visual settings will be restored.",
    UDim2.new(1, -44, 0, 60), UDim2.fromOffset(22, 70), 15, MUT)
warning.TextWrapped = true
warning.TextTruncate = Enum.TextTruncate.None
local cancel = button(dialog, "Cancel", UDim2.new(0.5, -26, 0, 44), UDim2.new(0, 20, 1, -64), CTRL)
local confirm = button(dialog, "StopSession", UDim2.new(0.5, -26, 0, 44), UDim2.new(0.5, 6, 1, -64), Color3.fromRGB(62, 37, 39))
for _, b in ipairs({cancel, confirm}) do round(b, 6) end
local cancelText = text(cancel, "Label", "Cancel", UDim2.fromScale(1, 1), UDim2.new(), 15, TXT, true)
local confirmText = text(confirm, "Label", "Stop session", UDim2.fromScale(1, 1), UDim2.new(), 15, Color3.fromRGB(245, 170, 172), true)
cancelText.TextXAlignment = Enum.TextXAlignment.Center
confirmText.TextXAlignment = Enum.TextXAlignment.Center
connect(cancel.Activated, function() modal.Visible = false end)

local fullSize = Vector2.new(624, 436)
local mobileSearchOpen = false
local function availableSize()
    local size = gui.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return workspace.CurrentCamera.ViewportSize end
    return size
end
local function clampPosition()
    local vp = availableSize()
    local size = main.AbsoluteSize
    local cx = main.Position.X.Scale * vp.X + main.Position.X.Offset
    local cy = main.Position.Y.Scale * vp.Y + main.Position.Y.Offset
    main.Position = UDim2.fromOffset(
        math.clamp(cx, size.X / 2 + 8, math.max(size.X / 2 + 8, vp.X - size.X / 2 - 8)),
        math.clamp(cy, size.Y / 2 + 8, math.max(size.Y / 2 + 8, vp.Y - size.Y / 2 - 8)))
end
local function layout()
    if collapsed or main:GetAttribute("Animating") then return end
    local w = main.AbsoluteSize.X
    compact = w < 520
    main:SetAttribute("Compact", compact)
    local sw = compact and 52 or (w < 660 and 152 or 172)
    side.Size = UDim2.new(0, sw, 1, -74)
    content.Position = UDim2.fromOffset(sw, 48)
    content.Size = UDim2.new(1, -sw, 1, -74)
    navHolder.Position = UDim2.fromOffset(compact and 8 or 8, compact and 50 or 52)
    navHolder.Size = UDim2.new(1, compact and -16 or -16, 1, compact and -58 or -60)
    for _, b in pairs(navBtns) do b.Label.Visible = not compact end
    smallSearch.Visible = compact
    searchWrap.Parent = compact and header or side
    searchWrap.Position = compact and UDim2.fromOffset(52, 9) or UDim2.fromOffset(10, 12)
    searchWrap.Size = compact and UDim2.new(1, -140, 0, 30) or UDim2.new(1, -20, 0, 32)
    searchWrap.Visible = not compact or mobileSearchOpen
    searchWrap.ZIndex = 4
    title.Visible = not (compact and mobileSearchOpen)
    version.Visible = not compact
    footHint.Visible = not compact
    dialog.Size = UDim2.fromOffset(math.min(360, w - 24), 190)
    for _, grip in ipairs(resizeGrips) do grip.Visible = not collapsed end
    local inset = compact and 12 or 16
    pageHead.Position = UDim2.fromOffset(inset, 0)
    pageHead.Size = UDim2.new(1, -inset * 2, 0, 56)
    pageDesc.TextWrapped = true
    pageDesc.TextTruncate = Enum.TextTruncate.None
    pageDesc.Size = UDim2.new(1, 0, 0, 18)
    for _, pg in pairs(pages) do
        pg.Position = UDim2.fromOffset(0, 56)
        pg.Size = UDim2.new(1, 0, 1, -56)
        local pad = pg:FindFirstChildOfClass("UIPadding")
        pad.PaddingLeft = UDim.new(0, inset)
        pad.PaddingRight = UDim.new(0, inset)
    end
    for _, fit in ipairs(responsive) do fit() end
end
local function fitViewport()
    local vp = availableSize()
    fullSize = Vector2.new(math.min(fullSize.X, vp.X - 24), math.min(fullSize.Y, vp.Y - 24))
    main.Size = collapsed and UDim2.fromOffset(math.min(244, vp.X - 24), 50) or UDim2.fromOffset(fullSize.X, fullSize.Y)
    clampPosition()
    layout()
end
-- Die Pille wächst aus dem Fenster heraus, darum bleibt das Layout während des Tweens stehen.
local function setCollapsed(value)
    if value == collapsed then return end
    closeDD2()
    search:ReleaseFocus()
    if value then fullSize = main.AbsoluteSize end
    collapsed = value
    main:SetAttribute("Collapsed", value)
    main:SetAttribute("Animating", true)
    mini.Visible = value
    header.Visible = not value
    side.Visible = not value
    content.Visible = not value
    footer.Visible = not value
    version.Visible = not value
    for _, grip in ipairs(resizeGrips) do grip.Visible = not value end
    searchWrap.Visible = not value and not compact
    title.Visible = true
    mobileSearchOpen = false
    modal.Visible = false
    local vp = availableSize()
    animate(main, { Size = value and UDim2.fromOffset(math.min(244, vp.X - 24), 50)
        or UDim2.fromOffset(fullSize.X, fullSize.Y) }, 0.34)
    animate(mainCorner, { CornerRadius = UDim.new(0, value and 25 or 10) }, 0.34)
    task.delay(0.36, function()
        main:SetAttribute("Animating", false)
        clampPosition()
        if not collapsed then layout() end
    end)
end
connect(btnMin.Activated, function() setCollapsed(not collapsed) end)
connect(btnX.Activated, function() setCollapsed(false) closeDD2() modal.Visible = true end)
connect(confirm.Activated, function()
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
connect(smallSearch.Activated, function()
    mobileSearchOpen = not mobileSearchOpen
    layout()
    if mobileSearchOpen then search:CaptureFocus() else search.Text = "" search:ReleaseFocus() end
end)
connect(search.FocusLost, function()
    if compact and search.Text == "" then mobileSearchOpen = false layout() end
end)
local pointer, gesture, startPointer, startPosition, startSize, gripDir
local function beginGesture(input, mode, grip)
    if modal.Visible then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    pointer, gesture = input, mode
    gripDir = grip and Vector2.new(grip:GetAttribute("DirX"), grip:GetAttribute("DirY")) or Vector2.one
    startPointer = Vector2.new(input.Position.X, input.Position.Y)
    startPosition = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
    startSize = main.AbsoluteSize
    closeDD2()
end
connect(dragHandle.InputBegan, function(input) beginGesture(input, "drag") end)
connect(mini.InputBegan, function(input) beginGesture(input, "drag") end)
connect(mini.Expand.Activated, function() setCollapsed(false) end)
for _, grip in ipairs(resizeGrips) do
    connect(grip.InputBegan, function(input) beginGesture(input, "resize", grip) end)
end
connect(UIS.InputChanged, function(input)
    if not pointer then return end
    if input ~= pointer and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = Vector2.new(input.Position.X, input.Position.Y) - startPointer
    if gesture == "drag" then
        main.Position = UDim2.fromOffset(startPosition.X + delta.X, startPosition.Y + delta.Y)
    else
        local vp = availableSize()
        local w = math.clamp(startSize.X + delta.X * gripDir.X, math.min(340, vp.X - 24), vp.X - 24)
        local h = math.clamp(startSize.Y + delta.Y * gripDir.Y, math.min(300, vp.Y - 24), vp.Y - 24)
        fullSize = Vector2.new(w, h)
        main.Size = UDim2.fromOffset(w, h)
        main.Position = UDim2.fromOffset(startPosition.X + (w - startSize.X) / 2 * gripDir.X,
            startPosition.Y + (h - startSize.Y) / 2 * gripDir.Y)
    end
    clampPosition()
end)
connect(UIS.InputEnded, function(input)
    if input == pointer then pointer, gesture = nil, nil end
end)
connect(UIS.InputBegan, function(input, processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.RightShift and not modal.Visible then
        setCollapsed(not collapsed)
    elseif input.KeyCode == Enum.KeyCode.Escape then
        modal.Visible = false
        closeDD2()
        search.Text = ""
    end
end)
connect(main:GetPropertyChangedSignal("AbsoluteSize"), layout)
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fitViewport)
connect(gui.Destroying, function()
    for _, c in ipairs(connections) do c:Disconnect() end
    table.clear(connections)
end)
if type(STATE) == "table" and STATE.onCleanup then
    STATE.onCleanup(function() if gui.Parent then gui:Destroy() end end)
end
fitViewport()
showPage()
do
    local target = main.Size
    main.Size = UDim2.fromOffset(target.X.Offset - 26, target.Y.Offset - 18)
    animate(main, { Size = target }, 0.3)
end
local STATUS_NAMES = {
    {"CW_Farm", "Seed farm"}, {"CW_Trees", "Trees"}, {"CW_Frenzy", "Frenzy"},
    {"CW_CollectCan", "Cans"}, {"CW_CollectFert", "Fertilizer"}, {"CW_Fert", "Fertilize"},
    {"CW_Shop", "Shop"}, {"CW_ShopRoll", "Restock"},
}
task.spawn(function()
    while gui.Parent do
        local active = {}
        for _, entry in ipairs(STATUS_NAMES) do
            if getgenv()[entry[1]] then active[#active + 1] = entry[2] end
        end
        if collapsed then
            local shown = table.concat(active, ", ", 1, math.min(#active, 3))
            if #active > 3 then shown = shown .. " +" .. (#active - 3) end
            paintMini(#active, #active == 0 and "Idle" or shown)
        else
            for _, paint in ipairs(painters) do paint() end
        end
        task.wait(0.5)
    end
end)
end
