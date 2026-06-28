include("shared.lua")

local COLOR_ACCENT = Color(231, 76, 60)
local COLOR_TEXT = Color(240, 240, 240)

local col_shadow = Color(0, 0, 0, 0)
local col_main = Color(0, 0, 0, 0)
local col_sub = Color(0, 0, 0, 0)

function ENT:Draw()
    self:DrawModel()

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local dist = ply:GetPos():DistToSqr(self:GetPos())
    if dist > 250000 then return end

    local alpha = (1 - (dist / 250000)) * 255
    local floatOffset = math.sin(CurTime() * 1.5) * 2

    local pos = self:GetPos() + self:GetUp() * (90 + floatOffset)
    local ang = ply:EyeAngles()

    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    col_shadow.a = alpha * 0.6
    col_main.r = COLOR_TEXT.r
    col_main.g = COLOR_TEXT.g
    col_main.b = COLOR_TEXT.b
    col_main.a = alpha
    col_sub.r = COLOR_TEXT.r
    col_sub.g = COLOR_TEXT.g
    col_sub.b = COLOR_TEXT.b
    col_sub.a = alpha * 0.6

    cam.Start3D2D(pos, ang, 0.08)
        draw.SimpleText("DISTRIBUTEUR AUTOMATIQUE", "CustomRP_Font_ATM_3D2D_Title", 2, 2, col_shadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("DISTRIBUTEUR AUTOMATIQUE", "CustomRP_Font_ATM_3D2D_Title", 0, 0, col_main, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, alpha * 0.8)
        surface.DrawRect(-250, 40, 500, 4)

        draw.SimpleText("Appuyez sur E pour interagir", "CustomRP_Font_ATM_3D2D_Sub", 0, 75, col_sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
