hook.Add("Initialize", "CustomRP.InitBankDB", function()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS custom_rp_banking (
            steamid VARCHAR(255) PRIMARY KEY,
            balance INTEGER NOT NULL DEFAULT 0
        );
    ]])
    MsgC(Color(0, 255, 0), "[CustomRP] Table SQLite custom_rp_banking prête.\n")
end)

local plyMeta = FindMetaTable("Player")

function plyMeta:GetBankBalance()
    return self.CustomRP_BankBalance or 0
end

function plyMeta:SetBankBalance(amount)
    self.CustomRP_BankBalance = math.max(0, math.floor(tonumber(amount) or 0))
end

function plyMeta:AddBankBalance(amount)
    self:SetBankBalance(self:GetBankBalance() + math.floor(tonumber(amount) or 0))
end

function plyMeta:SyncBankBalance()
    net.Start("CustomRP_ATM_UpdateBalance")
        net.WriteInt(self:GetBankBalance(), 32)
    net.Send(self)
end

local function SendATMNotification(ply, msg, isError)
    net.Start("CustomRP_ATM_Notification")
        net.WriteString(msg)
        net.WriteBool(isError or false)
    net.Send(ply)
end

local function IsNearATM(ply)
    local maxDist = CustomRP.Banking.MaxDistance
    local entities = ents.FindInSphere(ply:GetPos(), maxDist)
    for i = 1, #entities do
        local ent = entities[i]
        if IsValid(ent) and (ent:GetClass() == "custom_rp_atm" or ent:GetClass() == "darkrp_atm") then
            return true
        end
    end
    return false
end

net.Receive("CustomRP_ATM_Deposit", function(len, ply)
    if not IsValid(ply) then return end

    if (ply.NextATMTransaction or 0) > CurTime() then
        SendATMNotification(ply, "Veuillez patienter entre chaque transaction.", true)
        return
    end

    if not IsNearATM(ply) then
        SendATMNotification(ply, "Vous devez être proche d'un distributeur.", true)
        return
    end

    local amount = net.ReadInt(32)
    if not amount or amount <= 0 then
        SendATMNotification(ply, "Montant invalide.", true)
        return
    end

    amount = math.floor(amount)
    if amount > CustomRP.Banking.MaxDeposit then
        local limitStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(CustomRP.Banking.MaxDeposit) or ("$" .. string.Comma(CustomRP.Banking.MaxDeposit))
        SendATMNotification(ply, "Montant trop élevé (max: " .. limitStr .. ").", true)
        return
    end

    if not ply:CanAfford(amount) then
        SendATMNotification(ply, "Fonds insuffisants dans votre portefeuille.", true)
        return
    end

    ply:AddMoney(-amount)
    ply:AddBankBalance(amount)
    ply:SyncBankBalance()

    ply.NextATMTransaction = CurTime() + CustomRP.Banking.Cooldown
    local moneyStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(amount) or ("$" .. string.Comma(amount))
    SendATMNotification(ply, "Dépôt de " .. moneyStr .. " effectué avec succès.")
    
    local logMoneyStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(amount) or ("$" .. string.Comma(amount))
    local logBalanceStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(ply:GetBankBalance()) or ("$" .. string.Comma(ply:GetBankBalance()))
    MsgC(Color(46, 204, 113), "[ATM] ", color_white, ply:Nick() .. " a déposé " .. logMoneyStr .. " (Solde: " .. logBalanceStr .. ")\n")
end)

net.Receive("CustomRP_ATM_Withdraw", function(len, ply)
    if not IsValid(ply) then return end

    if (ply.NextATMTransaction or 0) > CurTime() then
        SendATMNotification(ply, "Veuillez patienter entre chaque transaction.", true)
        return
    end

    if not IsNearATM(ply) then
        SendATMNotification(ply, "Vous devez être proche d'un distributeur.", true)
        return
    end

    local amount = net.ReadInt(32)
    if not amount or amount <= 0 then
        SendATMNotification(ply, "Montant invalide.", true)
        return
    end

    amount = math.floor(amount)
    if amount > CustomRP.Banking.MaxWithdraw then
        local limitStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(CustomRP.Banking.MaxWithdraw) or ("$" .. string.Comma(CustomRP.Banking.MaxWithdraw))
        SendATMNotification(ply, "Montant trop élevé (max: " .. limitStr .. ").", true)
        return
    end

    if ply:GetBankBalance() < amount then
        SendATMNotification(ply, "Fonds insuffisants sur votre compte bancaire.", true)
        return
    end

    ply:AddBankBalance(-amount)
    ply:AddMoney(amount)
    ply:SyncBankBalance()

    ply.NextATMTransaction = CurTime() + CustomRP.Banking.Cooldown
    local moneyStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(amount) or ("$" .. string.Comma(amount))
    SendATMNotification(ply, "Retrait de " .. moneyStr .. " effectué avec succès.")
    
    local logMoneyStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(amount) or ("$" .. string.Comma(amount))
    local logBalanceStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(ply:GetBankBalance()) or ("$" .. string.Comma(ply:GetBankBalance()))
    MsgC(Color(231, 76, 60), "[ATM] ", color_white, ply:Nick() .. " a retiré " .. logMoneyStr .. " (Solde: " .. logBalanceStr .. ")\n")
end)

net.Receive("CustomRP_ATM_Transfer", function(len, ply)
    if not IsValid(ply) then return end

    if (ply.NextATMTransaction or 0) > CurTime() then
        SendATMNotification(ply, "Veuillez patienter entre chaque transaction.", true)
        return
    end

    if not IsNearATM(ply) then
        SendATMNotification(ply, "Vous devez être proche d'un distributeur.", true)
        return
    end

    local amount = net.ReadInt(32)
    local targetSteamID = net.ReadString()

    if not amount or amount <= 0 then
        SendATMNotification(ply, "Montant invalide.", true)
        return
    end

    amount = math.floor(amount)
    if amount > CustomRP.Banking.MaxTransfer then
        local limitStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(CustomRP.Banking.MaxTransfer) or ("$" .. string.Comma(CustomRP.Banking.MaxTransfer))
        SendATMNotification(ply, "Montant trop élevé (max: " .. limitStr .. ").", true)
        return
    end

    if ply:GetBankBalance() < amount then
        SendATMNotification(ply, "Fonds insuffisants sur votre compte bancaire.", true)
        return
    end

    local target = nil
    local plys = player.GetAll()
    for i = 1, #plys do
        local p = plys[i]
        if p:SteamID() == targetSteamID then
            target = p
            break
        end
    end

    if not IsValid(target) then
        SendATMNotification(ply, "Le joueur destinataire est introuvable ou déconnecté.", true)
        return
    end

    if target == ply then
        SendATMNotification(ply, "Vous ne pouvez pas vous envoyer de l'argent.", true)
        return
    end

    ply:AddBankBalance(-amount)
    target:AddBankBalance(amount)
    ply:SyncBankBalance()
    target:SyncBankBalance()

    ply.NextATMTransaction = CurTime() + CustomRP.Banking.Cooldown
    
    local moneyStr = DarkRP and DarkRP.FormatMoney and DarkRP.FormatMoney(amount) or ("$" .. string.Comma(amount))
    SendATMNotification(ply, "Virement de " .. moneyStr .. " envoyé à " .. target:Nick() .. ".")
    SendATMNotification(target, "Vous avez reçu un virement de " .. moneyStr .. " de " .. ply:Nick() .. ".")
    MsgC(Color(52, 152, 219), "[ATM] ", color_white, ply:Nick() .. " → " .. target:Nick() .. " : " .. moneyStr .. "\n")
end)

hook.Add("PlayerInitialSpawn", "CustomRP.LoadBanking", function(ply)
    local steamID = ply:SteamID()
    if not steamID then return end

    local data = sql.Query("SELECT balance FROM custom_rp_banking WHERE steamid = " .. sql.SQLStr(steamID) .. ";")
    if data and data[1] then
        ply:SetBankBalance(tonumber(data[1].balance) or 0)
    else
        sql.Query("INSERT INTO custom_rp_banking (steamid, balance) VALUES (" .. sql.SQLStr(steamID) .. ", 0);")
        ply:SetBankBalance(0)
    end

    timer.Simple(2, function()
        if IsValid(ply) then ply:SyncBankBalance() end
    end)
end)

local function SaveBanking(ply)
    local steamID = ply:SteamID()
    if not steamID or ply.CustomRP_BankBalance == nil then return end
    sql.Query("UPDATE custom_rp_banking SET balance = " .. tonumber(ply.CustomRP_BankBalance) .. " WHERE steamid = " .. sql.SQLStr(steamID) .. ";")
end

hook.Add("PlayerDisconnected", "CustomRP.SaveBanking", SaveBanking)

timer.Create("CustomRP.AutoSaveBanking", 300, 0, function()
    local plys = player.GetAll()
    for i = 1, #plys do
        SaveBanking(plys[i])
    end
end)
