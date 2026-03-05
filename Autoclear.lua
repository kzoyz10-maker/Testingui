local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Clear v8.0 - TRUE A* PATHFINDING & LOCK BYPASS" 

-- ========================================== --
-- [[ DEFAULT SETTINGS ]]
-- ========================================== --
getgenv().EnableAutoClear = getgenv().EnableAutoClear or false
getgenv().ClearDelay = getgenv().ClearDelay or 0.15 
getgenv().HitCount = getgenv().HitCount or 3
getgenv().WalkSpeed = getgenv().WalkSpeed or 16
getgenv().GridSize = 4.5

-- ========================================== --
-- [[ SERVICES & MANAGERS ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

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
                        PlayerMovement.VelocityX = 0
                        PlayerMovement.VelocityY = 0
                        PlayerMovement.Grounded = true 
                    end)
                end
            end)
        end
    else
        if ModflyConnection then
            ModflyConnection:Disconnect()
            ModflyConnection = nil
        end
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
    end
end

-- ========================================== --
-- [[ DETEKSI TILE (RADAR PINTAR) ]]
-- ========================================== --
local function IsTileEmpty(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        if not nameStr:find("bg") and not nameStr:find("background") and not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("door") then
            return false -- Ada blok padat (Dirt, Bedrock, Lock, dll)
        end
    end
    return true
end

local function IsTileBreakable(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return false end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    local hasBreakable = false
    local isUnbreakableTile = false 
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        
        -- [!] HAK VETO UNTUK BEDROCK, LOCK, DAN AREA
        if nameStr:find("bedrock") or nameStr:find("lock") or nameStr:find("area") then 
            isUnbreakableTile = true 
        end
        
        if not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("door") and not nameStr:find("bedrock") and not nameStr:find("lock") and not nameStr:find("area") and nameStr ~= "0" then
            hasBreakable = true
        end
    end
    
    if isUnbreakableTile then return false end
    return hasBreakable
end

local function GetNextExposedBlock()
    -- Scan dari atas ke bawah
    for y = 100, 0, -1 do 
        local isEven = (y % 2 == 0)
        local startX = isEven and 0 or 100
        local endX = isEven and 100 or 0
        local step = isEven and 1 or -1
        
        for x = startX, endX, step do
            if IsTileBreakable(x, y) then
                if IsTileEmpty(x, y + 1) then return x, y, "top" end
                if IsTileEmpty(x - 1, y) then return x, y, "left" end
                if IsTileEmpty(x + 1, y) then return x, y, "right" end
            end
        end
    end
    return nil, nil, nil
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
        if iterations > 3000 then break end -- Cegah lag jika jalan buntu murni
        
        -- Cari node paling efisien
        local current, currentIndex = openSet[1], 1
        for i = 2, #openSet do
            if fScore[openSet[i].key] < fScore[current.key] then
                current = openSet[i]; currentIndex = i
            end
        end
        
        -- Kalau sampai di tujuan, buat rutenya
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
        
        -- Cek atas, bawah, kiri, kanan
        local neighbors = { {x=current.x+1, y=current.y}, {x=current.x-1, y=current.y}, {x=current.x, y=current.y+1}, {x=current.x, y=current.y-1} }
        for _, n in ipairs(neighbors) do
            local nKey = n.x .. "," .. n.y
            if n.x >= 0 and n.x <= 100 and n.y >= 0 and n.y <= 100 and not closedSet[nKey] then
                -- Bisa dilewati JIKA kosong ATAU jika itu titik tujuan akhirnya
                if IsTileEmpty(n.x, n.y) or (n.x == endX and n.y == endY) then
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
    return nil -- Rute buntu total
end

-- ========================================== --
-- [[ FUNGSI MOVEMENT EXECUTOR ]]
-- ========================================== --
local function MoveToPoint(startP, endP)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local distance = (startP - endP).Magnitude
    if distance < 0.5 then return end

    local walkTime = distance / getgenv().WalkSpeed
    local steps = math.floor(walkTime * 45) 
    if steps < 1 then steps = 1 end
    
    for i = 1, steps do
        if not getgenv().EnableAutoClear then break end
        local alpha = i / steps
        local currentLerp = startP:Lerp(endP, alpha)
        
        if PlayerMovement then
            PlayerMovement.Position = currentLerp
        elseif hrp then
            hrp.CFrame = CFrame.new(currentLerp)
        end
        task.wait(1/45)
    end
end

local function FollowAStarPath(path, currZ)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local startPos = (PlayerMovement and PlayerMovement.Position) or (hrp and hrp.Position)
    
    for _, node in ipairs(path) do
        if not getgenv().EnableAutoClear then break end
        local targetPos = Vector3.new(node.x * getgenv().GridSize, node.y * getgenv().GridSize, currZ)
        MoveToPoint(startPos, targetPos)
        startPos = targetPos
    end
    if getgenv().EnableAutoClear and PlayerMovement then PlayerMovement.Position = startPos end
end

-- ========================================== --
-- [[ UI SECTION ]]
-- ========================================== --
local SecClear = Tab:Section({ Title = "🧨 Auto Clear (V8 A* Smart Walk)", Box = true, Opened = true })

SecClear:Toggle({ 
    Title = "▶ START AUTO CLEAR", 
    Default = getgenv().EnableAutoClear, 
    Callback = function(v) 
        getgenv().EnableAutoClear = v 
        SetModflyState(v)
    end 
})

SecClear:Input({ Title = "Walk Speed", Value = tostring(getgenv().WalkSpeed), Placeholder = "16", Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })
SecClear:Input({ Title = "Break Delay", Value = tostring(getgenv().ClearDelay), Placeholder = "0.15", Callback = function(v) getgenv().ClearDelay = tonumber(v) or getgenv().ClearDelay end })
SecClear:Input({ Title = "Hit Count", Value = tostring(getgenv().HitCount), Placeholder = "3", Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end })

-- ========================================== --
-- [[ LOGIKA UTAMA ]]
-- ========================================== --
task.spawn(function()
    while true do
        if getgenv().EnableAutoClear then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local currZ = hrp.Position.Z
                local targetX, targetY, safeSide = GetNextExposedBlock()
                
                if targetX and targetY then
                    -- Tentukan titik berdiri yang paling aman
                    local standX, standY = targetX, targetY
                    if safeSide == "top" then standY = targetY + 1
                    elseif safeSide == "left" then standX = targetX - 1
                    elseif safeSide == "right" then standX = targetX + 1
                    end
                    
                    local startPos = (PlayerMovement and PlayerMovement.Position) or hrp.Position
                    local myGridX = math.floor((startPos.X / getgenv().GridSize) + 0.5)
                    local myGridY = math.floor((startPos.Y / getgenv().GridSize) + 0.5)
                    local targetPos = Vector3.new(standX * getgenv().GridSize, standY * getgenv().GridSize, currZ)
                    
                    -- [!] EKSEKUSI A* PATHFINDING
                    local path = FindPathAStar(myGridX, myGridY, standX, standY)
                    
                    if path and #path > 0 then
                        FollowAStarPath(path, currZ) -- Jalan ngikutin grid layaknya maze/labirin
                    else
                        -- Fallback kalau misal rute buntu (misal kehalang lock dari segala arah)
                        MoveToPoint(startPos, targetPos) 
                    end
                    
                    if not getgenv().EnableAutoClear then continue end
                    
                    -- Pukul
                    for i = 1, getgenv().HitCount do
                        if not getgenv().EnableAutoClear then break end
                        local breakTarget = Vector2.new(targetX, targetY)
                        pcall(function()
                            if RemoteBreak:IsA("RemoteEvent") then 
                                RemoteBreak:FireServer(breakTarget, tick()) 
                            else 
                                RemoteBreak:InvokeServer(breakTarget, tick()) 
                            end
                        end)
                        task.wait(getgenv().ClearDelay)
                    end
                else
                    getgenv().EnableAutoClear = false
                    SetModflyState(false) 
                    WindUI:Notify({ Title = "Selesai", Content = "World sudah bersih! (Semua halangan & lock terhindari)", Duration = 5 })
                end
            end
        end
        task.wait(0.1)
    end
end)
