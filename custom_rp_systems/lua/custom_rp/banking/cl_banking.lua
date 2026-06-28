local ServerName = "" 

local COLOR_BG          = Color(10, 10, 15, 160)
local COLOR_PANEL       = Color(0, 0, 0, 150)
local COLOR_ACCENT      = Color(231, 76, 60)
local COLOR_SUCCESS     = Color(46, 204, 113)
local COLOR_BLUE        = Color(52, 152, 219)
local COLOR_TEXT        = Color(240, 240, 240)
local COLOR_TEXT_MUTED  = Color(150, 150, 150)
local COLOR_BORDER      = Color(255, 255, 255, 15)
local COLOR_BORDER_LIGHT= Color(255, 255, 255, 5)

local col_notif_bg = Color(0, 0, 0, 0)
local col_notif_edge = Color(0, 0, 0, 0)
local col_notif_txt = Color(0, 0, 0, 0)
local col_btn_bg = Color(0, 0, 0, 0)
local col_btn_glow = Color(255, 255, 255, 0)
local col_btn_border = Color(255, 255, 255, 0)
local col_entry_bg = Color(5, 5, 10, 200)
local col_entry_border = Color(255, 255, 255, 15)
local col_entry_accent = Color(231, 76, 60, 0)
local col_entry_placeholder = Color(150, 150, 150, 100)
local col_player_bg = Color(0, 0, 0, 0)
local col_player_border = Color(0, 0, 0, 0)
local col_player_accent = Color(0, 0, 0, 0)
local col_sep = Color(255, 255, 255, 5)
local col_preset_bg = Color(255, 255, 255, 0)
local col_preset_txt = Color(0, 0, 0, 0)
local col_close_hover = Color(231, 76, 60, 0)
local col_boot_pulse = Color(231, 76, 60, 0)
local col_boot_txt = Color(255, 255, 255, 255)

local blur = Material("pp/blurscreen")
local matGradientDown = Material("gui/gradient_down")

local ATMFrame = nil
local bankBalance = 0
local atmEntity = nil
local playerList = {}
local notifications = {}

local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 8))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

local function LerpColor(t, from, to)
    return Color(Lerp(t, from.r, to.r), Lerp(t, from.g, to.g), Lerp(t, from.b, to.b), Lerp(t, from.a, to.a))
end

local function FormatMoney(amount)
    if DarkRP and DarkRP.FormatMoney then return DarkRP.FormatMoney(amount) end
    return "$" .. string.Comma(amount)
end

local function AddNotification(msg, isError)
    table.insert(notifications, {
        text = msg,
        isError = isError,
        time = CurTime(),
        alpha = 0
    })
end

local function DrawNotifications(parent, w)
    local yOff = 10
    for i = #notifications, 1, -1 do
        local n = notifications[i]
        local age = CurTime() - n.time
        if age > 4 then
            table.remove(notifications, i)
        else
            local targetAlpha = (age < 0.3) and (age / 0.3) or (age > 3.5 and (1 - (age - 3.5) / 0.5) or 1)
            n.alpha = Lerp(FrameTime() * 10, n.alpha, targetAlpha * 255)
            local col = n.isError and COLOR_ACCENT or COLOR_SUCCESS
            
            col_notif_bg.r = col.r
            col_notif_bg.g = col.g
            col_notif_bg.b = col.b
            col_notif_bg.a = n.alpha * 0.3
            draw.RoundedBox(6, 20, yOff, w - 40, 36, col_notif_bg)
            
            col_notif_edge.r = col.r
            col_notif_edge.g = col.g
            col_notif_edge.b = col.b
            col_notif_edge.a = n.alpha
            draw.RoundedBoxEx(6, 20, yOff, 4, 36, col_notif_edge, true, false, true, false)
            
            col_notif_txt.r = COLOR_TEXT.r
            col_notif_txt.g = COLOR_TEXT.g
            col_notif_txt.b = COLOR_TEXT.b
            col_notif_txt.a = n.alpha
            draw.SimpleText(n.text, "CustomRP_Font_ATM_Notif", 34, yOff + 18, col_notif_txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            yOff = yOff + 44
        end
    end
end

local function CreateStatCard(parent, x, y, w, h, title, value, color)
    local card = vgui.Create("DPanel", parent)
    card:SetPos(x, y)
    card:SetSize(w, h)
    card.displayValue = value
    card.Paint = function(s, cw, ch)
        draw.RoundedBox(8, 0, 0, cw, ch, COLOR_PANEL)
        draw.RoundedBoxEx(8, 0, 0, cw, 4, color, true, true, false, false)
        surface.SetDrawColor(color.r, color.g, color.b, 15)
        surface.SetMaterial(matGradientDown)
        surface.DrawTexturedRect(0, 4, cw, 30)
        draw.SimpleText(title, "CustomRP_Font_ATM_Small", 20, 20, COLOR_TEXT_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(s.displayValue, "CustomRP_Font_ATM_Stat", 20, 50, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(COLOR_BORDER)
        surface.DrawOutlinedRect(0, 0, cw, ch, 1)
    end
    return card
end

local function CreateActionButton(parent, x, y, w, h, label, color, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetPos(x, y)
    btn:SetSize(w, h)
    btn:SetText("")
    btn.hoverLerp = 0
    btn.Paint = function(s, bw, bh)
        local isHovered = s:IsHovered()
        s.hoverLerp = Lerp(FrameTime() * 12, s.hoverLerp, isHovered and 1 or 0)
        
        local bg = LerpColor(s.hoverLerp, col_btn_bg, color)
        col_btn_bg.r = color.r * 0.4
        col_btn_bg.g = color.g * 0.4
        col_btn_bg.b = color.b * 0.4
        col_btn_bg.a = 200
        
        draw.RoundedBox(8, 0, 0, bw, bh, bg)
        if s.hoverLerp > 0.01 then
            col_btn_glow.a = 15 * s.hoverLerp
            surface.SetDrawColor(col_btn_glow.r, col_btn_glow.g, col_btn_glow.b, col_btn_glow.a)
            surface.SetMaterial(matGradientDown)
            surface.DrawTexturedRect(0, 0, bw, bh / 2)
        end
        col_btn_border.a = 5 + 15 * s.hoverLerp
        surface.SetDrawColor(col_btn_border.r, col_btn_border.g, col_btn_border.b, col_btn_border.a)
        surface.DrawOutlinedRect(0, 0, bw, bh, 1)
        draw.SimpleText(label, "CustomRP_Font_ATM_Btn", bw / 2, bh / 2, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btn.DoClick = onClick
    return btn
end

local function CreateStyledTextEntry(parent, x, y, w, h)
    local entry = vgui.Create("DTextEntry", parent)
    entry:SetPos(x, y)
    entry:SetSize(w, h)
    entry:SetFont("CustomRP_Font_ATM_Input")
    entry:SetTextColor(COLOR_TEXT)
    entry:SetCursorColor(COLOR_ACCENT)
    entry:SetNumeric(true)
    entry:SetPaintBackgroundEnabled(false)
    entry:SetDrawLanguageID(false)
    entry.focusLerp = 0
    entry.Paint = function(s, ew, eh)
        draw.RoundedBox(6, 0, 0, ew, eh, col_entry_bg)
        surface.SetDrawColor(col_entry_border.r, col_entry_border.g, col_entry_border.b, col_entry_border.a)
        surface.DrawOutlinedRect(0, 0, ew, eh, 1)
        
        s.focusLerp = Lerp(FrameTime() * 10, s.focusLerp, s:HasFocus() and 1 or 0)
        if s.focusLerp > 0.01 then
            local barW = ew * s.focusLerp
            col_entry_accent.a = 255 * s.focusLerp
            surface.SetDrawColor(col_entry_accent.r, col_entry_accent.g, col_entry_accent.b, col_entry_accent.a)
            surface.DrawRect((ew - barW) / 2, eh - 2, barW, 2)
        end
        if s:GetText() == "" then
            draw.SimpleText("Entrez un montant...", "CustomRP_Font_ATM_Body", 12, eh / 2, col_entry_placeholder, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        s:DrawTextEntryText(s:GetTextColor(), Color(100, 150, 255, 150), s:GetCursorColor())
    end
    return entry
end

local function ShowTransferPanel(parent, contentPanel, moneyInput)
    contentPanel:Clear()
    local amount = tonumber(moneyInput) or 0

    local pnl = vgui.Create("DPanel", contentPanel)
    pnl:Dock(FILL)
    pnl:SetAlpha(0)
    pnl:AlphaTo(255, 0.3, 0)
    pnl.Paint = function() end

    local header = vgui.Create("DPanel", pnl)
    header:Dock(TOP)
    header:SetTall(50)
    header.Paint = function(s, w, h)
        draw.SimpleText("Sélectionnez un destinataire", "CustomRP_Font_ATM_Subtitle", 0, 10, COLOR_TEXT)
        if amount > 0 then
            draw.SimpleText("Montant : " .. FormatMoney(amount), "CustomRP_Font_ATM_Body", 0, 35, COLOR_BLUE)
        end
    end

    local backBtn = CreateActionButton(pnl, 0, 0, 100, 36, "← Retour", COLOR_ACCENT, function()
        BuildDashboard(parent, contentPanel)
    end)
    backBtn:SetPos(contentPanel:GetWide() - 110, 5)

    local scroll = vgui.Create("DScrollPanel", pnl)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 15, 0, 0)

    local sbar = scroll:GetVBar()
    sbar:SetWide(4)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h) draw.RoundedBox(2, 0, 0, w, h, col_sep) end

    if #playerList == 0 then
        local empty = vgui.Create("DPanel", scroll)
        empty:Dock(TOP)
        empty:SetTall(60)
        empty.Paint = function(s, w, h)
            draw.SimpleText("Aucun joueur disponible pour le virement.", "CustomRP_Font_ATM_Body", w / 2, h / 2, COLOR_TEXT_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    for idx = 1, #playerList do
        local pData = playerList[idx]
        local card = vgui.Create("DButton", scroll)
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, 8)
        card:SetTall(56)
        card:SetText("")
        card.hoverLerp = 0

        card.Paint = function(s, w, h)
            s.hoverLerp = Lerp(FrameTime() * 10, s.hoverLerp, s:IsHovered() and 1 or 0)
            col_player_bg.a = 120 + 30 * s.hoverLerp
            draw.RoundedBox(8, 0, 0, w, h, col_player_bg)
            draw.RoundedBoxEx(8, 0, 0, 4, h, pData.jobColor, true, false, true, false)
            surface.SetDrawColor(pData.jobColor.r, pData.jobColor.g, pData.jobColor.b, 10 + 20 * s.hoverLerp)
            surface.DrawRect(4, 0, 40, h)
            draw.SimpleText(pData.name, "CustomRP_Font_ATM_Player", 18, 14, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(pData.job, "CustomRP_Font_ATM_PlayerJob", 18, 34, COLOR_TEXT_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(pData.jobColor.r, pData.jobColor.g, pData.jobColor.b, 10 + 40 * s.hoverLerp)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        card.DoClick = function()
            if amount <= 0 then
                AddNotification("Veuillez entrer un montant valide avant de sélectionner.", true)
                return
            end
            net.Start("CustomRP_ATM_Transfer")
                net.WriteInt(amount, 32)
                net.WriteString(pData.steamid)
            net.SendToServer()
        end
    end
end

function BuildDashboard(parent, contentPanel)
    contentPanel:Clear()

    local pnl = vgui.Create("DPanel", contentPanel)
    pnl:Dock(FILL)
    pnl:SetAlpha(0)
    pnl:AlphaTo(255, 0.3, 0)
    pnl.Paint = function() end

    local cw = contentPanel:GetWide()
    local cardW = (cw - 20) / 2
    local wallet = FormatMoney(LocalPlayer():GetMoney())
    local bank = FormatMoney(bankBalance)

    local walletCard = CreateStatCard(pnl, 0, 10, cardW, 100, "PORTEFEUILLE", wallet, COLOR_SUCCESS)
    local bankCard = CreateStatCard(pnl, cardW + 20, 10, cardW, 100, "COMPTE BANCAIRE", bank, COLOR_BLUE)

    local sep = vgui.Create("DPanel", pnl)
    sep:SetPos(0, 125)
    sep:SetSize(cw, 1)
    sep.Paint = function(s, w, h)
        surface.SetDrawColor(COLOR_BORDER_LIGHT)
        surface.DrawRect(0, 0, w, h)
    end

    local inputLabel = vgui.Create("DPanel", pnl)
    inputLabel:SetPos(0, 140)
    inputLabel:SetSize(cw, 20)
    inputLabel.Paint = function(s, w, h)
        draw.SimpleText("MONTANT DE LA TRANSACTION", "CustomRP_Font_ATM_Small", 0, 0, COLOR_TEXT_MUTED)
    end

    local moneyInput = CreateStyledTextEntry(pnl, 0, 165, cw, 50)
    local btnW = (cw - 30) / 3
    local btnY = 235

    CreateActionButton(pnl, 0, btnY, btnW, 52, "DÉPOSER", COLOR_SUCCESS, function()
        local amount = tonumber(moneyInput:GetText()) or 0
        if amount <= 0 then
            AddNotification("Veuillez entrer un montant valide.", true)
            return
        end
        net.Start("CustomRP_ATM_Deposit")
            net.WriteInt(math.floor(amount), 32)
        net.SendToServer()
    end)

    CreateActionButton(pnl, btnW + 15, btnY, btnW, 52, "RETIRER", COLOR_ACCENT, function()
        local amount = tonumber(moneyInput:GetText()) or 0
        if amount <= 0 then
            AddNotification("Veuillez entrer un montant valide.", true)
            return
        end
        net.Start("CustomRP_ATM_Withdraw")
            net.WriteInt(math.floor(amount), 32)
        net.SendToServer()
    end)

    CreateActionButton(pnl, (btnW + 15) * 2, btnY, btnW, 52, "VIREMENT", COLOR_BLUE, function()
        local amount = tonumber(moneyInput:GetText()) or 0
        ShowTransferPanel(parent, contentPanel, amount)
    end)

    local presetY = 305
    local presets = { 1000, 5000, 10000, 50000, 100000 }
    local presetW = (cw - (#presets - 1) * 8) / #presets

    for i = 1, #presets do
        local preset = presets[i]
        local px = (i - 1) * (presetW + 8)
        local pbtn = vgui.Create("DButton", pnl)
        pbtn:SetPos(px, presetY)
        pbtn:SetSize(presetW, 32)
        pbtn:SetText("")
        pbtn.hoverLerp = 0
        pbtn.Paint = function(s, w, h)
            s.hoverLerp = Lerp(FrameTime() * 10, s.hoverLerp, s:IsHovered() and 1 or 0)
            col_preset_bg.a = 5 + 10 * s.hoverLerp
            draw.RoundedBox(4, 0, 0, w, h, col_preset_bg)
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            col_preset_txt.r = COLOR_TEXT.r
            col_preset_txt.g = COLOR_TEXT.g
            col_preset_txt.b = COLOR_TEXT.b
            col_preset_txt.a = 150 + 105 * s.hoverLerp
            draw.SimpleText(FormatMoney(preset), "CustomRP_Font_ATM_Small", w / 2, h / 2, col_preset_txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        pbtn.DoClick = function()
            moneyInput:SetText(tostring(preset))
        end
    end

    timer.Create("ATM.UpdateCards", 0.5, 0, function()
        if not IsValid(pnl) then timer.Remove("ATM.UpdateCards") return end
        walletCard.displayValue = FormatMoney(LocalPlayer():GetMoney())
        bankCard.displayValue = FormatMoney(bankBalance)
    end)
end

local function OpenATMMenu()
    if IsValid(ATMFrame) then ATMFrame:Remove() end
    notifications = {}

    local frameW, frameH = 560, 420

    ATMFrame = vgui.Create("DFrame")
    ATMFrame:SetSize(frameW, frameH)
    ATMFrame:Center()
    ATMFrame:SetTitle("")
    ATMFrame:MakePopup()
    ATMFrame:SetDraggable(false)
    ATMFrame:ShowCloseButton(false)
    ATMFrame:SetAlpha(0)
    ATMFrame:AlphaTo(255, 0.3, 0)

    ATMFrame.Paint = function(s, w, h)
        DrawBlur(s, 8)
        draw.RoundedBox(12, 0, 0, w, h, COLOR_BG)
        surface.SetDrawColor(COLOR_BORDER)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    ATMFrame.Think = function(s)
        if not IsValid(atmEntity) then
            s:AlphaTo(0, 0.15, 0, function() if IsValid(s) then s:Remove() end end)
            return
        end
        local dist = LocalPlayer():GetPos():Distance(atmEntity:GetPos())
        if dist > CustomRP.Banking.MaxDistance then
            s:AlphaTo(0, 0.15, 0, function() if IsValid(s) then s:Remove() end end)
        end
    end

    local closeBtn = vgui.Create("DButton", ATMFrame)
    closeBtn:SetSize(36, 36)
    closeBtn:SetPos(frameW - 46, 10)
    closeBtn:SetText("✕")
    closeBtn:SetFont("CustomRP_Font_ATM_Body")
    closeBtn:SetTextColor(COLOR_TEXT_MUTED)
    closeBtn.bgAlpha = 0
    closeBtn.Paint = function(s, w, h)
        s.bgAlpha = Lerp(FrameTime() * 10, s.bgAlpha, s:IsHovered() and 255 or 0)
        if s.bgAlpha > 1 then
            col_close_hover.a = s.bgAlpha
            draw.RoundedBox(w / 2, 0, 0, w, h, col_close_hover)
            s:SetTextColor(color_white)
        else
            s:SetTextColor(COLOR_TEXT_MUTED)
        end
    end
    closeBtn.DoClick = function()
        ATMFrame:AlphaTo(0, 0.15, 0, function() if IsValid(ATMFrame) then ATMFrame:Remove() end end)
    end

    local headerPnl = vgui.Create("DPanel", ATMFrame)
    headerPnl:SetPos(20, 10)
    headerPnl:SetSize(frameW - 80, 40)
    headerPnl.Paint = function(s, w, h)
        draw.SimpleText("BANQUE", "CustomRP_Font_ATM_Title", 0, h / 2, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(" ATM", "CustomRP_Font_ATM_Title", surface.GetTextSize("BANQUE"), h / 2, COLOR_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local contentPanel = vgui.Create("DPanel", ATMFrame)
    contentPanel:SetPos(20, 55)
    contentPanel:SetSize(frameW - 40, frameH - 75)
    contentPanel.Paint = function() end
    contentPanel.PaintOver = function(s, w, h)
        DrawNotifications(s, w)
    end

    local bootPanel = vgui.Create("DPanel", contentPanel)
    bootPanel:Dock(FILL)
    bootPanel.startTime = CurTime()
    bootPanel.dotCount = 0
    bootPanel.lastDot = CurTime()

    bootPanel.Paint = function(s, w, h)
        local elapsed = CurTime() - s.startTime
        local alpha = math.Clamp(elapsed / 0.5, 0, 1) * 255
        if CurTime() - s.lastDot > 0.4 then
            s.dotCount = (s.dotCount + 1) % 4
            s.lastDot = CurTime()
        end
        local dots = string.rep(".", s.dotCount)
        local iconSize = 60
        local pulse = math.sin(CurTime() * 3) * 0.15 + 0.85
        
        col_boot_pulse.a = alpha * pulse
        draw.RoundedBox(12, w / 2 - iconSize / 2, h / 2 - 60, iconSize, iconSize, col_boot_pulse)
        
        col_boot_txt.a = alpha
        draw.SimpleText("$", "CustomRP_Font_ATM_Stat", w / 2, h / 2 - 30, col_boot_txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Insertion de la carte" .. dots, "CustomRP_Font_ATM_Boot", w / 2, h / 2 + 30, col_boot_txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if ServerName ~= "" then
            col_boot_txt.r = COLOR_TEXT_MUTED.r
            col_boot_txt.g = COLOR_TEXT_MUTED.g
            col_boot_txt.b = COLOR_TEXT_MUTED.b
            col_boot_txt.a = alpha * 0.6
            draw.SimpleText(ServerName, "CustomRP_Font_ATM_Small", w / 2, h / 2 + 65, col_boot_txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            col_boot_txt.r = 255
            col_boot_txt.g = 255
            col_boot_txt.b = 255
        end
    end

    timer.Simple(2, function()
        if not IsValid(ATMFrame) or not IsValid(bootPanel) then return end
        bootPanel:AlphaTo(0, 0.3, 0, function()
            if IsValid(bootPanel) then bootPanel:Remove() end
            if IsValid(ATMFrame) then
                BuildDashboard(ATMFrame, contentPanel)
            end
        end)
    end)
end

net.Receive("CustomRP_ATM_Open", function()
    bankBalance = net.ReadInt(32)
    atmEntity = net.ReadEntity()
    OpenATMMenu()
end)

net.Receive("CustomRP_ATM_UpdateBalance", function()
    bankBalance = net.ReadInt(32)
end)

net.Receive("CustomRP_ATM_Notification", function()
    local msg = net.ReadString()
    local isError = net.ReadBool()
    AddNotification(msg, isError)
end)

net.Receive("CustomRP_ATM_PlayerList", function()
    playerList = {}
    local count = net.ReadUInt(8)
    for i = 1, count do
        table.insert(playerList, {
            name = net.ReadString(),
            steamid = net.ReadString(),
            job = net.ReadString(),
            jobColor = net.ReadColor()
        })
    end
end)
