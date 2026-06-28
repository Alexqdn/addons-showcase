if not CLIENT then return end

local blur = Material("pp/blurscreen")
local col_bg = Color(10, 10, 12, 170)
local col_accent = Color(230, 45, 45, 255) 

local math_Clamp = math.Clamp
local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawPoly = surface.DrawPoly
local render_SetScissorRect = render.SetScissorRect
local CurTime = CurTime
local FrameTime = FrameTime
local Lerp = Lerp

local showSelector = false
local selectorAlpha = 0
local hideTime = 0

local currentSlot = 1
local currentIndex = 1
local wepSlots = {} 
local maxSlots = 6

local smoothX, smoothY = 0, 0
local colOffsets = {0, 0, 0, 0, 0, 0}

local col_head_bg = Color(10, 10, 12, 220)
local col_head_accent = Color(230, 45, 45, 255)
local col_head_txt_active = Color(255, 255, 255, 255)
local col_head_txt_inactive = Color(100, 100, 100, 150)
local col_wep_bg = Color(10, 10, 12, 180)
local col_wep_txt_active = Color(255, 255, 255, 255)
local col_wep_txt_inactive = Color(120, 120, 120, 180)
local col_neon = Color(230, 45, 45, 255)
local col_cursor = Color(230, 45, 45, 40)
local col_cursor_edge = Color(230, 45, 45, 255)
local col_shine = Color(255, 255, 255, 35)

local shinePoly = {
    {x = 0, y = 0},
    {x = 0, y = 0},
    {x = 0, y = 0},
    {x = 0, y = 0}
}

hook.Add("HUDShouldDraw", "CustomRP_Weapon_HideDefault", function(name)
    if name == "CHudWeaponSelection" then return false end
end)

local function UpdateWeaponList()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    wepSlots = {}
    for i = 1, maxSlots do wepSlots[i] = {} end

    local weps = ply:GetWeapons()
    for i = 1, #weps do
        local wep = weps[i]
        local slot = wep:GetSlot() + 1 
        if slot >= 1 and slot <= maxSlots then
            table.insert(wepSlots[slot], wep)
        end
    end

    for i = 1, maxSlots do
        table.sort(wepSlots[i], function(a, b)
            return a:GetSlotPos() < b:GetSlotPos()
        end)
    end
end

local function GetNextValidSlot(startSlot, dir)
    local s = startSlot
    for i = 1, maxSlots do
        s = s + dir
        if s > maxSlots then s = 1 end
        if s < 1 then s = maxSlots end
        if #wepSlots[s] > 0 then return s end
    end
    return startSlot
end

hook.Add("PlayerBindPress", "CustomRP_Weapon_Select", function(ply, bind, pressed)
    if not pressed then return end

    if bind:match("slot(%d)") then
        local slotNum = tonumber(bind:match("slot(%d)"))
        UpdateWeaponList()
        if slotNum and slotNum >= 1 and slotNum <= maxSlots and #wepSlots[slotNum] > 0 then
            if not showSelector then
                showSelector = true; currentSlot = slotNum; currentIndex = 1
            else
                if currentSlot == slotNum then
                    currentIndex = currentIndex + 1
                    if currentIndex > #wepSlots[currentSlot] then currentIndex = 1 end
                else
                    currentSlot = slotNum; currentIndex = 1
                end
            end
            hideTime = CurTime() + 3
            surface.PlaySound("garrysmod/ui_hover.wav")
            return true
        end
    end

    if bind:find("invnext") then 
        UpdateWeaponList()
        if not showSelector then
            showSelector = true
            local active = ply:GetActiveWeapon()
            currentSlot = (IsValid(active) and active:GetSlot() + 1) or 1
            if #wepSlots[currentSlot] == 0 then currentSlot = GetNextValidSlot(currentSlot, 1) end
            currentIndex = 1
        else
            currentIndex = currentIndex + 1
            if currentIndex > #wepSlots[currentSlot] then
                currentSlot = GetNextValidSlot(currentSlot, 1); currentIndex = 1
            end
        end
        hideTime = CurTime() + 3
        surface.PlaySound("garrysmod/ui_hover.wav")
        return true

    elseif bind:find("invprev") then 
        UpdateWeaponList()
        if not showSelector then
            showSelector = true
            local active = ply:GetActiveWeapon()
            currentSlot = (IsValid(active) and active:GetSlot() + 1) or 1
            if #wepSlots[currentSlot] == 0 then currentSlot = GetNextValidSlot(currentSlot, -1) end
            currentIndex = 1
        else
            currentIndex = currentIndex - 1
            if currentIndex < 1 then
                currentSlot = GetNextValidSlot(currentSlot, -1)
                currentIndex = #wepSlots[currentSlot]
            end
        end
        hideTime = CurTime() + 3
        surface.PlaySound("garrysmod/ui_hover.wav")
        return true

    elseif bind:find("+attack") and showSelector then 
        local wep = wepSlots[currentSlot][currentIndex]
        if IsValid(wep) then input.SelectWeapon(wep) end
        showSelector = false
        surface.PlaySound("garrysmod/ui_click.wav")
        return true
    end
end)

local function DrawBlur(x, y, w, h, alpha)
    surface_SetDrawColor(255, 255, 255, 255 * alpha)
    surface_SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * 4)
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        render_SetScissorRect(x, y, x + w, y + h, true)
        surface_DrawTexturedRect(0, 0, ScrW(), ScrH())
        render_SetScissorRect(0, 0, 0, 0, false)
    end
end

hook.Add("HUDPaint", "CustomRP_Weapon_DrawSlots", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if CurTime() > hideTime then showSelector = false end

    local targetAlpha = showSelector and 1 or 0
    selectorAlpha = Lerp(12 * FrameTime(), selectorAlpha, targetAlpha)

    if selectorAlpha < 0.01 then return end

    UpdateWeaponList()

    local colW = 180
    local wepH = 38
    local spacing = 12
    local headerH = 45

    local activeColumns = 0
    for i = 1, maxSlots do
        if #wepSlots[i] > 0 then activeColumns = activeColumns + 1 end
    end
    if activeColumns == 0 then return end

    local totalW = (activeColumns * colW) + ((activeColumns - 1) * spacing)
    local startX = (ScrW() / 2) - (totalW / 2)
    local baseStartY = 50 

    local currentDrawX = startX
    local targetCursorX, targetCursorY = 0, 0
    local cursorW, cursorH = colW, wepH

    for slotNum = 1, maxSlots do
        local weps = wepSlots[slotNum]
        if #weps > 0 then
            local targetOffset = (slotNum == currentSlot) and -15 or 0
            colOffsets[slotNum] = Lerp(12 * FrameTime(), colOffsets[slotNum], targetOffset)
            local colY = baseStartY + colOffsets[slotNum]

            DrawBlur(currentDrawX, colY, colW, headerH, selectorAlpha)
            col_head_bg.a = 220 * selectorAlpha
            draw_RoundedBox(8, currentDrawX, colY, colW, headerH, col_head_bg)
            
            if slotNum == currentSlot then
                col_head_accent.a = 255 * selectorAlpha
                draw.RoundedBoxEx(8, currentDrawX, colY, colW, 4, col_head_accent, true, true, false, false)
                col_head_txt_active.a = 255 * selectorAlpha
                draw_SimpleText("SLOT " .. slotNum, "CustomRP_Font_WeaponSlot", currentDrawX + (colW / 2), colY + (headerH / 2), col_head_txt_active, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                col_head_txt_inactive.a = 150 * selectorAlpha
                draw_SimpleText("SLOT " .. slotNum, "CustomRP_Font_WeaponSlot", currentDrawX + (colW / 2), colY + (headerH / 2), col_head_txt_inactive, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            for wepIdx = 1, #weps do
                local wep = weps[wepIdx]
                local wY = colY + headerH + spacing + ((wepIdx - 1) * (wepH + 6))

                DrawBlur(currentDrawX, wY, colW, wepH, selectorAlpha)
                col_wep_bg.a = 180 * selectorAlpha
                draw_RoundedBox(6, currentDrawX, wY, colW, wepH, col_wep_bg)

                local wepName = wep:GetPrintName() or wep:GetClass()
                wepName = string.upper(language.GetPhrase(wepName))
                if string.len(wepName) > 16 then wepName = string.sub(wepName, 1, 14) .. "..." end

                if slotNum == currentSlot and wepIdx == currentIndex then
                    targetCursorX = currentDrawX
                    targetCursorY = wY
                    col_wep_txt_active.a = 255 * selectorAlpha
                    draw_SimpleText(wepName, "CustomRP_Font_Weapon", currentDrawX + (colW / 2), wY + (wepH / 2), col_wep_txt_active, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    col_wep_txt_inactive.a = 180 * selectorAlpha
                    draw_SimpleText(wepName, "CustomRP_Font_Weapon", currentDrawX + (colW / 2), wY + (wepH / 2), col_wep_txt_inactive, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            currentDrawX = currentDrawX + colW + spacing
        end
    end

    if smoothX == 0 or selectorAlpha < 0.1 then 
        smoothX = targetCursorX
        smoothY = targetCursorY
    end

    smoothX = Lerp(20 * FrameTime(), smoothX, targetCursorX)
    smoothY = Lerp(20 * FrameTime(), smoothY, targetCursorY)

    if targetCursorX ~= 0 then
        local pulseGlow = 15 + math.abs(math.sin(CurTime() * 5)) * 30
        col_neon.a = pulseGlow * selectorAlpha
        draw_RoundedBox(10, smoothX - 6, smoothY - 6, cursorW + 12, cursorH + 12, col_neon)

        col_cursor.a = 40 * selectorAlpha
        draw_RoundedBox(6, smoothX, smoothY, cursorW, cursorH, col_cursor)
        
        col_cursor_edge.a = 255 * selectorAlpha
        draw.RoundedBoxEx(6, smoothX, smoothY, 4, cursorH, col_cursor_edge, true, false, true, false)
        draw.RoundedBoxEx(6, smoothX + cursorW - 4, smoothY, 4, cursorH, col_cursor_edge, false, true, false, true)

        local shineOffset = (CurTime() * 400) % (cursorW * 2.5) - cursorW
        
        render_SetScissorRect(smoothX, smoothY, smoothX + cursorW, smoothY + cursorH, true)
        
        shinePoly[1].x = smoothX + shineOffset
        shinePoly[1].y = smoothY
        shinePoly[2].x = smoothX + shineOffset + 25
        shinePoly[2].y = smoothY
        shinePoly[3].x = smoothX + shineOffset + 5
        shinePoly[3].y = smoothY + cursorH
        shinePoly[4].x = smoothX + shineOffset - 15
        shinePoly[4].y = smoothY + cursorH
        
        draw.NoTexture()
        col_shine.a = 35 * selectorAlpha
        surface_SetDrawColor(col_shine.r, col_shine.g, col_shine.b, col_shine.a)
        surface_DrawPoly(shinePoly)
        
        render_SetScissorRect(0, 0, 0, 0, false)
    end
end)
