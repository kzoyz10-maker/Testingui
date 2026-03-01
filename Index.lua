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
    Icon = "swords", 
    Author = ".Koziz",
    Folder = "KzoyzHub", 
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
})

local LoadedTabs = {}

local function CreateAutoLoadTab(TabName, IconName, DescText, LoadLink)
    -- BIKIN TAB (Di WindUI pakai :Tab, bukan :CreateTab)
    local Tab = Window:Tab({
        Title = TabName,
        Icon = IconName,
        Desc = DescText
    })

    -- BIKIN SECTION (Di WindUI pakai :Section)
    local LoadSection = Tab:Section({ Title = "Module Status", TextXAlignment = "Left" })
    
    -- BIKIN TOMBOL (Di WindUI pakai :Button)
    Tab:Button({
        Title = "Load " .. TabName,
        Desc = "Klik untuk memuat script dari server.",
        Callback = function()
            if LoadedTabs[TabName] then 
                WindUI:Notify({ Title = "Info", Content = "Module " .. TabName .. " sudah dimuat!", Duration = 3 })
                return 
            end

            WindUI:Notify({ Title = "Loading...", Content = "Memuat " .. TabName .. "...", Duration = 2 })
            
            task.spawn(function()
                local scriptCode = game:HttpGet(LoadLink)
                local func, compileErr = loadstring(scriptCode)
                
                if func then
                    local success, runErr = pcall(function()
                        func(Tab) -- Lempar variabel Tab ke script Github lu
                    end)
                    
                    if success then
                        LoadedTabs[TabName] = true
                        WindUI:Notify({ Title = "Sukses", Content = TabName .. " berhasil dimuat!", Duration = 3 })
                    else
                        WindUI:Notify({ Title = "Error", Content = tostring(runErr), Duration = 5 })
                    end
                else
                    WindUI:Notify({ Title = "Error Compile", Content = tostring(compileErr), Duration = 5 })
                end
            end)
        end
    })
end

-- List Tab (Icon pakai Lucide Icons)
CreateAutoLoadTab("Pabrik", "factory", "Pabrik (Factory)", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Pabrik.lua")
CreateAutoLoadTab("Auto Farm", "sprout", "Semi Auto Farm", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autofarm.lua")
CreateAutoLoadTab("Manager", "briefcase", "Farming Manager", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Manager.lua")
CreateAutoLoadTab("Auto PTHT", "tractor", "Plant & Harvest", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autoplant.lua")
CreateAutoLoadTab("Auto Collect", "magnet", "Sedot Sampe Peot", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autocollect.lua")
CreateAutoLoadTab("Information", "info", "How to use?", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Hrs.lua")

WindUI:Notify({ Title = "Kzoyz Hub", Content = "Welcome back bosku! Anti-AFK is active.", Duration = 5 })
