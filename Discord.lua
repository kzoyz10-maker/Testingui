local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then return end

local HttpService = game:GetService("HttpService")
local InviteCode = "ISI_DENGAN_KODE_INVITE_KAMU" -- Ganti dengan kode invite Discord kamu

local Response = nil

pcall(function()
    local DiscordAPI = "[https://discord.com/api/v10/invites/](https://discord.com/api/v10/invites/)" .. InviteCode .. "?with_counts=true"
    local ResponseString = ""
    
    if type(request) == "function" then
        local req = request({
            Url = DiscordAPI,
            Method = "GET"
        })
        if req and req.Body then
            ResponseString = req.Body
        end
    elseif type(game.HttpGet) == "function" then
        ResponseString = game:HttpGet(DiscordAPI)
    end

    if ResponseString and ResponseString ~= "" then
        Response = HttpService:JSONDecode(ResponseString)
    end
end)

if Response and Response.guild then
    Tab:Section({ Title = "Join our Discord Server!", TextSize = 20 })
    Tab:Paragraph({
        Title = tostring(Response.guild.name),
        Desc = tostring(Response.guild.description or "Mari bergabung dengan komunitas kami!"),
        Image = "[https://cdn.discordapp.com/icons/](https://cdn.discordapp.com/icons/)" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024",
        ImageSize = 48,
        Buttons = {
            {
                Title = "Copy Link Discord",
                Icon = "link",
                Callback = function()
                    if setclipboard then 
                        setclipboard("[https://discord.gg/](https://discord.gg/)" .. InviteCode)
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
                        setclipboard("[https://discord.gg/](https://discord.gg/)" .. InviteCode)
                        if WindUI then WindUI:Notify({ Title = "Discord", Content = "Link berhasil disalin ke Clipboard!" }) end
                    end
                end
            }
        }
    })
end
