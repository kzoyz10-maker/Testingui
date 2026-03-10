getgenv().HubVersion = "v0.12" 

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
    Title = "Kzoyz HUB FREE SCRIPT" .. getgenv().HubVersion,
    Icon = "globe", 
    Author = "FREE SCRIPT DO NOT SELL THIS SCRIPT!",
    Folder = "KzoyzHub", 
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
    
    -- [!] INI DIA RAHASIANYA BIAR GAK HILANG DI PC
    OpenButton = {
        Title = "Kzoyz HUB", 
        CornerRadius = UDim.new(1, 0), 
        StrokeThickness = 3,
        Enabled = true, 
        Draggable = true, 
        OnlyMobile = false, 
        Scale = 1,
        Color = ColorSequence.new(
            Color3.fromHex("#FFD700"), 
            Color3.fromHex("#FFA500")  
        )
    }
})

-- ========================================== --
-- [[ SISTEM ANTREAN LOAD GITHUB (ANTI-GAGAL) ]]
-- ========================================== --
local LoadQueue = {}

local function RegisterTab(TabName, IconName, DescText, LoadLink)
    -- Bikin tab-nya dulu di UI biar langsung muncul
    local Tab = Window:Tab({
        Title = TabName,
        Icon = IconName,
        Desc = DescText
    })
    
    -- Masukkan ke antrean download
    table.insert(LoadQueue, {
        Tab = Tab,
        TabName = TabName,
        LoadLink = LoadLink
    })
end

-- ========================================== --
-- [[ LIST TAB KAMU ]]
-- ========================================== --
RegisterTab("Pabrik", "factory", "Pabrik (Factory)", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Pabrik.lua")
RegisterTab("Auto Farm", "sprout", "Semi Auto Farm", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autofarm.lua")
RegisterTab("Manager", "briefcase", "Farming Manager", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Manager.lua")
RegisterTab("Auto PTHT", "tractor", "Plant & Harvest", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autoplant.lua")
RegisterTab("Auto Clear World", "globe", "Clear All Blocks", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autoclear.lua")
RegisterTab("Auto Build Farm", "map", "Build Your Farm", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autobuild.lua")
RegisterTab("Growscan", "monitor", "Sedot Sampe Peot", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autocollect.lua")
RegisterTab("Discord", "messages-square", "Join Community", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Discord.lua")
RegisterTab("Configs", "settings-2", "Save / Load Settings", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Config.lua")

-- ========================================== --
-- [[ EKSEKUSI ANTREAN SECARA BERTAHAP ]]
-- ========================================== --
task.spawn(function()
    for _, data in ipairs(LoadQueue) do
        local success, scriptCode = pcall(function()
            return game:HttpGet(data.LoadLink)
        end)
        
        if success and scriptCode then
            local func, compileErr = loadstring(scriptCode)
            
            if func then
                local runSuccess, runErr = pcall(function()
                    func(data.Tab, Window, WindUI) 
                end)
                
                if not runSuccess then
                    WindUI:Notify({ Title = "Error " .. data.TabName, Content = tostring(runErr), Duration = 5 })
                end
            else
                WindUI:Notify({ Title = "Compile Error " .. data.TabName, Content = tostring(compileErr), Duration = 5 })
            end
        else
            WindUI:Notify({ Title = "Gagal Memuat " .. data.TabName, Content = "Link GitHub gagal diakses.", Duration = 5 })
        end
        
        -- [!] INI KUNCINYA: Jeda 0.5 detik antar download biar GitHub & Executor gak kaget
        task.wait(0.5) 
    end
    
    WindUI:Notify({ Title = "Berhasil!", Content = "Semua Tab berhasil dimuat.", Duration = 3 })
end)
