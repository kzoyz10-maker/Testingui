getgenv().HubVersion = "v0.10" 

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- ========================================== --
-- [[ GLOBAL ANTI-AFK (MENCEGAH KICK 20 MENIT) ]]
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
-- Pakai source asli WindUI (bukan example, tapi main sourcenya)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Kzoyz HUB " .. getgenv().HubVersion,
    Icon = "lucide-swords", -- Icon judul
    Author = ".Koziz",
    Folder = "KzoyzHub", -- Folder buat nyimpen config
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
})

-- Biar pas tab diklik, module dari GitHub langsung di-load (kalau belum di-load)
local LoadedTabs = {}

local function CreateAutoLoadTab(TabName, IconName, DescText, LoadLink)
    -- Bikin Tab-nya di WindUI
    local Tab = Window:CreateTab({
        Title = TabName,
        Icon = IconName,
        Desc = DescText
    })

    -- Bikin section / tombol buat nge-load module
    local LoadSection = Tab:CreateSection({ Title = "Module Status", TextYAlignment = "Center" })
    
    local LoadBtn
    LoadBtn = Tab:CreateButton({
        Title = "Load " .. TabName,
        Desc = "Klik untuk memuat script dari server.",
        Callback = function()
            if LoadedTabs[TabName] then 
                WindUI:Notify({ Title = "Info", Content = "Module " .. TabName .. " sudah dimuat!", Duration = 3 })
                return 
            end

            WindUI:Notify({ Title = "Loading...", Content = "Memuat " .. TabName .. ", tunggu sebentar.", Duration = 2 })
            
            task.spawn(function()
                local scriptCode = game:HttpGet(LoadLink)
                local func, compileErr = loadstring(scriptCode)
                
                if func then
                    local success, runErr = pcall(function()
                        -- [PENTING] Ngirim Tab object ke script GitHub lu
                        func(Tab) 
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

-- Bikin list Tab (Pilih icon dari Lucide Icons yang disupport WindUI)
CreateAutoLoadTab("Pabrik", "lucide-factory", "Pabrik (Factory)", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Pabrik.lua")
CreateAutoLoadTab("Auto Farm", "lucide-sprout", "Semi Auto Farm", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Autofarm.lua")
CreateAutoLoadTab("Manager", "lucide-briefcase", "Farming Manager", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Manager.lua")
CreateAutoLoadTab("Auto PTHT", "lucide-tractor", "Plant & Harvest", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Autoplant.lua")
CreateAutoLoadTab("Auto Collect", "lucide-magnet", "Sedot Sampe Peot", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Autocollect.lua")
CreateAutoLoadTab("Information", "lucide-info", "How to use?", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Hrs.lua")

-- Notif awal pas inject
WindUI:Notify({
    Title = "Kzoyz Hub Injected",
    Content = "Welcome back bosku! Anti-AFK is active.",
    Duration = 5,
})
