include('shared.lua')

function ENT:Initialize()
	self:DrawShadow(false)
    
    net.Start("strut_request_mesh_renderer")
        net.WriteEntity(self)
    net.SendToServer()

    self:Readjust()
end

function ENT:CreateIMesh()
    self.IMesh = self:GetMesh():ToIMesh(self:GetMaterial())
end

function ENT:GetIMesh() return self.IMesh end

local matColor = Material("color")
function ENT:Readjust()
    if !self:GetMesh() then return end
    
    self:SetRenderBounds(self:GetBounds())
    
    local texture = self:GetTexture()
    local material = texture and strut.utils.ToVertexLit(Material(texture)) or matColor

    self:SetMeshMaterial(material)

    self:CreateIMesh()
end

function ENT:GetRenderMesh()
    if !self:GetIMesh() or !self:GetMeshMaterial() then return end
    
    return {Mesh = self:GetIMesh(), Material = self:GetMeshMaterial()}
end

net.Receive("strut_update_mesh_renderer", function()
    local ent = net.ReadEntity()
    local mesh = net.ReadTable()
    local texture = net.ReadString()
    
    if mesh and texture then
        ent:SetMesh(strut.mesh.Copy(mesh))
        ent:SetTexture(texture)

        ent:Readjust()
    end
end)