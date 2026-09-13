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
getgenv().CW_Water = getgenv().CW_Water or false
getgenv().CW_WaterCan = getgenv().CW_WaterCan or 64
getgenv().CW_Watered = getgenv().CW_Watered or 0
getgenv().CW_Prio1 = getgenv().CW_Prio1 or "Hyperwave"
getgenv().CW_Prio2 = getgenv().CW_Prio2 or "Voidstar"
getgenv().CW_Prio3 = getgenv().CW_Prio3 or "Birch"
getgenv().CW_Shop = getgenv().CW_Shop or false
getgenv().CW_ShopRoll = getgenv().CW_ShopRoll or false
getgenv().CW_ShopPay = getgenv().CW_ShopPay or "Gems"
getgenv().CW_ShopFloor = getgenv().CW_ShopFloor or 0
getgenv().CW_ShopPick = getgenv().CW_ShopPick or {}
getgenv().CW_ShopStay = getgenv().CW_ShopStay or false
getgenv().CW_ShopChipFloor = getgenv().CW_ShopChipFloor or 0
getgenv().CW_Carve = getgenv().CW_Carve or false
getgenv().CW_Shelve = getgenv().CW_Shelve or false
getgenv().CW_CarvePick = getgenv().CW_CarvePick or {}
getgenv().CW_ShelvePick = getgenv().CW_ShelvePick or {}
getgenv().CW_ShelveAuto = getgenv().CW_ShelveAuto or false
getgenv().CW_CustMin = getgenv().CW_CustMin or 0
getgenv().CW_CustStyles = getgenv().CW_CustStyles or {}
getgenv().CW_Declined = getgenv().CW_Declined or 0
getgenv().CW_Carved = getgenv().CW_Carved or 0
getgenv().CW_Shelved = getgenv().CW_Shelved or 0
getgenv().CW_Customers = getgenv().CW_Customers or false
getgenv().CW_Sold = getgenv().CW_Sold or 0
if getgenv().CW_ClickSfx == nil then getgenv().CW_ClickSfx = true end
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

-- Nur eine Aufgabe darf den Charakter gleichzeitig versetzen, sonst reissen sich
-- Chop, Giessen und Shop den Spieler gegenseitig aus der Reichweite.
local Move = {}
do

    Move.claim = function(tag, seconds)
        local now = os.clock()
        if (getgenv().CW_MoveUntil or 0) > now and getgenv().CW_MoveTag ~= tag then return false end
        getgenv().CW_MoveTag = tag
        getgenv().CW_MoveUntil = now + (seconds or 5)
        return true
    end

    Move.release = function(tag)
        if getgenv().CW_MoveTag == tag then getgenv().CW_MoveUntil = 0 end
    end

    -- Hart setzen und sofort die Restgeschwindigkeit killen, sonst stolpert oder
    -- faellt der Charakter nach dem Versetzen.
    Move.glide = function(root, cf)
        if not root or not root.Parent then return end
        root.CFrame = cf
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

local waterPass
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
    pcall(function() Move.glide(h, CFrame.new(wp + Vector3.new(3, 2, 3))) end)
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

-- Staerkste Axt gewinnt: Schaden mal Schlagtempo entscheidet, wie schnell ein Baum faellt.
local function findAxe()
    local best, bestScore
    for _, root in ipairs({ LP.Character, LP.Backpack }) do
        if root then
            for _, t in ipairs(root:GetChildren()) do
                if t:IsA("Tool") and (t:GetAttribute("AxeTool") or string.find(t.Name, "Axe", 1, true)) then
                    local score = (tonumber(t:GetAttribute("AxeDamage")) or 1) * (tonumber(t:GetAttribute("AxeAttackSpeed")) or 1)
                    if not bestScore or score > bestScore then best, bestScore = t, score end
                end
            end
        end
    end
    return best
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
    -- Der Server kennt die neue Position erst nach kurzer Replikation, darum wartet
    -- der Versuch ab und bleibt bei derselben Prioritaet statt sofort durchzufallen.
    if not Move.claim("plant", 10) then return nil end
    for _ = 1, 5 do
        if not (getgenv().CW_Running and getgenv().CW_Trees) then break end
        if not h.Parent then break end
        pcall(function() Move.glide(h, dest) end)
        task.wait(0.25)
        local needCloser = false
        for _, prio in ipairs({getgenv().CW_Prio1, getgenv().CW_Prio2, getgenv().CW_Prio3}) do
            if type(prio) == "string" and prio ~= "" and prio ~= "None" then
                local ok, r = pcall(function()
                    return rem:InvokeServer({PlanterIndex = tonumber(idx), TreeType = prio, TycoonName = ty.Name})
                end)
                if ok and type(r) == "table" then
                    if r.Success == true then
                        getgenv().CW_LastTree = "planted " .. prio .. " " .. os.date("%H:%M:%S")
                        Move.release("plant")
                        return prio
                    end
                    local msg = tostring(r.Error or r.Message or "")
                    if string.find(msg, "ccupied", 1, true) or string.find(msg, "nvalid", 1, true) then
                        Move.release("plant")
                        return nil
                    end
                    if string.find(msg, "loser", 1, true) or string.find(msg, "TooFar", 1, true) then
                        needCloser = true
                        break
                    end
                end
            end
        end
        if not needCloser then break end
        task.wait(0.3)
    end
    Move.release("plant")
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
    if not Move.claim("fert", 8) then return false end
    pcall(function() tool.Parent = ch end)
    local done = false
    for _ = 1, 4 do
        if not (getgenv().CW_Running and getgenv().CW_Fert) then break end
        if not h.Parent then break end
        pcall(function() Move.glide(h, dest) end)
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
    Move.release("fert")
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
local equipAxe, axeReady, chopAndCollect
do
    axeReady = function(axe)
        return axe ~= nil and axe.Parent == LP.Character and LP:GetAttribute("AxeEquipped") == true
    end

    -- Die Axt zaehlt erst als ausgeruestet, wenn sie direkt im Character haengt.
    -- Humanoid:EquipTool laesst den AxeController kalt, dann ignoriert der Server jeden Swing.
    -- Beim Seed-Farmen wandern staendig Samen in die Hand, die muessen vorher raus.
    equipAxe = function()
        local ch = LP.Character
        if not ch then return nil end
        local axe = findAxe()
        if not axe then return nil end
        for _ = 1, 3 do
            if axeReady(axe) then return axe end
            for _, t in ipairs(ch:GetChildren()) do
                if t:IsA("Tool") and t ~= axe then pcall(function() t.Parent = LP.Backpack end) end
            end
            pcall(function() axe.Parent = ch end)
            local t0 = os.clock()
            while os.clock() - t0 < 0.6 do
                if axeReady(axe) then return axe end
                task.wait(0.05)
            end
        end
        return axe
    end

    -- Drops liegen im ClientTreeDropEffects-Container, einsammeln heisst drueberfliegen.
    local sweepDrops
    sweepDrops = function()
        local h = hrp()
        if not h then return end
        local RunService = game:GetService("RunService")

        -- Holzspaene folgen dem Spieler, wenn man sie jeden Frame nachsetzt.
        -- Logs buchen auf ihrer Ursprungsposition, die muss man anfliegen.
        local chips = {}

        -- TreeDropEffects fuehrt selbst Buch ueber jeden Drop, das ist genauer als der Ordner.
        local function dropStates()
            local ok, mods = pcall(function()
                return require(game:GetService("ReplicatedFirst"):WaitForChild("Client")).ActiveModules
            end)
            local m = ok and type(mods) == "table" and mods.TreeDropEffects or nil
            return type(m) == "table" and type(m.States) == "table" and m.States or nil
        end

        local function collectLists()
            local logs = {}
            local states = dropStates()
            if states then
                table.clear(chips)
                for _, st in pairs(states) do
                    if type(st) == "table" and not st.Destroyed and st.Instance and st.Instance.Parent then
                        if st.Kind == "WoodChips" then
                            chips[#chips + 1] = st.Instance
                        elseif st.Kind == "Log" and st.Mode ~= "Pending" and st.Mode ~= "Homing" then
                            -- Ein Log, das unter einem landet, wartet sonst darauf, dass man
                            -- den Aufsammelradius einmal verlaesst.
                            st.RequirePickupExit = false
                            local pos = st.Root and st.Root.Position or dropPos(st.Instance)
                            if pos then logs[#logs + 1] = pos end
                        end
                    end
                end
                return logs
            end
            pcall(function()
                local c = dropContainer()
                if not c then return end
                table.clear(chips)
                for _, d in ipairs(c:GetChildren()) do
                    if string.find(d.Name, "ChipDrop", 1, true) then
                        chips[#chips + 1] = d
                    elseif string.find(d.Name, "Drop", 1, true) then
                        local pos = dropPos(d)
                        if pos then logs[#logs + 1] = pos end
                    end
                end
            end)
            return logs
        end

        local t0 = os.clock()
        while os.clock() - t0 < 2.5 do
            if #collectLists() > 0 or #chips > 0 then break end
            task.wait(0.05)
        end

        local pulling = RunService.RenderStepped:Connect(function()
            local root = hrp()
            if not root then return end
            local target = CFrame.new(root.Position + Vector3.new(0, -1, 0))
            for i = #chips, 1, -1 do
                local d = chips[i]
                if d.Parent then
                    pcall(function() d:PivotTo(target) end)
                else
                    table.remove(chips, i)
                end
            end
        end)

        -- Ein grosser Baum wirft seine Logs ueber die ganze Fallanimation verteilt aus,
        -- darum wird geraeumt bis nichts mehr nachkommt und nicht nur eine feste Zahl Runden.
        local deadline = os.clock() + 15
        local quiet, peak = 0, 0
        while getgenv().CW_Running and os.clock() < deadline do
            local logs = collectLists()
            peak = math.max(peak, #logs)
            if #logs == 0 then
                if #chips > 0 then task.wait(0.2) end
                quiet = quiet + 1
                -- Kleine Baeume sind sofort durch, nur bei dicken Staemmen lohnt das Warten.
                if quiet > (peak >= 6 and 3 or 1) then break end
                task.wait(peak >= 6 and 0.35 or 0.12)
                continue
            end
            quiet = 0
            local stops = {}
            while #logs > 0 do
                local anchor = table.remove(logs, 1)
                local group = { anchor }
                local i = 1
                while i <= #logs do
                    local d = logs[i] - anchor
                    if math.sqrt(d.X * d.X + d.Z * d.Z) <= 7 then
                        group[#group + 1] = table.remove(logs, i)
                    else
                        i = i + 1
                    end
                end
                local mid = Vector3.zero
                for _, pos in ipairs(group) do mid = mid + pos end
                stops[#stops + 1] = mid / #group
            end
            for _, stop in ipairs(stops) do
                if not getgenv().CW_Running then break end
                pcall(function() Move.glide(h, CFrame.new(stop + Vector3.new(0, 3, 0))) end)
                task.wait(0.22)
            end
        end
        task.wait(0.2)
        pulling:Disconnect()
        getgenv().CW_DropsLeft = #collectLists()
    end

    -- Der AxeController kettet Schwuenge selbst weiter, solange HeldInput steht.
    -- Das sieht aus wie gedrueckt halten, statt jede Animation neu anzureissen.
    local axeController
        axeController = function()
        local ok, client = pcall(function()
            return require(game:GetService("ReplicatedFirst"):WaitForChild("Client"))
        end)
        if not ok or type(client) ~= "table" then return nil end
        local mods = client.ActiveModules
        return type(mods) == "table" and mods.AxeController or nil
    end

    chopAndCollect = function(tree)
        local h = hrp()
        local axe = h and equipAxe()
        if not axe then return false end
        if not Move.claim("chop", 35) then return false end
        local tp
        pcall(function() tp = tree:GetPivot().Position end)
        if typeof(tp) ~= "Vector3" then
            Move.release("chop")
            return false
        end
        local away = h.Position - tp
        away = Vector3.new(away.X, 0, away.Z)
        if away.Magnitude < 1 then away = Vector3.new(1, 0, 1) end
        local stand = tp + away.Unit * 5 + Vector3.new(0, 4, 0)
        local aim = tp + Vector3.new(0, 3, 0)
        local pose = CFrame.lookAt(stand, aim)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        pcall(function()
            h.Anchored = false
            if hum then hum.AutoRotate = false end
        end)
        Move.glide(h, pose)
        task.wait(0.08)
        if not axeReady(axe) then axe = equipAxe() or axe end

        local ctrl = axeController()
        if ctrl then ctrl.HeldInput = true end
        pcall(function() axe:Activate() end)

        local felled = false
        local t0 = os.clock()
        local retried = false
        local lastHits, lastProgress = -1, os.clock()
        while getgenv().CW_Running and getgenv().CW_Trees do
            if tree.Parent == nil or tree:GetAttribute("TreeFelling") == true then
                felled = true
                break
            end
            -- Nur nachsetzen, wenn der Charakter wirklich weggerutscht ist, sonst zappelt er.
            if (h.Position - stand).Magnitude > 2.5 then
                pcall(function() h.CFrame = pose end)
            end
            local hits = tonumber(tree:GetAttribute("TreeChopHits")) or 0
            if hits ~= lastHits then
                lastHits, lastProgress = hits, os.clock()
            elseif os.clock() - lastProgress > 1.5 then
                -- Kein Treffer mehr: Baum schon weg oder Axt haengt, einmal neu greifen.
                if retried then break end
                retried = true
                axe = equipAxe() or axe
                lastProgress = os.clock()
            end
            -- Seeds und andere Aufgaben draengen die Axt aus der Hand, also vor jedem Schwung pruefen.
            if not axeReady(axe) then axe = equipAxe() or axe end
            pcall(function() axe:Activate() end)
            if os.clock() - t0 > 20 then break end
            task.wait(0.35)
        end
        if ctrl then ctrl.HeldInput = false end
        if hum then pcall(function() hum.AutoRotate = true end) end
        if tree.Parent == nil or tree:GetAttribute("TreeFelling") == true then felled = true end

        if felled then
            local chips0, logs0 = woodChips(), countLogs()
            sweepDrops()
            local got = (woodChips() - chips0) + (countLogs() - logs0)
            getgenv().CW_LastTree = "chopped+" .. tostring(got) .. " " .. os.date("%H:%M:%S")
            getgenv().CW_Chopped = (getgenv().CW_Chopped or 0) + 1
        end
        Move.release("chop")
        return felled
    end
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
                    -- Alle reifen Baeume in einem Durchgang, danach erst wieder pflanzen.
                    pcall(function()
                        local CS = game:GetService("CollectionService")
                        for _, t in ipairs(CS:GetTagged("ChoppableTree")) do
                            if not getgenv().CW_Trees then break end
                            if t:IsDescendantOf(ty) and t:GetAttribute("TreeMature") == true
                                and t:GetAttribute("TreeFelling") ~= true then
                                if chopAndCollect(t) then didWork = true end
                            end
                        end
                    end)
                    -- Der Server setzt den Planter erst kurz nach dem Fall auf Empty,
                    -- darum mehrere Runden statt eines einzelnen Durchgangs.
                    for round = 1, 2 do
                        local planted, pending = 0, 0
                        pcall(function()
                            for _, d in ipairs(planterCache) do
                                if not getgenv().CW_Trees then break end
                                if d.Parent and d:GetAttribute("TreePlanterStatus") == "Empty"
                                    and tonumber(d:GetAttribute("PlanterIndex")) ~= 0 then
                                    pending = pending + 1
                                    if plantPrio(d) then
                                        planted = planted + 1
                                        didWork = true
                                    end
                                end
                            end
                        end)
                        if pending == 0 or planted == pending then break end
                        task.wait(0.35)
                    end
                    -- Zum Schluss noch giessen, dann ist der Durchgang komplett.
                    if getgenv().CW_Water and waterPass then
                        if waterPass() then didWork = true end
                    end
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
                if save then pcall(function() local h = hrp() if h then Move.glide(h, save) end end) end
            end
        end
        task.wait(didWork and 0.4 or 5)
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
    local CW_ROLL_CHIPS = 5000
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

    local function chipBudget(cost)
        if woodChips() - cost >= (tonumber(getgenv().CW_ShopChipFloor) or 0) then return true end
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
        pcall(function() Move.glide(h, CFrame.new(pos + Vector3.new(0, 3, 5), pos)) end)
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
        if chips then
            if not chipBudget(CW_ROLL_CHIPS) then return false end
        elseif not gemBudget(CW_ROLL_GEMS) then
            return false
        end
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
                if gs and Move.claim("shop", 25) then
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
                        pcall(function() local h2 = hrp() if h2 then Move.glide(h2, save) end end)
                    end
                    Move.release("shop")
                end
            end
            task.wait(didWork and 0.1 or 1.5)
        end
    end)
end

local CW_CAN_MULTS = {1, 2, 4, 8, 16, 32, 64, 128, 256}
do
    local routeId
    local function waterRemote()
        if not routeId then routeId = resolveRoute("WaterPlanterWithEquippedCan") end
        if not routeId then return nil end
        local rem = game:GetService("ReplicatedStorage"):FindFirstChild("REM", true)
        rem = rem and rem:FindFirstChild(routeId)
        if not rem then routeId = nil end
        return rem
    end

    local function pickCan()
        local want = tonumber(getgenv().CW_WaterCan) or 64
        local ch = LP.Character
        for _, root in ipairs({ ch, LP.Backpack }) do
            if root then
                for _, t in ipairs(root:GetChildren()) do
                    if t:IsA("Tool") and t:GetAttribute("WateringCanMultiplier") == want then return t end
                end
            end
        end
        return nil
    end

    -- Der Boost läuft 60s und die Kanne wird dabei verbraucht, darum kurz vor Ablauf nachgießen.
    local function needsWater(planter)
        if planter:GetAttribute("TreePlanterStatus") ~= "Growing" then return false end
        local ends = tonumber(planter:GetAttribute("TreeWateringBoostEndsAt"))
        return not ends or ends - os.time() <= 1
    end

    -- Der Server laesst bis 35 Studs giessen, also eine Position pro Gruppe statt pro Planter.
    local function waterCluster(rem, hum, group, spot)
        local done = 0
        if not Move.claim("water", 10) then return 0 end
        local h = hrp()
        if h then Move.glide(h, CFrame.new(spot + Vector3.new(0, 4, 0))) end
        task.wait(0.2)
        for _, planter in ipairs(group) do
            if not (getgenv().CW_Running and getgenv().CW_Water) then break end
            local can = pickCan()
            if not can then break end
            pcall(function() hum:EquipTool(can) end)
            task.wait(0.1)
            local ok, r = pcall(function()
                return rem:InvokeServer({
                    PlanterIndex = planter:GetAttribute("PlanterIndex"),
                    ItemId = can:GetAttribute("WateringCanItemId"),
                })
            end)
            if ok and type(r) == "table" and r.Success == true then
                getgenv().CW_Watered = (getgenv().CW_Watered or 0) + 1
                done = done + 1
            end
        end
        return done
    end

    -- Eine geschlossene Giessrunde: alle durstigen Planter, gruppenweise, dann zurueck.
    waterPass = function()
        if not getgenv().CW_Water then return false end
        local rem = waterRemote()
        local ty = rem and myTycoon()
        if not ty then return false end
        if not pickCan() then
            getgenv().CW_WaterNote = "no " .. tostring(getgenv().CW_WaterCan) .. "x cans left"
            return false
        end
        getgenv().CW_WaterNote = nil
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local h = hrp()
        local save = h and h.CFrame
        local thirsty = {}
        pcall(function()
            for _, d in ipairs(ty:GetDescendants()) do
                if d:GetAttribute("TreePlanter") == true and needsWater(d) then
                    local ok, pos = pcall(function() return d:GetPivot().Position end)
                    if ok and typeof(pos) == "Vector3" then
                        thirsty[#thirsty + 1] = { planter = d, pos = pos }
                    end
                end
            end
        end)
        if #thirsty == 0 then return false end
        local did = false
        while #thirsty > 0 do
            if not (getgenv().CW_Running and getgenv().CW_Water) then break end
            local anchor = table.remove(thirsty, 1)
            local group, spot = { anchor.planter }, anchor.pos
            local i = 1
            while i <= #thirsty do
                if (thirsty[i].pos - anchor.pos).Magnitude <= 26 then
                    group[#group + 1] = table.remove(thirsty, i).planter
                else
                    i = i + 1
                end
            end
            if waterCluster(rem, hum, group, spot) > 0 then did = true end
        end
        if save and hrp() then pcall(function() Move.glide(hrp(), save) end) end
        Move.release("water")
        return did
    end

    -- Laeuft der Baum-Zyklus, ruft der die Giessrunde selbst auf, damit sich die
    -- Phasen nicht ins Gehege kommen.
    task.spawn(function()
        while getgenv().CW_Running and getgenv().CW_Gen == myGen do
            local didWork = false
            if getgenv().CW_Water and not getgenv().CW_Trees then
                didWork = waterPass()
            end
            task.wait(didWork and 0.3 or 1.5)
        end
    end)
end

-- Holzarten wie das Spiel sie fuehrt, Anzeige links, interne Id rechts.
local Carve = { kinds = {
    {"Oak", "oak"}, {"Birch", "birch"}, {"Pine", "pine"}, {"Maple", "maple"}, {"Palm", "palm"},
    {"Willow", "willow"}, {"Acacia", "acacia"}, {"Sakura", "sakura"}, {"Bubble", "bubble"},
    {"Doom", "doom"}, {"Night Blossom", "nightblossom"}, {"Redstar", "redstar"},
    {"Glow", "glow"}, {"Magical Palm", "magicalpalm"}, {"Astral", "astral"},
    {"Withered Rose", "witheredrose"}, {"Lunar", "lunar"}, {"Solar", "solar"},
    {"Cloud", "cloud"}, {"Lightning", "lightning"}, {"Sunset", "sunset"},
    {"Starfall", "starfall"}, {"Nightmare Bloom", "nightmarebloom"},
    {"Voidstar", "voidstar"}, {"Hyperwave", "hyperwave"}, {"Alien", "alien"},
    {"Scorching Mushroom", "scorchingmushroom"}, {"Kelp", "kelp"},
} }
do
    local Client = require(game:GetService("ReplicatedFirst"):WaitForChild("Client"))
    local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
    local WC = Shared:WaitForChild("WoodCarving")
    local Serializer = require(WC:WaitForChild("Serializer"))
    local TargetProfile = require(WC:WaitForChild("TargetProfile"))
    local latheCfg = require(Shared:WaitForChild("RobotLatheConfig"))
    local ROUTES = {
        session = "SetWoodCarvingSession",
        save = "SaveCarvedWood",
        place = "PlaceCarvedWoodOnSaleSpot",
        placeLast = "PlaceLastWoodStackItemOnSaleSpot",
        offer = "SaleNPCOfferResponse",
        data = "GetData",
    }
    local ids = {}

    local function carveRemote(key)
        if not ids[key] then ids[key] = resolveRoute(ROUTES[key]) end
        if not ids[key] then return nil end
        local rem = game:GetService("ReplicatedStorage"):FindFirstChild("REM", true)
        rem = rem and rem:FindFirstChild(ids[key])
        if not rem then ids[key] = nil end
        return rem
    end

    -- Leere Auswahl heisst alles, sonst zaehlt nur was angehakt ist.
    local function allowed(pick, woodId)
        if type(pick) ~= "table" then return false end
        if next(pick) == nil then return true end
        return pick[woodId] == true
    end

    Carve.picked = function(woodId)
        return allowed(getgenv().CW_CarvePick, woodId)
    end

    -- Regale brauchen eine bewusste Auswahl, sonst landen aus Versehen die teuren Stuecke da.
    Carve.shelved = function(woodId)
        local pick = getgenv().CW_ShelvePick
        return type(pick) == "table" and pick[woodId] == true
    end

    -- Das eingereichte Profil ist zugleich das Zielprofil, damit trifft es zu 100 Prozent.
    -- Ein paar Radien wandern zufaellig, sonst haelt der Server es fuer dasselbe Stueck.
    local function freshProfile(woodId, mutation)
        local target = TargetProfile.new({
            SliceCount = latheCfg.LogSliceCount,
            Length = latheCfg.LogLength,
            Radius = latheCfg.LogRadius,
            MinFeatures = latheCfg.TargetMinFeatures,
            MaxFeatures = latheCfg.TargetMaxFeatures,
        })
        local profile = target.Profile or target
        for _ = 1, 4 do
            local idx = math.random(5, latheCfg.LogSliceCount - 5)
            local ok, cur = pcall(function() return profile:GetRadius(idx) end)
            if ok and cur then
                pcall(function() profile:SetRadius(idx, math.max(0.15, cur - math.random(1, 9) / 1000)) end)
            end
        end
        return Serializer.SerializeCarvedLog(target, { WoodId = woodId, Mutation = mutation })
    end

    local function freeSpots(ty)
        local root = ty:FindFirstChild("TycoonRoot", true)
        local holder = root and root:FindFirstChild("SaleSpots")
        local out = {}
        if holder then
            for _, spot in ipairs(holder:GetChildren()) do
                if spot:GetAttribute("SaleSpot") == true and spot:GetAttribute("Occupied") ~= true then
                    out[#out + 1] = spot
                end
            end
        end
        return out
    end

    -- Alle Regalplaetze liegen dicht beieinander, ein Standort in der Mitte reicht.
    local function shelfCenter(ty)
        local root = ty:FindFirstChild("TycoonRoot", true)
        local holder = root and root:FindFirstChild("SaleSpots")
        if not holder then return nil end
        local mid, count = Vector3.zero, 0
        for _, spot in ipairs(holder:GetChildren()) do
            if spot:GetAttribute("SaleSpot") == true then
                local ok, pos = pcall(function()
                    return spot:IsA("BasePart") and spot.Position or spot:GetPivot().Position
                end)
                if ok and typeof(pos) == "Vector3" then
                    mid = mid + pos
                    count = count + 1
                end
            end
        end
        if count == 0 then return nil end
        return mid / count
    end

    local function placeOn(spot, ty, carvedId)
        local rem = carveRemote("place")
        if not rem then return false end
        local ok, r = pcall(function()
            return rem:InvokeServer({ SpotName = spot.Name, TycoonName = ty.Name, WoodId = carvedId })
        end)
        if ok and type(r) == "table" and r.Success == true then return true end
        local pos
        pcall(function()
            pos = spot:IsA("BasePart") and spot.Position or spot:GetPivot().Position
        end)
        local h = hrp()
        if typeof(pos) ~= "Vector3" or not h then return false end
        Move.glide(h, CFrame.new(pos + Vector3.new(0, 3, 8), pos))
        task.wait(0.25)
        local ok2, r2 = pcall(function()
            return rem:InvokeServer({ SpotName = spot.Name, TycoonName = ty.Name, WoodId = carvedId })
        end)
        return ok2 and type(r2) == "table" and r2.Success == true
    end

    -- Fertige Stuecke liegen im Profil und nicht als Tool, darum ueber GetData lesen.
    Carve.stock = function()
        local rem = carveRemote("data")
        if not rem then return {} end
        local ok, data = pcall(function() return rem:InvokeServer({}) end)
        if not ok or type(data) ~= "table" or type(data.Inventory) ~= "table" then return {} end
        local carved = data.Inventory.Carved
        if type(carved) ~= "table" then return {} end
        local out = {}
        for _, e in pairs(carved) do
            if type(e) == "table" and e.Id and Carve.shelved(tostring(e.WoodId)) then
                out[#out + 1] = e
            end
        end
        table.sort(out, function(a, b) return (a.Quality or 0) > (b.Quality or 0) end)
        return out
    end

    -- VIP-Kunden laufen als Gold, alles andere steht direkt im OfferStyle.
    local function offerStyle(p)
        local s = tostring(p.OfferStyle)
        if s == "Alien" or s == "Rainbow" or s == "Gold" then return s end
        return p.VIP == true and "Gold" or "Normal"
    end

    -- Der Client verteilt Server-Events ueber ActiveRemotes, da haengt sich der Script dazwischen.
    task.spawn(function()
        local slot
        while getgenv().CW_Running and getgenv().CW_Gen == myGen do
            local ar = Client and Client.ActiveRemotes
            slot = type(ar) == "table" and ar.SaleNPCOffer or nil
            if type(slot) == "table" and type(slot.Events) == "table" then break end
            slot = nil
            task.wait(1)
        end
        if not slot then return end
        local prev = getgenv().CW_OfferHook
        if prev then
            local at = table.find(slot.Events, prev)
            if at then table.remove(slot.Events, at) end
        end
        local hook = function(p)
            if getgenv().CW_Gen ~= myGen or not getgenv().CW_Customers then return end
            if type(p) ~= "table" or type(p.OfferId) ~= "string" then return end
            local rem = carveRemote("offer")
            if not rem then return end
            local pct = math.floor(((tonumber(p.Multiplier) or 1) - 1) * 100 + 0.5)
            local style = offerStyle(p)
            local take = pct >= (tonumber(getgenv().CW_CustMin) or 0)
                and allowed(getgenv().CW_CustStyles, style)
            pcall(function() rem:FireServer({ OfferId = p.OfferId, Accepted = take }) end)
            getgenv().CW_LastOffer = ("%s%d%% %s"):format(pct >= 0 and "+" or "", pct, style)
            local seen = getgenv().CW_OfferSeen
            if type(seen) ~= "table" then
                seen = {}
                getgenv().CW_OfferSeen = seen
            end
            if pct > (seen[style] or -1000) then seen[style] = pct end
            if take then
                getgenv().CW_Sold = (getgenv().CW_Sold or 0) + 1
            else
                getgenv().CW_Declined = (getgenv().CW_Declined or 0) + 1
            end
        end
        getgenv().CW_OfferHook = hook
        table.insert(slot.Events, hook)
    end)

    task.spawn(function()
        while getgenv().CW_Running and getgenv().CW_Gen == myGen do
            local didWork = false
            -- Erst raeumt der Script alles Geschnitzte aus dem Inventar auf die Regale.
            if getgenv().CW_Shelve then
                local ty = myTycoon()
                local spots = ty and freeSpots(ty)
                if spots and #spots > 0 and Move.claim("carve", 30) then
                    local stock = Carve.stock()
                    if #stock > 0 then
                        local center = shelfCenter(ty)
                        local h = hrp()
                        if center and h and (h.Position - center).Magnitude > 12 then
                            Move.glide(h, CFrame.new(center + Vector3.new(0, 6, 0)))
                            task.wait(0.3)
                        end
                        for i, spot in ipairs(spots) do
                            if not (getgenv().CW_Running and getgenv().CW_Shelve) then break end
                            if not stock[i] then break end
                            if placeOn(spot, ty, stock[i].Id) then
                                getgenv().CW_Shelved = (getgenv().CW_Shelved or 0) + 1
                                didWork = true
                            end
                            task.wait(0.12)
                        end
                    end
                    Move.release("carve")
                end
            end
            local refill = getgenv().CW_Shelve and getgenv().CW_ShelveAuto
            if getgenv().CW_Carve or (refill and not didWork) then
                local sess = carveRemote("session")
                local save = carveRemote("save")
                local ty = sess and save and myTycoon()
                if ty and Move.claim("carve", 25) then
                    -- Der Server will den Spieler an der Drehbank sehen, sonst laeuft nichts.
                    local lathe = ty:FindFirstChild("Lathe", true)
                    local h = hrp()
                    if lathe and h then
                        local pos
                        pcall(function() pos = lathe:GetPivot().Position end)
                        -- Die Session gilt nur bis 14 Studs, darum knapp danebenstellen.
                        if typeof(pos) == "Vector3" and (h.Position - pos).Magnitude > 12 then
                            local away = h.Position - pos
                            away = Vector3.new(away.X, 0, away.Z)
                            if away.Magnitude < 1 then away = Vector3.new(1, 0, 1) end
                            Move.glide(h, CFrame.new(pos + away.Unit * 8 + Vector3.new(0, 2, 0), pos))
                            task.wait(0.3)
                        end
                    end
                    local ok, session = pcall(function()
                        return sess:InvokeServer({ Active = true, SessionId = "", TycoonName = ty.Name })
                    end)
                    if ok and type(session) == "table" and session.Success then
                        local spots = freeSpots(ty)
                        local pending = {}
                        local budget = getgenv().CW_Shelve and math.min(#spots, 6) or 4
                        for _ = 1, budget do
                            if not (getgenv().CW_Carve or refill) then break end
                            -- Beim Nachschub zaehlt die Regal-Auswahl, sonst die Schnitz-Auswahl.
                            local wanted = getgenv().CW_Carve and Carve.picked or Carve.shelved
                            local variant
                            for _, v in pairs(session.RawWoodVariants or {}) do
                                if (v.Count or 0) > 0 and not v.IsMega and wanted(v.WoodId) then
                                    variant = v
                                    break
                                end
                            end
                            if not variant then break end
                            local ser = freshProfile(variant.WoodId, variant.VariantKey)
                            local sent, res = pcall(function()
                                return save:InvokeServer({
                                    Serialized = ser,
                                    TargetSerialized = ser,
                                    WoodId = variant.WoodId,
                                    Mutation = variant.VariantKey,
                                    VariantId = variant.Id,
                                    SessionId = session.SessionId,
                                    WorkpieceId = "",
                                })
                            end)
                            if not (sent and type(res) == "table" and res.Success and res.Entry) then break end
                            session.RawWoodVariants = res.RawWoodVariants or session.RawWoodVariants
                            getgenv().CW_Carved = (getgenv().CW_Carved or 0) + 1
                            getgenv().CW_LastCarve = res.Entry.DisplayName .. " " .. tostring(res.Entry.Quality) .. "%"
                            didWork = true
                            if getgenv().CW_Shelve and Carve.shelved(variant.WoodId) then
                                pending[#pending + 1] = res.Entry.Id
                            end
                            task.wait(0.15)
                        end
                        -- Erst am Stueck schnitzen, dann einmal zu den Regalen und alles ablegen.
                        if #pending > 0 then
                            local center = shelfCenter(ty)
                            local h2 = hrp()
                            if center and h2 then
                                Move.glide(h2, CFrame.new(center + Vector3.new(0, 6, 0)))
                                task.wait(0.3)
                            end
                            for i, id in ipairs(pending) do
                                if not spots[i] then break end
                                if placeOn(spots[i], ty, id) then
                                    getgenv().CW_Shelved = (getgenv().CW_Shelved or 0) + 1
                                end
                                task.wait(0.12)
                            end
                        end
                    end
                    pcall(function()
                        sess:InvokeServer({
                            Active = false,
                            SessionId = type(session) == "table" and session.SessionId or "",
                            TycoonName = ty.Name,
                        })
                    end)
                    Move.release("carve")
                end
            end
            task.wait(didWork and 0.5 or 3)
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
            local wa = g:FindFirstChild("CWValWater", true)
            if wa then wa.Text = tostring(getgenv().CW_Watered or 0) end
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
local C = {
    ACCENT = Color3.fromRGB(94, 226, 162),
    BG = Color3.fromRGB(11, 13, 12),
    SIDE = Color3.fromRGB(14, 16, 15),
    CARD = Color3.fromRGB(20, 23, 21),
    CTRL = Color3.fromRGB(32, 36, 34),
    STROKE = Color3.fromRGB(33, 38, 35),
    TXT = Color3.fromRGB(233, 239, 235),
    MUT = Color3.fromRGB(135, 148, 141),
    SELECTED = Color3.fromRGB(18, 35, 27),
    HOVER = Color3.fromRGB(25, 29, 27),
    ACCENT_SOFT = Color3.fromRGB(48, 138, 101),
}
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
    return make("UIStroke", { Color = color or C.STROKE, Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, obj)
end
local function frame(owner, name, size, pos, color)
    return make("Frame", { Name = name, Size = size, Position = pos or UDim2.new(),
        BackgroundColor3 = color or C.CARD, BackgroundTransparency = color and 0 or 1,
        BorderSizePixel = 0 }, owner)
end
local function text(owner, name, value, size, pos, fontSize, color, bold, display)
    return make("TextLabel", { Name = name, Text = value, Size = size, Position = pos,
        BackgroundTransparency = 1, FontFace = face(bold and W.SemiBold or W.Regular, display),
        TextSize = fontSize or 15, TextColor3 = color or C.TXT,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, owner)
end
-- Klickton liegt als Datei beim Script, der Executor mappt sie auf eine Asset-Url.
local clickTick
do
    local sound
    task.spawn(function()
        if not (writefile and getcustomasset and isfolder and makefolder and isfile) then return end
        if not isfolder("cw-sounds") then makefolder("cw-sounds") end
        local path = "cw-sounds/carvewood_click.wav"
        if not isfile(path) then
            local ok, data = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/Gakuseei/carvewood/master/sounds/click.wav")
            end)
            if not ok or type(data) ~= "string" or #data < 200 then return end
            writefile(path, data)
        end
        local ok, asset = pcall(function() return getcustomasset(path) end)
        if not ok then return end
        local s = Instance.new("Sound")
        s.Name = "CWClick"
        s.SoundId = asset
        s.Volume = 0.22
        s.Parent = game:GetService("SoundService")
        sound = s
    end)
    clickTick = function()
        if sound and getgenv().CW_ClickSfx then
            sound.TimePosition = 0
            sound:Play()
        end
    end
end

local function button(owner, name, size, pos, color)
    local b = make("TextButton", { Name = name, Size = size, Position = pos or UDim2.new(),
        Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        BackgroundColor3 = color or C.CARD, BackgroundTransparency = color and 0 or 1 }, owner)
    b.Activated:Connect(clickTick)
    return b
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
    connect(obj.MouseEnter, function() animate(obj, { BackgroundColor3 = over or C.CTRL }) end)
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
        ImageColor3 = color or C.MUT }, owner)
end
local function tintIcon(box, color)
    if box and box:IsA("ImageLabel") then
        Tween:Create(box, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { ImageColor3 = color }):Play()
    end
end

-- Kurzes Aufleuchten beim Drücken, damit ein Tap spürbar quittiert wird.
local function press(btn, base)
    connect(btn.MouseButton1Down, function() animate(btn, { BackgroundColor3 = C.SELECTED }, 0.08) end)
    connect(btn.MouseButton1Up, function() animate(btn, { BackgroundColor3 = base }, 0.18) end)
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
local main = frame(gui, "Main", UDim2.fromOffset(732, 508), UDim2.fromScale(0.5, 0.5), C.BG)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Active = true
main.ClipsDescendants = true
local mainCorner = round(main, 12)
outline(main)
local header = frame(main, "Header", UDim2.new(1, 0, 0, 56), nil, C.SIDE)
local dragHandle = button(header, "DragHandle", UDim2.new(1, -96, 1, 0))
local brand = icon(header, "Brand", UDim2.fromOffset(18, 18), C.ACCENT, 22)
local title = text(header, "Title", "CarveWood", UDim2.fromOffset(150, 24), UDim2.fromOffset(48, 16), 19, C.TXT, true, true)
local version = text(header, "Version", "v10.0", UDim2.fromOffset(70, 24), UDim2.fromOffset(162, 16), 17, C.MUT, true, true)
local side = frame(main, "Side", UDim2.new(0, 196, 1, -86), UDim2.fromOffset(0, 56), C.SIDE)
local searchWrap = frame(side, "SearchWrap", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 8))
local searchBorder = frame(searchWrap, "Divider", UDim2.new(1, -8, 0, 1), UDim2.new(0, 4, 1, -1), C.STROKE)
icon(searchWrap, "Search", UDim2.fromOffset(8, 13), C.MUT, 18)
local search = make("TextBox", { Name = "Search", Size = UDim2.new(1, -38, 1, -2),
    Position = UDim2.fromOffset(34, 0), Text = "", PlaceholderText = "Search...",
    PlaceholderColor3 = C.MUT, TextColor3 = C.TXT, BackgroundTransparency = 1,
    FontFace = face(W.Regular), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false }, searchWrap)
padding(search, 0, 0, 8, 0)
connect(search.Focused, function()
    searchBorder.BackgroundColor3 = C.ACCENT
    animate(searchBorder, { Size = UDim2.new(1, -8, 0, 2), Position = UDim2.new(0, 4, 1, -2) }, 0.18)
end)
connect(search.FocusLost, function()
    searchBorder.BackgroundColor3 = C.STROKE
    animate(searchBorder, { Size = UDim2.new(1, -8, 0, 1), Position = UDim2.new(0, 4, 1, -1) }, 0.22)
end)
local smallSearch = button(side, "SearchButton", UDim2.fromOffset(40, 40), UDim2.fromOffset(8, 8), C.CARD)
round(smallSearch, 10)
icon(smallSearch, "Search", UDim2.fromOffset(11, 11), C.MUT, 18)
smallSearch.Visible = false
local navHolder = make("ScrollingFrame", { Name = "Navigation", Position = UDim2.fromOffset(10, 62),
    Size = UDim2.new(1, -20, 1, -70), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, side)
stack(navHolder, 4)
local footer = frame(main, "Footer", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 1, -30), C.SIDE)
local footHint = text(footer, "Hint", UIS.TouchEnabled and "Drag the header to move" or "Right Shift to minimize",
    UDim2.new(1, -84, 1, 0), UDim2.fromOffset(18, 0), 12, C.MUT)
-- Eingeklappt: eine Pille mit Markenzeichen, Laufstatus und Aufklapp-Pfeil.
local mini, paintMini
do
    mini = frame(main, "Mini", UDim2.new(1, 0, 1, 0))
    mini.Visible = false
    mini.ZIndex = 6
    mini.Active = true
    icon(mini, "Brand", UDim2.fromOffset(18, 20), C.ACCENT, 22)
    text(mini, "Title", "CarveWood", UDim2.fromOffset(150, 22), UDim2.fromOffset(50, 10), 17, C.TXT, true, true)
    local dot = frame(mini, "Dot", UDim2.fromOffset(7, 7), UDim2.fromOffset(51, 37), C.MUT)
    round(dot, 4)
    local status = text(mini, "Status", "Idle", UDim2.new(1, -126, 0, 18), UDim2.fromOffset(64, 31), 13, C.MUT)
    local expand = button(mini, "Expand", UDim2.fromOffset(40, 40), UDim2.new(1, -10, 0.5, 0))
    expand.AnchorPoint = Vector2.new(1, 0.5)
    expand.ZIndex = 7
    local expandIcon = icon(expand, "Chevron", UDim2.fromOffset(11, 11), C.MUT, 18)
    expandIcon.Rotation = 180
    connect(expand.MouseEnter, function()
        tintIcon(expandIcon, C.ACCENT)
        animate(expandIcon, { Size = UDim2.fromOffset(21, 21), Position = UDim2.fromOffset(9, 9) }, 0.14)
    end)
    connect(expand.MouseLeave, function()
        tintIcon(expandIcon, C.MUT)
        animate(expandIcon, { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(11, 11) }, 0.14)
    end)
    local pulse
    paintMini = function(running, label)
        status.Text = label
        dot.BackgroundColor3 = running > 0 and C.ACCENT or C.MUT
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
local content = frame(main, "Content", UDim2.new(1, -196, 1, -86), UDim2.fromOffset(196, 56))
local pageHead = frame(content, "PageHeader", UDim2.new(1, -40, 0, 66), UDim2.fromOffset(20, 0))
local pageTitle = text(pageHead, "Title", "Overview", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 14), 23, C.TXT, true, true)
local pageDesc = text(pageHead, "Description", "", UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 42), 14, C.MUT)
local PAGE_INFO = {
    {"Home", "Overview", "Your session at a glance."},
    {"Farm", "Seed farming", "Reroll seeds and collect what is ready."},
    {"Trees", "Trees", "Planting priorities and tree care."},
    {"Sell Zone", "Sell Zone", "Carve logs and fill the shelves."},
    {"Shop", "Shop", "Buy and reroll stock at Moon's gem store."},
    {"Performance", "Performance", "Keep the game focused on what matters."},
}
local function makePage(name)
    local sc = make("ScrollingFrame", { Name = "Page_" .. name, Position = UDim2.fromOffset(0, 66),
        Size = UDim2.new(1, 0, 1, -66), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.STROKE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, content)
    padding(sc, 20, 4, 20, 20)
    stack(sc, 10)
    pages[name] = sc
    return sc
end
for _, info in ipairs(PAGE_INFO) do makePage(info[1]) end
local homePage, farmPage, treePage, shopPage, perfPage = pages.Home, pages.Farm, pages.Trees, pages.Shop, pages.Performance
local searchPage = makePage("Search")
local noResults = text(searchPage, "NoResults", "No matching features.", UDim2.new(1, 0, 0, 48), UDim2.new(), 14, C.MUT)
noResults.Visible = false
-- Ein Marker für alle Einträge, er fährt zum aktiven Punkt statt zu springen.
local navSlider = frame(side, "NavSlider", UDim2.fromOffset(3, 20), UDim2.fromOffset(4, 70), C.ACCENT)
round(navSlider, 2)
navSlider.ZIndex = 3
navSlider.Visible = false
local function paintNav()
    local active = nil
    for name, b in pairs(navBtns) do
        local on = name == currentPage and search.Text == ""
        animate(b, { BackgroundColor3 = on and C.SELECTED or C.SIDE })
        b.Label.TextColor3 = on and C.TXT or C.MUT
        tintIcon(b.Icon, on and C.ACCENT or C.MUT)
        if on then active = b end
    end
    if not active then
        navSlider.Visible = false
        return
    end
    local y = active.AbsolutePosition.Y - side.AbsolutePosition.Y + 13
    if navSlider.Visible then
        animate(navSlider, { Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(3, 12) }, 0.14)
        task.delay(0.14, function()
            if navSlider.Visible then animate(navSlider, { Size = UDim2.fromOffset(3, 20) }, 0.22) end
        end)
    else
        navSlider.Position = UDim2.fromOffset(4, y)
        navSlider.Visible = true
    end
end
showPage = function()
    for name, pg in pairs(pages) do
        local on = name == currentPage
        pg.Visible = on
        if on then
            pg.Position = UDim2.fromOffset(0, 78)
            animate(pg, { Position = UDim2.fromOffset(0, 66) }, 0.22)
            pageTitle.Position = UDim2.fromOffset(-10, 14)
            pageDesc.Position = UDim2.fromOffset(-10, 42)
            animate(pageTitle, { Position = UDim2.fromOffset(0, 14) }, 0.28)
            animate(pageDesc, { Position = UDim2.fromOffset(0, 42) }, 0.34)
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
    local b = button(navHolder, "Nav_" .. name, UDim2.new(1, 0, 0, 46), nil, C.SIDE)
    b.LayoutOrder = order
    round(b, 10)
    icon(b, name, UDim2.fromOffset(13, 13), C.MUT, 20)
    text(b, "Label", name, UDim2.new(1, -50, 1, 0), UDim2.fromOffset(45, 0), 18, C.MUT, true)
    navBtns[name] = b
    press(b, C.SIDE)
    connect(b.Activated, function() navigate(name) end)
    connect(b.MouseEnter, function() if name ~= currentPage then animate(b, { BackgroundColor3 = C.CARD }) end end)
    connect(b.MouseLeave, paintNav)
end

local function section(page, value, order)
    local row = frame(page, "Section", UDim2.new(1, 0, 0, 26))
    row.LayoutOrder = order
    text(row, "Label", value, UDim2.new(1, 0, 1, 0), UDim2.new(), 15, C.MUT, true)
    return row
end

local function card(page, pageName, value, desc, order, h)
    local row = frame(page, value:gsub("%W", ""), UDim2.new(1, 0, 0, h or 74), nil, C.CARD)
    row.LayoutOrder = order
    row.ClipsDescendants = true
    round(row, 12)
    local edge = outline(row)
    local t = text(row, "Heading", value, UDim2.new(1, -150, 0, 24), UDim2.fromOffset(18, 13), 18, C.TXT, true)
    local d = text(row, "Description", desc, UDim2.new(1, -150, 0, 30), UDim2.fromOffset(18, 38), 15, C.MUT)
    d.LineHeight = 1.12
    d.TextWrapped = true
    d.TextTruncate = Enum.TextTruncate.None
    d.TextYAlignment = Enum.TextYAlignment.Top
    local function fit()
        local narrow = row.AbsoluteSize.X < 400
        local height = narrow and 118 or (h or 74)
        t.Size = UDim2.new(1, narrow and -34 or -150, 0, 24)
        d.Size = UDim2.new(1, narrow and -34 or -150, 0, 30)
        if not row:FindFirstChild("Body") then row.Size = UDim2.new(1, 0, 0, height) end
        row:SetAttribute("HeaderHeight", height)
    end
    connect(row:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    allCards[#allCards + 1] = { frame = row, page = pageName, title = value,
        text = string.lower(pageName .. " " .. value .. " " .. desc) }
    connect(row.MouseEnter, function()
        animate(edge, { Color = C.CTRL }, 0.18)
        if not row:FindFirstChild("Body") then animate(row, { BackgroundColor3 = C.HOVER }, 0.18) end
    end)
    connect(row.MouseLeave, function()
        animate(edge, { Color = C.STROKE }, 0.22)
        if not row:FindFirstChild("Body") then animate(row, { BackgroundColor3 = C.CARD }, 0.18) end
    end)
    return row
end

local function toggle(row, get, set, rightInset)
    local b = button(row, "Toggle", UDim2.fromOffset(56, 44), UDim2.new(1, rightInset or -18, 0.5, 0))
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.ZIndex = 3
    local track = frame(b, "Track", UDim2.fromOffset(52, 30), UDim2.fromOffset(2, 7), C.CTRL)
    round(track, 15)
    local trackLine = outline(track)
    local knob = frame(track, "Knob", UDim2.fromOffset(24, 24), UDim2.fromOffset(3, 3), Color3.fromRGB(246, 250, 248))
    round(knob, 12)
    local previous
    local function paint()
        local on = get() == true
        if on == previous then return end
        previous = on
        b:SetAttribute("Value", on)
        trackLine.Color = on and C.ACCENT or C.STROKE
        if on then
            trackLine.Transparency = 0
            Tween:Create(trackLine, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Transparency = 0.45 }):Play()
        else
            trackLine.Transparency = 0
        end
        animate(track, { BackgroundColor3 = on and C.ACCENT_SOFT or C.CTRL }, 0.18)
        animate(knob, { Position = UDim2.fromOffset(on and 25 or 3, 3) }, 0.3, Enum.EasingStyle.Back)
    end
    local function fit()
        local stacked = row.AbsoluteSize.X < 400 and row.AbsoluteSize.Y >= 100
        b.Position = stacked and UDim2.new(1, rightInset or -18, 1, -30) or UDim2.new(1, rightInset or -18, 0.5, 0)
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
    local head = frame(row, "Head", UDim2.new(1, 0, 0, h or 74))
    local body = frame(row, "Body", UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, h or 74))
    body.AutomaticSize = Enum.AutomaticSize.Y
    stack(body, 4)
    padding(body, 18, 2, 18, 14)
    local divider = frame(body, "Divider", UDim2.new(1, 0, 0, 1), nil, C.STROKE)
    divider.BackgroundTransparency = 0.3
    divider.LayoutOrder = -10
    local chevronBtn = button(head, "Expand", UDim2.fromOffset(34, 44), UDim2.new(1, -18, 0.5, 0))
    chevronBtn.AnchorPoint = Vector2.new(1, 0.5)
    chevronBtn.ZIndex = 4
    local chevron = icon(chevronBtn, "Chevron", UDim2.fromOffset(8, 13), C.MUT, 18)
    local hit = button(head, "Hit", UDim2.new(1, -170, 1, 0))
    hit.ZIndex = 3
    local open, ready = true, false
    local function fit(instant)
        local hh = row:GetAttribute("HeaderHeight") or h or 74
        head.Size = UDim2.new(1, 0, 0, hh)
        body.Position = UDim2.fromOffset(0, hh)
        local target = UDim2.new(1, 0, 0, hh + (open and body.AbsoluteSize.Y or 0))
        if instant then row.Size = target else animate(row, { Size = target }, 0.22) end
        local narrow = row.AbsoluteSize.X < 420
        chevronBtn.Position = narrow and UDim2.new(1, -18, 1, -32) or UDim2.new(1, -18, 0.5, 0)
    end
    local function setOpen(v, instant)
        open = v
        row:SetAttribute("Expanded", v)
        if v then body.Visible = true end
        if instant then chevron.Rotation = v and 180 or 0
        else animate(chevron, { Rotation = v and 180 or 0 }, 0.22) end
        tintIcon(chevron, v and C.ACCENT or C.MUT)
        if not v then closeDD2() end
        fit(instant)
        if v and not instant then
            local rest = body.Position
            body.Position = rest - UDim2.fromOffset(0, 8)
            animate(body, { Position = rest }, 0.28)
        end
        if not v then
            task.delay(0.24, function() if not open then body.Visible = false end end)
        end
    end
    connect(body:GetPropertyChangedSignal("AbsoluteSize"), function() fit(not ready) end)
    connect(row:GetAttributeChangedSignal("HeaderHeight"), function() fit(not ready) end)
    connect(chevronBtn.Activated, function() setOpen(not open) end)
    connect(hit.Activated, function() setOpen(not open) end)
    connect(hit.MouseEnter, function() animate(row, { BackgroundColor3 = C.HOVER }, 0.18) end)
    connect(hit.MouseLeave, function() animate(row, { BackgroundColor3 = C.CARD }, 0.18) end)
    setOpen(true, true)
    task.defer(function() ready = true end)
    return { frame = row, body = body, head = head, setOpen = setOpen }
end

-- Zeile im Panel-Body, registriert für die Suche.
local function subRow(body, pageName, value, rootCard, order)
    local r = frame(body, value:gsub("%W", ""), UDim2.new(1, 0, 0, 52))
    r.LayoutOrder = order
    text(r, "Label", value, UDim2.new(1, -140, 1, 0), UDim2.new(), 16, C.TXT)
    allCards[#allCards + 1] = { frame = r, page = pageName, title = value,
        text = string.lower(pageName .. " " .. value), root = rootCard.frame, open = rootCard.setOpen }
    return r
end

local function subToggle(body, pageName, value, rootCard, order, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local function fit()
        local narrow = r.AbsoluteSize.X < 360
        r.Size = UDim2.new(1, 0, 0, narrow and 88 or 52)
        r.Label.Size = UDim2.new(1, narrow and -32 or -140, 0, narrow and 36 or 52)
        local t = r:FindFirstChild("Toggle")
        if t then t.Position = narrow and UDim2.new(1, -2, 1, -30) or UDim2.new(1, -2, 0.5, 0) end
    end
    local result = toggle(r, get, set, -2)
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    return result
end

-- Beim Aufklappen mitscrollen, sonst steht die Liste unter dem sichtbaren Rand.
local function revealList(list, height, pageName, row)
    local function nudge()
        if not gui.Parent or not list.Visible then return end
        local pg = pages[pageName]
        local overflow = list.AbsolutePosition.Y + height - pg.AbsolutePosition.Y - pg.AbsoluteSize.Y
        if overflow > 0 then
            local top = row.AbsolutePosition.Y - pg.AbsolutePosition.Y + pg.CanvasPosition.Y - 8
            pg.CanvasPosition = Vector2.new(0, math.max(0, math.min(top, pg.CanvasPosition.Y + overflow + 14)))
        end
    end
    task.defer(nudge)
    task.delay(0.26, nudge)
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
    local b = button(r, "Dropdown", UDim2.fromOffset(214, 40), UDim2.new(1, -2, 0.5, 0), C.SIDE)
    b.AnchorPoint = Vector2.new(1, 0.5)
    round(b, 8)
    local border = outline(b)
    local selected = text(b, "Value", "", UDim2.new(1, -46, 0, 21), UDim2.fromOffset(13, 3), 16, C.TXT, true)
    local rarity = text(b, "Rarity", "", UDim2.new(1, -46, 0, 16), UDim2.fromOffset(13, 22), 13, C.MUT)
    local arrow = icon(b, "Chevron", UDim2.new(1, -28, 0.5, -8), C.MUT, 16)
    local listHeight = math.min(264, 58 + #options * 46)
    local list = frame(body, "Options_" .. order, UDim2.new(1, 0, 0, listHeight), nil, C.SIDE)
    list.LayoutOrder = order + 1
    list.Visible = false
    local setList = listOpener(list, listHeight)
    list.ClipsDescendants = true
    round(list, 8)
    outline(list)
    DD2_LISTS[#DD2_LISTS + 1] = list
    local filterWrap = frame(list, "Filter", UDim2.new(1, -20, 0, 36), UDim2.fromOffset(10, 9), C.CARD)
    round(filterWrap, 8)
    icon(filterWrap, "Search", UDim2.fromOffset(10, 9), C.MUT, 16)
    local filter = make("TextBox", { Name = "Search", Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(34, 0), Text = "", PlaceholderText = "Search a tree or rarity",
        PlaceholderColor3 = C.MUT, TextColor3 = C.TXT, BackgroundTransparency = 1,
        ClearTextOnFocus = false, FontFace = face(W.Regular), TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left }, filterWrap)
    local sc = make("ScrollingFrame", { Name = "Options", Position = UDim2.fromOffset(10, 52),
        Size = UDim2.new(1, -20, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.STROKE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, list)
    stack(sc, 2)
    padding(sc, 2, 1, 7, 1)
    local empty = text(sc, "Empty", "No matching trees.", UDim2.new(1, 0, 0, 48), UDim2.new(), 14, C.MUT)
    empty.Visible = false
    local optionButtons = {}
    local function paint()
        local cur = get()
        selected.Text = tostring(cur)
        rarity.Text = ""
        for i, opt in ipairs(options) do
            local active = opt.value == cur
            local ob = optionButtons[i]
            ob.BackgroundColor3 = active and C.SELECTED or C.SIDE
            ob.SelectionMark.Visible = active
            if active then
                rarity.Text = opt.rarity
                rarity.TextColor3 = RARITY_COLORS[opt.rarity] or C.MUT
            end
        end
    end
    for i, opt in ipairs(options) do
        local ob = button(sc, "Option_" .. opt.value, UDim2.new(1, 0, 0, 44), nil, C.SIDE)
        ob.LayoutOrder = i
        round(ob, 6)
        local dot = frame(ob, "RarityDot", UDim2.fromOffset(5, 5), UDim2.fromOffset(12, 20), RARITY_COLORS[opt.rarity] or C.MUT)
        round(dot, 3)
        text(ob, "Name", opt.value, UDim2.new(1, -92, 0, 20), UDim2.fromOffset(28, 4), 16, C.TXT, true)
        text(ob, "Rarity", opt.rarity, UDim2.new(1, -92, 0, 17), UDim2.fromOffset(28, 24), 13, C.MUT)
        local mark = text(ob, "SelectionMark", "Selected", UDim2.fromOffset(70, 44), UDim2.new(1, -78, 0, 0), 12, C.ACCENT)
        mark.TextXAlignment = Enum.TextXAlignment.Right
        optionButtons[i] = ob
        connect(ob.Activated, function() set(opt.value) paint() filter:ReleaseFocus() setList(false) end)
        connect(ob.MouseEnter, function()
            if get() ~= opt.value then animate(ob, { BackgroundColor3 = C.HOVER }, 0.1) end
        end)
        connect(ob.MouseLeave, function()
            animate(ob, { BackgroundColor3 = get() == opt.value and C.SELECTED or C.SIDE }, 0.1)
        end)
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
        animate(arrow, { Rotation = list.Visible and 180 or 0 }, 0.22)
        border.Color = list.Visible and C.ACCENT or C.STROKE
        if not list.Visible then filter:ReleaseFocus() end
    end)
    connect(b.Activated, function()
        local was = list.Visible
        closeDD2()
        setList(not was)
        if not was then
            filter.Text = ""
            paint()
            revealList(list, listHeight, pageName, r)
        end
    end)
    local function fit()
        local narrow = r.AbsoluteSize.X < 400
        r.Size = UDim2.new(1, 0, 0, narrow and 92 or 56)
        r.Label.Size = UDim2.new(1, narrow and -28 or -228, 0, narrow and 34 or 56)
        b.Size = narrow and UDim2.new(1, -16, 0, 40) or UDim2.fromOffset(214, 40)
        b.Position = narrow and UDim2.new(1, -2, 1, -30) or UDim2.new(1, -2, 0.5, 0)
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
    local b = button(r, "Dropdown", UDim2.fromOffset(214, 40), UDim2.new(1, -2, 0.5, 0), C.SIDE)
    b.AnchorPoint = Vector2.new(1, 0.5)
    round(b, 8)
    local border = outline(b)
    local selected = text(b, "Value", "", UDim2.new(1, -46, 0, 21), UDim2.fromOffset(13, 3), 16, C.TXT, true)
    local summary = text(b, "Summary", "", UDim2.new(1, -46, 0, 16), UDim2.fromOffset(13, 22), 13, C.MUT)
    local arrow = icon(b, "Chevron", UDim2.new(1, -28, 0.5, -8), C.MUT, 16)
    local listHeight = math.min(288, 58 + #options * 46)
    local list = frame(body, "Picks_" .. order, UDim2.new(1, 0, 0, listHeight), nil, C.SIDE)
    list.LayoutOrder = order + 1
    list.Visible = false
    local setList = listOpener(list, listHeight)
    list.ClipsDescendants = true
    round(list, 8)
    outline(list)
    DD2_LISTS[#DD2_LISTS + 1] = list
    local filterWrap = frame(list, "Filter", UDim2.new(1, -20, 0, 36), UDim2.fromOffset(10, 9), C.CARD)
    round(filterWrap, 8)
    icon(filterWrap, "Search", UDim2.fromOffset(10, 9), C.MUT, 16)
    local filter = make("TextBox", { Name = "Search", Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(34, 0), Text = "", PlaceholderText = "Search",
        PlaceholderColor3 = C.MUT, TextColor3 = C.TXT, BackgroundTransparency = 1,
        ClearTextOnFocus = false, FontFace = face(W.Regular), TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left }, filterWrap)
    local sc = make("ScrollingFrame", { Name = "Options", Position = UDim2.fromOffset(10, 52),
        Size = UDim2.new(1, -20, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.STROKE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, list)
    stack(sc, 2)
    padding(sc, 2, 1, 7, 1)
    local optionButtons = {}
    local function paint()
        local picked = {}
        for i, opt in ipairs(options) do
            local on = isOn(opt.value) == true
            local ob = optionButtons[i]
            ob.BackgroundColor3 = on and C.SELECTED or C.SIDE
            ob.Box.BackgroundColor3 = on and C.ACCENT or C.SIDE
            ob.Box.Mark.Visible = on
            ob.Box.BoxStroke.Color = on and C.ACCENT or C.STROKE
            if on then picked[#picked + 1] = opt.label or opt.value end
        end
        if #picked == 0 then
            selected.Text = "Nothing picked"
            selected.TextColor3 = C.MUT
            summary.Text = "Tap to choose items"
        else
            selected.Text = #picked == 1 and picked[1] or (#picked .. " items")
            selected.TextColor3 = C.TXT
            summary.Text = table.concat(picked, ", ")
        end
    end
    for i, opt in ipairs(options) do
        local ob = button(sc, "Pick_" .. opt.value, UDim2.new(1, 0, 0, 44), nil, C.SIDE)
        ob.LayoutOrder = i
        round(ob, 6)
        local box = frame(ob, "Box", UDim2.fromOffset(20, 20), UDim2.fromOffset(12, 12), C.SIDE)
        round(box, 6)
        local boxStroke = outline(box)
        boxStroke.Name = "BoxStroke"
        local mark = icon(box, "Check", UDim2.fromOffset(3, 3), C.BG, 14)
        mark.Name = "Mark"
        text(ob, "Name", opt.value, UDim2.new(1, -88, 0, 20), UDim2.fromOffset(40, 3), 16, C.TXT, true)
        text(ob, "Note", opt.note or "", UDim2.new(1, -88, 0, 17), UDim2.fromOffset(40, 23), 13, C.MUT)
        optionButtons[i] = ob
        connect(ob.Activated, function() setOn(opt.value, not isOn(opt.value)) paint() end)
        connect(ob.MouseEnter, function()
            if not isOn(opt.value) then animate(ob, { BackgroundColor3 = C.HOVER }, 0.1) end
        end)
        connect(ob.MouseLeave, function()
            animate(ob, { BackgroundColor3 = isOn(opt.value) and C.SELECTED or C.SIDE }, 0.1)
        end)
    end
    local empty = text(sc, "Empty", "Nothing matches.", UDim2.new(1, 0, 0, 44), UDim2.new(), 14, C.MUT)
    empty.Visible = false
    empty.LayoutOrder = 999
    connect(filter:GetPropertyChangedSignal("Text"), function()
        local q = string.lower(filter.Text)
        local shown = 0
        for i, opt in ipairs(options) do
            local hit = string.find(string.lower(opt.value .. " " .. (opt.note or "")), q, 1, true) ~= nil
            optionButtons[i].Visible = hit
            if hit then shown = shown + 1 end
        end
        empty.Visible = shown == 0
        sc.CanvasPosition = Vector2.zero
    end)
    connect(list:GetPropertyChangedSignal("Visible"), function()
        animate(arrow, { Rotation = list.Visible and 180 or 0 }, 0.22)
        border.Color = list.Visible and C.ACCENT or C.STROKE
        if not list.Visible then filter:ReleaseFocus() end
    end)
    connect(b.Activated, function()
        local was = list.Visible
        closeDD2()
        setList(not was)
        if not was then
            filter.Text = ""
            paint()
            revealList(list, listHeight, pageName, r)
        end
    end)
    local function fit()
        local narrow = r.AbsoluteSize.X < 400
        r.Size = UDim2.new(1, 0, 0, narrow and 92 or 56)
        r.Label.Size = UDim2.new(1, narrow and -28 or -228, 0, narrow and 34 or 56)
        b.Size = narrow and UDim2.new(1, -16, 0, 40) or UDim2.fromOffset(214, 40)
        b.Position = narrow and UDim2.new(1, -2, 1, -30) or UDim2.new(1, -2, 0.5, 0)
    end
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    paint()
    return { repaint = paint }
end

local function subChoice(body, pageName, value, rootCard, order, options, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local wrap = frame(r, "Choice", UDim2.fromOffset(214, 40), UDim2.new(1, -2, 0.5, 0), C.SIDE)
    wrap.AnchorPoint = Vector2.new(1, 0.5)
    round(wrap, 8)
    outline(wrap)
    local entries = {}
    local function paint()
        for _, e in ipairs(entries) do
            local on = e.value == get()
            e.button.BackgroundColor3 = on and C.SELECTED or C.SIDE
            e.label.TextColor3 = on and C.ACCENT or C.MUT
        end
    end
    for i, opt in ipairs(options) do
        local b = button(wrap, "Choice_" .. i, UDim2.new(0.5, -6, 1, -8), UDim2.new((i - 1) * 0.5, 4, 0, 4), C.SIDE)
        round(b, 7)
        local l = text(b, "Label", opt.label or opt.value, UDim2.new(1, 0, 1, 0), UDim2.new(), 14, C.MUT, true)
        l.TextXAlignment = Enum.TextXAlignment.Center
        entries[#entries + 1] = { value = opt.value, button = b, label = l }
        connect(b.Activated, function() set(opt.value) paint() end)
    end
    local function fit()
        local narrow = r.AbsoluteSize.X < 400
        r.Size = UDim2.new(1, 0, 0, narrow and 92 or 56)
        r.Label.Size = UDim2.new(1, narrow and -28 or -228, 0, narrow and 34 or 56)
        wrap.Size = narrow and UDim2.new(1, -16, 0, 40) or UDim2.fromOffset(214, 40)
        wrap.Position = narrow and UDim2.new(1, -2, 1, -30) or UDim2.new(1, -2, 0.5, 0)
    end
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    painters[#painters + 1] = paint
    paint()
    return { repaint = paint }
end

-- Zeile mit Zahlenfeld, nimmt nur Ziffern.
-- Die Stufen sind ungleich verteilt, weil Alien-Angebote weit ueber dem Normalbereich liegen.
local function subSlider(body, pageName, value, rootCard, order, stops, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local lo, hi = stops[1], stops[#stops]
    local val = make("TextBox", { Name = "Val", Text = "", Size = UDim2.fromOffset(70, 26),
        Position = UDim2.new(1, -236, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        FontFace = face(W.SemiBold), TextSize = 15, TextColor3 = C.ACCENT,
        TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = false }, r)
    local hit = button(r, "Track", UDim2.fromOffset(160, 34), UDim2.new(1, -2, 0.5, 0))
    hit.AnchorPoint = Vector2.new(1, 0.5)
    local rail = frame(hit, "Rail", UDim2.new(1, 0, 0, 6), UDim2.new(0, 0, 0.5, -3), C.SIDE)
    round(rail, 3)
    local fill = frame(rail, "Fill", UDim2.new(0, 0, 1, 0), nil, C.ACCENT)
    round(fill, 3)
    local knob = frame(hit, "Knob", UDim2.fromOffset(16, 16), UDim2.new(0, -8, 0.5, -8), C.TXT)
    round(knob, 8)
    outline(knob, C.ACCENT)
    local function paint()
        if val:IsFocused() then return end
        local v = math.clamp(tonumber(get()) or lo, lo, hi)
        local idx = #stops
        for i, stop in ipairs(stops) do
            if v <= stop then
                idx = i
                break
            end
        end
        local a = (idx - 1) / (#stops - 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, -8, 0.5, -8)
        val.Text = (v > 0 and "+" or "") .. tostring(v) .. "%"
    end
    local function apply(x)
        local w = math.max(1, hit.AbsoluteSize.X)
        local a = math.clamp((x - hit.AbsolutePosition.X) / w, 0, 1)
        set(stops[math.floor(a * (#stops - 1) + 1.5)])
        paint()
    end
    local dragging = false
    connect(hit.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            animate(knob, { Size = UDim2.fromOffset(20, 20) })
            apply(i.Position.X)
        end
    end)
    connect(hit.InputChanged, function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            apply(i.Position.X)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            animate(knob, { Size = UDim2.fromOffset(16, 16) })
        end
    end)
    local function fit()
        local narrow = r.AbsoluteSize.X < 420
        r.Size = UDim2.new(1, 0, 0, narrow and 92 or 56)
        r.Label.Size = UDim2.new(1, narrow and -28 or -248, 0, narrow and 34 or 56)
        hit.Size = narrow and UDim2.new(1, -80, 0, 34) or UDim2.fromOffset(160, 34)
        hit.Position = narrow and UDim2.new(1, -2, 1, -26) or UDim2.new(1, -2, 0.5, 0)
        val.Position = narrow and UDim2.new(1, -74, 1, -58) or UDim2.new(1, -236, 0.5, 0)
        paint()
    end
    -- Der Wert laesst sich auch tippen, dann zaehlt jede Zahl und nicht nur die Stufen.
    connect(val.Focused, function() val.TextColor3 = C.TXT end)
    connect(val.FocusLost, function()
        val.TextColor3 = C.ACCENT
        local typed = tonumber((string.gsub(val.Text, "[^%-%d]", "")))
        if typed then set(math.clamp(typed, lo, hi)) end
        paint()
    end)
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    painters[#painters + 1] = paint
    paint()
    return { repaint = paint }
end

local function subNumber(body, pageName, value, rootCard, order, get, set)
    local r = subRow(body, pageName, value, rootCard, order)
    local box = make("TextBox", { Name = "Input", Size = UDim2.fromOffset(236, 48),
        Position = UDim2.new(1, -4, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = C.SIDE, BorderSizePixel = 0, Text = tostring(get() or 0),
        PlaceholderText = "0", PlaceholderColor3 = C.MUT, TextColor3 = C.TXT,
        FontFace = face(W.SemiBold), TextSize = 15, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left }, r)
    round(box, 8)
    local border = outline(box)
    padding(box, 13, 0, 13, 0)
    connect(box.Focused, function() border.Color = C.ACCENT end)
    connect(box.FocusLost, function()
        border.Color = C.STROKE
        local n = tonumber((string.gsub(box.Text, "%D", ""))) or 0
        set(n)
        box.Text = tostring(n)
    end)
    local function fit()
        local narrow = r.AbsoluteSize.X < 400
        r.Size = UDim2.new(1, 0, 0, narrow and 92 or 56)
        r.Label.Size = UDim2.new(1, narrow and -28 or -228, 0, narrow and 34 or 56)
        box.Size = narrow and UDim2.new(1, -16, 0, 40) or UDim2.fromOffset(214, 40)
        box.Position = narrow and UDim2.new(1, -2, 1, -30) or UDim2.new(1, -2, 0.5, 0)
    end
    connect(r:GetPropertyChangedSignal("AbsoluteSize"), fit)
    responsive[#responsive + 1] = fit
    return { repaint = function() if not box:IsFocused() then box.Text = tostring(get() or 0) end end }
end

section(homePage, "This session", 1)
do
    local strip = frame(homePage, "Stats", UDim2.new(1, 0, 0, 86), nil, C.CARD)
    strip.LayoutOrder = 2
    round(strip, 12)
    outline(strip)
    local cells = {}
    for i, d in ipairs({{"Runtime", "CWValTime", "0s"}, {"Rerolls", "CWValRolls", "0"},
        {"Chopped", "CWValTrees", "0"}, {"Watered", "CWValWater", "0"},
        {"Bought", "CWValBuys", "0"}}) do
        local cell = frame(strip, d[2] .. "Cell", UDim2.new(0.2, 0, 1, 0), UDim2.new((i - 1) / 5, 0, 0, 0))
        text(cell, "Label", d[1], UDim2.new(1, -18, 0, 20), UDim2.fromOffset(14, 13), 14, C.MUT)
        local valueLabel = text(cell, d[2], d[3], UDim2.new(1, -18, 0, 34), UDim2.fromOffset(14, 36), 22, i == 1 and C.ACCENT or C.TXT, true, true)
        local resting = i == 1 and C.ACCENT or C.TXT
        local shown = valueLabel.Text
        painters[#painters + 1] = function()
            if valueLabel.Text == shown then return end
            shown = valueLabel.Text
            valueLabel.TextColor3 = C.ACCENT
            Tween:Create(valueLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { TextColor3 = resting }):Play()
        end
        if i > 1 then
            local sep = frame(cell, "Sep", UDim2.fromOffset(1, 40), UDim2.fromOffset(0, 20), C.STROKE)
            sep.BackgroundTransparency = 0.4
        end
        cells[i] = cell
    end
    local function fit()
        local narrow = strip.AbsoluteSize.X < 460
        strip.Size = UDim2.new(1, 0, 0, narrow and math.ceil(#cells / 2) * 86 or 86)
        for i, cell in ipairs(cells) do
            cell.Size = narrow and UDim2.new(0.5, 0, 0, 86) or UDim2.new(0.2, 0, 1, 0)
            cell.Position = narrow and UDim2.new(((i - 1) % 2) * 0.5, 0, 0, math.floor((i - 1) / 2) * 86)
                or UDim2.new((i - 1) / 5, 0, 0, 0)
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
    local row = button(homePage, "Open_" .. data[1], UDim2.new(1, 0, 0, 68), nil, C.CARD)
    row.LayoutOrder = i + 5
    round(row, 12)
    outline(row)
    local rowIcon = icon(row, data[1], UDim2.fromOffset(18, 24), C.ACCENT, 20)
    connect(row.MouseEnter, function() animate(rowIcon, { Position = UDim2.fromOffset(22, 24) }, 0.18) end)
    connect(row.MouseLeave, function() animate(rowIcon, { Position = UDim2.fromOffset(18, 24) }, 0.18) end)
    text(row, "Title", data[2], UDim2.new(1, -190, 0, 23), UDim2.fromOffset(50, 12), 17, C.TXT, true)
    local desc = text(row, "Description", data[3], UDim2.new(1, -190, 0, 21), UDim2.fromOffset(50, 36), 14, C.MUT)
    local state = text(row, "State", "", UDim2.fromOffset(80, 68), UDim2.new(1, -130, 0, 0), 14, C.MUT)
    state.TextXAlignment = Enum.TextXAlignment.Right
    icon(row, "Arrow", UDim2.new(1, -38, 0.5, -9), C.MUT, 18)
    hover(row, C.CARD)
    connect(row.Activated, function() navigate(data[1]) end)
    painters[#painters + 1] = function()
        local on = getgenv()[data[4]] == true
        state.Text = on and "Running" or "Off"
        state.TextColor3 = on and C.ACCENT or C.MUT
        desc.Visible = row.AbsoluteSize.X >= 360
    end
end

section(farmPage, "Seed cycle", 1)
do
    local ec = panel(farmPage, "Farm", "Auto farm seeds", "Reroll seeds, wait for results, then collect.", 2, 74)
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
        end, -70)
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
    local ec = panel(treePage, "Trees", "Auto trees", "Plant by priority, chop mature trees and collect drops.", 2, 74)
    toggle(ec.head,
        function() return getgenv().CW_Trees end,
        function(v) getgenv().CW_Trees = v end, -70)
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
    UDim2.new(1, 0, 0, 44), UDim2.new(), 14, C.MUT)
priorityHelp.LayoutOrder = 3
priorityHelp.TextWrapped = true
priorityHelp.TextTruncate = Enum.TextTruncate.None

section(treePage, "Watering", 4)
do
    local ec = panel(treePage, "Trees", "Auto water", "Refill growing planters before the boost runs out.", 5, 74)
    toggle(ec.head,
        function() return getgenv().CW_Water end,
        function(v) getgenv().CW_Water = v end, -70)
    local canOpts = {}
    for _, mult in ipairs(CW_CAN_MULTS) do
        canOpts[#canOpts + 1] = { value = mult .. "x", rarity = "Watering can" }
    end
    subDropdown(ec.body, "Trees", "Watering can", ec, 10, canOpts,
        function() return (tonumber(getgenv().CW_WaterCan) or 64) .. "x" end,
        function(v) getgenv().CW_WaterCan = tonumber((string.gsub(v, "x", ""))) or 64 end)
    local note = text(ec.body, "CanNote", "", UDim2.new(1, -4, 0, 20), UDim2.new(), 13, C.MUT)
    note.LayoutOrder = 20
    painters[#painters + 1] = function()
        local want = tonumber(getgenv().CW_WaterCan) or 64
        local held = 0
        for _, root in ipairs({ LP.Character, LP.Backpack }) do
            if root then
                for _, t in ipairs(root:GetChildren()) do
                    if t:IsA("Tool") and t:GetAttribute("WateringCanMultiplier") == want then held = held + 1 end
                end
            end
        end
        note.Text = held > 0 and (held .. " cans in stock") or ("No " .. want .. "x cans left, watering paused")
        note.TextColor3 = held > 0 and C.MUT or Color3.fromRGB(226, 132, 118)
    end
end
local waterHelp = text(treePage, "WaterHelp", "Runs on its own, so you can keep planters watered while farming seeds with auto trees off.",
    UDim2.new(1, 0, 0, 44), UDim2.new(), 14, C.MUT)
waterHelp.LayoutOrder = 6
waterHelp.TextWrapped = true
waterHelp.TextTruncate = Enum.TextTruncate.None

section(shopPage, "Gem store", 1)
do
    local ec = panel(shopPage, "Shop", "Auto buy", "Empty every picked slot, then wait for new stock.", 2, 74)
    toggle(ec.head,
        function() return getgenv().CW_Shop end,
        function(v) getgenv().CW_Shop = v end, -70)
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
    local ec = panel(shopPage, "Shop", "Auto refresh", "Roll fresh stock once nothing picked is left, then buy again.", 4, 74)
    toggle(ec.head,
        function() return getgenv().CW_ShopRoll end,
        function(v) getgenv().CW_ShopRoll = v end, -70)
    subChoice(ec.body, "Shop", "Pay rolls with", ec, 10,
        {{ value = "Gems", label = "Gems (100)" }, { value = "Wood Chips", label = "Chips (5000)" }},
        function() return getgenv().CW_ShopPay end,
        function(v) getgenv().CW_ShopPay = v end)
    subNumber(ec.body, "Shop", "Keep at least this many gems", ec, 20,
        function() return getgenv().CW_ShopFloor end,
        function(v) getgenv().CW_ShopFloor = v end)
    subNumber(ec.body, "Shop", "Keep at least this many chips", ec, 25,
        function() return getgenv().CW_ShopChipFloor end,
        function(v) getgenv().CW_ShopChipFloor = v end)
    subToggle(ec.body, "Shop", "Stay at the store", ec, 30,
        function() return getgenv().CW_ShopStay end,
        function(v) getgenv().CW_ShopStay = v end)
end
local shopHelp = text(shopPage, "ShopHelp", "Buying and rolling teleport you to the store and back. Each limit stops spending of that currency, so gems and chips can run out on their own terms.",
    UDim2.new(1, 0, 0, 44), UDim2.new(), 14, C.MUT)
shopHelp.LayoutOrder = 5
shopHelp.TextWrapped = true
shopHelp.TextTruncate = Enum.TextTruncate.None

section(pages["Sell Zone"], "Carving", 1)
do
    local ec = panel(pages["Sell Zone"], "Sell Zone", "Auto carve", "Turn raw logs into carvings that hit the target exactly.", 2, 74)
    toggle(ec.head,
        function() return getgenv().CW_Carve end,
        function(v) getgenv().CW_Carve = v end, -70)
    local woodOpts = {}
    local byLabel = {}
    for _, kind in ipairs(Carve.kinds) do
        woodOpts[#woodOpts + 1] = { value = kind[1], note = "raw wood" }
        byLabel[kind[1]] = kind[2]
    end
    subMulti(ec.body, "Sell Zone", "Wood to carve", ec, 10, woodOpts,
        function(label)
            local pick = getgenv().CW_CarvePick
            return type(pick) == "table" and pick[byLabel[label]] == true
        end,
        function(label, on)
            local pick = getgenv().CW_CarvePick
            if type(pick) ~= "table" then
                pick = {}
                getgenv().CW_CarvePick = pick
            end
            pick[byLabel[label]] = on or nil
        end)
end
section(pages["Sell Zone"], "Shelves", 3)
do
    local ec = panel(pages["Sell Zone"], "Sell Zone", "Auto shelf", "Put finished carvings straight onto free shelf spots.", 4, 74)
    toggle(ec.head,
        function() return getgenv().CW_Shelve end,
        function(v) getgenv().CW_Shelve = v end, -70)
    local shelfOpts = {}
    local shelfById = {}
    for _, kind in ipairs(Carve.kinds) do
        shelfOpts[#shelfOpts + 1] = { value = kind[1], note = "carving" }
        shelfById[kind[1]] = kind[2]
    end
    subToggle(ec.body, "Sell Zone", "Refill from raw logs", ec, 6,
        function() return getgenv().CW_ShelveAuto end,
        function(v) getgenv().CW_ShelveAuto = v end)
    subMulti(ec.body, "Sell Zone", "Wood to shelf", ec, 10, shelfOpts,
        function(label)
            local pick = getgenv().CW_ShelvePick
            return type(pick) == "table" and pick[shelfById[label]] == true
        end,
        function(label, on)
            local pick = getgenv().CW_ShelvePick
            if type(pick) ~= "table" then
                pick = {}
                getgenv().CW_ShelvePick = pick
            end
            pick[shelfById[label]] = on or nil
        end)
end
section(pages["Sell Zone"], "Customers", 5)
do
    local ec = panel(pages["Sell Zone"], "Sell Zone", "Auto accept customers", "Answer offers on the spot, anything under your bar gets turned down.", 6, 74)
    toggle(ec.head,
        function() return getgenv().CW_Customers end,
        function(v) getgenv().CW_Customers = v end, -70)
    subSlider(ec.body, "Sell Zone", "Minimum offer", ec, 6, {
        -20, -10, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
        125, 150, 200, 250, 300, 400, 500, 600, 800, 1000, 1250, 1500, 2000, 2500,
    },
        function() return getgenv().CW_CustMin end,
        function(v) getgenv().CW_CustMin = v end)
    local seenLine = text(ec.body, "Seen", "", UDim2.new(1, 0, 0, 40), UDim2.new(), 14, C.MUT)
    seenLine.LayoutOrder = 8
    seenLine.TextWrapped = true
    seenLine.TextTruncate = Enum.TextTruncate.None
    painters[#painters + 1] = function()
        local seen = getgenv().CW_OfferSeen or {}
        local parts = {}
        for _, style in ipairs({ "Normal", "Gold", "Rainbow", "Alien" }) do
            local best = seen[style]
            parts[#parts + 1] = style .. " " .. (best and ((best > 0 and "+" or "") .. best .. "%") or "n/a")
        end
        seenLine.Text = "Best seen this session: " .. table.concat(parts, ", ")
    end
    local styleOpts = {
        { value = "Normal", note = "base roll, cashier scale -20% to +40%" },
        { value = "Gold", note = "gold frenzy or VIP, at least +30%" },
        { value = "Rainbow", note = "rainbow frenzy, at least +100%, 5x base" },
        { value = "Alien", note = "alien invasion, 15x base" },
    }
    subMulti(ec.body, "Sell Zone", "Offer types", ec, 10, styleOpts,
        function(label)
            local pick = getgenv().CW_CustStyles
            return type(pick) == "table" and pick[label] == true
        end,
        function(label, on)
            local pick = getgenv().CW_CustStyles
            if type(pick) ~= "table" then
                pick = {}
                getgenv().CW_CustStyles = pick
            end
            pick[label] = on or nil
        end)
end
do
    local help = text(pages["Sell Zone"], "CarveHelp", "Auto carve takes every wood while nothing is picked, auto shelf only what you tick. Anything under the minimum offer gets declined right away.",
        UDim2.new(1, 0, 0, 44), UDim2.new(), 14, C.MUT)
    help.LayoutOrder = 7
    help.TextWrapped = true
    help.TextTruncate = Enum.TextTruncate.None
end

section(perfPage, "Interface", 1)
toggle(card(perfPage, "Performance", "Click sound", "Play a soft click whenever you press something.", 2),
    function() return getgenv().CW_ClickSfx end,
    function(v) getgenv().CW_ClickSfx = v end)
section(perfPage, "Rendering", 3)
toggle(card(perfPage, "Performance", "Low quality mode", "Reduce effects, lights and shadows. Everything is restored when you turn it off.", 4),
    function() return getgenv().CW_LowQ end,
    function(v) getgenv().CW_LowQ = v if v then lowQOn() else lowQOff() end end)

for i, info in ipairs(PAGE_INFO) do navItem(info, i) end
local results = {}
for i, entry in ipairs(allCards) do
    local b = button(searchPage, "Result_" .. i, UDim2.new(1, 0, 0, 64), nil, C.CARD)
    b.LayoutOrder = i
    round(b, 6)
    outline(b)
    text(b, "Title", entry.title, UDim2.new(1, -58, 0, 26), UDim2.fromOffset(18, 11), 16, C.TXT, true)
    text(b, "Page", entry.page, UDim2.new(1, -58, 0, 20), UDim2.fromOffset(18, 39), 13, C.MUT)
    icon(b, "Arrow", UDim2.new(1, -32, 0.5, -9), C.MUT, 18)
    hover(b, C.CARD)
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

local btnMin = button(header, "Minimize", UDim2.fromOffset(38, 38), UDim2.new(1, -88, 0, 9), C.SIDE)
round(btnMin, 6)
local minIcon = icon(btnMin, "Minus", UDim2.fromOffset(10, 10), C.MUT, 18)
local plusIcon = icon(btnMin, "Plus", UDim2.fromOffset(10, 10), C.MUT, 18)
plusIcon.Visible = false
plusIcon.Visible = false
hover(btnMin, C.SIDE)
local btnX = button(header, "Close", UDim2.fromOffset(38, 38), UDim2.new(1, -46, 0, 9), C.SIDE)
round(btnX, 6)
icon(btnX, "Close", UDim2.fromOffset(10, 10), C.MUT, 18)
hover(btnX, C.SIDE, Color3.fromRGB(57, 35, 37))
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
    local arm = frame(grip, "ArmX", UDim2.fromOffset(11, 2), UDim2.fromOffset(dx > 0 and 11 or 8, dy > 0 and 20 or 8), C.MUT)
    local armY = frame(grip, "ArmY", UDim2.fromOffset(2, 11), UDim2.fromOffset(dx > 0 and 20 or 8, dy > 0 and 11 or 8), C.MUT)
    arm.BackgroundTransparency = 0.55
    armY.BackgroundTransparency = 0.55
    round(arm, 1)
    round(armY, 1)
    connect(grip.MouseEnter, function()
        animate(arm, { BackgroundColor3 = C.ACCENT, BackgroundTransparency = 0 }, 0.12)
        animate(armY, { BackgroundColor3 = C.ACCENT, BackgroundTransparency = 0 }, 0.12)
    end)
    connect(grip.MouseLeave, function()
        animate(arm, { BackgroundColor3 = C.MUT, BackgroundTransparency = 0.55 }, 0.12)
        animate(armY, { BackgroundColor3 = C.MUT, BackgroundTransparency = 0.55 }, 0.12)
    end)
    resizeGrips[#resizeGrips + 1] = grip
end
local modal = button(main, "ConfirmClose", UDim2.fromScale(1, 1), nil, C.BG)
modal.BackgroundTransparency = 0.12
modal.ZIndex = 20
modal.Visible = false
modal.Modal = true
local dialog = frame(modal, "Dialog", UDim2.fromOffset(390, 212), UDim2.fromScale(0.5, 0.5), C.CARD)
dialog.AnchorPoint = Vector2.new(0.5, 0.5)
round(dialog, 10)
outline(dialog)
text(dialog, "Title", "End this session?", UDim2.new(1, -40, 0, 30), UDim2.fromOffset(22, 26), 21, C.TXT, true)
local warning = text(dialog, "Description", "All automations will stop and visual settings will be restored.",
    UDim2.new(1, -44, 0, 60), UDim2.fromOffset(22, 70), 15, C.MUT)
warning.TextWrapped = true
warning.TextTruncate = Enum.TextTruncate.None
local cancel = button(dialog, "Cancel", UDim2.new(0.5, -26, 0, 44), UDim2.new(0, 20, 1, -64), C.CTRL)
local confirm = button(dialog, "StopSession", UDim2.new(0.5, -26, 0, 44), UDim2.new(0.5, 6, 1, -64), Color3.fromRGB(62, 37, 39))
for _, b in ipairs({cancel, confirm}) do round(b, 6) end
local cancelText = text(cancel, "Label", "Cancel", UDim2.fromScale(1, 1), UDim2.new(), 15, C.TXT, true)
local confirmText = text(confirm, "Label", "Stop session", UDim2.fromScale(1, 1), UDim2.new(), 15, Color3.fromRGB(245, 170, 172), true)
cancelText.TextXAlignment = Enum.TextXAlignment.Center
confirmText.TextXAlignment = Enum.TextXAlignment.Center
connect(cancel.Activated, function() modal.Visible = false end)

local fullSize = Vector2.new(732, 508)
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
    compact = w < 560
    main:SetAttribute("Compact", compact)
    local sw = compact and 60 or (w < 700 and 172 or 196)
    side.Size = UDim2.new(0, sw, 1, -86)
    content.Position = UDim2.fromOffset(sw, 56)
    content.Size = UDim2.new(1, -sw, 1, -86)
    navHolder.Position = UDim2.fromOffset(10, compact and 56 or 62)
    navHolder.Size = UDim2.new(1, -20, 1, compact and -64 or -70)
    for _, b in pairs(navBtns) do
        b.Label.Visible = not compact
        b.Icon.Position = compact and UDim2.new(0.5, -10, 0.5, -10) or UDim2.fromOffset(13, 13)
    end
    smallSearch.Visible = compact
    searchWrap.Parent = compact and header or side
    searchWrap.Position = compact and UDim2.fromOffset(60, 8) or UDim2.fromOffset(10, 8)
    searchWrap.Size = compact and UDim2.new(1, -164, 0, 40) or UDim2.new(1, -20, 0, 44)
    searchWrap.Visible = not compact or mobileSearchOpen
    searchWrap.ZIndex = 4
    title.Visible = not (compact and mobileSearchOpen)
    version.Visible = not compact
    footHint.Visible = not compact
    dialog.Size = UDim2.fromOffset(math.min(400, w - 28), 210)
    for _, grip in ipairs(resizeGrips) do grip.Visible = not collapsed end
    local inset = compact and 14 or 20
    pageHead.Position = UDim2.fromOffset(inset, 0)
    pageHead.Size = UDim2.new(1, -inset * 2, 0, 66)
    pageDesc.TextWrapped = true
    pageDesc.TextTruncate = Enum.TextTruncate.None
    pageDesc.Size = UDim2.new(1, 0, 0, 20)
    for _, pg in pairs(pages) do
        pg.Position = UDim2.fromOffset(0, 66)
        pg.Size = UDim2.new(1, 0, 1, -66)
        local pad = pg:FindFirstChildOfClass("UIPadding")
        pad.PaddingLeft = UDim.new(0, inset)
        pad.PaddingRight = UDim.new(0, inset)
    end
    for _, fit in ipairs(responsive) do fit() end
end
local function fitViewport()
    local vp = availableSize()
    fullSize = Vector2.new(math.min(fullSize.X, vp.X - 24), math.min(fullSize.Y, vp.Y - 24))
    main.Size = collapsed and UDim2.fromOffset(math.min(292, vp.X - 24), 64) or UDim2.fromOffset(fullSize.X, fullSize.Y)
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
    if value then
        for _, part in ipairs({ mini.Icon, mini.Title, mini.Status, mini.Dot }) do
            local rest = part.Position
            part.Position = rest - UDim2.fromOffset(10, 0)
            animate(part, { Position = rest }, 0.36)
        end
    end
    animate(main, { BackgroundColor3 = value and C.SIDE or C.BG }, 0.34)
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
    animate(main, { Size = value and UDim2.fromOffset(math.min(292, vp.X - 24), 64)
        or UDim2.fromOffset(fullSize.X, fullSize.Y) }, 0.34)
    animate(mainCorner, { CornerRadius = UDim.new(0, value and 32 or 12) }, 0.34)
    task.delay(0.36, function()
        main:SetAttribute("Animating", false)
        clampPosition()
        if not collapsed then layout() end
    end)
end
connect(btnMin.Activated, function() setCollapsed(not collapsed) end)
connect(btnX.Activated, function()
    setCollapsed(false)
    closeDD2()
    modal.Visible = true
    local rest = dialog.Size
    dialog.Size = UDim2.fromOffset(rest.X.Offset - 22, rest.Y.Offset - 14)
    animate(dialog, { Size = rest }, 0.26)
end)
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
-- Erster Start zeigt kurz die Wortmarke, danach wächst das Fenster auf.
do
    local target = main.Size
    local function grow()
        main.Visible = true
        main.Size = UDim2.fromOffset(target.X.Offset - 30, target.Y.Offset - 22)
        animate(main, { Size = target }, 0.32)
    end
    if getgenv().CW_Splashed then
        grow()
    else
        getgenv().CW_Splashed = true
        main.Visible = false
        local splash = make("CanvasGroup", { Name = "Splash", Size = UDim2.fromOffset(300, 136),
            Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = C.SIDE, BorderSizePixel = 0, GroupTransparency = 1 }, gui)
        round(splash, 16)
        outline(splash)
        local mark = icon(splash, "Brand", UDim2.new(0.5, -18, 0, 24), C.ACCENT, 36)
        local word = text(splash, "Word", "CarveWood", UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 72), 22, C.TXT, true, true)
        word.TextXAlignment = Enum.TextXAlignment.Center
        local rail = frame(splash, "Rail", UDim2.fromOffset(160, 2), UDim2.new(0.5, -80, 0, 110), C.CTRL)
        round(rail, 1)
        local fill = frame(rail, "Fill", UDim2.new(0, 0, 1, 0), nil, C.ACCENT)
        round(fill, 1)
        mark.Position = UDim2.new(0.5, -18, 0, 32)
        animate(splash, { GroupTransparency = 0 }, 0.24)
        animate(mark, { Position = UDim2.new(0.5, -18, 0, 24) }, 0.4)
        animate(fill, { Size = UDim2.new(1, 0, 1, 0) }, 0.9, Enum.EasingStyle.Quad)
        task.delay(1.05, function()
            if not gui.Parent then return end
            animate(splash, { GroupTransparency = 1 }, 0.24)
            task.delay(0.24, function()
                splash:Destroy()
                if gui.Parent then grow() end
            end)
        end)
    end
end
local STATUS_NAMES = {
    {"CW_Farm", "Seed farm"}, {"CW_Trees", "Trees"}, {"CW_Frenzy", "Frenzy"},
    {"CW_CollectCan", "Cans"}, {"CW_CollectFert", "Fertilizer"}, {"CW_Fert", "Fertilize"},
    {"CW_Shop", "Shop"}, {"CW_ShopRoll", "Restock"},
    {"CW_Carve", "Carve"}, {"CW_Shelve", "Shelf"}, {"CW_Customers", "Customers"},
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
