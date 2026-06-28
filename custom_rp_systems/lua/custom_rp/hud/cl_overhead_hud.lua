if not CLIENT then return end

local CFG = {
    MaxDist    = 350,
    FadeStart  = 220,
    PillH      = 26,
    PillPadX   = 12,
    DotR       = 5,
    BarH       = 3,
    BarGap     = 4,
    JobGap     = 5,
    HoverAmp   = 3.5,
    HoverSpeed = 1.4,
    BaseY      = -82,
    JobAlpha   = 0.55,
    LerpHP     = 8,
    LerpAlpha  = 10,
}

local COL_PILL_BG = Color(8,   8,  14, 195)
local COL_BAR_BG  = Color(255, 255, 255, 45)
local COL_NAME    = Color(255, 255, 255, 255)
local COL_HP_HIGH = Color(50,  210, 100)
local COL_HP_MID  = Color(220, 195,  40)
local COL_HP_LOW  = Color(215,  55,  55)
local COL_MIC     = Color(50,  210, 100)
local COL_TYPING  = Color(100, 175, 255)

local _reuse_col = Color(0, 0, 0, 255)

local function LerpColor3(t, a, b, out)
    out      = out or Color(0, 0, 0)
    out.r    = Lerp(t, a.r, b.r)
    out.g    = Lerp(t, a.g, b.g)
    out.b    = Lerp(t, a.b, b.b)
    return out
end

local function HPColor(frac)
    if frac >= 0.5 then
        return LerpColor3((frac - 0.5) * 2, COL_HP_MID, COL_HP_HIGH, _reuse_col)
    else
        return LerpColor3(frac * 2, COL_HP_LOW, COL_HP_MID, _reuse_col)
    end
end

local playerCache = {}

local function GetCache(ply)
    local c      = playerCache[ply]
    local teamID = ply:Team()

    if not c or c.lastTeam ~= teamID then
        local tc = team.GetColor(teamID)
        c = {
            jobName  = string.upper(team.GetName(teamID)),
            jobCol   = Color(tc.r, tc.g, tc.b),
            smoothHP = ply:Health(),
            smoothA  = 0,
            lastTeam = teamID,
            lastNick = "",
            pillW    = 120,
        }
        playerCache[ply] = c
    end
    return c
end

hook.Add("PlayerDisconnected", "CustomRP_Overhead_Cleanup", function(ply)
    playerCache[ply] = nil
end)

local DOTS = { "●○○", "●●○", "●●●" }
local function GetDots()
    return DOTS[(math.floor(CurTime() * 2.5) % 3) + 1]
end

local math_sin          = math.sin
local math_Clamp        = math.Clamp
local math_max          = math.max
local draw_SimpleText   = draw.SimpleText
local draw_RoundedBox   = draw.RoundedBox
local surf_SetColor     = surface.SetDrawColor
local surf_DrawRect     = surface.DrawRect
local surf_SetFont      = surface.SetFont
local surf_GetTextSize  = surface.GetTextSize
local local_vec         = Vector(0, 0, 0)

hook.Add("HUDPaint", "CustomRP_HUD_Overhead", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end

    local ct    = CurTime()
    local ft    = FrameTime()
    local lpPos = lp:EyePos()

    for _, ply in ipairs(player.GetAll()) do
        if ply == lp then continue end
        if not IsValid(ply) or not ply:Alive() then continue end

        local dist = lp:GetPos():Distance(ply:GetPos())
        if dist > CFG.MaxDist then continue end

        local tr = util.TraceLine({
            start  = lpPos,
            endpos = ply:GetShootPos(),
            filter = { lp, ply },
            mask   = MASK_OPAQUE_AND_NPCS,
        })
        if tr.Hit then continue end

        local fadeRange = math_max(CFG.MaxDist - CFG.FadeStart, 1)
        local targetA   = math_Clamp(1 - (dist - CFG.FadeStart) / fadeRange, 0, 1)
        local c         = GetCache(ply)
        c.smoothA       = Lerp(CFG.LerpAlpha * ft, c.smoothA, targetA)
        local a         = c.smoothA
        if a < 0.02 then continue end

        c.smoothHP = Lerp(CFG.LerpHP * ft, c.smoothHP, ply:Health())
        local hpFrac = math_Clamp(c.smoothHP / math_max(ply:GetMaxHealth(), 1), 0, 1)

        local hover  = math_sin(ct * CFG.HoverSpeed + ply:EntIndex() * 0.97) * CFG.HoverAmp
        
        local obbMax = ply:OBBMaxs()
        local_vec.x = 0
        local_vec.y = 0
        local_vec.z = obbMax.z + 14
        
        local origin = ply:GetPos()
        origin:Add(local_vec)
        
        local scr    = origin:ToScreen()
        if not scr.visible then continue end

        local sx = scr.x
        local sy = scr.y + CFG.BaseY + hover

        local nick = ply:Name()
        if c.lastNick ~= nick then
            surf_SetFont("CustomRP_Font_OverheadName")
            local nw = surf_GetTextSize(nick)
            c.pillW    = CFG.PillPadX + CFG.DotR * 2 + 8 + nw + CFG.PillPadX
            c.nameOffX = CFG.PillPadX + CFG.DotR * 2 + 8 + nw * 0.5
            c.lastNick = nick
        end

        local pw = c.pillW
        local ph = CFG.PillH
        local r  = ph / 2
        local px = sx - pw * 0.5
        local py = sy

        local aboveY = py - 20
        if ply:IsSpeaking() then
            local pulse = 0.55 + 0.45 * math_sin(ct * 7)
            draw_SimpleText("🎤", "CustomRP_Font_OverheadJob",
                sx, aboveY,
                Color(COL_MIC.r, COL_MIC.g, COL_MIC.b, math.floor(240 * a * pulse)),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif ply:IsTyping() then
            draw_SimpleText("💬 " .. GetDots(), "CustomRP_Font_OverheadJob",
                sx, aboveY,
                Color(COL_TYPING.r, COL_TYPING.g, COL_TYPING.b, math.floor(210 * a)),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local bgA = math.floor(COL_PILL_BG.a * a)
        draw_RoundedBox(r, px, py, pw, ph,
            Color(COL_PILL_BG.r, COL_PILL_BG.g, COL_PILL_BG.b, bgA))

        surf_SetColor(255, 255, 255, math.floor(14 * a))
        surf_DrawRect(px + r, py + 1, pw - r * 2, 1)

        local jc   = c.jobCol
        local dotX = px + CFG.PillPadX + CFG.DotR
        local dotY = py + ph * 0.5

        draw_RoundedBox(CFG.DotR + 3,
            dotX - CFG.DotR - 3, dotY - CFG.DotR - 3,
            (CFG.DotR + 3) * 2, (CFG.DotR + 3) * 2,
            Color(jc.r, jc.g, jc.b, math.floor(45 * a)))

        draw_RoundedBox(CFG.DotR,
            dotX - CFG.DotR, dotY - CFG.DotR,
            CFG.DotR * 2, CFG.DotR * 2,
            Color(jc.r, jc.g, jc.b, math.floor(255 * a)))

        draw_SimpleText(nick, "CustomRP_Font_OverheadName",
            px + c.nameOffX, py + ph * 0.5,
            Color(255, 255, 255, math.floor(255 * a)),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local barY = py + ph + CFG.BarGap
        local hpc  = HPColor(hpFrac)

        draw_RoundedBox(1, px, barY, pw, CFG.BarH,
            Color(COL_BAR_BG.r, COL_BAR_BG.g, COL_BAR_BG.b, math.floor(60 * a)))

        if hpFrac > 0.005 then
            draw_RoundedBox(1, px, barY,
                math_Clamp(pw * hpFrac, 2, pw), CFG.BarH,
                Color(hpc.r, hpc.g, hpc.b, math.floor(230 * a)))
        end

        draw_SimpleText(c.jobName, "CustomRP_Font_OverheadJob",
            sx, barY + CFG.BarH + CFG.JobGap,
            Color(255, 255, 255, math.floor(255 * a * CFG.JobAlpha)),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end)
