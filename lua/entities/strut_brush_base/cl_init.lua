include('shared.lua')

local matNodraw = Material("color")

function ENT:Initialize()
	self:DrawShadow(false)
    self:ResetMeshes()
    
    net.Start("strut_request_mesh")
        net.WriteEntity(self)
    net.SendToServer()

    self:CreatePhysics()
end

function ENT:Draw()
    return
end

net.Receive("strut_update_mesh", function()
    local ent = net.ReadEntity()
    local meshes = net.ReadTable()
    
    for _, mesh in pairs(meshes) do
        ent:AddMesh(strut.mesh.Copy(mesh))
    end
    
    ent:CreatePhysics()
end)