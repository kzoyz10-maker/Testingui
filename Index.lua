getgenv().HubVersion = "v0.10" 

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
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
AutoLoadTabFromGithub("Auto Farm", "sprout", "Semi Auto Farm", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autofarm.lua")
AutoLoadTabFromGithub("Manager", "briefcase", "Farming Manager", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Manager.lua")
AutoLoadTabFromGithub("Auto PTHT", "tractor", "Plant & Harvest", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autoplant.lua")
AutoLoadTabFromGithub("Auto Collect", "magnet", "Sedot Sampe Peot", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autocollect.lua")
AutoLoadTabFromGithub("Information", "info", "How to use?", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Hrs.lua")

-- ========================================== --
-- [[ TAB DISCORD COMMUNITY ]]
-- ========================================== --
task.spawn(function()
    local InviteCode = "y56q8zuj2r" -- [!] GANTI DENGAN KODE INVITE DISCORD KAMU [!]
    local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true" [cite: 107]

    local ResponseString = "{}"
    pcall(function()
        if request then
            ResponseString = request({
                Url = DiscordAPI,
                Method = "GET",
                Headers = { ["User-Agent"] = "WindUI", ["Accept"] = "application/json" } [cite: 108]
            }).Body
        elseif game:HttpGet then
            ResponseString = game:HttpGet(DiscordAPI)
        end
    end)

    local Response = HttpService:JSONDecode(ResponseString) [cite: 107]

    local DiscordTab = Window:Tab({
        Title = "Discord",
        Icon = "messages-square",
        Desc = "Join Community"
    })

    if Response and Response.guild then [cite: 108]
        DiscordTab:Section({ Title = "Join our Discord Server!", TextSize = 20 }) [cite: 109]
        DiscordTab:Paragraph({
            Title = tostring(Response.guild.name), [cite: 109]
            Desc = tostring(Response.guild.description or "Mari bergabung dengan komunitas kami!"), [cite: 109]
            Image = "https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024", [cite: 109]
            ImageSize = 48, [cite: 110]
            Buttons = {
                {
                    Title = "Copy Link Discord",
                    Icon = "link", [cite: 110]
                    Callback = function()
                        if setclipboard then 
                            setclipboard("https://discord.gg/" .. InviteCode) [cite: 111]
                            WindUI:Notify({ Title = "Discord", Content = "Link berhasil disalin ke Clipboard!" })
                        end
                    end
                }
            }
        })
    else
        DiscordTab:Section({ Title = "Join our Discord Server!", TextSize = 20 })
        DiscordTab:Paragraph({
            Title = "Komunitas Kami",
            Desc = "Klik tombol di bawah untuk menyalin link ke Discord Server kami.",
            Image = "solar:info-circle-bold", [cite: 112]
            Color = "Blue", [cite: 112]
            Buttons = {
                {
                    Title = "Copy Link Discord",
                    Icon = "link", [cite: 113]
                    Callback = function()
                        if setclipboard then 
                            setclipboard("https://discord.gg/" .. InviteCode) [cite: 114]
                            WindUI:Notify({ Title = "Discord", Content = "Link berhasil disalin ke Clipboard!" })
                        end
                    end
                }
            }
        })
    end
end)

-- ========================================== --
-- [[ TAB CONFIGURATION ]]
-- ========================================== --
local ConfigTab = Window:Tab({
    Title = "Configs",
    Icon = "settings-2",
    Desc = "Save / Load Settings"
})

local ConfigManager = Window.ConfigManager [cite: 96]
local ConfigName = "Default" [cite: 96]

local ConfigNameInput = ConfigTab:Input({
    Title = "Config Name",
    Placeholder = "Ketik nama config...",
    Value = ConfigName,
    Callback = function(value)
        ConfigName = value [cite: 96, 97]
    end
})

ConfigTab:Space()

local AllConfigsDropdown = ConfigTab:Dropdown({
    Title = "Available Configs",
    Desc = "Pilih config yang sudah kamu simpan sebelumnya",
    Values = ConfigManager:AllConfigs(), [cite: 98, 99]
    Value = ConfigName,
    Callback = function(value)
        ConfigName = value [cite: 99]
        ConfigNameInput:Set(value) [cite: 99]
    end
})

ConfigTab:Space() [cite: 100]

ConfigTab:Button({
    Title = "Save / Create Config",
    Icon = "save",
    Callback = function()
        Window.CurrentConfig = ConfigManager:Config(ConfigName) [cite: 101]
        if Window.CurrentConfig:Save() then [cite: 101]
            WindUI:Notify({
                Title = "Config Saved", [cite: 101]
                Content = "Berhasil menyimpan config: " .. ConfigName,
                Icon = "check", [cite: 102]
            })
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs()) [cite: 103]
        end
    end
})

ConfigTab:Space() [cite: 103]

ConfigTab:Button({
    Title = "Load Config",
    Icon = "folder-open",
    Callback = function()
        Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName) [cite: 104]
        if Window.CurrentConfig:Load() then [cite: 104]
            WindUI:Notify({
                Title = "Config Loaded", [cite: 104, 105]
                Content = "Berhasil memuat config: " .. ConfigName,
                Icon = "refresh-cw", [cite: 105]
            })
        end
    end
})

ConfigTab:Space()

ConfigTab:Button({
    Title = "Delete Config",
    Icon = "trash",
    Color = Color3.fromHex("#ff4830"), -- Warna Merah [cite: 30]
    Callback = function()
        local configPath = Window.Folder .. "/" .. ConfigName .. ".json"
        
        if isfile and isfile(configPath) and delfile then
            delfile(configPath)
            WindUI:Notify({
                Title = "Config Deleted",
                Content = "Berhasil menghapus config: " .. ConfigName,
                Icon = "trash",
            })
            ConfigNameInput:Set("Default")
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Gagal menghapus! File tidak ditemukan.",
                Icon = "x",
            })
        end
    end
})
