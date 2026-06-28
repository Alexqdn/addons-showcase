if not CLIENT then return end

local heartIcon = Material("hud/health.png", "noclamp smooth")
local armorIcon = Material("hud/armor.png", "noclamp smooth")
local blur = Material("pp/blurscreen")

local math_Clamp = math.Clamp
local math_Round = math.Round
local math_sin = math.sin
local math_abs = math.abs
local math_rad = math.rad
local math_cos = math.cos
local surface_DrawPoly = surface.DrawPoly
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local render_SetScissorRect = render.SetScissorRect
local render_ClearStencil = render.ClearStencil
local render_SetStencilEnable = render.SetStencilEnable
local CurTime = CurTime
local FrameTime = FrameTime
local Lerp = Lerp

local col_bg = Color(10, 10, 12, 180)
local col_bar_bg = Color(0, 0, 0, 160)
local col_text = Color(255, 255, 255, 255)
local col_hp = Color(230, 45, 45, 255)
local col_armor = Color(45, 130, 230, 255)
local col_pulse_hp = Color(255, 50, 50, 255)

local polyCache = {}
local lastX, lastY, lastRadius, lastW, lastH
local function GetRoundedBoxPoly(radius, x, y, w, h)
    if x == lastX and y == lastY and radius == lastRadius and w == lastW and h == lastH then
        return polyCache
    end
    lastX, lastY, lastRadius, lastW, lastH = x, y, radius, w, h
    polyCache = {}
    local segments = 16
    for i = 0, segments do
        local a = math_rad(180 + (i / segments) * 90)
        polyCache[#polyCache + 1] = { x = x + radius + math_cos(a) * radius, y = y + radius + math_sin(a) * radius }
    end
    for i = 0, segments do
        local a = math_rad(270 + (i / segments) * 90)
        polyCache[#polyCache + 1] = { x = x + w - radius + math_cos(a) * radius, y = y + radius + math_sin(a) * radius }
    end
    for i = 0, segments do
        local a = math_rad((i / segments) * 90)
        polyCache[#polyCache + 1] = { x = x + w - radius + math_cos(a) * radius, y = y + h - radius + math_sin(a) * radius }
    end
    for i = 0, segments do
        local a = math_rad(90 + (i / segments) * 90)
        polyCache[#polyCache + 1] = { x = x + radius + math_cos(a) * radius, y = y + h - radius + math_sin(a) * radius }
    end
    return polyCache
end

local function DrawRoundedBoxPoly(radius, x, y, w, h)
    local poly = GetRoundedBoxPoly(radius, x, y, w, h)
    draw.NoTexture()
    surface_DrawPoly(poly)
end

local playerAvatar = nil
local avatarSize = 52 

local function GetPlayerAvatar()
    if not IsValid(playerAvatar) then
        playerAvatar = vgui.Create("AvatarImage")
        playerAvatar:SetSize(avatarSize, avatarSize)
        playerAvatar:SetPaintedManually(true)
        if IsValid(LocalPlayer()) then
            playerAvatar:SetPlayer(LocalPlayer(), 64)
        end
    end
    return playerAvatar
end

local hideHUDElements = { ["CHudHealth"] = true, ["CHudBattery"] = true }
hook.Add("HUDShouldDraw", "CustomRP_HUD_HideDefault", function(name)
    if hideHUDElements[name] then return false end
end)

local function DrawBlur(x, y, w, h, amount)
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

local smoothHealth = 100
local smoothArmor = 0

hook.Add("HUDPaint", "CustomRP_HUD_Main", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local w, h = 250, 72
    local baseX, baseY = 20, ScrH() - h - 20
    local cornerRadius = 12 

    DrawBlur(baseX, baseY, w, h, 5)
    draw_RoundedBox(cornerRadius, baseX, baseY, w, h, col_bg)

    local avatarX, avatarY = baseX + 10, baseY + 10
    local avatarCorner = 12 
    local pAvatar = GetPlayerAvatar() 

    draw_RoundedBox(avatarCorner, avatarX, avatarY, avatarSize, avatarSize, col_bar_bg)

    if IsValid(pAvatar) then
        render_ClearStencil()
        render_SetStencilEnable(true)
        render.SetStencilWriteMask(255)
        render.SetStencilTestMask(255)
        render.SetStencilReferenceValue(1)
        render.SetStencilFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)

        surface_SetDrawColor(255, 255, 255, 255)
        DrawRoundedBoxPoly(avatarCorner, avatarX, avatarY, avatarSize, avatarSize)

        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilPassOperation(STENCILOPERATION_KEEP)

        pAvatar:SetPos(avatarX, avatarY)
        pAvatar:PaintManual()

        render_SetStencilEnable(false)
    end

    local textX = avatarX + avatarSize + 12
    local iconSize = 12
    local barX = textX + iconSize + 8
    local rightMarginX = baseX + w - 12 
    local barW = (rightMarginX - 35) - barX 
    local barH = 6 
    
    draw_SimpleText(ply:Name(), "CustomRP_Font_HUD_Name", textX, baseY + 18, col_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local healthY = baseY + 38
    local maxHP = ply:GetMaxHealth()
    local hp = math_Clamp(ply:Health(), 0, maxHP)
    smoothHealth = Lerp(10 * FrameTime(), smoothHealth, hp)

    if not heartIcon:IsError() then
        surface_SetMaterial(heartIcon)
        surface_SetDrawColor(255, 255, 255, 255)
        surface_DrawTexturedRect(textX, healthY - (iconSize/2), iconSize, iconSize)
    else
        draw_SimpleText("❤", "CustomRP_Font_HUD_Label", textX, healthY, col_hp, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    draw_RoundedBox(3, barX, healthY - (barH/2), barW, barH, col_bar_bg)
    local currentHpColor = col_hp
    if hp <= 20 then
        col_pulse_hp.a = math_abs(math_sin(CurTime() * 8)) * 255
        currentHpColor = col_pulse_hp
    end
    local fillRatioHP = math_Clamp(smoothHealth / maxHP, 0, 1)
    if fillRatioHP > 0 then
        draw_RoundedBox(3, barX, healthY - (barH/2), barW * fillRatioHP, barH, currentHpColor)
    end

    draw_SimpleText(math_Round(smoothHealth) .. "%", "CustomRP_Font_HUD_Label", rightMarginX, healthY, col_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    local armorY = baseY + 54
    local maxArmor = 100
    if ply:Armor() > maxArmor then maxArmor = ply:Armor() end 
    local armor = math_Clamp(ply:Armor(), 0, maxArmor)
    smoothArmor = Lerp(10 * FrameTime(), smoothArmor, armor)

    if not armorIcon:IsError() then
        surface_SetMaterial(armorIcon)
        surface_SetDrawColor(255, 255, 255, 255)
        surface_DrawTexturedRect(textX-.5, armorY - (iconSize/2), iconSize, iconSize)
    else
        draw_SimpleText("⛨", "CustomRP_Font_HUD_Label", textX, armorY, col_armor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    draw_RoundedBox(3, barX, armorY - (barH/2), barW, barH, col_bar_bg)
    local fillRatioArmor = math_Clamp(smoothArmor / maxArmor, 0, 1)
    if fillRatioArmor > 0 then
        draw_RoundedBox(3, barX, armorY - (barH/2), barW * fillRatioArmor, barH, col_armor)
    end

    draw_SimpleText(math_Round(smoothArmor) .. "%", "CustomRP_Font_HUD_Label", rightMarginX, armorY, col_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end)
