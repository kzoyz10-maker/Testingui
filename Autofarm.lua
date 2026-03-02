local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Farm v19.5 (SMART WALK + ANTI 3D + 150ms BREAK)" 

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
SecFarm:Button({ Title = "📝 Select Farm Tiles (Grid Area)", Callback = function() OpenTileSelectorModal() end })

local SecCollect = Tab:Section({ Title = "🧲 Filter Auto Collect", Box = true, Opened = false })
SecCollect:Toggle({ Title = "Only Collect Sapling (Abaikan drop lain)", Default = getgenv().AutoSaplingMode, Callback = function(v) getgenv().AutoSaplingMode = v end })

local SecSpeed = Tab:Section({ Title = "⏱️ Delay & Speeds", Box = true, Opened = false })
SecSpeed:Input({ Title = "Wait Drop Muncul (ms)", Value = tostring(getgenv().WaitDropMs), Placeholder = tostring(getgenv().WaitDropMs), Callback = function(v) getgenv().WaitDropMs = tonumber(v) or getgenv().WaitDropMs end })
SecSpeed:Input({ Title = "Walk Speed (Kecepatan Collect)", Value = tostring(getgenv().WalkSpeed), Placeholder = tostring(getgenv().WalkSpeed), Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })
SecSpeed:Input({ Title = "Hit Spam (Jumlah Pukulan)", Value = tostring(getgenv().HitCount), Placeholder = tostring(getgenv().HitCount), Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end })

local SecSeed = Tab:Section({ Title = "🌱 Auto Drop Seed (Sapling)", Box = true, Opened = false })
SecSeed:Toggle({ Title = "Enable Auto Drop Sapling", Default = getgenv().AutoDropSapling, Callback = function(v) getgenv().AutoDropSapling = v end })
SecSeed:Input({ Title = "Drop Threshold (Amount)", Value = tostring(getgenv().SaplingThreshold), Placeholder = tostring(getgenv().SaplingThreshold), Callback = function(v) getgenv().SaplingThreshold = tonumber(v) or getgenv().SaplingThreshold end })
local DropSeed = SecSeed:Dropdown({ Title = "Target Drop Seed (ID)", Options = ScanAvailableItems(), Default = getgenv().TargetSaplingName, Callback = function(v) getgenv().TargetSaplingName = v end })
SecSeed:Button({ Title = "🔄 Refresh Seed List", Callback = function() DropSeed:Refresh(ScanAvailableItems()) end })

-- [[ ========================================================= ]] --
-- [[ SYSTEM LOGIC & SAFE MOVEMENT ]]
-- [[ ========================================================= ]] --
local Remotes = RS:WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteBreak = Remotes:WaitForChild("PlayerFist")
local RemoteDrop = Remotes:WaitForChild("PlayerDrop")

getgenv().KzoyzHeartbeat = RunService.Heartbeat:Connect(function()
    local highlights = workspace:FindFirstChild("TileHighligts") or workspace:FindFirstChild("TileHighlights")
    if highlights then pcall(function() highlights:ClearAllChildren() end) end
end)

-- Ambil Kordinat Exact Drop (Smart Walk)
local function GetExactDropsInGrid(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local exactPositions = {}
    
    for _, folder in ipairs(TargetFolders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
                elseif obj:IsA("Model") then 
                    local firstPart = obj:FindFirstChildWhichIsA("BasePart")
                    if firstPart then pos = firstPart.Position end 
                end
                
                if pos then
                    local dX = math.floor(pos.X / getgenv().GridSize + 0.5)
                    local dY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                    
                    if dX == TargetGridX and dY == TargetGridY then
                        local isSapling = false
                        for _, attrValue in pairs(obj:GetAttributes()) do 
                            if type(attrValue) == "string" and string.find(string.lower(attrValue), "sapling") then isSapling = true; break end 
                        end
                        if not isSapling then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("StringValue") and string.find(string.lower(child.Value), "sapling") then isSapling = true; break end
                            end
                        end
                        
                        -- Filter mode (Sapling only atau Semua)
                        if (getgenv().AutoSaplingMode and isSapling) or (not getgenv().AutoSaplingMode) then
                            table.insert(exactPositions, pos)
                        end
                    end
                end
            end
        end
    end
    return exactPositions
end

-- Cek Block Solid (Biar ga maksa collect kalo ketutup block)
local function IsTileSolid(TargetGridX, TargetGridY, currZ)
    local searchPos = Vector3.new(TargetGridX * getgenv().GridSize, TargetGridY * getgenv().GridSize, currZ)
    local overlap = workspace:GetPartBoundsInBox(CFrame.new(searchPos), Vector3.new(2, 2, 2))
    for _, part in ipairs(overlap) do
        if part.Parent 
           and not part:IsDescendantOf(LP.Character) 
           and part.Parent.Name ~= "Drops" 
           and part.Parent.Name ~= "Gems" 
           and part.Parent.Name ~= "Hitbox" 
           and part.Parent.Name ~= "TileHighlights" then
           
           if part.CanCollide or part.Name == "Foreground" or part.Parent.Name == "Tiles" or part.Parent.Name == "Blocks" then
               return true
           end
        end
    end
    return false
end

-- SAFE MOVE (Anti 3D Bug 100% + Modfly Smooth)
local function SafeMoveTo(targetVec3)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    local mover = MyHitbox or hrp
    
    if not mover then return false end
    
    -- Matikan input manual sementara
    if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end

    -- Kita ambil posisi start dari PlayerMovement jika ada, supaya sinkron dengan game
    local startPos = mover.Position
    if PlayerMovement and PlayerMovement.Position then
        startPos = PlayerMovement.Position
    end
    
    -- Pastikan Z-axis kekunci (biar nggak geser kedalaman / 3D)
    targetVec3 = Vector3.new(targetVec3.X, targetVec3.Y, startPos.Z)
    
    local dist = (Vector3.new(startPos.X, startPos.Y, 0) - Vector3.new(targetVec3.X, targetVec3.Y, 0)).Magnitude 
    local duration = dist / getgenv().WalkSpeed
    if duration < 0.05 then duration = 0.05 end

    -- Aktifkan Modfly (Anti Jatuh)
    local oldGravity = workspace.Gravity
    workspace.Gravity = 0

    local t = 0
    while t < duration and getgenv().MasterAutoFarm do
        local dt = RunService.Heartbeat:Wait()
        t = t + dt
        local alpha = math.clamp(t / duration, 0, 1)
        local currentPos = startPos:Lerp(targetVec3, alpha)
        
        if PlayerMovement then 
            -- GAME PAKAI PLAYERMOVEMENT: JANGAN sentuh CFrame. Biar game yang urus visualnya (Solusi bug 3D).
            pcall(function() 
                PlayerMovement.Position = currentPos
                PlayerMovement.VelocityX = 0 
                PlayerMovement.VelocityY = 0 
                PlayerMovement.VelocityZ = 0 
            end)
        else
            -- Kalau nggak pakai PlayerMovement (Fallback murni)
            local fixedRot = mover.CFrame - mover.CFrame.Position
            local newCFrame = fixedRot + currentPos
            mover.CFrame = newCFrame
            if hrp and MyHitbox then hrp.CFrame = newCFrame end
        end
    end
    
    -- Set final position
    if PlayerMovement then 
        pcall(function() 
            PlayerMovement.Position = targetVec3 
            PlayerMovement.VelocityX = 0 
            PlayerMovement.VelocityY = 0 
            PlayerMovement.VelocityZ = 0 
            PlayerMovement.InputActive = true 
        end)
    else
        local fixedRot = mover.CFrame - mover.CFrame.Position
        local finalCFrame = fixedRot + targetVec3
        mover.CFrame = finalCFrame
        if hrp and MyHitbox then hrp.CFrame = finalCFrame end
    end

    workspace.Gravity = oldGravity
    task.wait(0.01)
end

-- ==============================================================
-- MAIN FARM LOOP
-- ==============================================================
getgenv().KzoyzFarmLoop = task.spawn(function() 
    while true do 
        if getgenv().MasterAutoFarm then 
            
            local HitboxFolder = workspace:FindFirstChild("Hitbox")
            local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
            local ref = MyHitbox or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
            
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
                    elseif getgenv().GameInventoryModule and getgenv().GameInventoryModule.GetSelectedItem then 
                        _, ItemIndex = getgenv().GameInventoryModule.GetSelectedItem() 
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

                -- [[ 2. BREAK (HIT COUNT DENGAN DELAY 150MS) ]]
                for _, offset in ipairs(getgenv().SelectedTiles) do 
                    if not getgenv().MasterAutoFarm then break end 
                    local TGrid = Vector2.new(BaseX + offset.x, BaseY + offset.y) 
                    
                    local hits = getgenv().HitCount or 25
                    for hit = 1, hits do 
                        if not getgenv().MasterAutoFarm then break end 
                        pcall(function() RemoteBreak:FireServer(TGrid) end)
                        task.wait(0.15) -- Jeda 150ms per pukulan seperti default dulu
                    end
                end
                
                -- [[ 3. SMART AUTO COLLECT ]]
                task.wait(getgenv().WaitDropMs / 1000) 
                
                local ExactDropsToCollect = {}
                for _, offset in ipairs(getgenv().SelectedTiles) do
                    local tx = BaseX + offset.x
                    local ty = BaseY + offset.y
                    
                    -- JIKA TILE KOSONG (Tidak ada block)
                    if not IsTileSolid(tx, ty, currZ) then 
                        local dropsInGrid = GetExactDropsInGrid(tx, ty)
                        for _, dropPos in ipairs(dropsInGrid) do
                            table.insert(ExactDropsToCollect, dropPos)
                        end
                    end
                end
                
                if #ExactDropsToCollect > 0 and getgenv().MasterAutoFarm then
                    for _, dropPos in ipairs(ExactDropsToCollect) do
                        if not getgenv().MasterAutoFarm then break end
                        
                        -- SMART WALK: Jalan persis ke koordinat (X, Y) drop
                        SafeMoveTo(Vector3.new(dropPos.X, dropPos.Y, currZ)) 
                        
                        local waitTimeout = 0
                        local gridX = math.floor(dropPos.X / getgenv().GridSize + 0.5)
                        local gridY = math.floor(dropPos.Y / getgenv().GridSize + 0.5)
                        
                        -- Tunggu sampai drop hilang terambil
                        while #GetExactDropsInGrid(gridX, gridY) > 0 and waitTimeout < 15 and getgenv().MasterAutoFarm do 
                            task.wait(0.1)
                            waitTimeout = waitTimeout + 1 
                        end
                    end
                    
                    -- Balik ke posisi tengah tempat bot farming semula
                    task.wait(0.1)
                    local baseVec = Vector3.new(BaseX * getgenv().GridSize, BaseY * getgenv().GridSize, currZ)
                    SafeMoveTo(baseVec) 
                end
                
                -- [[ 4. AUTO DROP SAPLING ]]
                if getgenv().AutoDropSapling and getgenv().TargetSaplingName ~= "Kosong" then
                    local sapSlot = GetSlotByItemID(getgenv().TargetSaplingName)
                    local sapAmount = GetItemAmountByID(getgenv().TargetSaplingName)
                    
                    if sapSlot and sapAmount >= getgenv().SaplingThreshold then
                        local dropX = getgenv().DropTargetX or (BaseX + 1)
                        local dropY = getgenv().DropTargetY or BaseY
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

            end 
        end 
        task.wait(0.1) 
    end 
end)
