local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Pabrik v2.3 - WINDUI INPUT FIXED" 

-- ========================================== --
-- [[ DEFAULT SETTINGS (ANTI-RESET) ]]
-- ========================================== --
getgenv().WalkSpeed = getgenv().WalkSpeed or 16     
getgenv().PlaceDelay = getgenv().PlaceDelay or 0.15  
getgenv().DropDelay = getgenv().DropDelay or 0.5      
getgenv().BreakDelay = getgenv().BreakDelay or 0.15 
getgenv().HitCount = getgenv().HitCount or 3    

getgenv().EnablePabrik = getgenv().EnablePabrik or false
getgenv().OnlyCollectSapling = getgenv().OnlyCollectSapling or true
getgenv().PabrikStartX = getgenv().PabrikStartX or 0
getgenv().PabrikEndX = getgenv().PabrikEndX or 100
getgenv().PabrikStartY = getgenv().PabrikStartY or 0
getgenv().PabrikEndY = getgenv().PabrikEndY or 100

getgenv().BreakPosX = getgenv().BreakPosX or 0
getgenv().BreakPosY = getgenv().BreakPosY or 0
getgenv().DropPosX = getgenv().DropPosX or 0
getgenv().DropPosY = getgenv().DropPosY or 0

getgenv().BlockThreshold = getgenv().BlockThreshold or 20 
getgenv().KeepSeedAmt = getgenv().KeepSeedAmt or 20    

getgenv().SelectedSeed = getgenv().SelectedSeed or "Kosong"
getgenv().SelectedBlock = getgenv().SelectedBlock or "Kosong" 

getgenv().AIDictionary = getgenv().AIDictionary or {}
getgenv().IsGhosting = false
getgenv().HoldCFrame = nil
getgenv().GridSize = 4.5

-- ========================================== --
-- [[ SERVICES & MANAGERS ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem") 

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local InventoryMod, UIManager, PlayerMovement
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

if getgenv().KzoyzHeartbeatPabrik then getgenv().KzoyzHeartbeatPabrik:Disconnect(); getgenv().KzoyzHeartbeatPabrik = nil end
getgenv().KzoyzHeartbeatPabrik = RunService.Heartbeat:Connect(function()
    if getgenv().IsGhosting then
        if getgenv().HoldCFrame then
            local char = LP.Character
            if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = getgenv().HoldCFrame end
        end
        if PlayerMovement then pcall(function() PlayerMovement.VelocityY = 0; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.Grounded = true; PlayerMovement.Jumping = false end) end
    end
end)

-- ========================================== --
-- [[ INVENTORY TRANSLATOR ]]
-- ========================================== --
getgenv().InventoryCacheNameMap = {}

local function GetItemName(rawId)
    if type(rawId) == "string" then return rawId end
    if WorldManager and WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] then return WorldManager.NumberToStringMap[rawId] end
    if ItemsManager and ItemsManager.ItemsData and ItemsManager.ItemsData[rawId] then
        local data = ItemsManager.ItemsData[rawId]
        if type(data) == "table" and data.Name then return data.Name end
    end
    return tostring(rawId)
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

local function GetItemAmountByItemName(targetName)
    local total = 0
    if not InventoryMod or not InventoryMod.Stacks then return total end
    local targetID = getgenv().InventoryCacheNameMap[targetName] or targetName
    for _, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            total = total + (data.Amount or 1)
        end
    end
    return total
end

local function ScanAvailableItems()
    local items = {}; local dict = {}
    getgenv().InventoryCacheNameMap = {}
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for _, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and data.Id then
                    if not data.Amount or data.Amount > 0 then
                        local realId = data.Id
                        local itemName = GetItemName(realId)
                        if not dict[itemName] then 
                            dict[itemName] = true; table.insert(items, itemName)
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

-- ========================================== --
-- [[ WIND UI MAKER UNTUK TAB INI ]]
-- ========================================== --

Tab:Section({ Title = "🚀 Smart Pabrik Control" })

Tab:Toggle({ Title = "▶ START SMART PABRIK", Default = getgenv().EnablePabrik, Callback = function(v) getgenv().EnablePabrik = v end })
Tab:Toggle({ Title = "Auto Collect Sapling (Pas Break)", Default = getgenv().OnlyCollectSapling, Callback = function(v) getgenv().OnlyCollectSapling = v end })

local DropSeed = Tab:Dropdown({ Title = "🎒 Pilih Seed (Bibit)", Options = ScanAvailableItems(), Default = getgenv().SelectedSeed, Callback = function(v) getgenv().SelectedSeed = v end })
local DropBlock = Tab:Dropdown({ Title = "🧱 Pilih Block (Untuk Dihancurkan)", Options = ScanAvailableItems(), Default = getgenv().SelectedBlock, Callback = function(v) getgenv().SelectedBlock = v end })

Tab:Button({ Title = "🔄 Refresh Tas Item", Callback = function() pcall(function() local newItems = ScanAvailableItems(); DropSeed:Refresh(newItems); DropBlock:Refresh(newItems) end) end })

Tab:Section({ Title = "🗺️ Area Scan Setup (X & Y)" })

-- DI WINDUI KITA PAKAI 'Value' & 'PlaceholderText' BIAR ANGKA MUNCUL (BUKAN DEFAULT)
Tab:Input({ Title = "Area Start X", Value = tostring(getgenv().PabrikStartX), PlaceholderText = tostring(getgenv().PabrikStartX), Callback = function(v) getgenv().PabrikStartX = tonumber(v) or getgenv().PabrikStartX end })
Tab:Input({ Title = "Area End X", Value = tostring(getgenv().PabrikEndX), PlaceholderText = tostring(getgenv().PabrikEndX), Callback = function(v) getgenv().PabrikEndX = tonumber(v) or getgenv().PabrikEndX end })
Tab:Input({ Title = "Area Start Y", Value = tostring(getgenv().PabrikStartY), PlaceholderText = tostring(getgenv().PabrikStartY), Callback = function(v) getgenv().PabrikStartY = tonumber(v) or getgenv().PabrikStartY end })
Tab:Input({ Title = "Area End Y", Value = tostring(getgenv().PabrikEndY), PlaceholderText = tostring(getgenv().PabrikEndY), Callback = function(v) getgenv().PabrikEndY = tonumber(v) or getgenv().PabrikEndY end })

Tab:Section({ Title = "⚙️ Threshold Settings (Batas Item)" })
Tab:Input({ Title = "Block Threshold (Sisa di tas)", Value = tostring(getgenv().BlockThreshold), PlaceholderText = tostring(getgenv().BlockThreshold), Callback = function(v) getgenv().BlockThreshold = tonumber(v) or getgenv().BlockThreshold end })
Tab:Input({ Title = "Keep Seed Amt (Sisa di tas)", Value = tostring(getgenv().KeepSeedAmt), PlaceholderText = tostring(getgenv().KeepSeedAmt), Callback = function(v) getgenv().KeepSeedAmt = tonumber(v) or getgenv().KeepSeedAmt end })

Tab:Section({ Title = "📍 Posisi Break & Drop" })

-- SIMPAN INPUT KE VARIABEL BIAR BISA DIUBAH DARI TOMBOL
local InpBreakX = Tab:Input({ Title = "Break Pos X", Value = tostring(getgenv().BreakPosX), PlaceholderText = tostring(getgenv().BreakPosX), Callback = function(v) getgenv().BreakPosX = tonumber(v) or getgenv().BreakPosX end })
local InpBreakY = Tab:Input({ Title = "Break Pos Y", Value = tostring(getgenv().BreakPosY), PlaceholderText = tostring(getgenv().BreakPosY), Callback = function(v) getgenv().BreakPosY = tonumber(v) or getgenv().BreakPosY end })

Tab:Button({
    Title = "📍 Set Break Pos (Posisi Kamu Saat Ini)",
    Callback = function() 
        local H = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) 
        if H then 
            local newX = math.floor(H.Position.X/4.5+0.5)
            local newY = math.floor(H.Position.Y/4.5+0.5)
            getgenv().BreakPosX = newX
            getgenv().BreakPosY = newY
            -- UPDATE TEKS UI OTOMATIS
            pcall(function() InpBreakX:SetValue(tostring(newX)) end)
            pcall(function() InpBreakX:Set(tostring(newX)) end)
            pcall(function() InpBreakY:SetValue(tostring(newY)) end)
            pcall(function() InpBreakY:Set(tostring(newY)) end)
        end 
    end
})

local InpDropX = Tab:Input({ Title = "Drop Pos X", Value = tostring(getgenv().DropPosX), PlaceholderText = tostring(getgenv().DropPosX), Callback = function(v) getgenv().DropPosX = tonumber(v) or getgenv().DropPosX end })
local InpDropY = Tab:Input({ Title = "Drop Pos Y", Value = tostring(getgenv().DropPosY), PlaceholderText = tostring(getgenv().DropPosY), Callback = function(v) getgenv().DropPosY = tonumber(v) or getgenv().DropPosY end })

Tab:Button({
    Title = "📍 Set Drop Pos (Posisi Kamu Saat Ini)",
    Callback = function() 
        local H = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) 
        if H then 
            local newX = math.floor(H.Position.X/4.5+0.5)
            local newY = math.floor(H.Position.Y/4.5+0.5)
            getgenv().DropPosX = newX
            getgenv().DropPosY = newY
            -- UPDATE TEKS UI OTOMATIS
            pcall(function() InpDropX:SetValue(tostring(newX)) end)
            pcall(function() InpDropX:Set(tostring(newX)) end)
            pcall(function() InpDropY:SetValue(tostring(newY)) end)
            pcall(function() InpDropY:Set(tostring(newY)) end)
        end 
    end
})

Tab:Section({ Title = "⏱️ Kecepatan & Delay" })

Tab:Input({ Title = "Walk Speed", Value = tostring(getgenv().WalkSpeed), PlaceholderText = tostring(getgenv().WalkSpeed), Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })
Tab:Input({ Title = "Place Delay (ms)", Value = tostring(getgenv().PlaceDelay), PlaceholderText = tostring(getgenv().PlaceDelay), Callback = function(v) getgenv().PlaceDelay = tonumber(v) or getgenv().PlaceDelay end })
Tab:Input({ Title = "Break Delay (ms)", Value = tostring(getgenv().BreakDelay), PlaceholderText = tostring(getgenv().BreakDelay), Callback = function(v) getgenv().BreakDelay = tonumber(v) or getgenv().BreakDelay end })
Tab:Input({ Title = "Hit Count (Pukulan per Block)", Value = tostring(getgenv().HitCount), PlaceholderText = tostring(getgenv().HitCount), Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end })


-- ========================================== --
-- [[ RADAR INVERTED & A-STAR ]]
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
        if not string.find(nameStr, "bg") and not string.find(nameStr, "background") and not string.find(nameStr, "air") and not string.find(nameStr, "water") then return false end
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
    local maxIterations, iterations = 2000, 0
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

local function SmoothWalkTo(targetPos)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    local startPos = MyHitbox.Position
    local dist = (Vector2.new(startPos.X, startPos.Y) - Vector2.new(targetPos.X, targetPos.Y)).Magnitude 
    local duration = dist / getgenv().WalkSpeed
    
    if duration > 0 then 
        local t = 0
        while t < duration do
            if not getgenv().EnablePabrik then return false end
            local dt = RunService.Heartbeat:Wait()
            t = t + dt
            local alpha = math.clamp(t / duration, 0, 1)
            MyHitbox.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
            if PlayerMovement then pcall(function() PlayerMovement.Position = startPos:Lerp(targetPos, alpha) end) end
        end
    end
    MyHitbox.CFrame = CFrame.new(targetPos)
    if PlayerMovement then pcall(function() PlayerMovement.Position = targetPos end) end
    task.wait(0.02) 
    return true
end

local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    local myZ = MyHitbox.Position.Z
    local myGridX = math.round(MyHitbox.Position.X / getgenv().GridSize)
    local myGridY = math.round(MyHitbox.Position.Y / getgenv().GridSize)

    if myGridX == targetX and myGridY == targetY then return true end
    local route = FindPathAStar(myGridX, myGridY, targetX, targetY)
    if not route then return false end

    for _, stepPos in ipairs(route) do
        if not getgenv().EnablePabrik then break end
        local pos = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, myZ)
        if not SmoothWalkTo(pos) then return false end
    end
    return true
end

-- ========================================== --
-- [[ SMART AI HARVEST WAKTU ]]
-- ========================================== --
local function DeepFindGrowTime(tbl)
    if type(tbl) ~= "table" then return nil end
    for k, v in pairs(tbl) do
        if type(v) == "number" and type(k) == "string" then
            local kl = k:lower()
            if kl:find("grow") or kl:find("time") or kl:find("harvest") or kl:find("duration") or kl:find("age") then if v > 0 then return v end end
        elseif type(v) == "table" then
            local res = DeepFindGrowTime(v)
            if res then return res end
        end
    end
    return nil
end

local function GetExactGrowTime(saplingName)
    if getgenv().AIDictionary[saplingName] then return getgenv().AIDictionary[saplingName] end
    pcall(function()
        local baseId = string.gsub(saplingName, "_sapling", "")
        local itemData = ItemsManager.ItemsData[baseId] or ItemsManager.ItemsData[saplingName]
        if itemData then
            local foundTime = DeepFindGrowTime(itemData)
            if foundTime then getgenv().AIDictionary[saplingName] = foundTime end
        end
    end)
    return getgenv().AIDictionary[saplingName] or nil
end

local function BackupAIBelajarWaktu(sapling)
    local sampai = MoveSmartlyTo(sapling.x, sapling.y)
    if not sampai then return false end
    local timer = 0
    while timer < 20 do
        if not getgenv().EnablePabrik then return false end
        local hover = workspace:FindFirstChild("HoverPart")
        if hover then
            for _, v in pairs(hover:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text ~= "" then
                    local text = string.lower(v.Text)
                    if string.find(text, "grown") or string.find(text, "harvest") or string.find(text, "100%%") then
                        local jam = tonumber(string.match(text, "(%d+)h")) or 0
                        local menit = tonumber(string.match(text, "(%d+)m")) or 0
                        local detik = tonumber(string.match(text, "(%d+)s")) or 0
                        local isReady = string.find(text, "harvest") or string.find(text, "100%%")
                        local sisaWaktuLayar = (jam * 3600) + (menit * 60) + detik
                        if isReady then sisaWaktuLayar = 0 end
                        local umurSekarang = os.time() - sapling.at
                        local totalDurasi = umurSekarang + sisaWaktuLayar
                        totalDurasi = math.floor((totalDurasi + 5) / 10) * 10
                        getgenv().AIDictionary[sapling.name] = totalDurasi
                        return true
                    end
                end
            end
        end
        timer = timer + 1; task.wait(0.1)
    end
    return false
end

-- ========================================== --
-- [[ GHOST COLLECT & UTILS ]]
-- ========================================== --
local function CheckDropsType(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local hasSapling = false; local hasAny = false
    
    for _, folder in ipairs(TargetFolders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
                elseif obj:IsA("Model") then
                    local firstPart = obj:FindFirstChildWhichIsA("BasePart"); if firstPart then pos = firstPart.Position end
                end
                
                if pos then
                    local dX = math.floor(pos.X / getgenv().GridSize + 0.5)
                    local dY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                    if dX == TargetGridX and dY == TargetGridY then
                        hasAny = true
                        local isSapling = false
                        for _, attrValue in pairs(obj:GetAttributes()) do
                            if type(attrValue) == "string" and (string.find(string.lower(attrValue), "sapling") or string.find(string.lower(attrValue), "seed")) then isSapling = true; break end
                        end
                        if not isSapling then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("StringValue") and (string.find(string.lower(child.Value), "sapling") or string.find(string.lower(child.Value), "seed")) then isSapling = true; break end
                                for _, attrValue in pairs(child:GetAttributes()) do
                                    if type(attrValue) == "string" and (string.find(string.lower(attrValue), "sapling") or string.find(string.lower(attrValue), "seed")) then isSapling = true; break end
                                end
                                if isSapling then break end
                            end
                        end
                        if isSapling then hasSapling = true end
                    end
                end
            end
        end
    end
    return hasAny, hasSapling
end

local function TrueGhostCollect(targetX, targetY, collectSaplingOnly)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    
    local ExactHrpCF = hrp and hrp.CFrame
    local ExactHitboxCF = MyHitbox and MyHitbox.CFrame
    local ExactPMPos = nil
    if PlayerMovement then pcall(function() ExactPMPos = PlayerMovement.Position end) end

    if hrp then getgenv().HoldCFrame = ExactHrpCF; hrp.Anchored = true; getgenv().IsGhosting = true end
    if hum then
        local animator = hum:FindFirstChildOfClass("Animator")
        local tracks = animator and animator:GetPlayingAnimationTracks() or hum:GetPlayingAnimationTracks()
        for _, track in ipairs(tracks) do track:Stop(0) end
    end
    
    MoveSmartlyTo(targetX, targetY)
    
    local waitTimeout = 0
    while waitTimeout < 15 and getgenv().EnablePabrik do
        local anyDrop, sapDrop = CheckDropsType(targetX, targetY)
        if collectSaplingOnly then if not sapDrop then break end else if not anyDrop then break end end
        task.wait(0.1); waitTimeout = waitTimeout + 1
    end
    
    task.wait(0.1)
    MoveSmartlyTo(getgenv().BreakPosX, getgenv().BreakPosY) 
    
    if hrp and ExactHrpCF then 
        hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
        if MyHitbox and ExactHitboxCF then MyHitbox.CFrame = ExactHitboxCF; MyHitbox.AssemblyLinearVelocity = Vector3.zero end
        hrp.CFrame = ExactHrpCF
        if PlayerMovement and ExactPMPos then 
            pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.Grounded = true end) 
        end
        RunService.Heartbeat:Wait(); hrp.Anchored = false 
        for _ = 1, 2 do if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end; RunService.Heartbeat:Wait() end
    end
    getgenv().IsGhosting = false 
end

local function DropItemLogic(targetName, dropAmount)
    local slot = GetSlotByItemName(targetName)
    if not slot then return false end
    local dropRemote = RS:WaitForChild("Remotes"):FindFirstChild("PlayerDrop") or RS:WaitForChild("Remotes"):FindFirstChild("PlayerDropItem")
    local promptRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):FindFirstChild("UIPromptEvent")
    if dropRemote and promptRemote then
        pcall(function() dropRemote:FireServer(slot) end); task.wait(0.2) 
        pcall(function() promptRemote:FireServer({ ButtonAction = "drp", Inputs = { amt = tostring(dropAmount) } }) end); task.wait(0.1)
        pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
        return true
    end
    return false
end

-- ========================================== --
-- [[ LOGIKA UTAMA: SMART PABRIK ]]
-- ========================================== --
task.spawn(function()
    while true do
        if getgenv().EnablePabrik then
            if getgenv().SelectedSeed == "Kosong" or getgenv().SelectedBlock == "Kosong" then 
                task.wait(2)
            else
                local targetPanen = {}
                local targetTanam = {}

                -- 1. SCAN WORLD 
                local sX, eX = math.min(getgenv().PabrikStartX, getgenv().PabrikEndX), math.max(getgenv().PabrikStartX, getgenv().PabrikEndX)
                local sY, eY = math.min(getgenv().PabrikStartY, getgenv().PabrikEndY), math.max(getgenv().PabrikStartY, getgenv().PabrikEndY)

                for y = sY, eY do
                    if not getgenv().EnablePabrik then break end
                    local isEven = (y % 2 == 0)
                    local loopStartX = isEven and sX or eX
                    local loopEndX = isEven and eX or sX
                    local step = isEven and 1 or -1
                    
                    for x = loopStartX, loopEndX, step do
                        local yCol = RawWorldTiles[x]
                        if type(yCol) == "table" then
                            if IsTileSolid(x, y - 1) and IsTileEmptyForPlant(x, y) then
                                table.insert(targetTanam, {x = x, y = y})
                            end
                            if type(yCol[y]) == "table" then
                                for layer, data in pairs(yCol[y]) do
                                    local rawId = type(data) == "table" and data[1] or data
                                    local tileInfo = type(data) == "table" and data[2] or nil
                                    local tileStr = rawId
                                    if type(rawId) == "number" and WorldManager.NumberToStringMap then tileStr = WorldManager.NumberToStringMap[rawId] or rawId end
                                    
                                    if type(tileStr) == "string" and (string.find(string.lower(tileStr), "sapling") or string.find(string.lower(tileStr), "seed")) and tileInfo and tileInfo.at then
                                        local sapling = {x = x, y = y, name = tileStr, at = tileInfo.at, stage = tileInfo.stage}
                                        local isReady = false
                                        if sapling.stage and sapling.stage >= 3 then
                                            isReady = true
                                        else
                                            local targetMatang = GetExactGrowTime(sapling.name)
                                            if not targetMatang then
                                                BackupAIBelajarWaktu(sapling)
                                                targetMatang = getgenv().AIDictionary[sapling.name]
                                            end
                                            if targetMatang then
                                                local umurServer1 = os.time() - sapling.at
                                                local umurServer2 = workspace:GetServerTimeNow() - sapling.at
                                                if math.max(umurServer1, umurServer2) >= targetMatang then isReady = true end
                                            end
                                        end
                                        if isReady then table.insert(targetPanen, sapling) end
                                    end
                                end
                            end
                        end
                    end
                end

                local seedSlot = GetSlotByItemName(getgenv().SelectedSeed)
                local canPlant = (#targetTanam > 0)
                
                local didHarvest = (#targetPanen > 0)
                local didPlant = (canPlant and seedSlot ~= nil)
                
                local needToFarmBlock = false
                if not didHarvest and not didPlant then
                    needToFarmBlock = true
                end

                if didHarvest then
                    for i, panen in ipairs(targetPanen) do
                        if not getgenv().EnablePabrik then break end
                        
                        if MoveSmartlyTo(panen.x, panen.y) then
                            task.wait(0.1)
                            pcall(function() 
                                local targetVec = Vector2.new(panen.x, panen.y)
                                if RemoteBreak:IsA("RemoteEvent") then RemoteBreak:FireServer(targetVec) else RemoteBreak:InvokeServer(targetVec) end
                            end)
                            task.wait(getgenv().BreakDelay)
                        end
                        
                        local nextPanen = targetPanen[i + 1]
                        if not nextPanen or nextPanen.y ~= panen.y then
                            local stepDir = (panen.y % 2 == 0) and 1 or -1
                            MoveSmartlyTo(panen.x + stepDir, panen.y)
                            task.wait(0.3) 
                        end
                    end
                end

                if didPlant then
                    for _, spot in ipairs(targetTanam) do
                        if not getgenv().EnablePabrik then break end
                        seedSlot = GetSlotByItemName(getgenv().SelectedSeed)
                        if not seedSlot then break end 
                        
                        if MoveSmartlyTo(spot.x, spot.y) then
                            task.wait(0.1)
                            pcall(function() 
                                local targetVec = Vector2.new(spot.x, spot.y); local targetStr = spot.x .. ", " .. spot.y
                                if RemotePlace:IsA("RemoteEvent") then 
                                    RemotePlace:FireServer(targetVec, seedSlot); RemotePlace:FireServer(targetStr, seedSlot) 
                                else RemotePlace:InvokeServer(targetVec, seedSlot) end
                            end)
                            task.wait(getgenv().PlaceDelay)
                        end
                    end
                end

                if needToFarmBlock and getgenv().EnablePabrik then
                    local blockSlot = GetSlotByItemName(getgenv().SelectedBlock)
                    
                    if blockSlot then
                        if MoveSmartlyTo(getgenv().BreakPosX, getgenv().BreakPosY) then
                            local BreakTarget = Vector2.new(getgenv().BreakPosX - 1, getgenv().BreakPosY)
                            
                            while getgenv().EnablePabrik do
                                local currentBlockAmt = GetItemAmountByItemName(getgenv().SelectedBlock)
                                blockSlot = GetSlotByItemName(getgenv().SelectedBlock)
                                
                                if currentBlockAmt <= getgenv().BlockThreshold or not blockSlot then
                                    local hasAny, _ = CheckDropsType(BreakTarget.X, BreakTarget.Y)
                                    if hasAny then TrueGhostCollect(BreakTarget.X, BreakTarget.Y, false) end
                                    break 
                                end
                                
                                RemotePlace:FireServer(BreakTarget, blockSlot)
                                task.wait(getgenv().PlaceDelay) 
                                
                                for hit = 1, getgenv().HitCount do
                                    if not getgenv().EnablePabrik then break end
                                    RemoteBreak:FireServer(BreakTarget)
                                    task.wait(getgenv().BreakDelay)
                                end
                                
                                if getgenv().OnlyCollectSapling then
                                    local _, hasSapling = CheckDropsType(BreakTarget.X, BreakTarget.Y)
                                    if hasSapling then TrueGhostCollect(BreakTarget.X, BreakTarget.Y, true) end
                                end
                            end
                        end
                    end

                    if getgenv().EnablePabrik then
                        local currentSeedAmt = GetItemAmountByItemName(getgenv().SelectedSeed)
                        if currentSeedAmt > getgenv().KeepSeedAmt then
                            if MoveSmartlyTo(getgenv().DropPosX, getgenv().DropPosY) then
                                task.wait(1.5)
                                while getgenv().EnablePabrik do
                                    local current = GetItemAmountByItemName(getgenv().SelectedSeed)
                                    local toDrop = current - getgenv().KeepSeedAmt 
                                    if toDrop <= 0 then break end
                                    local dropNow = math.min(toDrop, 200)
                                    if DropItemLogic(getgenv().SelectedSeed, dropNow) then task.wait(getgenv().DropDelay + 0.3) else break end
                                end
                                
                                pcall(function() 
                                    if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
                                    for _, gui in pairs(LP.PlayerGui:GetDescendants()) do 
                                        if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end 
                                    end 
                                end)
                                task.wait(0.1)
                                pcall(function() if UIManager and type(UIManager.ShowHUD) == "function" then UIManager:ShowHUD() end end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
