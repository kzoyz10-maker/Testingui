local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Manager v4.7 - SMART WARP & MOBILE JUMP" 

-- ========================================== --
-- [[ DEFAULT SETTINGS (ANTI-RESET) ]]
-- ========================================== --
getgenv().DropDelay = getgenv().DropDelay or 2     
getgenv().TrashDelay = getgenv().TrashDelay or 2    
getgenv().GridSize = getgenv().GridSize or 4.5 
getgenv().WalkSpeed = getgenv().WalkSpeed or 45 

getgenv().AutoCollect = getgenv().AutoCollect or false
getgenv().AutoDrop = getgenv().AutoDrop or false
getgenv().AutoTrash = getgenv().AutoTrash or false
getgenv().AutoBan = getgenv().AutoBan or false
getgenv().AutoPull = getgenv().AutoPull or false
getgenv().DropAmount = getgenv().DropAmount or 50
getgenv().TrashAmount = getgenv().TrashAmount or 50

getgenv().AutoChat = getgenv().AutoChat or false
getgenv().ChatText = getgenv().ChatText or "Halo Semuanya"
getgenv().ChatDelay = getgenv().ChatDelay or 3
getgenv().ChatRandomLetter = getgenv().ChatRandomLetter or true

getgenv().HideName = getgenv().HideName or false
getgenv().FakeNameText = getgenv().FakeNameText or "KzoyzPlayer"
getgenv().AntiStaff = getgenv().AntiStaff or false
getgenv().CustomZoom = getgenv().CustomZoom or 1000

getgenv().AntiHit = getgenv().AntiHit or false
getgenv().AntiBounce = getgenv().AntiBounce or false
getgenv().ModflyEnabled = getgenv().ModflyEnabled or false
getgenv().InfJump = getgenv().InfJump or false
getgenv().SuperSpeed = getgenv().SuperSpeed or false
getgenv().TargetWarpWorld = getgenv().TargetWarpWorld or "buy"

-- ========================================== --
-- [[ SERVICES & MODULES ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))

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
-- [[ REMOTES & ANTI-HIT HOOK ]]
-- ========================================== --
local Remotes = RS:WaitForChild("Remotes")
local RemoteDropSafe = Remotes:WaitForChild("PlayerDrop") 
local RemoteTrashSafe = Remotes:WaitForChild("PlayerItemTrash") 
local RemoteInspect = Remotes:WaitForChild("PlayerInspectPlayer") 
local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent") 
local ChatRemote = RS:WaitForChild("CB")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and getgenv().AntiHit then
        if method == "FireServer" and tostring(self.Name) == "PlayerHurtMe" then
            return nil 
        end
    end
    return oldNamecall(self, ...)
end)

-- ========================================== --
-- [[ INPUT TRACKING (PC & MOBILE) ]]
-- ========================================== --
getgenv().IsHoldingJump = false

-- PC Keyboard Tracking
UIS.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Space then getgenv().IsHoldingJump = true end
end)
UIS.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Space then getgenv().IsHoldingJump = false end
end)

-- Mobile Touch Tracking (Memaksa baca tombol lompat di layar)
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local jumpBtn = LP.PlayerGui.TouchGui.TouchControlFrame.JumpButton
            if jumpBtn and not getgenv().JumpBtnHooked then
                getgenv().JumpBtnHooked = true
                jumpBtn.InputBegan:Connect(function() getgenv().IsHoldingJump = true end)
                jumpBtn.InputEnded:Connect(function() getgenv().IsHoldingJump = false end)
            end
        end)
    end
end)

-- ========================================== --
-- [[ WIND UI SETUP ]]
-- ========================================== --

local SecPlayer = Tab:Section({ Title = "Misc & Player Hacks", Box = true, Opened = true })
SecPlayer:Toggle({ Title = "Anti Hit", Default = getgenv().AntiHit, Callback = function(v) getgenv().AntiHit = v end })
SecPlayer:Toggle({ Title = "Anti Punch / No Knockback", Default = getgenv().AntiBounce, Callback = function(v) getgenv().AntiBounce = v end })
SecPlayer:Toggle({ Title = "Anti-Gravity (Modfly)", Default = getgenv().ModflyEnabled, Callback = function(v) getgenv().ModflyEnabled = v end })
SecPlayer:Toggle({ Title = "Infinite Jump", Default = getgenv().InfJump, Callback = function(v) 
    getgenv().InfJump = v 
    if not v and PlayerMovement then
        PlayerMovement.MaxJump = 1
        PlayerMovement.RemainingJumps = 1
    end
end })
SecPlayer:Toggle({ Title = "Super Speed (Recommended 2)", Default = getgenv().SuperSpeed, Callback = function(v) getgenv().SuperSpeed = v end })
SecPlayer:Input({ Title = "Speed Modifier (Isi Angka)", Value = tostring(getgenv().WalkSpeed), Placeholder = "45", Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })

-- ========================================== --
-- [[ NEW SMART WARP SYSTEM ]]
-- ========================================== --
local queue_on_tp = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or getgenv().queue_on_teleport

local SecWarp = Tab:Section({ Title = "Teleport / Warp World", Box = true, Opened = true })
SecWarp:Input({ Title = "Nama World", Value = getgenv().TargetWarpWorld, Placeholder = "buy", Callback = function(v) getgenv().TargetWarpWorld = v end })
SecWarp:Button({ Title = "🚀 Warp Now!", Callback = function() 
    task.spawn(function()
        local targetWorld = getgenv().TargetWarpWorld
        if not targetWorld or targetWorld == "" then
            warn("Nama World masih kosong!")
            return
        end

        local TpRemote = RS:FindFirstChild("tp")

        if TpRemote then
            -- Kondisi 1: Sedang di Lobby
            print("Mencoba Warp ke: " .. targetWorld)
            pcall(function() TpRemote:FireServer(targetWorld) end)
        else
            -- Kondisi 2: Sedang di World
            print("Lagi di World! Menyiapkan Auto-Warp untuk di Lobby...")
            
            if queue_on_tp then
                local autoWarpScript = string.format([[
                    task.spawn(function()
                        local target = "%s"
                        print("Menunggu remote tp untuk auto-warp ke: " .. target)
                        local RS = game:GetService("ReplicatedStorage")
                        local tpRemote = RS:WaitForChild("tp", 15)
                        
                        if tpRemote then
                            task.wait(0.5) 
                            tpRemote:FireServer(target)
                        else
                            warn("Gagal Auto-Warp: Remote 'tp' tidak ditemukan di Lobby.")
                        end
                    end)
                ]], targetWorld)
                
                queue_on_tp(autoWarpScript)
            else
                warn("Executor kamu nggak support 'queue_on_teleport'. Script Auto-Warp terpaksa dibatalkan.")
            end

            local exitRemote = RS:WaitForChild("Remotes"):FindFirstChild("RequestPlayerExitWorld")
            if exitRemote then
                pcall(function() exitRemote:InvokeServer() end)
            end
        end
    end)
end })

local SecMisc = Tab:Section({ Title = "Server Tools", Box = true, Opened = false })
SecMisc:Toggle({ Title = "Auto Pull Players", Default = getgenv().AutoPull, Callback = function(v) getgenv().AutoPull = v; if not v then ForceRestoreUI() end end })
SecMisc:Toggle({ Title = "Auto Ban Players", Default = getgenv().AutoBan, Callback = function(v) getgenv().AutoBan = v; if not v then ForceRestoreUI() end end })
SecMisc:Toggle({ Title = "Enable Anti-Staff", Default = getgenv().AntiStaff, Callback = function(v) getgenv().AntiStaff = v end })

local SecCam = Tab:Section({ Title = "Camera Settings", Box = true, Opened = false })
SecCam:Input({ Title = "Max Zoom Distance", Value = tostring(getgenv().CustomZoom), Placeholder = tostring(getgenv().CustomZoom), Callback = function(v) getgenv().CustomZoom = tonumber(v) or getgenv().CustomZoom end })
SecCam:Button({ Title = "Apply Camera Zoom", Callback = function() pcall(function() LP.CameraMaxZoomDistance = tonumber(getgenv().CustomZoom) or 1000; LP.CameraMinZoomDistance = 0.5 end) end })

local SecCollect = Tab:Section({ Title = "Auto Collect", Box = true, Opened = false })
SecCollect:Toggle({ Title = "Auto Collect", Default = getgenv().AutoCollect, Callback = function(v) getgenv().AutoCollect = v end })
SecCollect:Button({ Title = "Clear Blacklisted Drops", Callback = function() getgenv().BlacklistedLoot = {} warn("✅ Blacklist Dibersihkan!") end })

local SecDrop = Tab:Section({ Title = "Auto Drop", Box = true, Opened = false })
SecDrop:Toggle({ Title = "Auto Drop", Default = getgenv().AutoDrop, Callback = function(v) getgenv().AutoDrop = v; if not v then ForceRestoreUI() end end })
SecDrop:Input({ Title = "Drop Amount", Value = tostring(getgenv().DropAmount), Placeholder = tostring(getgenv().DropAmount), Callback = function(v) getgenv().DropAmount = tonumber(v) or getgenv().DropAmount end })
SecDrop:Input({ Title = "Drop Delay (sec)", Value = tostring(getgenv().DropDelay), Placeholder = tostring(getgenv().DropDelay), Callback = function(v) getgenv().DropDelay = tonumber(v) or getgenv().DropDelay end })

local SecTrash = Tab:Section({ Title = "Auto Trash", Box = true, Opened = false })
SecTrash:Toggle({ Title = "Auto Trash", Default = getgenv().AutoTrash, Callback = function(v) getgenv().AutoTrash = v; if not v then ForceRestoreUI() end end })
SecTrash:Input({ Title = "Trash Amount", Value = tostring(getgenv().TrashAmount), Placeholder = tostring(getgenv().TrashAmount), Callback = function(v) getgenv().TrashAmount = tonumber(v) or getgenv().TrashAmount end })
SecTrash:Input({ Title = "Trash Delay (sec)", Value = tostring(getgenv().TrashDelay), Placeholder = tostring(getgenv().TrashDelay), Callback = function(v) getgenv().TrashDelay = tonumber(v) or getgenv().TrashDelay end })

local SecStreamer = Tab:Section({ Title = "Custom Username", Box = true, Opened = false })
SecStreamer:Toggle({ Title = "Spoof Name", Default = getgenv().HideName, Callback = function(v) getgenv().HideName = v end })
SecStreamer:Input({ Title = "Custom Fake Name", Value = tostring(getgenv().FakeNameText), Placeholder = tostring(getgenv().FakeNameText), Callback = function(v) getgenv().FakeNameText = v end })

local SecChat = Tab:Section({ Title = "Auto Spam Chat Settings", Box = true, Opened = false })
SecChat:Toggle({ Title = "Auto Chat", Default = getgenv().AutoChat, Callback = function(v) getgenv().AutoChat = v end })
SecChat:Input({ Title = "Message", Value = tostring(getgenv().ChatText), Placeholder = tostring(getgenv().ChatText), Callback = function(v) getgenv().ChatText = v end })
SecChat:Input({ Title = "Delay (sec)", Value = tostring(getgenv().ChatDelay), Placeholder = tostring(getgenv().ChatDelay), Callback = function(v) getgenv().ChatDelay = tonumber(v) or getgenv().ChatDelay end })
SecChat:Toggle({ Title = "Anti Spam (Random Alfabet)", Default = getgenv().ChatRandomLetter, Callback = function(v) getgenv().ChatRandomLetter = v end })

-- ========================================== --
-- [[ PATHFINDING & SMART GLIDE SYSTEM ]]
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

    local startPos = MyHitbox.Position
    if PlayerMovement and PlayerMovement.Position then startPos = PlayerMovement.Position end

    for _, targetPos in ipairs(pathTable) do
        if not getgenv().AutoCollect then break end
        local targetVec3 = Vector3.new(targetPos.X, targetPos.Y, currZ)
        local dist = (Vector2.new(startPos.X, startPos.Y) - Vector2.new(targetVec3.X, targetVec3.Y)).Magnitude 
        local duration = dist / getgenv().WalkSpeed
        if duration < 0.05 then duration = 0.05 end

        local t = 0
        while t < duration and getgenv().AutoCollect do
            local dt = RunService.Heartbeat:Wait()
            t = t + dt
            local alpha = math.clamp(t / duration, 0, 1)
            local currentPos = startPos:Lerp(targetVec3, alpha)
            
            if PlayerMovement then 
                pcall(function() PlayerMovement.Position = currentPos; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0; PlayerMovement.VelocityZ = 0 end)
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
        pcall(function() PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.InputActive = true end) 
    end
    return true
end

local function SmartMoveToExact(targetVec3)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    local currZ = MyHitbox.Position.Z
    local myGridX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
    local myGridY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)

    local targetX = math.floor(targetVec3.X / getgenv().GridSize + 0.5)
    local targetY = math.floor(targetVec3.Y / getgenv().GridSize + 0.5)

    if myGridX == targetX and myGridY == targetY then return SmoothWalkPath({ Vector3.new(targetVec3.X, targetVec3.Y, currZ) }, currZ) end
    local route = FindPathAStar(myGridX, myGridY, targetX, targetY)
    
    if route and #route > 0 then
        local pathTable = {}
        for _, step in ipairs(route) do table.insert(pathTable, Vector3.new(step.x * getgenv().GridSize, step.y * getgenv().GridSize, currZ)) end
        table.insert(pathTable, Vector3.new(targetVec3.X, targetVec3.Y, currZ))
        return SmoothWalkPath(pathTable, currZ)
    else
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end
        local targetFallback = Vector3.new(targetVec3.X, targetVec3.Y, currZ)
        if PlayerMovement then pcall(function() PlayerMovement.Position = targetFallback end) else MyHitbox.CFrame = CFrame.new(targetFallback) end
        task.wait(0.2)
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
        return true
    end
end

-- ========================================== --
-- [[ ⚙️ HEARTBEAT: MOVEMENT & COMBAT LOGIC ]]
-- ========================================== --

RunService.RenderStepped:Connect(function(dt)
    if not PlayerMovement then return end
    
    local char = LP.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    local pMoveX = PlayerMovement.MoveX or 0

    pcall(function()
        -- [1] SENSOR BYPASS
        if getgenv().AntiBounce or getgenv().AntiHit then
            PlayerMovement.Sensor = false
        else
            PlayerMovement.Sensor = true
        end

        -- [2] SUPER SPEED
        if getgenv().SuperSpeed and pMoveX ~= 0 then
            PlayerMovement.VelocityX = pMoveX * (getgenv().WalkSpeed or 45)
        end

        -- [3] INFINITE JUMP
        if getgenv().InfJump then
            PlayerMovement.RemainingJumps = 999
            PlayerMovement.MaxJump = 999
        end

        -- [4] MODFLY (Anti-Gravity) 
        if getgenv().ModflyEnabled then
            local flySpeed = (getgenv().WalkSpeed or 45) / 10
            
            -- Mengecek variabel universal IsHoldingJump (Trigger dari HP dan PC)
            if getgenv().IsHoldingJump then
                PlayerMovement.VelocityY = flySpeed
            elseif UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then
                PlayerMovement.VelocityY = -flySpeed
            else
                PlayerMovement.VelocityY = 0 -- Stay di udara
            end
        end
    end)
    
    if getgenv().AutoDrop or getgenv().AutoTrash then ManageUIState("Dropping") end 
end)

-- [[ SISA LOGIKA: BAN, PULL, STAFF, CHAT, TRASH, DROP, AUTOLOOT ]]
local function ExecuteBan(targetPlayer)
    if targetPlayer == LP then return end
    pcall(function() RemoteInspect:FireServer(targetPlayer) end); task.wait(0.1) 
    pcall(function() ManagerRemote:FireServer({ButtonAction = "ban", Inputs = {}}) end)
    pcall(function() if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end; for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
end

local function ExecutePull(targetPlayer)
    if targetPlayer == LP then return end
    pcall(function() RemoteInspect:FireServer(targetPlayer) end); task.wait(0.1) 
    pcall(function() ManagerRemote:FireServer({ButtonAction = "pull", Inputs = {}}) end)
    pcall(function() if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end; for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
end

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
        if getgenv().AntiStaff then for _, p in ipairs(Players:GetPlayers()) do CheckIfStaff(p) end end
        task.wait(2)
    end
end)

task.spawn(function()
    local realName = LP.Name; local realDisplay = LP.DisplayName; local activeFake = realName
    while true do
        local targetName = realName; local targetDisplay = realDisplay
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

getgenv().BlacklistedLoot = getgenv().BlacklistedLoot or {}
task.spawn(function() 
    while true do 
        if getgenv().AutoCollect then 
            local HitboxFolder = workspace:FindFirstChild("Hitbox")
            local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
            
            if MyHitbox then 
                local pPos = MyHitbox.Position
                local itemsToLoot = {}
                local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
                
                for _, folder in ipairs(TargetFolders) do
                    if folder then
                        for _, obj in ipairs(folder:GetChildren()) do
                            if not getgenv().BlacklistedLoot[obj] then
                                local pos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
                                if pos then table.insert(itemsToLoot, { instance = obj, position = pos, dist = (Vector2.new(pPos.X, pPos.Y) - Vector2.new(pos.X, pos.Y)).Magnitude }) end
                            end
                        end
                    end
                end
                
                if #itemsToLoot > 0 then
                    table.sort(itemsToLoot, function(a, b) return a.dist < b.dist end)
                    for _, itemData in ipairs(itemsToLoot) do
                        if not getgenv().AutoCollect then break end
                        
                        local endX = math.floor(itemData.position.X / getgenv().GridSize + 0.5)
                        local endY = math.floor(itemData.position.Y / getgenv().GridSize + 0.5)
                        
                        if IsTileSolid(endX, endY) then
                            getgenv().BlacklistedLoot[itemData.instance] = true
                        else
                            SmartMoveToExact(itemData.position)
                            task.wait(0.05) 
                        end
                    end
                else
                    task.wait(0.5) 
                end
            end 
        end
        task.wait(0.1) 
    end 
end)
