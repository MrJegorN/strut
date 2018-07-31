include('shared.lua')

function ENT:Initialize()
	self:DrawShadow(false)

    self:ResetMeshes()
    
    net.Start("strut_request_mesh")
        net.WriteEntity(self)
    net.SendToServer()

    self:CreatePhysics()
end

function ENT:Draw()
    
end

net.Receive("strut_update_mesh", function()
    local reset = net.ReadBool()
    local ent = net.ReadEntity()
    local meshes = net.ReadTable()

    if reset then
        ent:ResetMeshes()
    end
    
    if !meshes[1] then
        ent:AddMesh(strut.mesh.Copy(meshes))
    else
        for _, mesh in pairs(meshes) do
            ent:AddMesh(strut.mesh.Copy(mesh))
        end
    end
    
    ent:CreatePhysics()
end)