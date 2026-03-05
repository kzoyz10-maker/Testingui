local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Make Farm v4.0 - ANTI FREEZE & SMART BYPASS" 

-- ========================================== --
-- [[ DEFAULT SETTINGS ]]
-- ========================================== --
getgenv().EnableAutoBuild = false
getgenv().BuildPlaceDelay = 0.15
getgenv().BuildWalkSpeed = 16
getgenv().BuildSelectedBlock = "Kosong"

getgenv().BuildStartX = 0
getgenv().BuildEndX = 100
getgenv().BuildStartY = 60
getgenv().BuildEndY = 10
getgenv().BuildYStep = 2 

getgenv().GridSize = 4.5

-- ========================================== --
-- [[ SERVICES & MANAGERS ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem") 

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local InventoryMod, PlayerMovement
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

-- ========================================== --
-- [[ INVENTORY SCANNER ]]
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
-- [[ RADAR TILE & COLLISION CHECK ]]
-- ========================================== --
local function IsTileEmptyForPlant(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return false end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then tileString = WorldManager.NumberToStringMap[rawId] or rawId end
        local nameStr = tostring(tileString):lower()
        
        -- [!] HAK VETO: Bedrock dan Lock TIDAK BOLEH ditimpa blok!
        if nameStr:find("bedrock") or nameStr:find("lock") then
            return false
        end
        
        -- Selain bg, air, water, dan AREA, berarti ada blok padat
        if not nameStr:find("bg") and not nameStr:find("background") and not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("area") and nameStr ~= "0" then 
            return false 
        end
    end
    return true
end

local function IsTileWalkable(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        
        -- [!] HAK VETO: Bedrock dan Lock TIDAK BISA DILEWATI
        if nameStr:find("bedrock") or nameStr:find("lock") then
            return false
        end
        
        -- Yg bisa dilewati: bg, air, water, door, dan AREA
        if not nameStr:find("bg") and not nameStr:find("background") and not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("door") and not nameStr:find("area") and nameStr ~= "0" then
            return false 
        end
    end
    return true
end

-- ========================================== --
-- [[ SISTEM MODFLY PERMANEN ]]
-- ========================================== --
local ModflyConnection = nil

local function SetModflyState(state)
    if state then
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end
        if not ModflyConnection then
            ModflyConnection = RunService.Heartbeat:Connect(function()
                if PlayerMovement then
                    pcall(function()
                        PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true 
                    end)
                end
            end)
        end
    else
        if ModflyConnection then ModflyConnection:Disconnect(); ModflyConnection = nil end
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
    end
end

-- ========================================== --
-- [[ ALGORITMA A* PATHFINDING PINTAR ]]
-- ========================================== --
local function FindPathAStar(startX, startY, endX, endY)
    if startX == endX and startY == endY then return {} end
    
    local openSet, closedSet, cameFrom, gScore, fScore = {}, {}, {}, {}, {}
    local function heuristic(x, y) return math.abs(x - endX) + math.abs(y - endY) end
    
    local startKey = startX .. "," .. startY
    table.insert(openSet, {x = startX, y = startY, key = startKey})
    gScore[startKey] = 0
    fScore[startKey] = heuristic(startX, startY)
    
    local iterations = 0
    while #openSet > 0 do
        iterations = iterations + 1
        if iterations > 3000 then break end 
        
        local current, currentIndex = openSet[1], 1
        for i = 2, #openSet do
            if fScore[openSet[i].key] < fScore[current.key] then
                current = openSet[i]; currentIndex = i
            end
        end
        
        if current.x == endX and current.y == endY then
            local path, currKey = {}, current.key
            while cameFrom[currKey] do
                local node = cameFrom[currKey]
                table.insert(path, 1, {x = current.x, y = current.y})
                current = node; currKey = node.x .. "," .. node.y
            end
            return path
        end
        
        table.remove(openSet, currentIndex)
        closedSet[current.key] = true
        
        local neighbors = { {x=current.x+1, y=current.y}, {x=current.x-1, y=current.y}, {x=current.x, y=current.y+1}, {x=current.x, y=current.y-1} }
        for _, n in ipairs(neighbors) do
            local nKey = n.x .. "," .. n.y
            if n.x >= 0 and n.x <= 100 and n.y >= 0 and n.y <= 100 and not closedSet[nKey] then
                if IsTileWalkable(n.x, n.y) or (n.x == endX and n.y == endY) then
                    local tentativeG = gScore[current.key] + 1
                    if not gScore[nKey] or tentativeG < gScore[nKey] then
                        cameFrom[nKey] = current
                        gScore[nKey] = tentativeG
                        fScore[nKey] = tentativeG + heuristic(n.x, n.y)
                        
                        local inOpen = false
                        for _, openNode in ipairs(openSet) do if openNode.key == nKey then inOpen = true break end end
                        if not inOpen then table.insert(openSet, {x = n.x, y = n.y, key = nKey}) end
                    end
                end
            end
        end
    end
    return nil -- Rute Buntu
end

-- ========================================== --
-- [[ FUNGSI MOVEMENT EXECUTOR ]]
-- ========================================== --
local function MoveToPoint(startP, endP)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local distance = (startP - endP).Magnitude
    if distance < 0.5 then return end

    local walkTime = distance / getgenv().BuildWalkSpeed
    local steps = math.floor(walkTime * 45) 
    if steps < 1 then steps = 1 end
    
    for i = 1, steps do
        if not getgenv().EnableAutoBuild then break end
        local alpha = i / steps
        local currentLerp = startP:Lerp(endP, alpha)
        
        if PlayerMovement then PlayerMovement.Position = currentLerp
        elseif hrp then hrp.CFrame = CFrame.new(currentLerp) end
        task.wait(1/45)
    end
end

local function FollowAStarPath(path, currZ)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local startPos = (PlayerMovement and PlayerMovement.Position) or (hrp and hrp.Position)
    
    for _, node in ipairs(path) do
        if not getgenv().EnableAutoBuild then break end
        local targetPos = Vector3.new(node.x * getgenv().GridSize, node.y * getgenv().GridSize, currZ)
        MoveToPoint(startPos, targetPos)
        startPos = targetPos
    end
    if getgenv().EnableAutoBuild and PlayerMovement then PlayerMovement.Position = startPos end
end

-- ========================================== --
-- [[ UI SECTION ]]
-- ========================================== --
local SecBuild = Tab:Section({ Title = "🏗️ Auto Make Farm (V4 Anti Freeze)", Box = true, Opened = true })

SecBuild:Toggle({ 
    Title = "▶ START AUTO BUILD", 
    Default = getgenv().EnableAutoBuild, 
    Callback = function(v) 
        getgenv().EnableAutoBuild = v 
        SetModflyState(v)
    end 
})

local DropBlock = SecBuild:Dropdown({ 
    Title = "🧱 Pilih Block Farm (Tanah/Platform)", 
    Options = ScanAvailableItems(), 
    Default = getgenv().BuildSelectedBlock, 
    Callback = function(v) getgenv().BuildSelectedBlock = v end 
})

SecBuild:Button({ Title = "🔄 Refresh Tas Item", Callback = function() pcall(function() DropBlock:Refresh(ScanAvailableItems()) end) end })

local SecSettings = Tab:Section({ Title = "⚙️ Builder Settings", Box = true, Opened = true })
SecSettings:Input({ Title = "Place Delay", Value = tostring(getgenv().BuildPlaceDelay), Callback = function(v) getgenv().BuildPlaceDelay = tonumber(v) or getgenv().BuildPlaceDelay end })
SecSettings:Input({ Title = "Walk Speed", Value = tostring(getgenv().BuildWalkSpeed), Callback = function(v) getgenv().BuildWalkSpeed = tonumber(v) or getgenv().BuildWalkSpeed end })
SecSettings:Input({ Title = "Jarak Antar Baris (Turun Y)", Value = tostring(getgenv().BuildYStep), Callback = function(v) getgenv().BuildYStep = tonumber(v) or getgenv().BuildYStep end })

local SecArea = Tab:Section({ Title = "🗺️ Area Bikin Farm (X & Y)", Box = true, Opened = false })
SecArea:Input({ Title = "Start X (Kiri)", Value = tostring(getgenv().BuildStartX), Callback = function(v) getgenv().BuildStartX = tonumber(v) or getgenv().BuildStartX end })
SecArea:Input({ Title = "End X (Kanan)", Value = tostring(getgenv().BuildEndX), Callback = function(v) getgenv().BuildEndX = tonumber(v) or getgenv().BuildEndX end })
SecArea:Input({ Title = "Start Y (Atas)", Value = tostring(getgenv().BuildStartY), Callback = function(v) getgenv().BuildStartY = tonumber(v) or getgenv().BuildStartY end })
SecArea:Input({ Title = "End Y (Bawah)", Value = tostring(getgenv().BuildEndY), Callback = function(v) getgenv().BuildEndY = tonumber(v) or getgenv().BuildEndY end })

-- ========================================== --
-- [[ LOGIKA UTAMA: BUILDER ]]
-- ========================================== --
task.spawn(function()
    while true do
        if getgenv().EnableAutoBuild then
            if getgenv().BuildSelectedBlock == "Kosong" then
                WindUI:Notify({ Title = "Error", Content = "Pilih block dulu di Dropdown!", Duration = 3 })
                getgenv().EnableAutoBuild = false
                SetModflyState(false)
            else
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local currZ = hrp and hrp.Position.Z or 0
                
                local startY = math.max(getgenv().BuildStartY, getgenv().BuildEndY)
                local endY = math.min(getgenv().BuildStartY, getgenv().BuildEndY)
                local sX = math.min(getgenv().BuildStartX, getgenv().BuildEndX)
                local eX = math.max(getgenv().BuildStartX, getgenv().BuildEndX)

                for y = startY, endY, -getgenv().BuildYStep do 
                    if not getgenv().EnableAutoBuild then break end
                    
                    local isEven = (math.floor(y / getgenv().BuildYStep) % 2 == 0)
                    local loopStartX = isEven and sX or eX
                    local loopEndX = isEven and eX or sX
                    local step = isEven and 1 or -1
                    
                    for x = loopStartX, loopEndX, step do
                        if not getgenv().EnableAutoBuild then break end
                        
                        local blockSlot = GetSlotByItemName(getgenv().BuildSelectedBlock)
                        if not blockSlot then
                            WindUI:Notify({ Title = "Kehabisan Item", Content = "Block farm kamu sudah habis!", Duration = 5 })
                            getgenv().EnableAutoBuild = false
                            break
                        end
                        
                        -- Cek apakah kotak ini aman dan kosong untuk ditaruh blok
                        if IsTileEmptyForPlant(x, y) then
                            local startPos = (PlayerMovement and PlayerMovement.Position) or (hrp and hrp.Position)
                            if not startPos then break end
                            
                            local myGridX = math.floor((startPos.X / getgenv().GridSize) + 0.5)
                            local myGridY = math.floor((startPos.Y / getgenv().GridSize) + 0.5)
                            
                            -- [!] CARI POSISI BERDIRI YANG PALING AMAN (Nggak maksain harus dari Atas)
                            local standPosList = {
                                {x = x, y = y + 1}, -- Opsi 1: Coba dari Atas
                                {x = x - 1, y = y}, -- Opsi 2: Coba dari Kiri
                                {x = x + 1, y = y}  -- Opsi 3: Coba dari Kanan
                            }
                            
                            local validPath = nil
                            
                            for _, sPos in ipairs(standPosList) do
                                -- Kalau titik berdirinya aman (bukan bedrock/lock)
                                if IsTileWalkable(sPos.x, sPos.y) then
                                    local path = FindPathAStar(myGridX, myGridY, sPos.x, sPos.y)
                                    if path then -- A* berhasil nemu jalan (atau kita udah ada di posisi itu)
                                        validPath = path
                                        break
                                    end
                                end
                            end
                            
                            -- Kalau ada jalannya, Eksekusi! Kalau gak ada, SKIP tanpa nembus.
                            if validPath then
                                FollowAStarPath(validPath, currZ)
                                task.wait(0.05)
                                
                                if not getgenv().EnableAutoBuild then break end
                                
                                local targetVec = Vector2.new(x, y)
                                local targetStr = x .. ", " .. y
                                pcall(function()
                                    if RemotePlace:IsA("RemoteEvent") then 
                                        RemotePlace:FireServer(targetVec, blockSlot)
                                        RemotePlace:FireServer(targetStr, blockSlot) 
                                    else 
                                        RemotePlace:InvokeServer(targetVec, blockSlot) 
                                    end
                                end)
                                
                                task.wait(getgenv().BuildPlaceDelay)
                            else
                                -- Gak ada jalan gara-gara di-lock / tutup bedrock, bot akan nge-skip ke blok selanjutnya
                                print("Skipping area karena terhalang Lock/Bedrock di X:", x, "Y:", y)
                            end
                        end
                    end
                end
                
                if getgenv().EnableAutoBuild then
                    getgenv().EnableAutoBuild = false
                    SetModflyState(false)
                    WindUI:Notify({ Title = "Selesai", Content = "Farm sudah selesai dibangun!", Duration = 5 })
                end
            end
        end
        task.wait(1)
    end
end)
