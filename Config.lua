local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module must be loaded from Kzoyz Index!") return end

-- ==========================================
-- SETUP VARIABLES & SERVICES
-- ==========================================
local RS = game:GetService("ReplicatedStorage")
local queue_on_tp = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or getgenv().queue_on_teleport

local ConfigManager = Window.ConfigManager
local ConfigName = "Default"

getgenv().TargetWarpWorld = getgenv().TargetWarpWorld or "buy"
getgenv().EnableAutoWarp = getgenv().EnableAutoWarp or false
getgenv().CancelWarp = false -- Emergency variable to cancel warping

-- ==========================================
-- AUTO-LOAD SYSTEM (READING FILE)
-- ==========================================
local autoLoadPath = "WindUI/KzoyzHub/AutoLoad.txt"

local function GetAutoLoad()
    if isfile and isfile(autoLoadPath) and readfile then
        local saved = readfile(autoLoadPath)
        if saved and saved ~= "" then return saved end
    end
    return "None"
end

local function SetAutoLoad(name)
    if writefile then writefile(autoLoadPath, name) end
end

-- ==========================================
-- MAIN FUNCTION FOR WARP
-- ==========================================
local function ExecuteWarp()
    task.spawn(function()
        local targetWorld = getgenv().TargetWarpWorld
        if not targetWorld or targetWorld == "" then
            warn("World name is still empty!")
            return
        end

        local TpRemote = RS:FindFirstChild("tp")

        if TpRemote then
            print("Attempting to Warp to: " .. targetWorld)
            if WindUI then WindUI:Notify({ Title = "Warping", Content = "Warping directly to: " .. targetWorld, Icon = "plane" }) end
            pcall(function() TpRemote:FireServer(targetWorld) end)
        else
            print("Currently in a World! Preparing Auto-Warp for Lobby...")
            if WindUI then WindUI:Notify({ Title = "Auto-Warp", Content = "Exiting world... Auto-warp prepared!", Icon = "loader" }) end
            
            if queue_on_tp then
                local autoWarpScript = string.format([[
                    task.spawn(function()
                        local target = "%s"
                        local RS = game:GetService("ReplicatedStorage")
                        local tpRemote = RS:WaitForChild("tp", 15)
                        
                        if tpRemote then
                            task.wait(0.5) 
                            tpRemote:FireServer(target)
                        end
                    end)
                ]], targetWorld)
                queue_on_tp(autoWarpScript)
            end

            local exitRemote = RS:WaitForChild("Remotes"):FindFirstChild("RequestPlayerExitWorld")
            if exitRemote then pcall(function() exitRemote:InvokeServer() end) end
        end
    end)
end

-- ==========================================
-- UI: WORLD SELECTION & TELEPORT (ADVANCED)
-- ==========================================
Tab:Divider({ Title = "Teleport / Warp World" })

Tab:Input({
    Title = "World Name",
    Flag = "TargetWarp_ConfigFlag", 
    Placeholder = "Example: buy, world2...",
    Value = getgenv().TargetWarpWorld,
    Callback = function(value)
        getgenv().TargetWarpWorld = value
    end
})

Tab:Toggle({
    Title = "Allow Auto-Warp on Script Start",
    Desc = "Check this if you want to automatically warp when joining a server/executing",
    Flag = "EnableAutoWarp_ConfigFlag",
    Value = getgenv().EnableAutoWarp,
    Callback = function(value)
        getgenv().EnableAutoWarp = value
    end
})

Tab:Space()

Tab:Button({
    Title = " Warp Now! (Manual)",
    Callback = function()
        ExecuteWarp()
    end
})

Tab:Button({
    Title = "🛑 Cancel AutoWarp",
    Desc = "Press this quickly if the script is counting down to warp!",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        getgenv().CancelWarp = true
        if WindUI then
            WindUI:Notify({
                Title = "CANCELLED",
                Content = "Auto-warp successfully stopped!",
                Icon = "x-circle",
            })
        end
    end
})

-- ==========================================
-- UI: CONFIG MANAGEMENT
-- ==========================================
Tab:Divider({ Title = "Config Management" })

local ConfigNameInput = Tab:Input({
    Title = "Config Name",
    Placeholder = "Type config name...",
    Value = ConfigName,
    Callback = function(value) ConfigName = value end
})

local AllConfigsDropdown = Tab:Dropdown({
    Title = "Available Configs",
    Values = ConfigManager:AllConfigs(),
    Value = ConfigName,
    Callback = function(value)
        ConfigName = value
        ConfigNameInput:Set(value)
    end
})

Tab:Button({
    Title = "Save / Create Config",
    Icon = "save",
    Callback = function()
        Window.CurrentConfig = ConfigManager:Config(ConfigName)
        if Window.CurrentConfig:Save() then
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            if _G.AutoLoadDropdown then
                local updatedConfigs = ConfigManager:AllConfigs()
                table.insert(updatedConfigs, 1, "None")
                _G.AutoLoadDropdown:Refresh(updatedConfigs)
            end
            if WindUI then WindUI:Notify({ Title = "Config Saved", Content = "Saved: " .. ConfigName, Icon = "check" }) end
        end
    end
})

Tab:Button({
    Title = "Load Config",
    Icon = "folder-open",
    Callback = function()
        Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
        Window.CurrentConfig:Load()
    end
})

Tab:Button({
    Title = "Delete Config",
    Icon = "trash",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        local configPath = "WindUI/KzoyzHub/config/" .. ConfigName .. ".json"
        if isfile and isfile(configPath) and delfile then
            delfile(configPath)
            ConfigName = "Default"
            ConfigNameInput:Set("Default")
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            if _G.AutoLoadDropdown then
                local updatedConfigs = ConfigManager:AllConfigs()
                table.insert(updatedConfigs, 1, "None")
                _G.AutoLoadDropdown:Refresh(updatedConfigs)
            end
        end
    end
})

-- ==========================================
-- UI: AUTO-EXECUTE SETTINGS
-- ==========================================
Tab:Divider({ Title = "Auto-Execute" })

local currentAutoLoad = GetAutoLoad()
local configListForAuto = ConfigManager:AllConfigs()
table.insert(configListForAuto, 1, "None") 

_G.AutoLoadDropdown = Tab:Dropdown({
    Title = "Set Auto-Load Config",
    Values = configListForAuto,
    Value = currentAutoLoad,
    Callback = function(value)
        SetAutoLoad(value)
    end
})

-- ==========================================
-- AUTO-LOAD EXECUTION ON SCRIPT START
-- ==========================================
task.spawn(function()
    task.wait(1.5) 
    local autoConfig = GetAutoLoad()
    
    if autoConfig ~= "None" then
        local checkPath = "WindUI/KzoyzHub/config/" .. autoConfig .. ".json"
        if isfile and isfile(checkPath) then
            Window.CurrentConfig = ConfigManager:CreateConfig(autoConfig)
            
            if Window.CurrentConfig:Load() then
                ConfigName = autoConfig
                ConfigNameInput:Set(autoConfig)
                
                task.wait(1) -- Wait for UI to adjust values
                
                -- CHECK IF AUTO-WARP TOGGLE IS CHECKED
                if getgenv().EnableAutoWarp then
                    getgenv().CancelWarp = false -- Reset cancel status
                    
                    if WindUI then
                        WindUI:Notify({
                            Title = "WARNING!",
                            Content = "Auto-Warp will execute in 5 SECONDS! Press 'Cancel' to stop.",
                            Icon = "alert-triangle",
                            Duration = 5
                        })
                    end
                    
                    -- 5-second countdown, constantly checking if Cancel button is pressed
                    for i = 5, 1, -1 do
                        if getgenv().CancelWarp then break end
                        task.wait(1)
                    end
                    
                    -- If not cancelled after 5 seconds, execute!
                    if not getgenv().CancelWarp then
                        ExecuteWarp()
                    end
                else
                    print("Auto-Load finished, but Auto-Warp is off. Waiting for manual command.")
                end
            end
        end
    end
end)
