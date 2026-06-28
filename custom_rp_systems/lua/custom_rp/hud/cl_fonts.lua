if not CLIENT then return end

local function F(name, size, weight, italic)
    surface.CreateFont(name, {
        font      = "Montserrat",
        size      = size,
        weight    = weight or 600,
        italic    = italic or false,
        antialias = true,
    })
end

F("CustomRP_Font_HUD_Name",  18, 700)
F("CustomRP_Font_HUD_Label", 15, 700)

F("CustomRP_Font_Notify", 16, 1000)

F("CustomRP_Font_SB_Title",  28, 800)
F("CustomRP_Font_SB_Sub",    14, 600)
F("CustomRP_Font_SB_Header", 12, 700)
F("CustomRP_Font_SB_Row",    15, 600)
F("CustomRP_Font_SB_Rank",   12, 800)

F("CustomRP_Font_WeaponSlot", 22, 800)
F("CustomRP_Font_Weapon",     16, 700)

F("CustomRP_Font_ATM_Title",    28, 800)
F("CustomRP_Font_ATM_Subtitle", 22, 700)
F("CustomRP_Font_ATM_Body",     18, 600)
F("CustomRP_Font_ATM_Small",    14, 500)
F("CustomRP_Font_ATM_Stat",     32, 800)
F("CustomRP_Font_ATM_Boot",     26, 700)
F("CustomRP_Font_ATM_Input",    20, 600)
F("CustomRP_Font_ATM_Btn",      18, 700)
F("CustomRP_Font_ATM_Notif",    16, 600)
F("CustomRP_Font_ATM_Player",   16, 600)
F("CustomRP_Font_ATM_PlayerJob",13, 500)

F("CustomRP_Font_ATM_3D2D_Title", 64, 800)
F("CustomRP_Font_ATM_3D2D_Sub",   32, 600)

F("CustomRP_Font_Chat",       18, 600)
F("CustomRP_Font_ChatBold",   18, 800)
F("CustomRP_Font_ChatItalic", 18, 600, true)
F("CustomRP_Font_ChatTab",    14, 800)
F("CustomRP_Font_ChatMenu",   15, 600)

F("CustomRP_Font_OverheadName", 15, 700)
F("CustomRP_Font_OverheadJob",  12, 600)
