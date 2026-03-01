local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Farm v9.00 (WINDUI + SMOOTH COLLECT)" 

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- [[ ========================================================= ]] --
-- [[ 🧹 CLEANUP SYSTEM (ANTI-STACKING / ANTI-NGEBUT)           ]] --
-- [[ ========================================================= ]] --
if getgenv().KzoyzFarmLoop then task.cancel(getgenv().KzoyzFarmLoop); getgenv().KzoyzFarmLoop = nil end
if getgenv().KzoyzHeartbeat then getgenv().KzoyzHeartbeat:Disconnect(); getgenv().KzoyzHeartbeat = nil end

-- ========================================== --
-- [[ DEFAULT SETTINGS (ANTI-RESET) ]]
-- ========================================== --
getgenv().ActionDelay = getgenv().ActionDelay or 0.15 
getgenv().GridSize = getgenv().GridSize or 4.5 

getgenv().MasterAutoFarm = getgenv().MasterAutoFarm or false; 
getgenv().AutoCollect = getgenv().AutoCollect or false; 
getgenv().AutoSaplingMode = getgenv().AutoSaplingMode or false; 
getgenv().HitCount = getgenv().HitCount or 3;
getgenv().BreakDelayMs = getgenv().BreakDelayMs or 150; 
getgenv().WaitDropMs = getgenv().WaitDropMs or 250;  
getgenv().WalkSpeedMs = getgenv().WalkSpeedMs or 100;

getgenv().TargetFarmBlock = getgenv().TargetFarmBlock or "Auto (Equipped)"
getgenv().AutoDropSapling = getgenv().AutoDropSapling or false
getgenv().SaplingThreshold = getgenv().SaplingThreshold or 50
getgenv().TargetSaplingName = getgenv().TargetSaplingName or "Kosong"

getgenv().SelectedTiles = getgenv().SelectedTiles or {{x = 0, y = 1}}
getgenv().IsGhosting = false
getgenv().HoldCFrame = nil

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
-- [[ MODAL TILE SELECTOR (TETAP PAKAI GUI BAWAAN ROBLOX KARENA KHUSUS) ]]
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

-- 1. SECTION FARM CONTROL
local SecFarm = Tab:Section({ Title = "🚜 Master Auto Farm", Box = true, Opened = true })

SecFarm:Toggle({ Title = "▶ START AUTO FARM", Default = getgenv().MasterAutoFarm, Callback = function(v) getgenv().MasterAutoFarm = v end })

local function GetBlockOptions()
    local opts = {"Auto (Equipped)"}
    for _, item in ipairs(ScanAvailableItems()) do table.insert(opts, item) end
    return opts
end

local DropFarmBlock = SecFarm:Dropdown({ Title = "🎯 Target Farm Block", Options = GetBlockOptions(), Default = getgenv().TargetFarmBlock, Callback = function(v) getgenv().TargetFarmBlock = v end })
SecFarm:Button({ Title = "🔄 Refresh Items", Callback = function() DropFarmBlock:Refresh(GetBlockOptions()) end })
SecFarm:Button({ Title = "📝 Select Farm Tiles (Grid Area)", Callback = function() OpenTileSelectorModal() end })


-- 2. SECTION AUTO COLLECT
local SecCollect = Tab:Section({ Title = "🧲 Auto Collect Settings", Box = true, Opened = false })
SecCollect:Toggle({ Title = "Enable Auto Collect", Default = getgenv().AutoCollect, Callback = function(v) getgenv().AutoCollect = v end })
SecCollect:Toggle({ Title = "Only Collect Sapling", Default = getgenv().AutoSaplingMode, Callback = function(v) getgenv().AutoSaplingMode = v end })


-- 3. SECTION SPEED & DELAY
local SecSpeed = Tab:Section({ Title = "⏱️ Delay & Speeds", Box = true, Opened = false })
SecSpeed:Input({ Title = "Delay Collect (ms)", Value = tostring(getgenv().WaitDropMs), Placeholder = tostring(getgenv().WaitDropMs), Callback = function(v) getgenv().WaitDropMs = tonumber(v) or getgenv().WaitDropMs end })
SecSpeed:Input({ Title = "Collect Speed (ms per block)", Value = tostring(getgenv().WalkSpeedMs), Placeholder = tostring(getgenv().WalkSpeedMs), Callback = function(v) getgenv().WalkSpeedMs = tonumber(v) or getgenv().WalkSpeedMs end })
SecSpeed:Input({ Title = "Break Delay (ms)", Value = tostring(getgenv().BreakDelayMs), Placeholder = tostring(getgenv().BreakDelayMs), Callback = function(v) getgenv().BreakDelayMs = tonumber(v) or getgenv().BreakDelayMs end })
SecSpeed:Input({ Title = "Hit Count (Pukulan per blok)", Value = tostring(getgenv().HitCount), Placeholder = tostring(getgenv().HitCount), Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end })


-- 4. SECTION AUTO DROP SEED
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
        local HitboxFolder = workspace:FindFirstChild("Hitbox")
        local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
        local ref = MyHitbox or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
        if ref then
            local cx = math.floor(ref.Position.X / getgenv().GridSize + 0.5)
            local cy = math.floor(ref.Position.Y / getgenv().GridSize + 0.5)
            getgenv().DropTargetX = cx
            getgenv().DropTargetY = cy
            pcall(function() InpDropX:Set(tostring(cx)) end)
            pcall(function() InpDropY:Set(tostring(cy)) end)
        end
    end
})

-- [[ ========================================================= ]] --
-- [[ SYSTEM LOGIC (REMOTES & FARM LOOP) ]]
-- [[ ========================================================= ]] --
local Remotes = RS:WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteBreak = Remotes:WaitForChild("PlayerFist")
local RemoteDrop = Remotes:WaitForChild("PlayerDrop")

getgenv().KzoyzHeartbeat = RunService.Heartbeat:Connect(function()
    if getgenv().AutoCollect then
        local highlights = workspace:FindFirstChild("TileHighligts") or workspace:FindFirstChild("TileHighlights")
        if highlights then pcall(function() highlights:ClearAllChildren() end) end
        if getgenv().IsGhosting then
            if getgenv().HoldCFrame then
                local char = LP.Character
                if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = getgenv().HoldCFrame end
            end
            if PlayerMovement then pcall(function() PlayerMovement.VelocityY = 0; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.Grounded = true; PlayerMovement.Jumping = false end) end
        end
    end
end)

local function GetPlayerGridPosition()
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    local ref = MyHitbox or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if ref then return ref.Position.X, ref.Position.Y end
    return nil, nil
end

local function CheckDropsAtGrid(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local foundSapling = false; local foundAny = false
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
                        foundAny = true
                        local isSapling = false
                        for _, attrValue in pairs(obj:GetAttributes()) do
                            if type(attrValue) == "string" and string.find(string.lower(attrValue), "sapling") then isSapling = true; break end
                        end
                        if not isSapling then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("StringValue") and string.find(string.lower(child.Value), "sapling") then isSapling = true; break end
                                for _, attrValue in pairs(child:GetAttributes()) do
                                    if type(attrValue) == "string" and string.find(string.lower(attrValue), "sapling") then isSapling = true; break end
                                end
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

-- FIXED BUGS: Menggunakan Lerp agar movement sangat smooth dan tidak ngeblink kiri-kanan
local function WalkGridSmooth(TargetX, TargetY)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    if not MyHitbox then return end
    
    local startPos = MyHitbox.Position
    local startZ = startPos.Z
    local startGridX = math.floor(startPos.X / getgenv().GridSize + 0.5)
    local startGridY = math.floor(startPos.Y / getgenv().GridSize + 0.5)
    
    if startGridX == TargetX and startGridY == TargetY then return end -- Sudah di posisi

    local targetPos = Vector3.new(TargetX * getgenv().GridSize, TargetY * getgenv().GridSize, startZ)
    
    -- Hitung jarak blok (X & Y) buat dapet total durasi animasi yang akurat
    local distanceBlocks = math.abs(TargetX - startGridX) + math.abs(TargetY - startGridY)
    if distanceBlocks == 0 then distanceBlocks = 1 end
    
    -- Durasi total = jumlah blok x kecepatan input dari UI
    local duration = distanceBlocks * (getgenv().WalkSpeedMs / 1000)
    
    if duration > 0 then
        local t = 0
        while t < duration and getgenv().MasterAutoFarm do
            local dt = RunService.Heartbeat:Wait()
            t = t + dt
            local alpha = math.clamp(t / duration, 0, 1)
            local currentPos = startPos:Lerp(targetPos, alpha) -- LERP BIKIN JALANNYA MULUS
            
            MyHitbox.CFrame = CFrame.new(currentPos)
            if PlayerMovement then pcall(function() PlayerMovement.Position = currentPos end) end
        end
    end
    
    MyHitbox.CFrame = CFrame.new(targetPos)
    if PlayerMovement then pcall(function() PlayerMovement.Position = targetPos end) end
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

-- Simpan Main Loop ke global variable
getgenv().KzoyzFarmLoop = task.spawn(function() 
    while true do 
        if getgenv().MasterAutoFarm and InventoryMod then 
            local PosX, PosY = GetPlayerGridPosition()
            
            if PosX and PosY then 
                local BaseX = math.floor(PosX / getgenv().GridSize + 0.5)
                local BaseY = math.floor(PosY / getgenv().GridSize + 0.5)
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
                
                if ItemIndex then
                    for _, offset in ipairs(getgenv().SelectedTiles) do 
                        if not getgenv().MasterAutoFarm then break end 
                        local TGrid = Vector2.new(BaseX + offset.x, BaseY + offset.y) 
                        RemotePlace:FireServer(TGrid, ItemIndex); task.wait(getgenv().ActionDelay) 
                    end
                end

                for _, offset in ipairs(getgenv().SelectedTiles) do 
                    if not getgenv().MasterAutoFarm then break end 
                    local TGrid = Vector2.new(BaseX + offset.x, BaseY + offset.y) 
                    for hit = 1, getgenv().HitCount do 
                        if not getgenv().MasterAutoFarm then break end 
                        RemoteBreak:FireServer(TGrid); task.wait(getgenv().BreakDelayMs / 1000) 
                    end
                end
                
                if getgenv().AutoCollect then
                    task.wait(getgenv().WaitDropMs / 1000) 
                    local TilesToCollect = {}
                    for _, offset in ipairs(getgenv().SelectedTiles) do
                        local tx = BaseX + offset.x; local ty = BaseY + offset.y
                        if CheckDropsAtGrid(tx, ty) then table.insert(TilesToCollect, {x = tx, y = ty}) end
                    end
                    
                    if #TilesToCollect > 0 and getgenv().MasterAutoFarm then
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
                        
                        for _, tile in ipairs(TilesToCollect) do
                            if not getgenv().MasterAutoFarm then break end
                            WalkGridSmooth(tile.x, tile.y) -- JALAN MULUS KE TILE DROPAN
                            
                            local waitTimeout = 0
                            while CheckDropsAtGrid(tile.x, tile.y) and waitTimeout < 15 and getgenv().MasterAutoFarm do task.wait(0.1); waitTimeout = waitTimeout + 1 end
                        end
                        
                        task.wait(0.1); WalkGridSmooth(BaseX, BaseY) -- KEMBALI KE BASE DENGAN MULUS
                        
                        if hrp and ExactHrpCF then 
                            hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
                            if MyHitbox and ExactHitboxCF then MyHitbox.CFrame = ExactHitboxCF; MyHitbox.AssemblyLinearVelocity = Vector3.zero end
                            hrp.CFrame = ExactHrpCF
                            if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.Grounded = true end) end
                            RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
                            hrp.Anchored = false 
                            for _ = 1, 2 do if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end; RunService.Heartbeat:Wait() end
                        end
                        getgenv().IsGhosting = false 
                    end
                end
                
                -- [[ LOGIC AUTO DROP (UPDATE POSISI) ]]
                if getgenv().AutoDropSapling and getgenv().TargetSaplingName ~= "Kosong" then
                    local sapSlot = GetSlotByItemID(getgenv().TargetSaplingName)
                    local sapAmount = GetItemAmountByID(getgenv().TargetSaplingName)
                    
                    if sapSlot and sapAmount >= getgenv().SaplingThreshold then
                        local dropX, dropY
                        if getgenv().DropTargetX and getgenv().DropTargetY then
                            dropX = getgenv().DropTargetX
                            dropY = getgenv().DropTargetY
                        else
                            dropX, dropY = FindEmptyGridNearPlayer(BaseX, BaseY)
                        end
                        
                        local char = LP.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local HitboxFolder = workspace:FindFirstChild("Hitbox")
                        local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
                        local ExactHrpCF = hrp and hrp.CFrame
                        local ExactHitboxCF = MyHitbox and MyHitbox.CFrame
                        local ExactPMPos = nil
                        if PlayerMovement then pcall(function() ExactPMPos = PlayerMovement.Position end) end

                        if hrp then getgenv().HoldCFrame = ExactHrpCF; hrp.Anchored = true; getgenv().IsGhosting = true end
                        
                        WalkGridSmooth(dropX, dropY) -- JALAN MULUS KE TEMPAT DROP SEED
                        task.wait(0.2)
                        
                        pcall(function() RemoteDrop:FireServer(sapSlot, sapAmount) end)
                        pcall(function() 
                            if UIManager and type(UIManager.FireEvent) == "function" then
                                UIManager:FireEvent("drp", { amt = tostring(sapAmount) })
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
                        
                        task.wait(0.5); WalkGridSmooth(BaseX, BaseY) -- KEMBALI KE BASE DENGAN MULUS
                        
                        if hrp and ExactHrpCF then 
                            hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
                            if MyHitbox and ExactHitboxCF then MyHitbox.CFrame = ExactHitboxCF; MyHitbox.AssemblyLinearVelocity = Vector3.zero end
                            hrp.CFrame = ExactHrpCF
                            if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end
                            RunService.Heartbeat:Wait(); hrp.Anchored = false 
                        end
                        getgenv().IsGhosting = false 
                    end
                end

            end 
        else 
            task.wait(0.1) 
        end 
    end 
end)
