AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

function ENT:SendUpdate()
    local mesh = self:GetMesh()
    local texture = self:GetTexture()
    
    if mesh and texture then
        net.Start("strut_update_mesh_renderer")
            net.WriteEntity(self)
            net.WriteTable(mesh)
            net.WriteString(texture)
        net.Broadcast()
    end
end

util.AddNetworkString("strut_request_mesh_renderer")
util.AddNetworkString("strut_update_mesh_renderer")

net.Receive("strut_request_mesh_renderer", function(len, ply)
    local ent = net.ReadEntity()
    
    ent:SendUpdate()
end)