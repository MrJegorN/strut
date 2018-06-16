AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

function ENT:Initialize()
    self:CreatePhysics()
end

util.AddNetworkString("strut_request_mesh")
util.AddNetworkString("strut_update_mesh")

net.Receive("strut_request_mesh", function(len, ply)
    local ent = net.ReadEntity()
    local meshes = ent:GetMeshes()

    if meshes then
        net.Start("strut_update_mesh")
            net.WriteEntity(ent)
            net.WriteTable(meshes)
        net.Broadcast()
    end
end)