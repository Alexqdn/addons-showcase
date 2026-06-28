if not CLIENT then return end

local blur = Material("pp/blurscreen")
local col_bg = Color(10, 10, 12, 180)
local col_text = Color(255, 255, 255, 255)
local col_line_accent = Color(0, 0, 0, 100)

local table_insert = table.insert
local table_remove = table.remove
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local render_SetScissorRect = render.SetScissorRect
local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local CurTime = CurTime
local FrameTime = FrameTime
local Lerp = Lerp
local ScrW = ScrW
local ScrH = ScrH

local NotifyColors = {
    [NOTIFY_GENERIC] = Color(45, 230, 100, 255),
    [NOTIFY_ERROR]   = Color(230, 45, 45, 255),
    [NOTIFY_UNDO]    = Color(230, 130, 45, 255),
    [NOTIFY_HINT]    = Color(45, 130, 230, 255),
    [NOTIFY_CLEANUP] = Color(230, 200, 45, 255)
}

local notificationsList = {}

function notification.AddLegacy(text, type, length)
    surface.SetFont("CustomRP_Font_Notify")
    local textW, textH = surface_GetTextSize(text)
    
    local notif = {
        text = text,
        type = type or NOTIFY_GENERIC,
        length = length or 3,
        startTime = CurTime(),
        w = textW + 45,
        h = 36,
        x = ScrW() + 10,
        y = ScrH()
    }
    
    table_insert(notificationsList, 1, notif)
end

hook.Add("DrawDeathNotice", "CustomRP_Notify_HideDefault", function() return false end)

local function DrawBlurNotify(x, y, w, h, amount)
    surface_SetDrawColor(255, 255, 255)
    surface_SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * amount)
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        render_SetScissorRect(x, y, x + w, y + h, true)
        surface_DrawTexturedRect(0, 0, ScrW(), ScrH())
        render_SetScissorRect(0, 0, 0, 0, false)
    end
end

hook.Add("HUDPaint", "CustomRP_Notify_Draw", function()
    if #notificationsList == 0 then return end

    local spacing = 8
    local startY = ScrH() - 110

    for i = #notificationsList, 1, -1 do
        local notif = notificationsList[i]
        local timeAlive = CurTime() - notif.startTime
        local targetX = ScrW() - notif.w - 20
        
        if timeAlive > notif.length then
            targetX = ScrW() + 10
            if notif.x > ScrW() then
                table_remove(notificationsList, i)
                continue
            end
        end

        notif.x = Lerp(12 * FrameTime(), notif.x, targetX)
        if not notif.targetY then notif.y = startY end
        notif.targetY = startY
        notif.y = Lerp(12 * FrameTime(), notif.y, notif.targetY)

        local x, y, w, h = notif.x, notif.y, notif.w, notif.h
        local cornerRadius = 6

        DrawBlurNotify(x, y, w, h, 4)
        draw_RoundedBox(cornerRadius, x, y, w, h, col_bg)

        local barColor = NotifyColors[notif.type] or col_text
        render_SetScissorRect(x, y, x + 6, y + h, true)
        draw_RoundedBox(cornerRadius, x, y, w, h, barColor)
        render_SetScissorRect(0, 0, 0, 0, false)
        
        draw_RoundedBox(0, x + 4, y, 2, h, col_line_accent)

        draw_SimpleText(notif.text, "CustomRP_Font_Notify", x + 18, y + (h/2), col_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        startY = startY - h - spacing
    end
end)
