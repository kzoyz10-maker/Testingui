local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index!") return end

local HttpService = game:GetService("HttpService")
local InviteCode = "y56q8zuj2r" -- [!] GANTI DENGAN KODE INVITE DISCORD KAMU [!]
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

local ResponseString = ""
local success, err = pcall(function()
    if request then
        ResponseString = request({
            Url = DiscordAPI,
            Method = "GET",
            Headers = { ["User-Agent"] = "WindUI", ["Accept"] = "application/json" }
        }).Body
    elseif game:HttpGet then
        ResponseString = game:HttpGet(DiscordAPI)
    end
end)

-- Pengecekan Aman (Safe Decode)
local Response = nil
if success and type(ResponseString) == "string" and ResponseString ~= "" then
    pcall(function()
        Response = HttpService:JSONDecode(ResponseString)
    end)
end

if Response and Response.guild then
    Tab:Section({ Title = "Join our Discord Server!", TextSize = 20 })
    Tab:Paragraph({
        Title = tostring(Response.guild.name),
        Desc = tostring(Response.guild.description or "Mari bergabung dengan komunitas kami!"),
        Image = "https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024",
        ImageSize = 48,
        Buttons = {
            {
                Title = "Copy Link Discord",
                Icon = "link",
                Callback = function()
                    if setclipboard then 
                        setclipboard("https://discord.gg/" .. InviteCode)
                        if WindUI then WindUI:Notify({ Title = "Discord", Content = "Link berhasil disalin ke Clipboard!" }) end
                    end
                end
            }
        }
    })
else
    Tab:Section({ Title = "Join our Discord Server!", TextSize = 20 })
    Tab:Paragraph({
        Title = "Komunitas Kami",
        Desc = "Klik tombol di bawah untuk menyalin link ke Discord Server kami.",
        Image = "solar:info-circle-bold",
        Color = "Blue",
        Buttons = {
            {
                Title = "Copy Link Discord",
                Icon = "link",
                Callback = function()
                    if setclipboard then 
                        setclipboard("https://discord.gg/" .. InviteCode)
                        if WindUI then WindUI:Notify({ Title = "Discord", Content = "Link berhasil disalin ke Clipboard!" }) end
                    end
                end
            }
        }
    })
end
