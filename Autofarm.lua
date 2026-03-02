local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Farm v20.1 (SMART PATHING V3 + MAX DROP 200 FIX)" 

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- [[ ========================================================= ]] --
-- [[ 🧹 CLEANUP SYSTEM ]]
-- [[ ========================================================= ]] --
if getgenv().KzoyzFarmLoop then task.cancel(getgenv().KzoyzFarmLoop); getgenv().KzoyzFarmLoop = nil end
if getgenv().KzoyzHeartbeat then getgenv().KzoyzHeartbeat:Disconnect(); getgenv().KzoyzHeartbeat = nil end

-- ========================================== --
-- [[ DEFAULT SETTINGS ]]
-- ========================================== --
getgenv().ActionDelay = getgenv().ActionDelay or 0.15 
getgenv().GridSize = getgenv().GridSize or 4.5 

getgenv().MasterAutoFarm = getgenv().MasterAutoFarm or false
getgenv().AutoSaplingMode = getgenv().AutoSaplingMode or false
getgenv().HitCount = getgenv().HitCount or 25 
getgenv().BreakDelayMs = getgenv().BreakDelayMs or 150
getgenv().WaitDropMs = getgenv().WaitDropMs or 250  
getgenv().WalkSpeed = getgenv().WalkSpeed or 25 

getgenv().TargetFarmBlock = getgenv().TargetFarmBlock or "Auto (Equipped)"
getgenv().AutoDropSapling = getgenv().AutoDropSapling or false
getgenv().SaplingThreshold = getgenv().SaplingThreshold or 50
getgenv().TargetSaplingName = getgenv().TargetSaplingName or "Kosong"

getgenv().SelectedTiles = getgenv().SelectedTiles or {{x = 0, y = 1}}
getgenv().DropTargetX = getgenv().DropTargetX or nil
getgenv().DropTargetY = getgenv().DropTargetY or nil

local PlayerMovement
task.spawn(function() pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end) end)

local InventoryMod
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)

local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

-- [[ ========================================================= ]] --
-- [[ HELPER FUNCTIONS ]]
-- [[ ========================================================= ]] --
local function GetSlotByItemID(targetID)
    if not InventoryMod or not InventoryMod.Stacks then return nil end
    for slotIndex, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            if not data.Amount or data.Amount > 0 then return slotIndex end
        end
    end
    return nil
end

local function GetItemAmountByID(targetID)
    local total = 0
    if not InventoryMod or not InventoryMod.Stacks then return total end
    for _, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            total = total + (data.Amount or 1)
        end
    end
    return total
end

local function ScanAvailableItems()
    local items = {}; local dict = {}
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for _, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and data.Id then
                    local itemID = tostring(data.Id)
                    if not dict[itemID] then dict[itemID] = true; table.insert(items, itemID) end
                end
            end
        end
    end)
    if #items == 0 then items = {"Kosong"} end
    table.sort(items)
    return items
end

local function FindHotbarModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindHotbarModule()

-- [[ ========================================================= ]] --
-- [[ MODAL UI SELECTOR GRID ]]
-- [[ ========================================================= ]] --
local function OpenTileSelectorModal()
    local ThemeTile = { TileOff = Color3.fromRGB(45, 55, 80), TileOn = Color3.fromRGB(240, 160, 60), TileYou = Color3.fromRGB(100, 200, 100), DarkBlue = Color3.fromRGB(25, 30, 45) }
    local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "KzoyzTileModal"; ScreenGui.Parent = game:GetService("CoreGui") or LP.PlayerGui
    local Overlay = Instance.new("TextButton"); Overlay.Parent = ScreenGui; Overlay.Size = UDim2.new(1, 0, 1, 0); Overlay.BackgroundColor3 = Color3.new(0,0,0); Overlay.BackgroundTransparency = 0.6; Overlay.Text = ""; Overlay.AutoButtonColor = false
    local Panel = Instance.new("Frame"); Panel.Parent = Overlay; Panel.BackgroundColor3 = ThemeTile.DarkBlue; Panel.Size = UDim2.new(0, 260, 0, 340); Panel.Position = UDim2.new(0.5, 0, 0.5, 0); Panel.AnchorPoint = Vector2.new(0.5, 0.5); Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)
    local Title = Instance.new("TextLabel"); Title.Parent = Panel; Title.Text = "Select Farm Tiles"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1
    local GridContainer = Instance.new("Frame"); GridContainer.Parent = Panel; GridContainer.Size = UDim2.new(0, 220, 0, 220); GridContainer.Position = UDim2.new(0.5, 0, 0, 45); GridContainer.AnchorPoint = Vector2.new(0.5, 0); GridContainer.BackgroundTransparency = 1
    local UIGrid = Instance.new("UIGridLayout"); UIGrid.Parent = GridContainer; UIGrid.CellSize = UDim2.new(0, 40, 0, 40); UIGrid.CellPadding = UDim2.new(0, 5, 0, 5); UIGrid.SortOrder = Enum.SortOrder.LayoutOrder
    
    local yLevels = {3, 2, 1, 0, -1}; local xLevels = {-2, -1, 0, 1, 2} 
    for _, y in ipairs(yLevels) do
        for _, x in ipairs(xLevels) do
            local Tile = Instance.new("TextButton"); Tile.Parent = GridContainer; Tile.Text = ""; Tile.Font = Enum.Font.GothamBold; Tile.TextSize = 10; Tile.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", Tile).CornerRadius = UDim.new(0, 8)
            if x == 0 and y == 0 then Tile.Text = "I'm Here" end 
            local isSelected = false
            for _, v in ipairs(getgenv().SelectedTiles) do if v.x == x and v.y == y then isSelected = true; break end end
            Tile.BackgroundColor3 = isSelected and ThemeTile.TileOn or ThemeTile.TileOff
            Tile.MouseButton1Click:Connect(function()
                local foundIdx = nil
                for i, v in ipairs(getgenv().SelectedTiles) do if v.x == x and v.y == y then foundIdx = i; break end end
                if foundIdx then table.remove(getgenv().SelectedTiles, foundIdx); Tile.BackgroundColor3 = ThemeTile.TileOff
                else table.insert(getgenv().SelectedTiles, {x=x, y=y}); Tile.BackgroundColor3 = ThemeTile.TileOn end
            end)
        end
    end
    
    local DoneBtn = Instance.new("TextButton"); DoneBtn.Parent = Panel; DoneBtn.BackgroundColor3 = ThemeTile.TileYou; DoneBtn.Size = UDim2.new(0, 150, 0, 40); DoneBtn.Position = UDim2.new(0.5, 0, 1, -20); DoneBtn.AnchorPoint = Vector2.new(0.5, 1); DoneBtn.Text = "Done"; DoneBtn.TextColor3 = Color3.new(1,1,1); DoneBtn.Font = Enum.Font.GothamBold; DoneBtn.TextSize = 14; Instance.new("UICorner", DoneBtn).CornerRadius = UDim.new(0, 8)
    DoneBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
end

-- [[ ========================================================= ]] --
-- [[ WINDUI SECTIONS ]]
-- [[ ========================================================= ]] --
local SecFarm = Tab:Section({ Title = "🚜 Master Auto Farm & Collect", Box = true, Opened = true })

SecFarm:Toggle({ 
    Title = "▶ START AUTO FARM & COLLECT", 
    Default = getgenv().MasterAutoFarm, 
    Callback = function(v) 
        getgenv().MasterAutoFarm = v 
        if not v then
            if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
        end
    end 
})

local function GetBlockOptions() local opts = {"Auto (Equipped)"}; for _, item in ipairs(ScanAvailableItems()) do table.insert(opts, item) end; return opts end
local DropFarmBlock = SecFarm:Dropdown({ Title = "🎯 Target Farm Block (ID)", Options = GetBlockOptions(), Default = getgenv().TargetFarmBlock, Callback = function(v) getgenv().TargetFarmBlock = v end })
SecFarm:Button({ Title = "🔄 Refresh Items", Callback = function() DropFarmBlock:Refresh(GetBlockOptions()) end })
SecFarm:Button({ Title = "📝 Select Farm Tiles", Callback = function() OpenTileSelectorModal() end })

local SecCollect = Tab:Section({ Title = "🧲 Filter Auto Collect", Box = true, Opened = false })
SecCollect:Toggle({ Title = "Only Collect Sapling (Abaikan drop lain)", Default = getgenv().AutoSaplingMode, Callback = function(v) getgenv().AutoSaplingMode = v end })

local SecSpeed = Tab:Section({ Title = "⏱️ Delay & Speeds", Box = true, Opened = false })
SecSpeed:Input({ Title = "Wait Drop Muncul (ms)", Value = tostring(getgenv().WaitDropMs), Placeholder = tostring(getgenv().WaitDropMs), Callback = function(v) getgenv().WaitDropMs = tonumber(v) or getgenv().WaitDropMs end })
SecSpeed:Input({ Title = "Walk Speed (Kecepatan Collect)", Value = tostring(getgenv().WalkSpeed), Placeholder = tostring(getgenv().WalkSpeed), Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })
SecSpeed:Input({ Title = "Hit Spam (Jumlah Pukulan)", Value = tostring(getgenv().HitCount), Placeholder = tostring(getgenv().HitCount), Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end })

local SecSeed = Tab:Section({ Title = "🌱 Auto Drop Seed (Sapling)", Box = true, Opened = false })
SecSeed:Toggle({ Title = "Enable Auto Drop Sapling", Default = getgenv().AutoDropSapling, Callback = function(v) getgenv().AutoDropSapling = v end })
SecSeed:Input({ Title = "Drop Threshold (Amount)", Value = tostring(getgenv().SaplingThreshold), Placeholder = tostring(getgenv().SaplingThreshold), Callback = function(v) getgenv().SaplingThreshold = tonumber(v) or getgenv().SaplingThreshold end })

SecSeed:Button({ 
    Title = "📍 Set Posisi Drop Seed (Di Sini)", 
    Callback = function() 
        local ref = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if ref then
            getgenv().DropTargetX = math.floor(ref.Position.X / getgenv().GridSize + 0.5)
            getgenv().DropTargetY = math.floor(ref.Position.Y / getgenv().GridSize + 0.5)
            warn("✅ Berhasil! Drop Posisi di-set ke Grid X:", getgenv().DropTargetX, " Y:", getgenv().DropTargetY)
        end
    end 
})

local DropSeed = SecSeed:Dropdown({ Title = "Target Drop Seed (ID)", Options = ScanAvailableItems(), Default = getgenv().TargetSaplingName, Callback = function(v) getgenv().TargetSaplingName = v end })
SecSeed:Button({ Title = "🔄 Refresh Seed List", Callback = function() DropSeed:Refresh(ScanAvailableItems()) end })

-- [[ ========================================================= ]] --
-- [[ SYSTEM LOGIC & SAFE MOVEMENT ]]
-- [[ ========================================================= ]] --
local Remotes = RS:WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteBreak = Remotes:WaitForChild("PlayerFist")
local RemoteDrop = Remotes:WaitForChild("PlayerDrop")

local function GetExactDropsInGrid(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local exactPositions = {}
    
    for _, folder in ipairs(TargetFolders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
                end
                
                if pos then
                    local dX = math.floor(pos.X / getgenv().GridSize + 0.5)
                    local dY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                    if dX == TargetGridX and dY == TargetGridY then
                        table.insert(exactPositions, pos)
                    end
                end
            end
        end
    end
    return exactPositions
end

-- MEMBUAT BOT LEBIH PINTAR: Box deteksi dikecilin jadi 0.5 (cuma ngecek center grid)
local function IsTileSolid(TargetGridX, TargetGridY, currZ)
    local searchPos = Vector3.new(TargetGridX * getgenv().GridSize, TargetGridY * getgenv().GridSize, currZ)
    local overlap = workspace:GetPartBoundsInBox(CFrame.new(searchPos), Vector3.new(0.5, 0.5, 0.5))
    
    for _, part in ipairs(overlap) do
        if part.Parent and part.CanCollide and not part:IsDescendantOf(LP.Character) then
            local pName = part.Parent.Name
            if pName ~= "Drops" and pName ~= "Gems" and pName ~= "Hitbox" and pName ~= "TileHighlights" then
                return true
            end
        end
    end
    return false
end

-- A-Star Anti Nyerah & Pinter Cari Jalan (Micro-Sensor)
local function FindPathAStar(startX, startY, targetX, targetY, currZ)
    if startX == targetX and startY == targetY then return {} end
    local function heuristic(x, y) return math.abs(x - targetX) + math.abs(y - targetY) end
    
    local openSet, closedSet, cameFrom, gScore, fScore = {}, {}, {}, {}, {}
    local startKey = startX .. "," .. startY
    table.insert(openSet, {x = startX, y = startY, key = startKey})
    gScore[startKey] = 0
    fScore[startKey] = heuristic(startX, startY)
    
    local maxIterations = 3000 
    local iterations = 0
    local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
    local solidCache = {}
    
    local bestNode = {x = startX, y = startY, key = startKey}
    local bestH = fScore[startKey]

    while #openSet > 0 do
        iterations = iterations + 1; if iterations > maxIterations then break end
        
        local current, currentIndex = openSet[1], 1
        for i = 2, #openSet do 
            if fScore[openSet[i].key] < fScore[current.key] then current = openSet[i]; currentIndex = i end 
        end
        
        local currentH = heuristic(current.x, current.y)
        if currentH < bestH then
            bestH = currentH
            bestNode = current
        end
        
        if current.x == targetX and current.y == targetY then
            bestNode = current
            break 
        end
        
        table.remove(openSet, currentIndex)
        closedSet[current.key] = true
        
        for _, dir in ipairs(directions) do
            local nextX, nextY = current.x + dir[1], current.y + dir[2]
            local nextKey = nextX .. "," .. nextY
            
            if closedSet[nextKey] then continue end
            if solidCache[nextKey] == nil then solidCache[nextKey] = IsTileSolid(nextX, nextY, currZ) end
            
            if solidCache[nextKey] then 
                closedSet[nextKey] = true
                continue 
            end
            
            local tentative_gScore = gScore[current.key] + 1
            if not gScore[nextKey] or tentative_gScore < gScore[nextKey] then
                cameFrom[nextKey] = current
                gScore[nextKey] = tentative_gScore
                fScore[nextKey] = tentative_gScore + heuristic(nextX, nextY)
                
                local inOpenSet = false
                for _, node in ipairs(openSet) do if node.key == nextKey then inOpenSet = true; break end end
                if not inOpenSet then table.insert(openSet, {x = nextX, y = nextY, key = nextKey}) end
            end
        end
    end
    
    local path = {}
    local currKey = bestNode.key
    local currNode = bestNode
    while cameFrom[currKey] do
        table.insert(path, 1, {x = currNode.x, y = currNode.y})
        currNode = cameFrom[currKey]
        currKey = currNode.key
    end
    return path
end

local function SafeMovePath(pathTable, currZ)
    if #pathTable == 0 then return end
    
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end

    local oldGravity = workspace.Gravity
    workspace.Gravity = 0

    local startPos = hrp.Position
    if PlayerMovement and PlayerMovement.Position then startPos = PlayerMovement.Position end

    for _, targetPos in ipairs(pathTable) do
        if not getgenv().MasterAutoFarm then break end
        
        local targetVec3 = Vector3.new(targetPos.X, targetPos.Y, startPos.Z)
        local dist = (Vector3.new(startPos.X, startPos.Y, 0) - Vector3.new(targetVec3.X, targetVec3.Y, 0)).Magnitude 
        local duration = dist / getgenv().WalkSpeed
        if duration < 0.05 then duration = 0.05 end

        local t = 0
        while t < duration and getgenv().MasterAutoFarm do
            local dt = RunService.Heartbeat:Wait()
            t = t + dt
            local alpha = math.clamp(t / duration, 0, 1)
            local currentPos = startPos:Lerp(targetVec3, alpha)
            
            if PlayerMovement then 
                pcall(function() 
                    PlayerMovement.Position = currentPos; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0 
                end)
            else
                hrp.CFrame = (hrp.CFrame - hrp.CFrame.Position) + currentPos
            end
        end
        startPos = targetVec3
    end
    
    if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
    workspace.Gravity = oldGravity
end

local function SmartMoveTo(targetVec3, currZ)
    local mover = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not mover then return false end
    
    local startX = math.floor(mover.Position.X / getgenv().GridSize + 0.5)
    local startY = math.floor(mover.Position.Y / getgenv().GridSize + 0.5)
    local targetX = math.floor(targetVec3.X / getgenv().GridSize + 0.5)
    local targetY = math.floor(targetVec3.Y / getgenv().GridSize + 0.5)
    
    local path = FindPathAStar(startX, startY, targetX, targetY, currZ)
    
    if path and #path > 0 then
        local pathTable = {}
        for _, step in ipairs(path) do
            table.insert(pathTable, Vector3.new(step.x * getgenv().GridSize, step.y * getgenv().GridSize, currZ))
        end
        
        local lastStep = path[#path]
        -- Hanya masukin absolut targetVec3 kalau kotak tujuannya bener-bener gak ke-block
        if lastStep.x == targetX and lastStep.y == targetY and not IsTileSolid(targetX, targetY, currZ) then
            table.insert(pathTable, targetVec3)
        end
        
        SafeMovePath(pathTable, currZ)
    end
end

-- ==============================================================
-- MAIN FARM LOOP
-- ==============================================================
getgenv().KzoyzFarmLoop = task.spawn(function() 
    while true do 
        if getgenv().MasterAutoFarm then 
            local ref = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if ref then 
                local BaseX = math.floor(ref.Position.X / getgenv().GridSize + 0.5)
                local BaseY = math.floor(ref.Position.Y / getgenv().GridSize + 0.5)
                local currZ = ref.Position.Z
                local ItemIndex 
                
                if getgenv().TargetFarmBlock and getgenv().TargetFarmBlock ~= "Auto (Equipped)" then
                    ItemIndex = GetSlotByItemID(getgenv().TargetFarmBlock) 
                else
                    if getgenv().GameInventoryModule and getgenv().GameInventoryModule.GetSelectedHotbarItem then 
                        _, ItemIndex = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    end 
                end
                
                -- [[ 1. PLACE ]]
                if ItemIndex then
                    for _, offset in ipairs(getgenv().SelectedTiles) do 
                        if not getgenv().MasterAutoFarm then break end 
                        local TGrid = Vector2.new(BaseX + offset.x, BaseY + offset.y) 
                        pcall(function() RemotePlace:FireServer(TGrid, ItemIndex) end)
                        task.wait(getgenv().ActionDelay) 
                    end
                end

                -- [[ 2. BREAK ]]
                for _, offset in ipairs(getgenv().SelectedTiles) do 
                    if not getgenv().MasterAutoFarm then break end 
                    local TGrid = Vector2.new(BaseX + offset.x, BaseY + offset.y) 
                    
                    local hits = getgenv().HitCount or 25
                    for hit = 1, hits do 
                        if not getgenv().MasterAutoFarm then break end 
                        pcall(function() RemoteBreak:FireServer(TGrid) end)
                        task.wait(0.15) 
                    end
                end
                
                -- [[ 3. COLLECT SWEEP ]]
                task.wait(getgenv().WaitDropMs / 1000) 
                local ExactDropsToCollect = {}
                for _, offset in ipairs(getgenv().SelectedTiles) do
                    local tx = BaseX + offset.x
                    local ty = BaseY + offset.y
                    if not IsTileSolid(tx, ty, currZ) then 
                        for _, dropPos in ipairs(GetExactDropsInGrid(tx, ty)) do table.insert(ExactDropsToCollect, dropPos) end
                    end
                end
                
                if #ExactDropsToCollect > 0 and getgenv().MasterAutoFarm then
                    SafeMovePath(ExactDropsToCollect, currZ)
                    local baseVec = Vector3.new(BaseX * getgenv().GridSize, BaseY * getgenv().GridSize, currZ)
                    SmartMoveTo(baseVec, currZ) 
                end
                
                -- [[ 4. AUTO DROP (FIXED: CHUNKING MAX 200) ]]
                if getgenv().AutoDropSapling and getgenv().TargetSaplingName ~= "Kosong" then
                    local sapSlot = GetSlotByItemID(getgenv().TargetSaplingName)
                    local sapAmount = GetItemAmountByID(getgenv().TargetSaplingName)
                    
                    if sapSlot and sapAmount >= getgenv().SaplingThreshold then
                        local dropX = getgenv().DropTargetX or (BaseX + 1)
                        local dropY = getgenv().DropTargetY or BaseY
                        local dropVec = Vector3.new(dropX * getgenv().GridSize, dropY * getgenv().GridSize, currZ)
                        
                        -- Jalan ngikutin lantai ke titik drop
                        SmartMoveTo(dropVec, currZ) 
                        task.wait(0.2)
                        
                        -- LOOP DROP BERTAHAP (Max 200 per klik)
                        local remainingToDrop = sapAmount
                        while remainingToDrop > 0 and getgenv().MasterAutoFarm do
                            local currentDrop = math.min(remainingToDrop, 200)
                            
                            pcall(function() RemoteDrop:FireServer(sapSlot, currentDrop) end)
                            pcall(function() 
                                if UIManager and type(UIManager.FireEvent) == "function" then UIManager:FireEvent("drp", { amt = tostring(currentDrop) })
                                else
                                    local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent")
                                    ManagerRemote:FireServer(unpack({{ ButtonAction = "drp", Inputs = { amt = tostring(currentDrop) } }}))
                                end
                            end)
                            
                            remainingToDrop = remainingToDrop - currentDrop
                            task.wait(0.35) -- Jeda biar nggak spam server
                        end
                        
                        -- Tutup UI Prompt Drop
                        pcall(function()
                            if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
                            for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
                                if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
                            end
                        end)
                        
                        workspace.Gravity = 196.2 
                        task.wait(1.5) 
                        
                        -- Balik ke tempat farm
                        local baseVec = Vector3.new(BaseX * getgenv().GridSize, BaseY * getgenv().GridSize, currZ)
                        SmartMoveTo(baseVec, currZ) 
                    end
                end

            end 
        end 
        task.wait(0.1) 
    end 
end)
