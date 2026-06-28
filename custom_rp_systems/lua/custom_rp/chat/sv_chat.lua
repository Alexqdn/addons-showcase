hook.Add("PlayerCanSeePlayersChat", "CustomRP_ChatVisibility", function(text, teamOnly, listener, speaker)
    if string.sub(text, 1, 2) == "//" or string.sub(string.lower(text), 1, 5) == "/ooc " then
        return true
    end
    
    if string.sub(text, 1, 3) == "///" or string.sub(text, 1, 1) == "@" then
        if listener:IsAdmin() or speaker == listener then
            return true
        end
        return false
    end
    
    if string.sub(text, 1, 1) == "/" then
        return false
    end
    
    local distSqr = 250 * 250
    if speaker:GetPos():DistToSqr(listener:GetPos()) > distSqr then
        return false
    end
    
    return true
end)

hook.Add("PlayerSay", "CustomRP_Chat_PM", function(ply, text)
    if string.sub(string.lower(text), 1, 4) == "/pm " then
        local args = string.Explode(" ", text)
        table.remove(args, 1)
        
        local targetName = string.lower(table.remove(args, 1) or "")
        local message = table.concat(args, " ")
        
        if targetName == "" or message == "" then
            ply:ChatPrint("Usage: /pm [nom] [message]")
            return ""
        end
        
        local targetPly = nil
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), targetName, 1, true) then
                targetPly = p
                break
            end
        end
        
        if IsValid(targetPly) then
            net.Start("CustomRP_Net_Chat_PM")
            net.WriteEntity(ply)
            net.WriteEntity(targetPly)
            net.WriteString(message)
            net.Send(targetPly)
            
            if ply ~= targetPly then
                net.Start("CustomRP_Net_Chat_PM")
                net.WriteEntity(ply)
                net.WriteEntity(targetPly)
                net.WriteString(message)
                net.Send(ply)
            end
        else
            ply:ChatPrint("Joueur introuvable.")
        end
        return ""
    end
    
    local lText = string.lower(text)
    
    if string.sub(lText, 1, 5) == "/ooc " or string.sub(lText, 1, 2) == "//" then
        local msg = string.sub(lText, 1, 2) == "//" and string.sub(text, 3) or string.sub(text, 6)
        if string.Trim(msg) == "" then return "" end
        net.Start("CustomRP_Net_Chat_Command")
        net.WriteEntity(ply)
        net.WriteString("OOC")
        net.WriteString(string.Trim(msg))
        net.Broadcast()
        return ""
    elseif string.sub(lText, 1, 5) == "/roll" then
        local roll = math.random(1, 100)
        net.Start("CustomRP_Net_Chat_Command")
        net.WriteEntity(ply)
        net.WriteString("ROLL")
        net.WriteString(tostring(roll))
        local recipients = {}
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():DistToSqr(ply:GetPos()) <= 250*250 then
                table.insert(recipients, p)
            end
        end
        net.Send(recipients)
        return ""
    end
    
    if string.sub(lText, 1, 4) == "/me " then
        net.Start("CustomRP_Net_Chat_Command")
        net.WriteEntity(ply)
        net.WriteString("ME")
        net.WriteString(string.sub(text, 5))
        net.Broadcast()
        return ""
    elseif string.sub(lText, 1, 6) == "/yell " then
        net.Start("CustomRP_Net_Chat_Command")
        net.WriteEntity(ply)
        net.WriteString("YELL")
        net.WriteString(string.sub(text, 7))
        net.Broadcast()
        return ""
    elseif string.sub(lText, 1, 3) == "/w " then
        net.Start("CustomRP_Net_Chat_Command")
        net.WriteEntity(ply)
        net.WriteString("WHISPER")
        net.WriteString(string.sub(text, 4))
        net.Broadcast()
        return ""
    elseif string.sub(lText, 1, 8) == "/advert " then
        net.Start("CustomRP_Net_Chat_Command")
        net.WriteEntity(ply)
        net.WriteString("ADVERT")
        net.WriteString(string.sub(text, 9))
        net.Broadcast()
        return ""
    end
end)
