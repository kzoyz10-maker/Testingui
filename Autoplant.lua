local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Farm V62 (SMART GLIDE + HARVEST SWEEP)"

-- ========================================== --
-- [[ KONFIGURASI AWAL ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().WalkSpeed = getgenv().WalkSpeed or 16     
getgenv().BreakDelay = getgenv().BreakDelay or 0.15  
getgenv().PlantDelay = getgenv().PlantDelay or 0.15

getgenv().EnableSmartHarvest = getgenv().EnableSmartHarvest or false
getgenv().EnableAutoPlant = getgenv().EnableAutoPlant or false
getgenv().CollectDrops = getgenv().CollectDrops or true
getgenv().SelectedSeed = getgenv().SelectedSeed or "Kosong"

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- REMOTES
local Remotes = RS:WaitForChild("Remotes")
local RemoteFist = Remotes:WaitForChild("PlayerFist")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem") 

-- MANAGERS
local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

local InventoryMod
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)

local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

-- ========================================== --
-- [[ SISTEM INVENTORY TRANSLATOR ]]
-- ========================================== --
getgenv().InventoryCacheNameMap = {}

local function GetItemName(rawId)
    if type(rawId) == "string" then return rawId end
    if WorldManager and WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] then
        return WorldManager.NumberToStringMap[rawId]
    end
    if ItemsManager and ItemsManager.ItemsData and ItemsManager.ItemsData[rawId] then
        local data = ItemsManager.ItemsData[rawId]
        if type(data) == "table" and data.Name then return data.Name end
    end
    return tostring(rawId)
end

local function ScanAvailableItems()
    local items = {}; local dict = {}
    getgenv().InventoryCacheNameMap = {} 
    
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for slotIndex, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and data.Id then
                    if not data.Amount or data.Amount > 0 then
                        local realId = data.Id
                        local itemName = GetItemName(realId)
                        
                        if not dict[itemName] then 
                            dict[itemName] = true
                            table.insert(items, itemName)
                            getgenv().InventoryCacheNameMap[itemName] = realId
                        end
                    end
                end
            end
        end
    end)
    
    if #items == 0 then table.insert(items, "Kosong"); getgenv().InventoryCacheNameMap["Kosong"] = nil end
    table.sort(items)
    return items
end

local function GetSlotByItemName(targetName)
    if not InventoryMod or not InventoryMod.Stacks then return nil end
    local targetID = getgenv().InventoryCacheNameMap[targetName] or targetName
    
    for slotIndex, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            if not data.Amount or data.Amount > 0 then return slotIndex end
        end
    end
    return nil
end

-- ========================================== --
-- [[ BIKIN UI MENU (WIND UI) ]]
-- ========================================== --
local SecFarm = Tab:Section({ Title = "🌾 Farm & Plant Logic", Box = true, Opened = true })

SecFarm:Toggle({ Title = "▶ START AUTO HARVEST", Default = getgenv().EnableSmartHarvest, Callback = function(v) getgenv().EnableSmartHarvest = v end })
SecFarm:Toggle({ Title = "▶ START AUTO PLANT", Default = getgenv().EnableAutoPlant, Callback = function(v) getgenv().EnableAutoPlant = v end })
SecFarm:Toggle({ Title = "🧲 Auto Sweep Collect (Pas Harvest)", Default = getgenv().CollectDrops, Callback = function(v) getgenv().CollectDrops = v end })

local DropSeed = SecFarm:Dropdown({ Title = "🎒 Choose Seed (Bibit)", Options = ScanAvailableItems(), Default = getgenv().SelectedSeed, Callback = function(v) getgenv().SelectedSeed = v end })
SecFarm:Button({ Title = "🔄 Refresh Inventory", Callback = function() pcall(function() DropSeed:Refresh(ScanAvailableItems()) end) end })

local SecSpeed = Tab:Section({ Title = "⚡ Speeds & Delays", Box = true, Opened = false })
SecSpeed:Input({ Title = "Walk Speed (Kecepatan)", Value = tostring(getgenv().WalkSpeed), Placeholder = tostring(getgenv().WalkSpeed), Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })
SecSpeed:Input({ Title = "Harvest Break Delay (ms)", Value = tostring(getgenv().BreakDelay), Placeholder = tostring(getgenv().BreakDelay), Callback = function(v) getgenv().BreakDelay = tonumber(v) or getgenv().BreakDelay end })
SecSpeed:Input({ Title = "Plant Delay (ms)", Value = tostring(getgenv().PlantDelay), Placeholder = tostring(getgenv().PlantDelay), Callback = function(v) getgenv().PlantDelay = tonumber(v) or getgenv().PlantDelay end })

-- ========================================== --
-- [[ RADAR INVERTED & 99999 A-STAR (SMART GLIDE) ]]
-- ========================================== --
local BlockSolidityCache = {}
local function IsTileSolid(gridX, gridY)
    if gridX < 0 or gridX > 100 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then tileString = WorldManager.NumberToStringMap[rawId] or rawId end
        local nameStr = tostring(tileString):lower()
        if BlockSolidityCache[nameStr] ~= nil then 
            if BlockSolidityCache[nameStr] == true then return true end
        else
            if string.find(nameStr, "bg") or string.find(nameStr, "background") or string.find(nameStr, "sapling") or string.find(nameStr, "door") or string.find(nameStr, "seed") or string.find(nameStr, "air") or string.find(nameStr, "water") then 
                BlockSolidityCache[nameStr] = false
            else
                BlockSolidityCache[nameStr] = true; return true
            end
        end
    end
    return false
end

local function IsTileEmptyForPlant(gridX, gridY)
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then tileString = WorldManager.NumberToStringMap[rawId] or rawId end
        local nameStr = tostring(tileString):lower()
        if not string.find(nameStr, "bg") and not string.find(nameStr, "background") and not string.find(nameStr, "air") and not string.find(nameStr, "water") then 
            return false 
        end
    end
    return true
end

local function FindPathAStar(startX, startY, targetX, targetY)
    if startX == targetX and startY == targetY then return {} end
    local function heuristic(x, y) return math.abs(x - targetX) + math.abs(y - targetY) end
    local openSet, closedSet, cameFrom, gScore, fScore = {}, {}, {}, {}, {}
    local startKey = startX .. "," .. startY
    table.insert(openSet, {x = startX, y = startY, key = startKey})
    gScore[startKey] = 0; fScore[startKey] = heuristic(startX, startY)
    
    local maxIterations, iterations = 99999, 0 
    local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

    while #openSet > 0 do
        iterations = iterations + 1; if iterations > maxIterations then break end
        local current, currentIndex = openSet[1], 1
        for i = 2, #openSet do if fScore[openSet[i].key] < fScore[current.key] then current = openSet[i]; currentIndex = i end end

        if current.x == targetX and current.y == targetY then
            local path, currKey = {}, current.key
            while cameFrom[currKey] do
                local node = cameFrom[currKey]; table.insert(path, 1, {x = current.x, y = current.y}); current = node; currKey = node.x .. "," .. node.y
            end
            return path
        end
        table.remove(openSet, currentIndex); closedSet[current.key] = true
        for _, dir in ipairs(directions) do
            local nextX, nextY = current.x + dir[1], current.y + dir[2]
            local nextKey = nextX .. "," .. nextY
            if nextX >= 0 and nextX <= 100 and not closedSet[nextKey] then
                local isTarget = (nextX == targetX and nextY == targetY)
                if isTarget or not IsTileSolid(nextX, nextY) then
                    local tentative_gScore = gScore[current.key] + 1
                    if not gScore[nextKey] or tentative_gScore < gScore[nextKey] then
                        cameFrom[nextKey] = current; gScore[nextKey] = tentative_gScore; fScore[nextKey] = tentative_gScore + heuristic(nextX, nextY)
                        local inOpenSet = false
                        for _, node in ipairs(openSet) do if node.key == nextKey then inOpenSet = true; break end end
                        if not inOpenSet then table.insert(openSet, {x = nextX, y = nextY, key = nextKey}) end
                    end
                else closedSet[nextKey] = true end
            end
        end
    end
    return nil 
end

local function SmoothWalkPath(pathTable, currZ)
    if #pathTable == 0 then return end
    
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    
    if not MyHitbox then return false end
    if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end

    local oldGravity = workspace.Gravity
    workspace.Gravity = 0

    local startPos = MyHitbox.Position
    if PlayerMovement and PlayerMovement.Position then startPos = PlayerMovement.Position end

    for _, targetPos in ipairs(pathTable) do
        if not getgenv().EnableSmartHarvest and not getgenv().EnableAutoPlant then break end
        
        local targetVec3 = Vector3.new(targetPos.X, targetPos.Y, currZ)
        local dist = (Vector2.new(startPos.X, startPos.Y) - Vector2.new(targetVec3.X, targetVec3.Y)).Magnitude 
        local duration = dist / getgenv().WalkSpeed
        if duration < 0.05 then duration = 0.05 end

        local t = 0
        while t < duration and (getgenv().EnableSmartHarvest or getgenv().EnableAutoPlant) do
            local dt = RunService.Heartbeat:Wait()
            t = t + dt
            local alpha = math.clamp(t / duration, 0, 1)
            local currentPos = startPos:Lerp(targetVec3, alpha)
            
            if PlayerMovement then 
                pcall(function() 
                    PlayerMovement.Position = currentPos
                    PlayerMovement.VelocityX = 0 
                    PlayerMovement.VelocityY = 0 
                    PlayerMovement.VelocityZ = 0 
                end)
            else
                local fixedRot = MyHitbox.CFrame - MyHitbox.CFrame.Position
                local newCFrame = fixedRot + currentPos
                MyHitbox.CFrame = newCFrame
                if hrp and MyHitbox ~= hrp then hrp.CFrame = newCFrame end
            end
        end
        startPos = targetVec3
    end
    
    if PlayerMovement then 
        pcall(function() 
            PlayerMovement.VelocityX = 0 
            PlayerMovement.VelocityY = 0 
            PlayerMovement.VelocityZ = 0 
            PlayerMovement.InputActive = true 
        end)
    end
    workspace.Gravity = oldGravity
    return true
end

local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    local currZ = MyHitbox.Position.Z
    local myGridX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
    local myGridY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)

    if myGridX == targetX and myGridY == targetY then return true end
    
    local route = FindPathAStar(myGridX, myGridY, targetX, targetY)
    
    if route and #route > 0 then
        local pathTable = {}
        for _, step in ipairs(route) do table.insert(pathTable, Vector3.new(step.x * getgenv().GridSize, step.y * getgenv().GridSize, currZ)) end
        table.insert(pathTable, Vector3.new(targetX * getgenv().GridSize, targetY * getgenv().GridSize, currZ))
        return SmoothWalkPath(pathTable, currZ)
    else
        warn("⚠️ Map belum ter-render atau jalan buntu! Menggunakan Fast-Travel...")
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end
        local targetVec3 = Vector3.new(targetX * getgenv().GridSize, targetY * getgenv().GridSize, currZ)
        if PlayerMovement then pcall(function() PlayerMovement.Position = targetVec3 end) else MyHitbox.CFrame = CFrame.new(targetVec3) end
        task.wait(0.2)
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
        return true
    end
end

local function GetExactDropsInGrid(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local exactPositions = {}
    for _, folder in ipairs(TargetFolders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position end
                
                if pos then
                    local dX = math.floor(pos.X / getgenv().GridSize + 0.5)
                    local dY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                    if dX == TargetGridX and dY == TargetGridY then table.insert(exactPositions, pos) end
                end
            end
        end
    end
    return exactPositions
end

-- ========================================== --
-- [[ AUTO HARVEST LOGIC (TYPEWRITER + SWEEP BACK) ]]
-- ========================================== --
if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end
getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartHarvest then
            local SaplingsData = {}
            for x, yCol in pairs(RawWorldTiles) do
                if type(yCol) == "table" then
                    for y, layers in pairs(yCol) do
                        if type(layers) == "table" then
                            for layer, data in pairs(layers) do
                                local rawId = type(data) == "table" and data[1] or data
                                local tileString = rawId
                                
                                if type(rawId) == "number" and WorldManager.NumberToStringMap then
                                    tileString = WorldManager.NumberToStringMap[rawId] or rawId
                                end
                                
                                if type(tileString) == "string" and string.find(string.lower(tileString), "sapling") then
                                    table.insert(SaplingsData, {x = x, y = y})
                                end
                            end
                        end
                    end
                end
            end
            
            -- Harvest: Selalu dari X = 0 sampai ke X = 100 buat tiap baris
            table.sort(SaplingsData, function(a, b)
                if a.y == b.y then return a.x < b.x end
                return a.y < b.y 
            end)

            for i, sapling in ipairs(SaplingsData) do
                if not getgenv().EnableSmartHarvest then break end
                local bisaJalan = MoveSmartlyTo(sapling.x, sapling.y)
                
                if bisaJalan then
                    task.wait(0.05)
                    pcall(function() 
                        local targetVec = Vector2.new(sapling.x, sapling.y)
                        if RemoteFist:IsA("RemoteEvent") then RemoteFist:FireServer(targetVec) 
                        else RemoteFist:InvokeServer(targetVec) end
                    end)
                    
                    -- FIX SWEEP COLLECT: Tunggu jatuh lalu sapu kayak script Pabrik!
                    task.wait(getgenv().BreakDelay + 0.3)
                    if getgenv().CollectDrops then
                        local exactDrops = GetExactDropsInGrid(sapling.x, sapling.y)
                        if #exactDrops > 0 then
                            local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
                            if MyHitbox then 
                                SmoothWalkPath(exactDrops, MyHitbox.Position.Z)
                                MoveSmartlyTo(sapling.x, sapling.y) -- Normalin posisi biar ga melenceng
                            end
                        end
                    end
                    
                    local nextSapling = SaplingsData[i + 1]
                    if not nextSapling or nextSapling.y ~= sapling.y then
                        MoveSmartlyTo(sapling.x + 1, sapling.y)
                        task.wait(0.1)
                        
                        MoveSmartlyTo(0, sapling.y)
                        task.wait(0.1)
                    end
                end
            end
        end
        task.wait(1) 
    end
end)

-- ========================================== --
-- [[ AUTO PLANT LOGIC (TRUE ZIG-ZAG FIXED) ]]
-- ========================================== --
if getgenv().KzoyzAutoPlantLoop then task.cancel(getgenv().KzoyzAutoPlantLoop) end
getgenv().KzoyzAutoPlantLoop = task.spawn(function()
    while true do
        if getgenv().EnableAutoPlant and not getgenv().EnableSmartHarvest then 
            local tempList = {}
            local uniqueYs = {}
            local seenYs = {}

            -- Scan area buat nanam
            for x = 0, 100 do
                local yCol = RawWorldTiles[x]
                if type(yCol) == "table" then
                    for y, _ in pairs(yCol) do
                        if IsTileSolid(x, y) and IsTileEmptyForPlant(x, y + 1) then
                            local targetY = y + 1
                            table.insert(tempList, {x = x, y = targetY})
                            
                            -- Nyimpen daftar Y yang unik biar bisa di-indeks
                            if not seenYs[targetY] then
                                seenYs[targetY] = true
                                table.insert(uniqueYs, targetY)
                            end
                        end
                    end
                end
            end
            
            -- SORTIR ZIG-ZAG PINTAR
            table.sort(uniqueYs) -- Urutin dari baris paling bawah/atas
            local yDirectionMap = {}
            for index, yValue in ipairs(uniqueYs) do
                -- Index ganjil = Kiri ke Kanan (True) | Index genap = Kanan ke Kiri (False)
                yDirectionMap[yValue] = (index % 2 == 1) 
            end

            table.sort(tempList, function(a, b)
                if a.y == b.y then
                    if yDirectionMap[a.y] then return a.x < b.x -- Kiri ke Kanan
                    else return a.x > b.x end -- Kanan ke Kiri
                end
                return a.y < b.y 
            end)

            for _, spot in ipairs(tempList) do
                if not getgenv().EnableAutoPlant or getgenv().EnableSmartHarvest then break end
                
                local bibit = getgenv().SelectedSeed
                if bibit ~= "Kosong" and bibit ~= "None" then 
                    
                    local seedSlot = GetSlotByItemName(bibit)
                    if not seedSlot then
                        warn("⚠️ Bibit " .. tostring(bibit) .. " habis!")
                        getgenv().EnableAutoPlant = false
                        break
                    end
                    
                    local bisaJalan = MoveSmartlyTo(spot.x, spot.y)
                    if bisaJalan then
                        task.wait(0.05)
                        pcall(function() 
                            local targetVec = Vector2.new(spot.x, spot.y)
                            local targetStr = tostring(spot.x) .. ", " .. tostring(spot.y)
                            if RemotePlace:IsA("RemoteEvent") then 
                                RemotePlace:FireServer(targetVec, seedSlot) 
                                RemotePlace:FireServer(targetStr, seedSlot) 
                            else 
                                RemotePlace:InvokeServer(targetVec, seedSlot) 
                            end
                        end)
                        task.wait(getgenv().PlantDelay)
                    end
                end
            end
        end
        task.wait(1.5) 
    end
end)
