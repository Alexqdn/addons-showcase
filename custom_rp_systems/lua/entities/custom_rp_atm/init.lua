AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_unique/atm01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if (activator.NextATMUse or 0) > CurTime() then return end
    activator.NextATMUse = CurTime() + 1.5

    net.Start("CustomRP_ATM_Open")
        net.WriteInt(activator:GetBankBalance(), 32)
        net.WriteEntity(self)
    net.Send(activator)

    local players = {}
    local allPlys = player.GetAll()
    for i = 1, #allPlys do
        local ply = allPlys[i]
        if ply ~= activator then
            players[#players + 1] = {
                name = ply:Nick(),
                steamid = ply:SteamID(),
                job = team.GetName(ply:Team()),
                jobColor = team.GetColor(ply:Team())
            }
        end
    end

    net.Start("CustomRP_ATM_PlayerList")
        net.WriteUInt(#players, 8)
        for i = 1, #players do
            local p = players[i]
            net.WriteString(p.name)
            net.WriteString(p.steamid)
            net.WriteString(p.job)
            net.WriteColor(p.jobColor)
        end
    net.Send(activator)
end
