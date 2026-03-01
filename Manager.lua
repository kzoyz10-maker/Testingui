local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Manager v3.0 - WINDUI + AUTO PULL" 

-- ========================================== --
-- [[ DEFAULT SETTINGS (ANTI-RESET) ]]
-- ========================================== --
getgenv().DropDelay = getgenv().DropDelay or 2     
getgenv().TrashDelay = getgenv().TrashDelay or 2    
getgenv().StepDelay = getgenv().StepDelay or 0.1   
getgenv().GridSize = getgenv().GridSize or 4.5 

getgenv().AutoCollect = getgenv().AutoCollect or false
getgenv().AutoDrop = getgenv().AutoDrop or false
getgenv().AutoTrash = getgenv().AutoTrash or false
getgenv().AutoBan = getgenv().AutoBan or false
getgenv().AutoPull = getgenv().AutoPull or false
getgenv().DropAmount = getgenv().DropAmount or 50
getgenv().TrashAmount = getgenv().TrashAmount or 50
getgenv().TargetPosX = getgenv().TargetPosX or 0
getgenv().TargetPosY = getgenv().TargetPosY or 0

getgenv().AutoChat = getgenv().AutoChat or false
getgenv().ChatText = getgenv().ChatText or "Halo Semuanya"
getgenv().ChatDelay = getgenv().ChatDelay or 3
getgenv().ChatRandomLetter = getgenv().ChatRandomLetter or true

getgenv().HideName = getgenv().HideName or false
getgenv().FakeNameText = getgenv().FakeNameText or "KzoyzPlayer"
getgenv().AntiStaff = getgenv().AntiStaff or false
getgenv().CustomZoom = getgenv().CustomZoom or 1000

-- ========================================== --
-- [[ SERVICES & MODULES ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser") 

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

local function ManageUIState(Mode)
    local PG = LP:FindFirstChild("PlayerGui")
    if not PG then return end
    if Mode == "Normal" then
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = true end end end end
        local RestoredUI = {"GemsUI", "TopbarCentered", "TopbarCenteredClipped", "TopbarStandard", "TopbarStandardClipped", "ExperienceChat"}
        for _, name in pairs(RestoredUI) do local ui = PG:FindFirstChild(name); if ui and ui:IsA("ScreenGui") then ui.Enabled = true end end
    elseif Mode == "Dropping" then
        if PlayerMovement then PlayerMovement.InputActive = true end
        if PG:FindFirstChild("TouchGui") then PG.TouchGui.Enabled = true end
        if PG:FindFirstChild("InventoryUI") then PG.InventoryUI.Enabled = true end
        if PG:FindFirstChild("ExperienceChat") then PG.ExperienceChat.Enabled = true end
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = false end end end end
    end
end

local function ForceRestoreUI()
    ManageUIState("Normal") 
    pcall(function()
        if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
        end
    end)
    task.wait(0.1)
    pcall(function()
        if UIManager then
            if type(UIManager.ShowHUD) == "function" then UIManager:ShowHUD() end
            if type(UIManager.ShowUI) == "function" then UIManager:ShowUI() end
        end
    end)
end

local function FindInventoryModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindInventoryModule()

-- ========================================== --
-- [[ REMOTES ]]
-- ========================================== --
local Remotes = RS:WaitForChild("Remotes")
local RemoteDropSafe = Remotes:WaitForChild("PlayerDrop") 
local RemoteTrashSafe = Remotes:WaitForChild("PlayerItemTrash") 
local RemoteInspect = Remotes:WaitForChild("PlayerInspectPlayer") 
local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent") 
local ChatRemote = RS:WaitForChild("CB")

-- ========================================== --
-- [[ WIND UI SETUP ]]
-- ========================================== --

-- SECTION: PLAYER CONTROL & SECURITY
local SecPlayer = Tab:Section({ Title = "🛡️ Player Control & Security", Box = true, Opened = true })

SecPlayer:Toggle({ Title = "🧲 Auto Pull Players (World)", Default = getgenv().AutoPull, Callback = function(v) getgenv().AutoPull = v; if not v then ForceRestoreUI() end end })
SecPlayer:Toggle({ Title = "🛡️ Enable Anti-Staff (Auto Disconnect)", Default = getgenv().AntiStaff, Callback = function(v) getgenv().AntiStaff = v end })

-- SECTION: CAMERA
local SecCam = Tab:Section({ Title = "🎥 Camera Custom Zoom", Box = true, Opened = false })
SecCam:Input({ Title = "Max Zoom Distance", Value = tostring(getgenv().CustomZoom), Placeholder = tostring(getgenv().CustomZoom), Callback = function(v) getgenv().CustomZoom = tonumber(v) or getgenv().CustomZoom end })
SecCam:Button({
    Title = "Apply Camera Zoom",
    Callback = function()
        pcall(function()
            LP.CameraMaxZoomDistance = tonumber(getgenv().CustomZoom) or 1000
            LP.CameraMinZoomDistance = 0.5 
        end)
    end
})

-- SECTION: AUTO COLLECT
local SecCollect = Tab:Section({ Title = "⚙️ Auto Collect Settings", Box = true, Opened = false })
SecCollect:Toggle({ Title = "▶ Enable Auto Collect", Default = getgenv().AutoCollect, Callback = function(v) getgenv().AutoCollect = v end })

local InpX = SecCollect:Input({ Title = "Target Grid X", Value = tostring(getgenv().TargetPosX), Placeholder = tostring(getgenv().TargetPosX), Callback = function(v) getgenv().TargetPosX = tonumber(v) or getgenv().TargetPosX end })
local InpY = SecCollect:Input({ Title = "Target Grid Y", Value = tostring(getgenv().TargetPosY), Placeholder = tostring(getgenv().TargetPosY), Callback = function(v) getgenv().TargetPosY = tonumber(v) or getgenv().TargetPosY end })

SecCollect:Button({
    Title = "📍 Save Pos (Current Loc)",
    Callback = function()
        local HitboxFolder = workspace:FindFirstChild("Hitbox")
        local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
        local RefPart = MyHitbox or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
        if RefPart then
            local currX = math.floor(RefPart.Position.X / getgenv().GridSize + 0.5)
            local currY = math.floor(RefPart.Position.Y / getgenv().GridSize + 0.5)
            getgenv().TargetPosX = currX; getgenv().TargetPosY = currY
            pcall(function() InpX:Set(tostring(currX)) end)
            pcall(function() InpY:Set(tostring(currY)) end)
        end
    end
})

-- SECTION: AUTO DROP
local SecDrop = Tab:Section({ Title = "📦 Auto Drop Settings", Box = true, Opened = false })
SecDrop:Toggle({ Title = "▶ Enable Auto Drop", Default = getgenv().AutoDrop, Callback = function(v) getgenv().AutoDrop = v; if not v then ForceRestoreUI() end end })
SecDrop:Input({ Title = "Drop Amount", Value = tostring(getgenv().DropAmount), Placeholder = tostring(getgenv().DropAmount), Callback = function(v) getgenv().DropAmount = tonumber(v) or getgenv().DropAmount end })
SecDrop:Input({ Title = "Drop Delay (Detik)", Value = tostring(getgenv().DropDelay), Placeholder = tostring(getgenv().DropDelay), Callback = function(v) getgenv().DropDelay = tonumber(v) or getgenv().DropDelay end })

-- SECTION: AUTO TRASH
local SecTrash = Tab:Section({ Title = "🚮 Auto Trash Settings", Box = true, Opened = false })
SecTrash:Toggle({ Title = "▶ Enable Auto Trash", Default = getgenv().AutoTrash, Callback = function(v) getgenv().AutoTrash = v; if not v then ForceRestoreUI() end end })
SecTrash:Input({ Title = "Trash Amount", Value = tostring(getgenv().TrashAmount), Placeholder = tostring(getgenv().TrashAmount), Callback = function(v) getgenv().TrashAmount = tonumber(v) or getgenv().TrashAmount end })
SecTrash:Input({ Title = "Trash Delay (Detik)", Value = tostring(getgenv().TrashDelay), Placeholder = tostring(getgenv().TrashDelay), Callback = function(v) getgenv().TrashDelay = tonumber(v) or getgenv().TrashDelay end })

-- SECTION: STREAMER MODE
local SecStreamer = Tab:Section({ Title = "👁️ Streamer Mode (Spoof Name)", Box = true, Opened = false })
SecStreamer:Toggle({ Title = "▶ Enable Spoof Name", Default = getgenv().HideName, Callback = function(v) getgenv().HideName = v end })
SecStreamer:Input({ Title = "Custom Fake Name", Value = tostring(getgenv().FakeNameText), Placeholder = tostring(getgenv().FakeNameText), Callback = function(v) getgenv().FakeNameText = v end })

-- SECTION: SPAM CHAT
local SecChat = Tab:Section({ Title = "💬 Auto Spam Chat Settings", Box = true, Opened = false })
SecChat:Toggle({ Title = "▶ Enable Auto Chat", Default = getgenv().AutoChat, Callback = function(v) getgenv().AutoChat = v end })
SecChat:Input({ Title = "Pesan Chat", Value = tostring(getgenv().ChatText), Placeholder = tostring(getgenv().ChatText), Callback = function(v) getgenv().ChatText = v end })
SecChat:Input({ Title = "Delay (Detik)", Value = tostring(getgenv().ChatDelay), Placeholder = tostring(getgenv().ChatDelay), Callback = function(v) getgenv().ChatDelay = tonumber(v) or getgenv().ChatDelay end })
SecChat:Toggle({ Title = "Anti Spam (Huruf Random)", Default = getgenv().ChatRandomLetter, Callback = function(v) getgenv().ChatRandomLetter = v end })

-- ========================================== --
-- [[ LOGIKA SISTEM ]]
-- ========================================== --

RunService.RenderStepped:Connect(function() if getgenv().AutoDrop or getgenv().AutoTrash then ManageUIState("Dropping") end end)

-- [[ FUNGSI EKSEKUSI BAN & PULL ]]
local function ExecuteBan(targetPlayer)
    if targetPlayer == LP then return end
    pcall(function() RemoteInspect:FireServer(targetPlayer) end)
    task.wait(0.1) 
    pcall(function() ManagerRemote:FireServer({ButtonAction = "ban", Inputs = {}}) end)
    pcall(function()
        if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
        end
    end)
end

local function ExecutePull(targetPlayer)
    if targetPlayer == LP then return end
    pcall(function() RemoteInspect:FireServer(targetPlayer) end)
    task.wait(0.1) 
    pcall(function() ManagerRemote:FireServer({ButtonAction = "pull", Inputs = {}}) end)
    pcall(function()
        if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
        end
    end)
end

-- [[ LOGIKA AUTO BAN & AUTO PULL ]]
task.spawn(function()
    while true do
        if getgenv().AutoBan or getgenv().AutoPull then
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= LP then 
                    if getgenv().AutoBan then ExecuteBan(targetPlayer) end
                    if getgenv().AutoPull then ExecutePull(targetPlayer) end
                    task.wait(0.2) 
                end
            end
        end
        task.wait(0.5) 
    end
end)

-- [[ LOGIKA ANTI-STAFF ]]
local function CheckIfStaff(player)
    if not getgenv().AntiStaff then return end
    if player == LP then return end
    task.spawn(function()
        pcall(function()
            local isStaff = false
            if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then isStaff = true end
            if game.CreatorType == Enum.CreatorType.Group then
                local playerRank = player:GetRankInGroup(game.CreatorId)
                if playerRank >= 100 then isStaff = true end
            end
            if player:GetRankInGroup(1200769) > 0 then isStaff = true end
            if isStaff then LP:Kick("🛡️ Kzoyz Security: Auto Disconnect!\n\nModerator/Developer (" .. player.Name .. ") terdeteksi memasuki server.") end
        end)
    end)
end

Players.PlayerAdded:Connect(function(newPlayer) 
    CheckIfStaff(newPlayer)
    if getgenv().AutoBan then ExecuteBan(newPlayer) end 
    if getgenv().AutoPull then ExecutePull(newPlayer) end
end)

task.spawn(function()
    while true do
        if getgenv().AntiStaff then
            for _, p in ipairs(Players:GetPlayers()) do CheckIfStaff(p) end
        end
        task.wait(2)
    end
end)

-- [[ LOGIKA STREAMER MODE / SPOOF NAME ]]
task.spawn(function()
    local realName = LP.Name
    local realDisplay = LP.DisplayName
    local activeFake = realName
    while true do
        local targetName = realName
        local targetDisplay = realDisplay
        if getgenv().HideName then
            local f = getgenv().FakeNameText
            targetName = (f == "" or f == " ") and "HiddenPlayer" or f
            targetDisplay = targetName
        end
        local function ReplaceSafe(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                local txt = obj.Text; local changed = false
                if targetName ~= realName and txt:find(realName) then txt = string.gsub(txt, realName, targetName); changed = true end
                if targetDisplay ~= realDisplay and txt:find(realDisplay) then txt = string.gsub(txt, realDisplay, targetDisplay); changed = true end
                if activeFake ~= targetName and activeFake ~= realName and activeFake ~= realDisplay then
                    if txt:find(activeFake) then txt = string.gsub(txt, activeFake, targetName); changed = true end
                end
                if changed and obj.Text ~= txt then obj.Text = txt end
            end
        end
        if LP.Character then for _, v in pairs(LP.Character:GetDescendants()) do ReplaceSafe(v) end end
        if LP:FindFirstChild("PlayerGui") then for _, v in pairs(LP.PlayerGui:GetDescendants()) do ReplaceSafe(v) end end
        activeFake = targetName
        task.wait(1) 
    end
end)

-- [[ LOGIKA AUTO CHAT SPAM ]]
task.spawn(function()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    while true do
        if getgenv().AutoChat then
            local currentMsg = getgenv().ChatText
            if getgenv().ChatRandomLetter then
                local rand = math.random(1, #charset)
                currentMsg = currentMsg .. " [" .. string.sub(charset, rand, rand) .. "]"
            end
            pcall(function() ChatRemote:FireServer(currentMsg) end)
            task.wait(getgenv().ChatDelay) 
        else
            task.wait(0.5)
        end
    end
end)

-- [[ LOGIKA AUTO DROP ]]
task.spawn(function() 
    local WasAutoDropOn = false
    while true do 
        if getgenv().AutoDrop then 
            WasAutoDropOn = true
            local Amt = getgenv().DropAmount; 
            pcall(function() 
                if getgenv().GameInventoryModule then 
                    local _, slot; 
                    if getgenv().GameInventoryModule.GetSelectedHotbarItem then _, slot = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    elseif getgenv().GameInventoryModule.GetSelectedItem then _, slot = getgenv().GameInventoryModule.GetSelectedItem() end; 
                    if slot then RemoteDropSafe:FireServer(slot, Amt) end 
                end 
            end); 
            task.wait(0.2)
            pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "drp", Inputs = { amt = tostring(Amt) } }})) end)
            pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
            task.wait(getgenv().DropDelay) 
        else
            if WasAutoDropOn then WasAutoDropOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)

-- [[ LOGIKA AUTO TRASH ]]
task.spawn(function() 
    local WasAutoTrashOn = false
    while true do 
        if getgenv().AutoTrash then 
            WasAutoTrashOn = true
            local Amt = getgenv().TrashAmount; 
            pcall(function() 
                if getgenv().GameInventoryModule then 
                    local _, slot; 
                    if getgenv().GameInventoryModule.GetSelectedHotbarItem then _, slot = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    elseif getgenv().GameInventoryModule.GetSelectedItem then _, slot = getgenv().GameInventoryModule.GetSelectedItem() end; 
                    if slot then RemoteTrashSafe:FireServer(slot) end 
                end 
            end); 
            task.wait(0.2)
            pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "trsh", Inputs = { amt = tostring(Amt) } }})) end)
            pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
            task.wait(getgenv().TrashDelay)
        else
            if WasAutoTrashOn then WasAutoTrashOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)

-- [[ LOGIKA AUTO COLLECT GRID ]]
task.spawn(function() 
    while true do 
        if getgenv().AutoCollect then 
            local HitboxFolder = workspace:FindFirstChild("Hitbox")
            local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
            if MyHitbox then 
                local startZ = MyHitbox.Position.Z
                local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
                local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)
                local homeX = currentX
                local homeY = currentY
                local targetX = getgenv().TargetPosX
                local targetY = getgenv().TargetPosY
                if currentX ~= targetX or currentY ~= targetY then 
                    local function WalkGrid(tX, tY) 
                        while (currentX ~= tX or currentY ~= tY) and getgenv().AutoCollect do 
                            if currentX ~= tX then currentX = currentX + (tX > currentX and 1 or -1) 
                            elseif currentY ~= tY then currentY = currentY + (tY > currentY and 1 or -1) end
                            local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ)
                            MyHitbox.CFrame = CFrame.new(newWorldPos)
                            if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end
                            task.wait(getgenv().StepDelay) 
                        end 
                    end
                    WalkGrid(targetX, targetY)
                    task.wait(0.6)
                    WalkGrid(homeX, homeY) 
                end 
            end 
        end
        task.wait(2) 
    end 
end)
