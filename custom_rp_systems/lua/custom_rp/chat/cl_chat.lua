if not CLIENT then return end

local blur = Material("pp/blurscreen")
local col_bg = Color(10, 10, 12, 220)
local col_text = Color(255, 255, 255, 255)
local col_accent = Color(230, 45, 45, 255)

local col_close_hover = Color(230, 45, 45, 0)
local col_entry_bg = Color(10, 10, 12, 230)
local col_entry_accent = Color(230, 45, 45, 0)
local col_entry_placeholder = Color(150, 150, 150, 100)
local col_emoji_btn = Color(255, 255, 255, 0)
local col_emoji_menu_bg = Color(20, 20, 25, 230)
local col_emoji_menu_border = Color(255, 255, 255, 10)
local col_search_bg = Color(0, 0, 0, 150)
local col_search_border = Color(255, 255, 255, 20)
local col_search_placeholder = Color(150, 150, 150, 150)
local col_row_hover = Color(255, 255, 255, 5)
local col_row_mention = Color(255, 200, 50, 15)
local col_row_badge_bg = Color(255, 255, 255, 255)
local col_row_badge_txt = Color(255, 255, 255, 255)
local col_autocomplete_bg = Color(15, 15, 20, 240)
local col_autocomplete_btn = Color(255, 255, 255, 10)
local col_grip = Color(255, 255, 255, 50)
local col_grip_emoji = Color(255, 255, 255, 30)

local EMOJIS = {
    [":)"] = "icon16/emoticon_smile.png",
    [":D"] = "icon16/emoticon_grin.png",
    [":("] = "icon16/emoticon_unhappy.png",
    [":O"] = "icon16/emoticon_surprised.png",
    ["xD"] = "icon16/emoticon_evilgrin.png",
    ["<3"] = "icon16/heart.png",
    [":p"] = "icon16/emoticon_tongue.png"
}

local CustomEmojis = {}
local CustomEmojisMat = {}
local emojiFiles, _ = file.Find("materials/chat/emojis/*.png", "GAME")
if emojiFiles then
    for _, f in ipairs(emojiFiles) do
        local name = string.StripExtension(f)
        local path = "chat/emojis/" .. f
        CustomEmojis[name] = path
        CustomEmojisMat[name] = Material(path, "noclamp smooth")
    end
end

local function PaintBlur(pnl, w, h, alpha)
    local x, y = pnl:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255, 255 * alpha)
    surface.SetMaterial(blur)
    render.UpdateScreenEffectTexture() 
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (5 * alpha)) 
        blur:Recompute()
        render.SetScissorRect(x, y, x + w, y + h, true)
        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

local ChatFrame = nil
local ChatScroll = nil
local ChatEntry = nil
local AutoCompleteMenu = nil
local EmojiBtn = nil
local EmojiMenu = nil

local isChatting = false
local lastMsgTime = CurTime()
local escapePressed = false

local history = {}
local COMMANDS_LIST = { "/dropmoney", "/ticket", "/goto", "/bring", "/return", "/job", "/ooc", "/me", "/pm", "/yell", "/w", "/advert", "//", "/roll" }

local function ShouldShowMessage(msgType) return true end

local function ProcessFormatting(text)
    local rowEmojis = {}
    
    for str, icon in pairs(EMOJIS) do
        local safeStr = string.gsub(str, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
        text = string.gsub(text, safeStr, function()
            table.insert(rowEmojis, icon)
            return "<font=CustomRP_Font_Chat>[E]</font>"
        end)
    end
    
    local mentionedMe = false
    local lowerText = string.lower(text)
    local plys = player.GetAll()
    for i = 1, #plys do
        local p = plys[i]
        local nick = p:Nick()
        local searchNick = string.gsub(string.lower(nick), "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
        
        local s, e = string.find(lowerText, "@" .. searchNick)
        if s then
            local exactMatch = string.sub(text, s, e)
            local escapedMatch = string.gsub(exactMatch, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
            text = string.gsub(text, escapedMatch, "</font><font=CustomRP_Font_ChatBold><color=255,200,50>@" .. nick .. "</color></font><font=CustomRP_Font_Chat><color=255,255,255>")
            if p == LocalPlayer() then mentionedMe = true end
            lowerText = string.lower(text)
        end
    end
    
    text = string.gsub(text, ":([%w_%-]+):", function(emojiName)
        if CustomEmojis[emojiName] then
            table.insert(rowEmojis, CustomEmojis[emojiName])
            return "<font=CustomRP_Font_Chat>[E]</font>"
        end
        return ":" .. emojiName .. ":"
    end)
    
    text = string.gsub(text, "<rainbow>(.-)</rainbow>", function(content)
        local chars = {}
        for i = 1, #content do
            local c = string.sub(content, i, i)
            table.insert(chars, string.format("<color=1,2,%d,254>%s</color>", (i % 2 == 0) and 3 or 4, c))
        end
        return table.concat(chars)
    end)
    
    text = string.gsub(text, "<red>(.-)</red>", "<color=255,50,50>%1</color>")
    text = string.gsub(text, "<blue>(.-)</blue>", "<color=50,150,255>%1</color>")
    text = string.gsub(text, "<green>(.-)</green>", "<color=50,255,50>%1</color>")
    text = string.gsub(text, "<gold>(.-)</gold>", "<color=255,200,50>%1</color>")
    
    text = string.gsub(text, "%*%*(.-)%*%*", "</font><font=CustomRP_Font_ChatBold>%1</font><font=CustomRP_Font_Chat>")
    text = string.gsub(text, "%*(.-)%*", "</font><font=CustomRP_Font_ChatItalic>%1</font><font=CustomRP_Font_Chat>")
    text = string.gsub(text, "__(.-)__", "<color=100,200,255>%1</color><color=255,255,255>")
    text = string.gsub(text, "(https?://[%w-_%.%?%.:/%+=&]+)", "<color=100,150,255>%1</color><color=255,255,255>")

    return text, mentionedMe, rowEmojis
end

local function CreateChatbox()
    if IsValid(ChatFrame) then return end

    local w = cookie.GetNumber("CustomRP_Chat_W", 500)
    local h = cookie.GetNumber("CustomRP_Chat_H", 350)
    local x = cookie.GetNumber("CustomRP_Chat_X", 30)
    local y = cookie.GetNumber("CustomRP_Chat_Y", ScrH() - h - 150)

    ChatFrame = vgui.Create("DFrame")
    ChatFrame:SetPos(x, y)
    ChatFrame:SetSize(w, h)
    ChatFrame:SetTitle("")
    ChatFrame:ShowCloseButton(false)
    ChatFrame:SetSizable(true)
    ChatFrame:SetDraggable(true)
    ChatFrame:SetMinHeight(200)
    ChatFrame:SetMinWidth(350)
    
    if IsValid(ChatFrame.btnClose) then ChatFrame.btnClose:Hide() end
    if IsValid(ChatFrame.btnMaxim) then ChatFrame.btnMaxim:Hide() end
    if IsValid(ChatFrame.btnMinim) then ChatFrame.btnMinim:Hide() end
    if IsValid(ChatFrame.lblTitle) then ChatFrame.lblTitle:Hide() end
    
    ChatFrame.Paint = function(self, fw, fh)
        if not isChatting then return end 
        PaintBlur(self, fw, fh, 1)
        draw.RoundedBox(12, 0, 0, fw, fh, col_bg)
    end
    
    ChatFrame.Think = function(self)
        if not isChatting then return end
        if input.IsKeyDown(KEY_ESCAPE) then
            if not escapePressed then
                escapePressed = true
                chat.Close()
                gui.HideGameUI()
            end
        else
            escapePressed = false
        end
    end
    
    local oldLayout = ChatFrame.PerformLayout
    ChatFrame.PerformLayout = function(self, pw, ph)
        if oldLayout then oldLayout(self, pw, ph) end
        if IsValid(self.btnClose) then self.btnClose:Hide() end
        if IsValid(EmojiBtn) then EmojiBtn:SetPos(pw - 40, ph - 45) end
        if IsValid(EmojiMenu) and EmojiMenu:IsVisible() then
            EmojiMenu:SetPos(pw - 260, ph - EmojiMenu:GetTall() - 55)
        end
        if IsValid(ChatFrame.closeBtn) then ChatFrame.closeBtn:SetPos(pw - 30, 5) end
    end

    local headerPnl = vgui.Create("DPanel", ChatFrame)
    ChatFrame.Header = headerPnl
    headerPnl:Dock(TOP) 
    headerPnl:SetTall(24)
    headerPnl.Paint = function() end
    
    local dragHandle = vgui.Create("DPanel", headerPnl)
    dragHandle:Dock(FILL)
    dragHandle:SetCursor("sizeall")
    dragHandle.Paint = function() end
    dragHandle.OnMousePressed = function(self, key)
        if key == MOUSE_LEFT then
            self.Dragging = true
            self.MouseX, self.MouseY = gui.MousePos()
            self.StartX, self.StartY = ChatFrame:GetPos()
            self:MouseCapture(true)
        end
    end
    dragHandle.OnMouseReleased = function(self, key)
        if key == MOUSE_LEFT and self.Dragging then
            self.Dragging = false
            self:MouseCapture(false)
            local fx, fy = ChatFrame:GetPos()
            cookie.Set("CustomRP_Chat_X", fx)
            cookie.Set("CustomRP_Chat_Y", fy)
        end
    end
    dragHandle.Think = function(self)
        if self.Dragging then
            local mx, my = gui.MousePos()
            ChatFrame:SetPos(self.StartX + mx - self.MouseX, self.StartY + my - self.MouseY)
        end
    end

    local closeBtn = vgui.Create("DButton", ChatFrame)
    ChatFrame.closeBtn = closeBtn
    closeBtn:SetSize(30, 30)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, bw, bh)
        if not isChatting then return end
        self.hoverLerp = Lerp(10 * FrameTime(), self.hoverLerp or 0, self:IsHovered() and 1 or 0)
        
        if self.hoverLerp > 0.01 then
            local size = 20
            col_close_hover.a = 220 * self.hoverLerp
            draw.RoundedBox(size / 2, (bw - size) / 2, (bh - size) / 2, size, size, col_close_hover)
        end
        
        local cx, cy = bw / 2, bh / 2
        local s = 10 
        local t = 2  
        local cVal = 150 + (105 * self.hoverLerp)
        surface.SetDrawColor(cVal, cVal, cVal, 255)
        draw.NoTexture()
        
        local rot = self.hoverLerp * 90
        surface.DrawTexturedRectRotated(cx, cy, s, t, 45 + rot)
        surface.DrawTexturedRectRotated(cx, cy, s, t, -45 + rot)
    end
    closeBtn.DoClick = function()
        surface.PlaySound("UI/buttonclick.wav")
        chat.Close()
    end

    ChatScroll = vgui.Create("DScrollPanel", ChatFrame)
    ChatScroll:Dock(FILL)
    ChatScroll:DockMargin(10, 5, 10, 5)
    
    local sbar = ChatScroll:GetVBar()
    sbar:SetWide(4)
    sbar:SetHideButtons(true)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(self, bw, bh)
        if isChatting then draw.RoundedBox(2, 0, 0, bw, bh, col_grip) end
    end

    ChatEntry = vgui.Create("DTextEntry", ChatFrame)
    ChatEntry:Dock(BOTTOM)
    ChatEntry:DockMargin(10, 5, 45, 10)
    ChatEntry:SetTall(40)
    ChatEntry:SetFont("CustomRP_Font_Chat")
    ChatEntry:SetTextColor(col_text)
    ChatEntry:SetCursorColor(col_accent)
    ChatEntry:SetHistoryEnabled(true)
    ChatEntry:SetPaintBackgroundEnabled(false) 
    ChatEntry:SetDrawLanguageID(false) 
    
    ChatEntry.Paint = function(self, pw, ph)
        if not isChatting then return end
        
        draw.RoundedBox(4, 0, 0, pw, ph, col_entry_bg)
        surface.SetDrawColor(255, 255, 255, 10)
        
        self.focusLerp = Lerp(10 * FrameTime(), self.focusLerp or 0, self:HasFocus() and 1 or 0)
        
        if self.focusLerp > 0.01 then
            local barW = pw * self.focusLerp
            col_entry_accent.a = 255 * self.focusLerp
            surface.SetDrawColor(col_entry_accent.r, col_entry_accent.g, col_entry_accent.b, col_entry_accent.a)
            surface.DrawRect((pw - barW) / 2, ph - 2, barW, 2)
        end
        
        if self:GetText() == "" then
            col_entry_placeholder.a = 100 - (50 * self.focusLerp)
            draw.SimpleText("Écrivez un message...", "CustomRP_Font_ChatItalic", 5, ph/2 - 1, col_entry_placeholder, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        self:DrawTextEntryText(self:GetTextColor(), Color(100, 150, 255, 150), self:GetCursorColor())
    end
    
    ChatEntry.OnKeyCodeTyped = function(self, code)
        if code == KEY_TAB and IsValid(AutoCompleteMenu) and AutoCompleteMenu:IsVisible() then
            if AutoCompleteMenu.isCmd then
                self:SetText(AutoCompleteMenu.firstChoice .. " ")
            else
                local curTxt = self:GetText()
                local newTxt = string.gsub(curTxt, "@[%w_]*$", AutoCompleteMenu.firstChoice .. " ")
                self:SetText(newTxt)
            end
            self:SetCaretPos(#self:GetText())
            AutoCompleteMenu:SetVisible(false)
            return true
        elseif code == KEY_ENTER or code == KEY_PAD_ENTER then
            self:OnEnter()
            return true
        end
    end
    
    ChatEntry.OnChange = function(self)
        local txt = self:GetText()
        local isCmd = string.StartWith(txt, "/") and not string.find(txt, " ")
        local atMatch = string.match(txt, "@([%w_]*)$")
        
        if isCmd or atMatch then
            if not IsValid(AutoCompleteMenu) then
                AutoCompleteMenu = vgui.Create("DPanel", ChatFrame)
                AutoCompleteMenu:SetSize(180, 120)
                AutoCompleteMenu:SetZPos(100)
                AutoCompleteMenu.Paint = function(s, pw, ph)
                    draw.RoundedBox(6, 0, 0, pw, ph, col_autocomplete_bg)
                    surface.SetDrawColor(255, 255, 255, 40)
                    surface.DrawOutlinedRect(0, 0, pw, ph, 1)
                end
            end
            
            AutoCompleteMenu:Clear()
            local matches = 0
            AutoCompleteMenu.firstChoice = nil
            AutoCompleteMenu.isCmd = isCmd
            
            local function AddChoice(label, replaceStr)
                if matches == 0 then AutoCompleteMenu.firstChoice = replaceStr end
                matches = matches + 1
                local btn = vgui.Create("DButton", AutoCompleteMenu)
                btn:Dock(TOP)
                btn:SetTall(25)
                btn:SetText(label)
                btn:SetFont("CustomRP_Font_ChatMenu")
                btn:SetTextColor(col_text)
                btn.Paint = function(s, bw, bh)
                    if s:IsHovered() then draw.RoundedBox(0, 0, 0, bw, bh, col_autocomplete_btn) end
                end
                btn.DoClick = function()
                    if isCmd then
                        self:SetText(replaceStr .. " ")
                    else
                        local curTxt = self:GetText()
                        local newTxt = string.gsub(curTxt, "@[%w_]*$", replaceStr .. " ")
                        self:SetText(newTxt)
                    end
                    self:SetCaretPos(#self:GetText())
                    self:RequestFocus()
                    AutoCompleteMenu:SetVisible(false)
                end
            end
            
            if isCmd then
                for i = 1, #COMMANDS_LIST do
                    local cmd = COMMANDS_LIST[i]
                    if string.StartWith(cmd, txt) then
                        AddChoice(cmd, cmd)
                    end
                end
            elseif atMatch then
                local plys = player.GetAll()
                for i = 1, #plys do
                    local p = plys[i]
                    local nick = p:Nick()
                    if atMatch == "" or string.find(string.lower(nick), string.lower(atMatch), 1, true) then
                        AddChoice("@" .. nick, nick)
                    end
                end
            end
            
            if matches > 0 then
                AutoCompleteMenu:SetTall(math.min(matches * 25 + 5, 200))
                AutoCompleteMenu:SetPos(10, ChatFrame:GetTall() - ChatEntry:GetTall() - 15 - AutoCompleteMenu:GetTall())
                AutoCompleteMenu:SetVisible(true)
            else
                AutoCompleteMenu:SetVisible(false)
            end
        else
            if IsValid(AutoCompleteMenu) then AutoCompleteMenu:SetVisible(false) end
        end
    end
    
    ChatEntry.OnEnter = function(self)
        local txt = string.Trim(self:GetText())
        if txt ~= "" then
            if string.StartWith(txt, "///") then
                local ticketMsg = string.Trim(string.sub(txt, 4))
                if ticketMsg == "" then
                    LocalPlayer():ConCommand("say /ticket")
                else
                    LocalPlayer():ConCommand("say /ticket " .. ticketMsg)
                end
            else
                LocalPlayer():ConCommand("say \"" .. txt .. "\"")
            end
            self:AddHistory(txt)
        end
        chat.Close()
    end
    
    EmojiBtn = vgui.Create("DButton", ChatFrame)
    EmojiBtn:SetSize(30, 30)
    EmojiBtn:SetText("")
    EmojiBtn.Paint = function(self, w, h)
        if not isChatting then return end
        col_emoji_btn.a = self:IsHovered() and 255 or 150
        surface.SetDrawColor(col_emoji_btn.r, col_emoji_btn.g, col_emoji_btn.b, col_emoji_btn.a)
        surface.SetMaterial(Material("icon16/emoticon_smile.png"))
        surface.DrawTexturedRect(w/2 - 8, h/2 - 8, 16, 16)
    end
    EmojiBtn.DoClick = function()
        if IsValid(EmojiMenu) then
            EmojiMenu:SetVisible(not EmojiMenu:IsVisible())
            if EmojiMenu:IsVisible() then 
                EmojiMenu:MoveToFront()
                if IsValid(EmojiMenu.search) then EmojiMenu.search:RequestFocus() end
            end
            return
        end
        
        EmojiMenu = vgui.Create("DPanel", ChatFrame)
        EmojiMenu:SetSize(250, 240)
        EmojiMenu:SetPos(ChatFrame:GetWide() - 270, ChatFrame:GetTall() - EmojiMenu:GetTall() - 55)
        EmojiMenu:SetZPos(100)
        EmojiMenu.Paint = function(s, w, h)
            PaintBlur(s, w, h, 1)
            draw.RoundedBox(8, 0, 0, w, h, col_emoji_menu_bg)
            surface.SetDrawColor(col_emoji_menu_border.r, col_emoji_menu_border.g, col_emoji_menu_border.b, col_emoji_menu_border.a)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        
        local searchBar = vgui.Create("DTextEntry", EmojiMenu)
        searchBar:Dock(TOP)
        searchBar:DockMargin(5, 5, 5, 0)
        searchBar:SetTall(25)
        searchBar:SetPlaceholderText("Rechercher un emoji...")
        searchBar:SetFont("CustomRP_Font_ChatMenu")
        searchBar:SetTextColor(col_text)
        searchBar.Paint = function(self, pw, ph)
            draw.RoundedBox(4, 0, 0, pw, ph, col_search_bg)
            surface.SetDrawColor(col_search_border.r, col_search_border.g, col_search_border.b, col_search_border.a)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            
            if self:GetText() == "" and not self:HasFocus() then
                draw.SimpleText("Rechercher...", "CustomRP_Font_ChatMenu", 5, ph/2 - 1, col_search_placeholder, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            self:DrawTextEntryText(self:GetTextColor(), Color(100, 150, 255, 150), self:GetCursorColor())
        end
        EmojiMenu.search = searchBar
        
        local scroll = vgui.Create("DScrollPanel", EmojiMenu)
        scroll:Dock(FILL)
        scroll:DockMargin(5, 5, 5, 5)
        local sbar = scroll:GetVBar()
        sbar:SetWide(4)
        sbar:SetHideButtons(true)
        sbar.Paint = function() end
        sbar.btnGrip.Paint = function(s, bw, bh) draw.RoundedBox(2, 0, 0, bw, bh, col_grip_emoji) end
        
        local layout = vgui.Create("DIconLayout", scroll)
        layout:Dock(FILL)
        layout:SetSpaceX(4)
        layout:SetSpaceY(4)
        
        local topEmojis = {
            "grinning", "smiley", "smile", "grin", "laughing", "sweat_smile", "joy", "rolling_on_the_floor_laughing",
            "blush", "innocent", "slightly_smiling_face", "upside_down_face", "wink", "relieved", "heart_eyes",
            "smiling_face_with_3_hearts", "kissing_heart", "kissing", "kissing_smiling_eyes", "kissing_closed_eyes",
            "yum", "stuck_out_tongue", "stuck_out_tongue_winking_eye", "zany_face", "stuck_out_tongue_closed_eyes",
            "money_mouth_face", "hugging_face", "hand_over_mouth", "shushing_face", "thinking_face", "zipper_mouth_face",
            "raised_eyebrow", "neutral_face", "expressionless", "no_mouth", "smirk", "unamused", "face_with_rolling_eyes",
            "grimacing", "lying_face", "relieved", "pensive", "sleepy", "drooling_face", "sleeping", "mask",
            "thermometer_face", "head_bandage", "nauseated_face", "vomiting_face", "sneezing_face", "hot_face",
            "cold_face", "woozy_face", "dizzy_face", "exploding_head", "cowboy_hat_face", "partying_face", "sunglasses",
            "nerd_face", "monocle_face", "confused", "worried", "slightly_frowning_face", "frowning_face", "open_mouth",
            "hushed", "astonished", "flushed", "pleading_face", "frowning", "anguished", "fearful", "cold_sweat",
            "disappointed_relieved", "cry", "sob", "scream", "confounded", "persevere", "disappointed", "sweat",
            "weary", "tired_face", "triumph", "rage", "angry", "cursing_face", "smiling_imp", "imp", "skull", "skull_and_crossbones",
            "hankey", "clown_face", "alien", "space_invader", "robot", "ghost"
        }
        local emojiPriority = {}
        for i, name in ipairs(topEmojis) do emojiPriority[name] = i end
        
        local sortedNames = {}
        for name, _ in pairs(CustomEmojis) do table.insert(sortedNames, name) end
        table.sort(sortedNames, function(a, b)
            local pA = emojiPriority[a] or 9999
            local pB = emojiPriority[b] or 9999
            if pA ~= pB then return pA < pB end
            return a < b
        end)
        
        local function Populate(filter)
            layout:Clear()
            local lowerFilter = string.lower(filter or "")
            for idx = 1, #sortedNames do
                local name = sortedNames[idx]
                if lowerFilter == "" or string.find(string.lower(name), lowerFilter) then
                    local btn = layout:Add("DImageButton")
                    btn:SetSize(24, 24)
                    btn:SetImage(CustomEmojis[name])
                    btn:SetTooltip(":" .. name .. ":")
                    btn.DoClick = function()
                        local curTxt = ChatEntry:GetText()
                        ChatEntry:SetText(curTxt .. ":" .. name .. ": ")
                        ChatEntry:SetCaretPos(#ChatEntry:GetText())
                        ChatEntry:RequestFocus()
                        EmojiMenu:SetVisible(false)
                    end
                end
            end
        end
        
        Populate("")
        
        searchBar.OnChange = function(self)
            Populate(self:GetText())
        end
        
        searchBar.OnKeyCodeTyped = function(self, code)
            if code == KEY_ESCAPE then
                EmojiMenu:SetVisible(false)
                ChatEntry:RequestFocus()
            end
        end
        
        searchBar:RequestFocus()
    end
    
    ChatFrame:SetVisible(true)
    ChatEntry:SetVisible(false)
    headerPnl:SetVisible(false)
    EmojiBtn:SetVisible(false)
end

local rainbow_col = Color(0, 0, 0)
local function GetRainbowColor(hue, s, v)
    local c = v * s
    local x = c * (1 - math.abs((hue / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if hue < 60 then
        r, g, b = c, x, 0
    elseif hue < 120 then
        r, g, b = x, c, 0
    elseif hue < 180 then
        r, g, b = 0, c, x
    elseif hue < 240 then
        r, g, b = 0, x, c
    elseif hue < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    rainbow_col.r = (r + m) * 255
    rainbow_col.g = (g + m) * 255
    rainbow_col.b = (b + m) * 255
    return rainbow_col
end

local function AddLine(msgType, ply, text, isDead)
    if not IsValid(ChatFrame) then CreateChatbox() end
    
    local row = ChatScroll:Add("DButton")
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 8)
    row:SetText("")
    row.msgType = msgType
    row.rawText = text
    row.timeAdded = CurTime()
    
    local imgUrl = string.match(text, "https?://[%w-_%.%?%.:/%+=&]+%.png") or string.match(text, "https?://[%w-_%.%?%.:/%+=&]+%.jpg")
    local timeStr = os.date("%H:%M")
    local mStr = "<font=CustomRP_Font_Chat><color=120,120,120>[" .. timeStr .. "] </color>"
    
    if msgType == "OOC" then mStr = mStr .. "<color=200,200,200>[OOC] </color>" end
    if msgType == "Admin" then mStr = mStr .. "<color=230,45,45>[ADMIN] </color>" end
    if msgType == "PM" then mStr = mStr .. "<color=230,100,200>[PM] </color>" end
    if msgType == "ROLL" then mStr = mStr .. "<color=100,255,100>[ROLL] </color>" end
    if msgType == "ADVERT" then mStr = mStr .. "<color=255,215,0>[PUBLICITÉ] </color>" end
    if isDead then mStr = mStr .. "<color=255,50,50>*MORT* </color>" end
    
    local avatarOffset = 0
    if IsValid(ply) then
        avatarOffset = 34
        local ava = vgui.Create("AvatarImage", row)
        ava:SetSize(24, 24)
        ava:SetPos(0, 2)
        ava:SetPlayer(ply, 32)
    end
    
    if msgType == "RP" or msgType == "ME" or msgType == "YELL" or msgType == "WHISPER" then
        local col = "255,255,200"
        if msgType == "ME" then col = "255,150,255" end
        if msgType == "YELL" then col = "255,100,100" end
        if msgType == "WHISPER" then col = "150,200,255" end
        
        mStr = mStr .. "<font=CustomRP_Font_ChatItalic><color=" .. col .. ">*** "
        if IsValid(ply) then mStr = mStr .. ply:Nick() .. " " end
    else
        if IsValid(ply) then
            if ply:IsSuperAdmin() then
                mStr = mStr .. "<color=0,0,0,0><font=CustomRP_Font_ChatBold>[FONDATEUR]</font></color> "
            elseif ply:IsUserGroup("vip") then
                mStr = mStr .. "<color=0,0,0,0><font=CustomRP_Font_ChatBold>[VIP]</font></color> "
            elseif ply:IsAdmin() then
                mStr = mStr .. "<color=0,0,0,0><font=CustomRP_Font_ChatBold>[ADMIN]</font></color> "
            end
            
            local nameStr = ply:Nick()
            local tc = team.GetColor(ply:Team())
            if msgType == "PM" then tc = Color(230, 100, 200) end
            if msgType == "ADVERT" then tc = Color(255, 215, 0) end
            mStr = mStr .. string.format("<color=%d,%d,%d>%s</color>", tc.r, tc.g, tc.b, nameStr)
        else
            if msgType == "System" then
                mStr = mStr .. "<color=150,230,150>"
            elseif msgType == "Raw" then
                mStr = mStr .. "<color=255,255,255>"
            else
                mStr = mStr .. "<color=150,150,150>Console"
            end
        end
        mStr = mStr .. ((msgType == "System" or msgType == "Raw") and "" or "<color=255,255,255>: ")
    end
    
    local formattedText, mentionedMe, rowEmojis = ProcessFormatting(text)
    
    if msgType == "ADVERT" then
        mStr = mStr .. "<color=255,240,150>" .. formattedText .. "</color>"
    elseif msgType == "ME" then
        mStr = mStr .. "<color=255,150,255>" .. formattedText .. "</color>"
    elseif msgType == "YELL" then
        mStr = mStr .. "<color=255,100,100>" .. formattedText .. "</color>"
    elseif msgType == "WHISPER" then
        mStr = mStr .. "<color=150,200,255>" .. formattedText .. "</color>"
    else
        mStr = mStr .. formattedText
    end
    
    mStr = mStr .. "</color></font>"
    
    local parsed = markup.Parse(mStr, ChatFrame:GetWide() - 40 - avatarOffset)
    
    row.emojiBlocks = {}
    if rowEmojis and #rowEmojis > 0 then
        local emojiIndex = 1
        for j = 1, #parsed.blocks do
            local blk = parsed.blocks[j]
            if blk.text == "[E]" then
                table.insert(row.emojiBlocks, {
                    blk = blk,
                    path = rowEmojis[emojiIndex]
                })
                blk.text = "" 
                emojiIndex = emojiIndex + 1
            end
        end
    end
    
    for j = 1, #parsed.blocks do
        local blk = parsed.blocks[j]
        if blk.colour and blk.colour.a == 0 and string.match(blk.text, "^%[(.-)%]$") then
            local badgeName = string.match(blk.text, "^%[(.-)%]$")
            if badgeName == "FONDATEUR" or badgeName == "VIP" or badgeName == "ADMIN" then
                table.insert(row.emojiBlocks, { blk = blk, badge = badgeName })
                blk.text = ""
            end
        end
        if blk.colour and blk.colour.r == 1 and blk.colour.g == 2 and blk.colour.a == 254 then
            blk.isRainbow = true
        end
    end
    
    local previewH = 0
    local imgPanel = nil
    if imgUrl then
        previewH = 120
        imgPanel = vgui.Create("DHTML", row)
        imgPanel:SetSize(200, 110)
        imgPanel:SetHTML([[
            <body style="margin:0; overflow:hidden; background:transparent; display:flex; justify-content:left; align-items:center; height:100%;">
                <img src="]] .. imgUrl .. [[" style="max-width:100%; max-height:100%; border-radius:4px;">
            </body>
        ]])
        local clickBtn = vgui.Create("DButton", imgPanel)
        clickBtn:Dock(FILL)
        clickBtn:SetText("")
        clickBtn.Paint = function() end
        clickBtn.DoClick = function() gui.OpenURL(imgUrl) end
    end
    
    row:SetTall(math.max(28, parsed:GetHeight()) + previewH + 4)
    if IsValid(imgPanel) then
        imgPanel:SetPos(avatarOffset, parsed:GetHeight() + 4)
    end
    
    row.Think = function(self)
        if not isChatting then
            local timeSinceMsg = CurTime() - self.timeAdded
            if timeSinceMsg > 12 then
                if self:IsVisible() then self:SetVisible(false) end
                return
            elseif timeSinceMsg > 10 then
                self:SetAlpha((1 - ((timeSinceMsg - 10) / 2)) * 255)
            end
        elseif not self:IsVisible() and ShouldShowMessage(self.msgType) then
            self:SetVisible(true)
            self:SetAlpha(255)
        end
    end
    
    row.Paint = function(self, w, h)
        if isChatting and self:IsHovered() then
            draw.RoundedBox(4, avatarOffset - 4, 0, w - avatarOffset + 4, h, col_row_hover)
        end
        
        if mentionedMe then
            draw.RoundedBox(4, avatarOffset - 4, 0, w - avatarOffset + 4, h, col_row_mention)
        end
        
        for j = 1, #parsed.blocks do
            local blk = parsed.blocks[j]
            if blk.isRainbow then
                local h = (CurTime() * 150 + blk.offset.x) % 360
                local col = GetRainbowColor(h, 1, 1)
                blk.colour.r = col.r
                blk.colour.g = col.g
                blk.colour.b = col.b
                blk.colour.a = 255
            end
        end
        
        parsed:Draw(avatarOffset, 2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 255)
        
        if self.emojiBlocks then
            for j = 1, #self.emojiBlocks do
                local e = self.emojiBlocks[j]
                if e.path then
                    local mat = CustomEmojisMat[string.StripExtension(string.GetFileFromFilename(e.path))] or Material(e.path, "noclamp smooth")
                    if mat then
                        surface.SetDrawColor(255, 255, 255, 255)
                        surface.SetMaterial(mat)
                        surface.DrawTexturedRect(avatarOffset + e.blk.offset.x + 1, 2 + e.blk.offset.y - 1, 18, 18)
                    end
                elseif e.badge then
                    surface.SetFont("CustomRP_Font_ChatBold")
                    local bw, bh = surface.GetTextSize(e.badge)
                    
                    local r, g, b = 100, 100, 100
                    if e.badge == "FONDATEUR" then r, g, b = 220, 50, 50
                    elseif e.badge == "VIP" then r, g, b = 220, 150, 50
                    elseif e.badge == "ADMIN" then r, g, b = 50, 150, 220 end
                    
                    col_row_badge_bg.r = r
                    col_row_badge_bg.g = g
                    col_row_badge_bg.b = b
                    
                    draw.RoundedBox(4, avatarOffset + e.blk.offset.x, 2 + e.blk.offset.y, bw + 6, 18, col_row_badge_bg)
                    draw.SimpleText(e.badge, "CustomRP_Font_ChatBold", avatarOffset + e.blk.offset.x + 3, 2 + e.blk.offset.y, col_row_badge_txt)
                end
            end
        end
    end
    
    row.DoRightClick = function(self)
        local menu = DermaMenu()
        menu:AddOption("Copier le message", function() SetClipboardText(self.rawText) end):SetIcon("icon16/page_copy.png")
        
        local url = string.match(self.rawText, "https?://[%w-_%.%?%.:/%+=&]+")
        if url then
            menu:AddOption("Ouvrir le lien...", function() gui.OpenURL(url) end):SetIcon("icon16/world_link.png")
        end
        
        if IsValid(ply) then
            menu:AddOption("Copier SteamID", function() SetClipboardText(ply:SteamID()) end):SetIcon("icon16/tag_blue.png")
            menu:AddOption("Répondre en MP", function()
                if not isChatting then chat.Open(1) end
                timer.Simple(0.1, function()
                    if IsValid(ChatEntry) then
                        ChatEntry:SetText("/pm \"" .. ply:Nick() .. "\" ")
                        ChatEntry:SetCaretPos(#ChatEntry:GetText())
                        ChatEntry:RequestFocus()
                    end
                end)
            end):SetIcon("icon16/email_go.png")
        end
        menu:Open()
    end
    
    row:SetVisible(ShouldShowMessage(msgType))
    table.insert(history, row)
    
    if #history > 100 then
        if IsValid(history[1]) then history[1]:Remove() end
        table.remove(history, 1)
    end
    
    lastMsgTime = CurTime()
    
    timer.Simple(0.05, function()
        if IsValid(ChatScroll) then
            local maxScroll = ChatScroll:GetVBar().CanvasSize
            if isChatting then
                ChatScroll:GetVBar():AnimateTo(maxScroll, 0.3, 0, -1)
            else
                ChatScroll:GetVBar():SetScroll(maxScroll)
            end
        end
    end)
    
    if (msgType == "PM" and not isChatting) or mentionedMe then
        surface.PlaySound("buttons/blip1.wav")
    end
end

hook.Add("HUDShouldDraw", "CustomRP_Chat_HideDefault", function(name)
    if name == "CHudChat" then return false end
end)

hook.Add("StartChat", "CustomRP_Chat_Start", function(isTeamChat)
    if not IsValid(ChatFrame) then CreateChatbox() end
    isChatting = true
    
    ChatFrame:SetMouseInputEnabled(true)
    ChatFrame:SetKeyboardInputEnabled(true)
    
    ChatEntry:SetVisible(true)
    if IsValid(ChatFrame.Header) then ChatFrame.Header:SetVisible(true) end
    if IsValid(EmojiBtn) then EmojiBtn:SetVisible(true) end
    
    ChatFrame:MakePopup() 
    ChatEntry:RequestFocus()
    
    if IsValid(ChatScroll) then
        local maxScroll = ChatScroll:GetVBar().CanvasSize
        ChatScroll:GetVBar():AnimateTo(maxScroll, 0.2, 0, -1)
    end
    return true
end)

hook.Add("FinishChat", "CustomRP_Chat_Finish", function()
    isChatting = false
    if IsValid(ChatEntry) then ChatEntry:SetVisible(false) end
    if IsValid(ChatFrame) then 
        if IsValid(ChatFrame.Header) then ChatFrame.Header:SetVisible(false) end
        ChatFrame:SetKeyboardInputEnabled(false)
        ChatFrame:SetMouseInputEnabled(false)
    end
    if IsValid(ChatEntry) then ChatEntry:SetText("") end
    if IsValid(AutoCompleteMenu) then AutoCompleteMenu:SetVisible(false) end
    if IsValid(EmojiMenu) then EmojiMenu:SetVisible(false) end
    if IsValid(EmojiBtn) then EmojiBtn:SetVisible(false) end
    lastMsgTime = CurTime()
    
    if IsValid(ChatFrame) then
        local cx, cy = ChatFrame:GetPos()
        cookie.Set("CustomRP_Chat_W", ChatFrame:GetWide())
        cookie.Set("CustomRP_Chat_H", ChatFrame:GetTall())
        cookie.Set("CustomRP_Chat_X", cx)
        cookie.Set("CustomRP_Chat_Y", cy)
    end
end)

hook.Add("OnPlayerChat", "CustomRP_Chat_OnPlayer", function(ply, text, teamChat, isDead)
    local msgType = "Local"
    
    if string.sub(text, 1, 2) == "//" or string.sub(string.lower(text), 1, 5) == "/ooc " then
        msgType = "OOC"
        text = string.sub(text, 1, 2) == "//" and string.Trim(string.sub(text, 3)) or string.Trim(string.sub(text, 6))
    elseif string.sub(text, 1, 3) == "///" or string.sub(text, 1, 1) == "@" then
        msgType = "Admin"
    elseif string.sub(text, 1, 4) == "/pm " then
        return true
    elseif string.sub(text, 1, 1) == "/" then
        return true
    end
    
    AddLine(msgType, ply, text, isDead)
    return true
end)

hook.Add("ChatText", "CustomRP_Chat_Text", function(index, name, text, type)
    if type == "joinleave" or type == "none" then
        AddLine("System", nil, text, false)
        return true
    end
end)

net.Receive("CustomRP_Net_Chat_PM", function()
    local sender = net.ReadEntity()
    local target = net.ReadEntity()
    local msg = net.ReadString()
    
    local text = "(à " .. (IsValid(target) and target:Nick() or "Inconnu") .. ") " .. msg
    AddLine("PM", sender, text, false)
end)

net.Receive("CustomRP_Net_Chat_Command", function()
    local sender = net.ReadEntity()
    local cmdType = net.ReadString()
    local msg = net.ReadString()
    
    if cmdType == "OOC" then
        AddLine("OOC", sender, msg, false)
    elseif cmdType == "ROLL" then
        AddLine("ROLL", sender, "a obtenu un " .. msg .. " sur 100", false)
    elseif cmdType == "ME" then
        AddLine("ME", sender, msg, false)
    elseif cmdType == "YELL" then
        AddLine("YELL", sender, "CRIE : " .. msg, false)
    elseif cmdType == "WHISPER" then
        AddLine("WHISPER", sender, "CHUCHOTE : " .. msg, false)
    elseif cmdType == "ADVERT" then
        AddLine("ADVERT", sender, msg, false)
    end
end)

chat.OldAddText = chat.OldAddText or chat.AddText
function chat.AddText(...)
    local args = {...}
    local text = ""
    for idx = 1, #args do
        local arg = args[idx]
        if type(arg) == "string" then text = text .. arg
        elseif type(arg) == "Player" then text = text .. arg:Nick() end
    end
    AddLine("Raw", nil, text, false)
    if chat.OldAddText then chat.OldAddText(...) end
end

if IsValid(ChatFrame) then
    ChatFrame:Remove()
    CreateChatbox()
end
