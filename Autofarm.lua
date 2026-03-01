local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Farm v17.0 (LOGIKA TEMAN: STATE MACHINE)" 

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
-- Disamain kayak script teman lu (Burst Hit)
getgenv().HitCount = getgenv().HitCount or 25 
getgenv().BreakDelayMs = getgenv().BreakDelayMs or 250
getgenv().WaitDropMs = getgenv().WaitDropMs or 250  
getgenv().WalkSpeed = getgenv().WalkSpeed or 45 -- Speed ngikut teman lu (45)

getgenv().TargetFarmBlock = getgenv().TargetFarmBlock or "Auto (Equipped)"
getgenv().AutoDropSapling = getgenv().AutoDropSapling or false
getgenv().SaplingThreshold = getgenv().SaplingThreshold or 50
getgenv().TargetSaplingName = getgenv().TargetSaplingName or "Kosong"

getgenv().SelectedTiles = getgenv().SelectedTiles or {{x = 0, y = 1}}

local PlayerMovement
task.spawn(function() pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end) end)

local InventoryMod, UIManager, WorldManager, ItemsManager
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)
pcall(function() WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager")) end)
pcall(function() ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager")) end)

-- [[ ========================================================= ]] --
-- [[ INVENTORY TRANSLATOR ]]
-- [[ ========================================================= ]] --
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

local function FindHotbarModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindHotbarModule()

local function GetPlayerGridPosition()
    local ref = workspace:FindFirstChild("Hitbox") and workspace:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if ref then return ref.Position.X, ref.Position.Y end
    return nil, nil
end

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

local SecFarm = Tab:Section({ Title = "🚜 Smart Auto-Farm Engine", Box = true, Opened = true })

SecFarm:Toggle({ 
    Title = "▶ ENABLE SMART FARM ENGINE", 
    Default = getgenv().MasterAutoFarm, 
    Callback = function(v) 
        getgenv().MasterAutoFarm = v 
        if not v then
            if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
        end
    end 
})

local function GetBlockOptions() local opts = {"Auto (Equipped)"}; for _, item in ipairs(ScanAvailableItems()) do table.insert(opts, item) end; return opts end
local DropFarmBlock = SecFarm:Dropdown({ Title = "🎯 Target Farm Block", Options = GetBlockOptions(), Default = getgenv().TargetFarmBlock, Callback = function(v) getgenv().TargetFarmBlock = v end })
SecFarm:Button({ Title = "🔄 Refresh Items", Callback = function() DropFarmBlock:Refresh(GetBlockOptions()) end })
SecFarm:Button({ Title = "📝 Select Farm Tiles (Grid Area)", Callback = function() OpenTileSelectorModal() end })

local SecCollect = Tab:Section({ Title = "🧲 Genius Auto-Loot Settings", Box = true, Opened = false })
SecCollect:Toggle({ Title = "Only Collect Sapling (Abaikan drop lain)", Default = getgenv().AutoSaplingMode, Callback = function(v) getgenv().AutoSaplingMode = v end })

local SecSpeed = Tab:Section({ Title = "⏱️ Delay & Speeds", Box = true, Opened = false })
SecSpeed:Input({ Title = "Wait Drop Muncul (ms)", Value = tostring(getgenv().WaitDropMs), Placeholder = tostring(getgenv().WaitDropMs), Callback = function(v) getgenv().WaitDropMs = tonumber(v) or getgenv().WaitDropMs end })
SecSpeed:Input({ Title = "AI Walk Speed", Value = tostring(getgenv().WalkSpeed), Placeholder = tostring(getgenv().WalkSpeed), Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })
SecSpeed:Input({ Title = "Delay Break (ms)", Value = tostring(getgenv().BreakDelayMs), Placeholder = tostring(getgenv().BreakDelayMs), Callback = function(v) getgenv().BreakDelayMs = tonumber(v) or getgenv().BreakDelayMs end })
SecSpeed:Input({ Title = "Hit Spam / Break (Burst)", Value = tostring(getgenv().HitCount), Placeholder = tostring(getgenv().HitCount), Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end })

local SecSeed = Tab:Section({ Title = "🌱 Auto Drop Seed (Sapling)", Box = true, Opened = false })
SecSeed:Toggle({ Title = "Enable Auto Drop Sapling", Default = getgenv().AutoDropSapling, Callback = function(v) getgenv().AutoDropSapling = v end })
SecSeed:Input({ Title = "Drop Threshold (Amount)", Value = tostring(getgenv().SaplingThreshold), Placeholder = tostring(getgenv().SaplingThreshold), Callback = function(v) getgenv().SaplingThreshold = tonumber(v) or getgenv().SaplingThreshold end })
local DropSeed = SecSeed:Dropdown({ Title = "Target Drop Seed", Options = ScanAvailableItems(), Default = getgenv().TargetSaplingName, Callback = function(v) getgenv().TargetSaplingName = v end })
SecSeed:Button({ Title = "🔄 Refresh Seed List", Callback = function() DropSeed:Refresh(ScanAvailableItems()) end })

local InpDropX = SecSeed:Input({ Title = "Drop Pos X", Value = tostring(getgenv().DropTargetX or ""), Placeholder = "Belum diset", Callback = function(v) getgenv().DropTargetX = tonumber(v) or getgenv().DropTargetX end })
local InpDropY = SecSeed:Input({ Title = "Drop Pos Y", Value = tostring(getgenv().DropTargetY or ""), Placeholder = "Belum diset", Callback = function(v) getgenv().DropTargetY = tonumber(v) or getgenv().DropTargetY end })

SecSeed:Button({ 
    Title = "📍 Set Drop Pos (Current Loc)", 
    Callback = function() 
        local px, py = GetPlayerGridPosition()
        if px and py then
            local cx = math.floor(px / getgenv().GridSize + 0.5)
            local cy = math.floor(py / getgenv().GridSize + 0.5)
            getgenv().DropTargetX = cx; getgenv().DropTargetY = cy
            pcall(function() InpDropX:Set(tostring(cx)) end)
            pcall(function() InpDropY:Set(tostring(cy)) end)
        end
    end
})

-- [[ ========================================================= ]] --
-- [[ SYSTEM LOGIC ]]
-- [[ ========================================================= ]] --
local Remotes = RS:WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteBreak = Remotes:WaitForChild("PlayerFist")
local RemoteDrop = Remotes:WaitForChild("PlayerDrop")

getgenv().KzoyzHeartbeat = RunService.Heartbeat:Connect(function()
    local highlights = workspace:FindFirstChild("TileHighligts") or workspace:FindFirstChild("TileHighlights")
    if highlights then pcall(function() highlights:ClearAllChildren() end) end
end)

local function CheckDropsAtGrid(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local foundSapling, foundAny = false, false
    for _, folder in ipairs(TargetFolders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
                elseif obj:IsA("Model") then local firstPart = obj:FindFirstChildWhichIsA("BasePart"); if firstPart then pos = firstPart.Position end end
                
                if pos then
                    local dX = math.floor(pos.X / getgenv().GridSize + 0.5)
                    local dY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                    if dX == TargetGridX and dY == TargetGridY then
                        foundAny = true
                        local isSapling = false
                        for _, attrValue in pairs(obj:GetAttributes()) do if type(attrValue) == "string" and string.find(string.lower(attrValue), "sapling") then isSapling = true; break end end
                        if not isSapling then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("StringValue") and string.find(string.lower(child.Value), "sapling") then isSapling = true; break end
                                if isSapling then break end
                            end
                        end
                        if isSapling then foundSapling = true end
                    end
                end
            end
        end
    end
    if getgenv().AutoSaplingMode then return foundSapling else return foundAny end
end

local function SafeMoveTo(targetVec3)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    local mover = MyHitbox or hrp
    
    if not mover then return false end
    
    if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end

    local startPos = mover.Position
    local dist = (Vector3.new(startPos.X, startPos.Y, 0) - Vector3.new(targetVec3.X, targetVec3.Y, 0)).Magnitude 
    local duration = dist / getgenv().WalkSpeed
    if duration < 0.05 then duration = 0.05 end

    local t = 0
    while t < duration and getgenv().MasterAutoFarm do
        local dt = RunService.Heartbeat:Wait()
        t = t + dt
        local alpha = math.clamp(t / duration, 0, 1)
        local currentPos = startPos:Lerp(targetVec3, alpha)
        
        mover.CFrame = CFrame.new(currentPos)
        if hrp and MyHitbox then hrp.CFrame = CFrame.new(currentPos) end
        
        if PlayerMovement then 
            pcall(function() 
                PlayerMovement.Position = currentPos
                PlayerMovement.VelocityX = 0 
                PlayerMovement.VelocityY = 0 
                PlayerMovement.VelocityZ = 0 
            end) 
        end
    end
    
    mover.CFrame = CFrame.new(targetVec3)
    if hrp and MyHitbox then hrp.CFrame = CFrame.new(targetVec3) end

    if PlayerMovement then 
        pcall(function() 
            PlayerMovement.Position = targetVec3 
            PlayerMovement.VelocityX = 0 
            PlayerMovement.VelocityY = 0 
            PlayerMovement.VelocityZ = 0 
            PlayerMovement.InputActive = true 
        end) 
    end
    task.wait(0.01)
end

local function FindEmptyGridNearPlayer(BaseX, BaseY)
    local offsets = { {x=1, y=0}, {x=-1, y=0}, {x=0, y=1}, {x=0, y=-1}, {x=1, y=1}, {x=-1, y=-1}, {x=1, y=-1}, {x=-1, y=1}, {x=2, y=0}, {x=-2, y=0}, {x=0, y=2}, {x=0, y=-2} }
    for _, offset in ipairs(offsets) do
        local checkX = BaseX + offset.x; local checkY = BaseY + offset.y
        local isFarmTile = false
        for _, farmOffset in ipairs(getgenv().SelectedTiles) do if (BaseX + farmOffset.x) == checkX and (BaseY + farmOffset.y) == checkY then isFarmTile = true; break end end
        if not isFarmTile and not CheckDropsAtGrid(checkX, checkY) then return checkX, checkY end
    end
    return BaseX, BaseY 
end

-- ==============================================================
-- LOGIKA TEMAN (STATE MACHINE: PLACE -> BREAK -> LOOT)
-- ==============================================================
local farmPhase = "PLACE"
local farmStartPos = nil
local isOutOfItems = false

getgenv().KzoyzFarmLoop = task.spawn(function() 
    while true do 
        pcall(function()
            if getgenv().MasterAutoFarm and InventoryMod then 
                
                -- Kunci Posisi Base secara otomatis (hanya di awal)
                local px, py = GetPlayerGridPosition()
                if not px then return end
                
                if not farmStartPos then 
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local currZ = hrp and hrp.Position.Z or 0
                    farmStartPos = {
                        x = math.floor(px / getgenv().GridSize + 0.5), 
                        y = math.floor(py / getgenv().GridSize + 0.5),
                        z = currZ
                    }
                end
                
                local BaseX = farmStartPos.x
                local BaseY = farmStartPos.y
                local currZ = farmStartPos.z

                local targetList = {}
                for _, offset in ipairs(getgenv().SelectedTiles) do
                    table.insert(targetList, {x = BaseX + offset.x, y = BaseY + offset.y})
                end

                if #targetList > 0 then
                    
                    -- ================== FASE 1: PLACE ================== --
                    if farmPhase == "PLACE" then
                        local itemHabis = false
                        local placedAny = false
                        
                        local ItemIndex 
                        if getgenv().TargetFarmBlock and getgenv().TargetFarmBlock ~= "Auto (Equipped)" then
                            ItemIndex = GetSlotByItemName(getgenv().TargetFarmBlock)
                        else
                            if getgenv().GameInventoryModule and getgenv().GameInventoryModule.GetSelectedHotbarItem then 
                                _, ItemIndex = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                            elseif getgenv().GameInventoryModule and getgenv().GameInventoryModule.GetSelectedItem then 
                                _, ItemIndex = getgenv().GameInventoryModule.GetSelectedItem() 
                            end 
                        end
                        
                        if ItemIndex then
                            for _, tile in ipairs(targetList) do
                                if not getgenv().MasterAutoFarm then break end
                                
                                local hasBlock = false
                                if WorldManager and WorldManager.GetTile then
                                    for l = 1, 5 do if WorldManager.GetTile(tile.x, tile.y, l) then hasBlock = true break end end
                                end
                                
                                if not hasBlock then
                                    local TGrid = Vector2.new(tile.x, tile.y)
                                    pcall(function()
                                        if RemotePlace:IsA("RemoteEvent") then RemotePlace:FireServer(TGrid, ItemIndex)
                                        else RemotePlace:InvokeServer(TGrid, ItemIndex) end
                                    end)
                                    placedAny = true
                                    task.wait(getgenv().ActionDelay)
                                end
                            end
                        else
                            itemHabis = true
                        end
                        
                        if itemHabis or not placedAny then
                            farmPhase = "BREAK"
                        end

                    -- ================== FASE 2: BREAK ================== --
                    elseif farmPhase == "BREAK" then
                        local brokeAny = false
                        
                        for _, tile in ipairs(targetList) do
                            if not getgenv().MasterAutoFarm then break end
                            
                            local hasBlock = false
                            if WorldManager and WorldManager.GetTile then
                                for l = 1, 5 do if WorldManager.GetTile(tile.x, tile.y, l) then hasBlock = true break end end
                            else
                                hasBlock = true -- Fallback asumsikan ada block jika GetTile gagal
                            end
                            
                            if hasBlock then
                                local TGrid = Vector2.new(tile.x, tile.y)
                                local hitsToSend = getgenv().HitCount or 25 
                                
                                -- SPAM HIT BURST (Logika Teman Lu)
                                for i = 1, hitsToSend do
                                    pcall(function()
                                        if RemoteBreak:IsA("RemoteEvent") then RemoteBreak:FireServer(TGrid)
                                        else RemoteBreak:InvokeServer(TGrid) end
                                    end)
                                end
                                
                                -- Tunggu setelah nge-burst 
                                task.wait(getgenv().BreakDelayMs / 1000)
                                brokeAny = true
                            end
                        end
                        
                        if not brokeAny then
                            farmPhase = "LOOT"
                        end

                    -- ================== FASE 3: LOOT / COLLECT ================== --
                    elseif farmPhase == "LOOT" then
                        task.wait(getgenv().WaitDropMs / 1000) 
                        
                        local TilesToCollect = {}
                        for _, tile in ipairs(targetList) do
                            if CheckDropsAtGrid(tile.x, tile.y) then table.insert(TilesToCollect, {x = tile.x, y = tile.y}) end
                        end
                        
                        if #TilesToCollect > 0 and getgenv().MasterAutoFarm then
                            local char = LP.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            local pPos = hrp and hrp.Position or Vector3.new(BaseX * getgenv().GridSize, BaseY * getgenv().GridSize, currZ)
                            
                            -- Sortir dropan terdekat (Logika Teman Lu)
                            table.sort(TilesToCollect, function(a, b)
                                local posA = Vector3.new(a.x * getgenv().GridSize, a.y * getgenv().GridSize, currZ)
                                local posB = Vector3.new(b.x * getgenv().GridSize, b.y * getgenv().GridSize, currZ)
                                return (pPos - posA).Magnitude < (pPos - posB).Magnitude
                            end)
                            
                            for _, tile in ipairs(TilesToCollect) do
                                if not getgenv().MasterAutoFarm then break end
                                local targetVec = Vector3.new(tile.x * getgenv().GridSize, tile.y * getgenv().GridSize, currZ)
                                SafeMoveTo(targetVec) 
                                
                                local waitTimeout = 0
                                while CheckDropsAtGrid(tile.x, tile.y) and waitTimeout < 15 and getgenv().MasterAutoFarm do 
                                    task.wait(0.1); waitTimeout = waitTimeout + 1 
                                end
                            end
                            
                            task.wait(0.1)
                            -- Balik lagi ke posisi Base Awal
                            local baseVec = Vector3.new(BaseX * getgenv().GridSize, BaseY * getgenv().GridSize, currZ)
                            SafeMoveTo(baseVec) 
                        end
                        
                        -- LOGIKA AUTO DROP SAPLING (Setelah Loot Selesai)
                        if getgenv().AutoDropSapling and getgenv().TargetSaplingName ~= "Kosong" then
                            local sapSlot = GetSlotByItemName(getgenv().TargetSaplingName)
                            local sapAmount = GetItemAmountByItemName(getgenv().TargetSaplingName)
                            
                            if sapSlot and sapAmount >= getgenv().SaplingThreshold then
                                local dropX, dropY
                                if getgenv().DropTargetX and getgenv().DropTargetY then
                                    dropX = getgenv().DropTargetX; dropY = getgenv().DropTargetY
                                else
                                    dropX, dropY = FindEmptyGridNearPlayer(BaseX, BaseY)
                                end
                                
                                local dropVec = Vector3.new(dropX * getgenv().GridSize, dropY * getgenv().GridSize, currZ)
                                SafeMoveTo(dropVec) 
                                task.wait(0.2)
                                
                                pcall(function() RemoteDrop:FireServer(sapSlot, sapAmount) end)
                                pcall(function() 
                                    if UIManager and type(UIManager.FireEvent) == "function" then UIManager:FireEvent("drp", { amt = tostring(sapAmount) })
                                    else
                                        local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent")
                                        ManagerRemote:FireServer(unpack({{ ButtonAction = "drp", Inputs = { amt = tostring(sapAmount) } }}))
                                    end
                                end)
                                
                                pcall(function()
                                    if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
                                    for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
                                        if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
                                    end
                                end)
                                
                                task.wait(0.5)
                                local baseVec = Vector3.new(BaseX * getgenv().GridSize, BaseY * getgenv().GridSize, currZ)
                                SafeMoveTo(baseVec) 
                            end
                        end
                        
                        -- Restart Siklus balik ke Place
                        farmPhase = "PLACE"
                    end
                end
            else
                -- Kalau fitur dimatikan, reset state-nya
                farmStartPos = nil
                farmPhase = "PLACE"
            end
        end) -- END PCALL
        task.wait(0.1) 
    end 
end)
