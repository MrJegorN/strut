include('shared.lua')

local matNodraw = Material("nodraw")

function ENT:Initialize()
	self:DrawShadow(false)
    self:ResetMeshes()
    
    net.Start("strut_request_mesh")
        net.WriteEntity(self)
    net.SendToServer()

    self:CreatePhysics()
    self:SetRenderBounds(self:GetBounds())
end

function ENT:CreateIMesh()
    self.IMesh = strut.mesh.CreateIMesh(self.Meshes)
end

function ENT:Draw()
    render.MaterialOverride(matNodraw)
        self:DrawModel()
    render.MaterialOverride()
    
    local matrix = Matrix()
    matrix:SetTranslation(self:GetPos())
    matrix:SetAngles(self:GetAngles())
    
    if self.IMesh and self.IMesh.Draw then self.IMesh:Draw(matrix) end
end

net.Receive("strut_update_mesh", function()
    local ent = net.ReadEntity()
    local meshes = net.ReadTable()
    
    for _, mesh in pairs(meshes) do
        ent:AddMesh(strut.mesh.Copy(mesh))
    end
    
    ent:CreateIMesh()
    ent:CreatePhysics()
    ent:SetRenderBounds(ent:GetBounds())
end)