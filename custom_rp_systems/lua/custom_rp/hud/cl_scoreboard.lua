if not CLIENT then return end

local blur = Material("pp/blurscreen")
local col_bg = Color(10, 10, 12, 190)
local col_accent = Color(230, 45, 45, 255)

local ScoreboardPanel = nil
local ActivePlayerMenu = nil

local col_bg_mut = Color(10, 10, 12, 220)
local col_border_mut = Color(255, 255, 255, 20)
local col_hover_mut = Color(255, 255, 255, 10)
local col_btn_edge_mut = Color(255, 255, 255, 255)
local col_btn_text_mut = Color(255, 255, 255, 255)
local col_row_bg_mut = Color(0, 0, 0, 160)
local col_row_hover_mut = Color(255, 255, 255, 12)
local col_row_edge_mut = Color(255, 255, 255, 255)
local col_row_text_mut = Color(255, 255, 255, 255)
local col_row_job_mut = Color(255, 255, 255, 255)
local col_row_rank_bg_mut = Color(255, 255, 255, 25)
local col_row_rank_text_mut = Color(255, 255, 255, 255)
local col_row_frags_mut = Color(200, 200, 200, 255)
local col_row_ping_mut = Color(45, 230, 100, 255)
local col_sb_bg_mut = Color(10, 10, 12, 190)
local col_sb_border_mut = Color(255, 255, 255, 25)
local col_sb_title_mut = Color(255, 255, 255, 255)
local col_sb_sub_mut = Color(180, 180, 180, 255)
local col_sb_accent_mut = Color(230, 45, 45, 150)
local col_sb_header_mut = Color(120, 120, 120, 255)
local col_grip_draw = Color(0, 0, 0, 0)

local function PaintBlur(pnl, w, h, alpha)
    local x, y = pnl:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (5 * alpha)) 
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        render.SetScissorRect(x, y, x + w, y + h, true)
        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

local function GetFormattedRank(ply)
    local group = ply:GetUserGroup()
    if group == "superadmin" then return "FONDATEUR", Color(230, 45, 45)
    elseif group == "admin" then return "ADMIN", Color(45, 130, 230)
    elseif group == "moderator" or group == "modo" then return "MODÉRATEUR", Color(45, 230, 130)
    elseif group == "vip" then return "VIP", Color(230, 200, 45)
    end
    return "USER", Color(120, 120, 120)
end

local function FormatTextLimit(text, limit)
    if string.len(text) > limit then
        return string.sub(text, 1, limit - 3) .. "..."
    end
    return text
end

local posName = 48
local posJob = 320
local posRank = 530
local posKills = 700
local posPing = 830

local headName = posName + 20
local headJob = posJob + 20
local headRank = posRank + 20
local headKills = posKills + 20
local headPing = posPing + 20

local function OpenPlayerMenu(targetPly)
    if not IsValid(targetPly) or not IsValid(ScoreboardPanel) then return end
    if IsValid(ActivePlayerMenu) then ActivePlayerMenu:Remove() end

    local bgLayer = vgui.Create("DButton", ScoreboardPanel)
    bgLayer:SetSize(ScoreboardPanel:GetWide(), ScoreboardPanel:GetTall())
    bgLayer:SetText("")
    bgLayer.Paint = function() end
    bgLayer.DoClick = function(self) self:Remove() end
    bgLayer:SetKeyboardInputEnabled(false)
    
    ActivePlayerMenu = bgLayer

    local pnl = vgui.Create("EditablePanel", bgLayer)
    pnl:SetKeyboardInputEnabled(false)
    pnl.alpha = 0
    
    local btnHeight = 35
    local btns = {}

    table.insert(btns, { name = "Profil Steam", func = function() targetPly:ShowProfile() end, col = Color(100, 150, 255) })

    if LocalPlayer():IsAdmin() then
        table.insert(btns, { name = "Aller à lui", func = function() RunConsoleCommand("ulx", "goto", targetPly:Nick()) end, col = Color(200, 200, 200) })
        table.insert(btns, { name = "L'amener", func = function() RunConsoleCommand("ulx", "bring", targetPly:Nick()) end, col = Color(200, 200, 200) })
        table.insert(btns, { name = "Geler / Dégeler", func = function() RunConsoleCommand("ulx", "freeze", targetPly:Nick()) end, col = Color(45, 230, 200) })
        table.insert(btns, { name = "Kick", func = function() RunConsoleCommand("ulx", "kick", targetPly:Nick(), "Raison") end, col = Color(230, 150, 45) })
        table.insert(btns, { name = "Ban", func = function() RunConsoleCommand("ulx", "ban", targetPly:Nick(), "0", "Raison") end, col = Color(230, 45, 45) })
    end

    local pW = 180
    local pH = (#btns * btnHeight) + 10
    local mx, my = ScoreboardPanel:ScreenToLocal(gui.MousePos())
    
    if mx + pW > ScoreboardPanel:GetWide() then mx = ScoreboardPanel:GetWide() - pW - 10 end
    if my + pH > ScoreboardPanel:GetTall() then my = ScoreboardPanel:GetTall() - pH - 10 end
    
    pnl:SetPos(mx, my)
    pnl:SetSize(pW, pH)

    pnl.Paint = function(self, w, h)
        self.alpha = Lerp(15 * FrameTime(), self.alpha, 1)
        PaintBlur(self, w, h, self.alpha)
        col_bg_mut.a = 220 * self.alpha
        draw.RoundedBox(6, 0, 0, w, h, col_bg_mut)
        col_border_mut.a = 20 * self.alpha
        surface.SetDrawColor(col_border_mut.r, col_border_mut.g, col_border_mut.b, col_border_mut.a)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    for i = 1, #btns do
        local b = btns[i]
        local btn = vgui.Create("DButton", pnl)
        btn:SetSize(pW - 10, btnHeight)
        btn:SetPos(5, 5 + (i - 1) * btnHeight)
        btn:SetText("")
        btn:SetKeyboardInputEnabled(false)
        btn.hoverAlpha = 0
        
        btn.Paint = function(self, w, h)
            self.hoverAlpha = Lerp(12 * FrameTime(), self.hoverAlpha, self:IsHovered() and 1 or 0)
            
            col_hover_mut.a = 10 * self.hoverAlpha
            draw.RoundedBox(4, 0, 0, w, h, col_hover_mut)
            if self.hoverAlpha > 0.01 then
                col_btn_edge_mut.r = b.col.r
                col_btn_edge_mut.g = b.col.g
                col_btn_edge_mut.b = b.col.b
                col_btn_edge_mut.a = 255 * self.hoverAlpha
                draw.RoundedBoxEx(4, 0, 0, 3, h, col_btn_edge_mut, true, false, true, false)
            end
            
            col_btn_text_mut.r = b.col.r
            col_btn_text_mut.g = b.col.g
            col_btn_text_mut.b = b.col.b
            col_btn_text_mut.a = 255 * pnl.alpha
            draw.SimpleText(b.name, "CustomRP_Font_SB_Row", 15, h/2, col_btn_text_mut, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        btn.DoClick = function()
            b.func()
            bgLayer:Remove() 
        end
    end
end

local function CreatePlayerRow(parent, ply, index)
    local row = vgui.Create("DButton", parent)
    row:SetText("")
    row:Dock(TOP)
    row:DockMargin(0, 0, 8, 6) 
    row:SetTall(42)
    
    row.hoverAlpha = 0
    row.spawnTime = CurTime() + (index * 0.03) 
    row.animX = 50 
    row.animAlpha = 0

    local avatar = vgui.Create("AvatarImage", row)
    avatar:SetSize(28, 28)
    avatar:SetPlayer(ply, 64)
    avatar:SetPaintedManually(true) 

    row.Paint = function(self, w, h)
        if not IsValid(ply) then self:Remove() return end

        if CurTime() >= self.spawnTime then
            self.animX = Lerp(15 * FrameTime(), self.animX, 0)
            self.animAlpha = Lerp(15 * FrameTime(), self.animAlpha, 1)
        end

        if self.animAlpha < 0.01 then return end

        local targetHover = self:IsHovered() and 1 or 0
        self.hoverAlpha = Lerp(12 * FrameTime(), self.hoverAlpha, targetHover)

        col_row_bg_mut.a = 160 * self.animAlpha
        draw.RoundedBox(6, self.animX, 0, w, h, col_row_bg_mut)
        
        if self.hoverAlpha > 0.01 then
            col_row_hover_mut.a = 12 * self.hoverAlpha
            draw.RoundedBox(6, self.animX, 0, w, h, col_row_hover_mut)
            col_row_edge_mut.a = 255 * self.hoverAlpha
            draw.RoundedBoxEx(6, self.animX, 0, 4, h, col_row_edge_mut, true, false, true, false)
        end

        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilWriteMask(1)
        render.SetStencilTestMask(1)
        render.SetStencilReferenceValue(1)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

        draw.RoundedBox(6, self.animX + 8, (h/2) - 14, 28, 28, color_white)

        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilPassOperation(STENCILOPERATION_KEEP)

        avatar:SetPos(self.animX + 8, (h/2) - 14)
        avatar:SetAlpha(255 * self.animAlpha)
        avatar:PaintManual()

        render.SetStencilEnable(false)

        local textAlpha = 255 * self.animAlpha
        local name = FormatTextLimit(ply:Name() or ply:Nick(), 20)
        local jobColor = team.GetColor(ply:Team())
        local jobName = FormatTextLimit(string.upper(team.GetName(ply:Team())), 20)
        local frags = ply:Frags()
        local ping = ply:Ping()
        local rankName, rankColor = GetFormattedRank(ply)

        col_row_text_mut.a = textAlpha
        draw.SimpleText(name, "CustomRP_Font_SB_Row", self.animX + posName, h/2, col_row_text_mut, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        col_row_job_mut.r = jobColor.r
        col_row_job_mut.g = jobColor.g
        col_row_job_mut.b = jobColor.b
        col_row_job_mut.a = textAlpha
        draw.SimpleText(jobName, "CustomRP_Font_SB_Row", self.animX + posJob, h/2, col_row_job_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        surface.SetFont("CustomRP_Font_SB_Rank")
        local rankW, rankH = surface.GetTextSize(rankName)
        local boxW = rankW + 16
        
        col_row_rank_bg_mut.r = rankColor.r
        col_row_rank_bg_mut.g = rankColor.g
        col_row_rank_bg_mut.b = rankColor.b
        col_row_rank_bg_mut.a = 25 * self.animAlpha
        draw.RoundedBox(4, self.animX + posRank - (boxW/2), (h/2) - 10, boxW, 20, col_row_rank_bg_mut)
        
        col_row_rank_text_mut.r = rankColor.r
        col_row_rank_text_mut.g = rankColor.g
        col_row_rank_text_mut.b = rankColor.b
        col_row_rank_text_mut.a = textAlpha
        draw.SimpleText(rankName, "CustomRP_Font_SB_Rank", self.animX + posRank, h/2, col_row_rank_text_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        col_row_frags_mut.a = textAlpha
        draw.SimpleText(frags, "CustomRP_Font_SB_Row", self.animX + posKills, h/2, col_row_frags_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local r, g, b = 45, 230, 100
        if ping > 80 then r, g, b = 230, 150, 45 end
        if ping > 150 then r, g, b = 230, 45, 45 end
        col_row_ping_mut.r = r
        col_row_ping_mut.g = g
        col_row_ping_mut.b = b
        col_row_ping_mut.a = textAlpha
        draw.SimpleText(ping .. " ms", "CustomRP_Font_SB_Row", self.animX + posPing, h/2, col_row_ping_mut, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    row.DoClick = function()
        if IsValid(ply) then OpenPlayerMenu(ply) end
    end
end

local function ShowScoreboard()
    if IsValid(ScoreboardPanel) then ScoreboardPanel:Remove() end

    local w, h = 900, ScrH() * 0.75

    ScoreboardPanel = vgui.Create("EditablePanel")
    ScoreboardPanel:SetSize(w, h)
    ScoreboardPanel:Center()
    ScoreboardPanel:MakePopup()
    ScoreboardPanel:SetKeyboardInputEnabled(false)
    ScoreboardPanel.alpha = 0

    ScoreboardPanel.Paint = function(self, w, h)
        self.alpha = Lerp(12 * FrameTime(), self.alpha, 1)

        PaintBlur(self, w, h, self.alpha)
        
        col_sb_bg_mut.a = col_bg.a * self.alpha
        draw.RoundedBox(12, 0, 0, w, h, col_sb_bg_mut)
        
        col_sb_border_mut.a = 25 * self.alpha
        surface.SetDrawColor(255, 255, 255, col_sb_border_mut.a)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        col_sb_title_mut.a = 255 * self.alpha
        draw.SimpleText(string.upper(GetHostName()), "CustomRP_Font_SB_Title", w/2, 35, col_sb_title_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        col_sb_sub_mut.a = 255 * self.alpha
        draw.SimpleText("JOUEURS EN LIGNE : " .. #player.GetAll() .. " / " .. game.MaxPlayers(), "CustomRP_Font_SB_Sub", w/2, 65, col_sb_sub_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        col_sb_accent_mut.a = 150 * self.alpha
        draw.RoundedBox(0, 20, 95, w - 40, 2, col_sb_accent_mut)

        col_sb_header_mut.a = 255 * self.alpha
        draw.SimpleText("IDENTITÉ", "CustomRP_Font_SB_Header", headName, 110, col_sb_header_mut, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("PROFESSION", "CustomRP_Font_SB_Header", headJob, 110, col_sb_header_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("ACCRÉDITATION", "CustomRP_Font_SB_Header", headRank, 110, col_sb_header_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("ÉLIMINATIONS", "CustomRP_Font_SB_Header", headKills, 110, col_sb_header_mut, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("RÉSEAU", "CustomRP_Font_SB_Header", headPing, 110, col_sb_header_mut, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local scrollPanel = vgui.Create("DScrollPanel", ScoreboardPanel)
    scrollPanel:SetPos(20, 130)
    scrollPanel:SetSize(w - 40, h - 150)

    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(6)
    sbar:SetHideButtons(true)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        local gripHover = self:IsHovered() and 255 or 100
        col_grip_draw.r = col_accent.r
        col_grip_draw.g = col_accent.g
        col_grip_draw.b = col_accent.b
        col_grip_draw.a = gripHover
        draw.RoundedBox(3, 0, 0, w, h, col_grip_draw)
    end

    local players = player.GetAll()
    table.sort(players, function(a, b)
        local aGroup = a:IsSuperAdmin() and 1 or (a:IsAdmin() and 2 or 3)
        local bGroup = b:IsSuperAdmin() and 1 or (b:IsAdmin() and 2 or 3)
        if aGroup == bGroup then return a:Team() < b:Team() end
        return aGroup < bGroup
    end)

    for index, ply in ipairs(players) do
        CreatePlayerRow(scrollPanel, ply, index)
    end
end

hook.Add("ScoreboardShow", "CustomRP_ScoreboardShow", function()
    ShowScoreboard()
    return true
end)

hook.Add("ScoreboardHide", "CustomRP_ScoreboardHide", function()
    if IsValid(ScoreboardPanel) then ScoreboardPanel:Remove() end
end)
