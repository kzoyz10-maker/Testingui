getgenv().HubVersion = "v0.10" 

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- ========================================== --
-- [[ GLOBAL ANTI-AFK ]]
-- ========================================== --
if not getgenv().AntiAfkLoaded then
    getgenv().AntiAfkLoaded = true
    LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
-- ========================================== --

-- [[ LOAD WIND UI ]] --
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Kzoyz HUB " .. getgenv().HubVersion,
    Icon = "worlds", 
    Author = "Koziz",
    Folder = "KzoyzHub", 
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
})

-- Fungsi buat Bikin Tab + Langsung Auto-Load Script dari Github
local function AutoLoadTabFromGithub(TabName, IconName, DescText, LoadLink)
    -- Bikin Tab-nya dulu di WindUI
    local Tab = Window:Tab({
        Title = TabName,
        Icon = IconName,
        Desc = DescText
    })

    -- Langsung download dan jalankan script-nya di background tanpa bikin ngelag
    task.spawn(function()
        local success, scriptCode = pcall(function()
            return game:HttpGet(LoadLink)
        end)
        
        if success and scriptCode then
            local func, compileErr = loadstring(scriptCode)
            
            if func then
                local runSuccess, runErr = pcall(function()
                    func(Tab) -- Lempar variabel Tab ke script Github lu biar UI kerender di situ
                end)
                
                if not runSuccess then
                    WindUI:Notify({ Title = "Error " .. TabName, Content = tostring(runErr), Duration = 5 })
                end
            else
                WindUI:Notify({ Title = "Compile Error " .. TabName, Content = tostring(compileErr), Duration = 5 })
            end
        else
            WindUI:Notify({ Title = "Gagal Memuat " .. TabName, Content = "Link GitHub tidak dapat diakses / bermasalah.", Duration = 5 })
        end
    end)
end

-- ========================================== --
-- [[ LIST TAB & AUTO LOAD MUNCUL SEMUA ]]
-- ========================================== --
WindUI:Notify({ Title = "Kzoyz Hub", Content = "Memuat semua fitur di background...", Duration = 3 })

AutoLoadTabFromGithub("Pabrik", "factory", "Pabrik (Factory)", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Pabrik.lua")
AutoLoadTabFromGithub("Auto Farm", "sprout", "Semi Auto Farm", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Autofarm.lua")
AutoLoadTabFromGithub("Manager", "briefcase", "Farming Manager", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Manager.lua")
AutoLoadTabFromGithub("Auto PTHT", "tractor", "Plant & Harvest", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Autoplant.lua")
AutoLoadTabFromGithub("Auto Collect", "magnet", "Sedot Sampe Peot", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Autocollect.lua")
AutoLoadTabFromGithub("Information", "info", "How to use?", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Hrs.lua")
