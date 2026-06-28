CustomRP = CustomRP or {}

local function LoadFile(path, realm)
    if realm == "client" then
        if SERVER then
            AddCSLuaFile(path)
        else
            include(path)
        end
    elseif realm == "server" then
        if SERVER then
            include(path)
        end
    elseif realm == "shared" then
        if SERVER then
            AddCSLuaFile(path)
        end
        include(path)
    end
end

local plyMeta = FindMetaTable("Player")
if plyMeta then
    if not plyMeta.GetMoney then
        function plyMeta:GetMoney()
            if self.getDarkRPVar then
                return self:getDarkRPVar("money") or 0
            end
            return self.CustomRP_Money or 0
        end
    end
    if not plyMeta.AddMoney then
        function plyMeta:AddMoney(amount)
            if self.addMoney then
                self:addMoney(amount)
            else
                self.CustomRP_Money = (self.CustomRP_Money or 0) + amount
                if SERVER then
                    net.Start("CustomRP_UpdateMoney")
                        net.WriteInt(self.CustomRP_Money, 32)
                    net.Send(self)
                end
            end
        end
    end
    if not plyMeta.CanAfford then
        function plyMeta:CanAfford(amount)
            if self.canAfford then
                return self:canAfford(amount)
            end
            return self:GetMoney() >= amount
        end
    end
    if not plyMeta.GetJob then
        function plyMeta:GetJob()
            if self.getDarkRPVar then
                return self:Team() or 1
            end
            return self.CustomRP_Job or 1
        end
    end
end

if SERVER then
    util.AddNetworkString("CustomRP_ATM_Open")
    util.AddNetworkString("CustomRP_ATM_Deposit")
    util.AddNetworkString("CustomRP_ATM_Withdraw")
    util.AddNetworkString("CustomRP_ATM_Transfer")
    util.AddNetworkString("CustomRP_ATM_UpdateBalance")
    util.AddNetworkString("CustomRP_ATM_Notification")
    util.AddNetworkString("CustomRP_ATM_PlayerList")
    
    util.AddNetworkString("CustomRP_UpdateMoney")
    util.AddNetworkString("CustomRP_UpdateJob")
    util.AddNetworkString("CustomRP_Notify")
    
    util.AddNetworkString("CustomRP_Net_Chat_PM")
    util.AddNetworkString("CustomRP_Net_Chat_Command")
    
    function CustomRP.Notify(ply, msgtype, len, msg)
        if not IsValid(ply) then return end
        net.Start("CustomRP_Notify")
            net.WriteUInt(msgtype or 0, 8)
            net.WriteUInt(len or 4, 8)
            net.WriteString(msg or "")
        net.Send(ply)
    end
    
    DarkRP = DarkRP or {}
    DarkRP.notify = CustomRP.Notify
    DarkRP.Notify = CustomRP.Notify
    
    hook.Add("PlayerInitialSpawn", "CustomRP_InitialSync", function(ply)
        timer.Simple(1.5, function()
            if IsValid(ply) then
                net.Start("CustomRP_UpdateMoney")
                    net.WriteInt(ply:GetMoney(), 32)
                net.Send(ply)
                
                net.Start("CustomRP_UpdateJob")
                    net.WriteEntity(ply)
                    net.WriteUInt(ply:GetJob(), 16)
                net.Broadcast()
            end
        end)
    end)
end

if CLIENT then
    net.Receive("CustomRP_UpdateMoney", function()
        local money = net.ReadInt(32)
        LocalPlayer().CustomRP_Money = money
    end)

    net.Receive("CustomRP_UpdateJob", function()
        local ply = net.ReadEntity()
        local job = net.ReadUInt(16)
        if IsValid(ply) then
            ply.CustomRP_Job = job
        end
    end)

    net.Receive("CustomRP_Notify", function()
        local msgtype = net.ReadUInt(8)
        local len = net.ReadUInt(8)
        local msg = net.ReadString()
        if notification and notification.AddLegacy then
            notification.AddLegacy(msg, msgtype, len)
        else
            chat.AddText(Color(255, 100, 100), "[Notification] ", Color(255, 255, 255), msg)
        end
    end)
end

LoadFile("custom_rp/hud/cl_fonts.lua", "client")
LoadFile("custom_rp/hud/cl_hud.lua", "client")
LoadFile("custom_rp/hud/cl_notifications.lua", "client")
LoadFile("custom_rp/hud/cl_overhead_hud.lua", "client")
LoadFile("custom_rp/hud/cl_scoreboard.lua", "client")
LoadFile("custom_rp/hud/cl_weapon_selector.lua", "client")

LoadFile("custom_rp/chat/cl_chat.lua", "client")
LoadFile("custom_rp/chat/sv_chat.lua", "server")

LoadFile("custom_rp/banking/sh_banking.lua", "shared")
LoadFile("custom_rp/banking/cl_banking.lua", "client")
LoadFile("custom_rp/banking/sv_banking.lua", "server")
