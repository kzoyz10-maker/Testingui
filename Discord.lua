local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then return end

local InviteCode = "y56q8zuj2r" -- GANTI INI AJA

Tab:Section({ Title = "Join our Discord Server!", TextSize = 20 })
Tab:Paragraph({
    Title = "Kzoyz Community",
    Desc = "Mari bergabung dengan komunitas kami untuk mendapatkan update terbaru, diskusi, dan report bug!",
    Image = "messages-square",
    ImageSize = 48,
    Buttons = {
        {
            Title = "Copy Link Discord",
            Icon = "link",
            Callback = function()
                if setclipboard then 
                    setclipboard("[https://discord.gg/](https://discord.gg/)" .. InviteCode)
                    if WindUI then 
                        WindUI:Notify({ Title = "Discord", Content = "Link berhasil disalin ke Clipboard!", Icon = "check" }) 
                    end
                end
            end
        }
    }
})
