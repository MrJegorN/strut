ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = false
ENT.PrintName = "Brush Renderer"

function ENT:SetTexture(texture) self.Texture = texture end

function ENT:GetTexture() return self.Texture end 

function ENT:SetMeshMaterial(material) self.Material = material end

function ENT:GetMeshMaterial() return self.Material end 

function ENT:SetMesh(mesh) self.Mesh = mesh end

function ENT:GetMesh() return self.Mesh end

function ENT:GetBounds() return self.Mesh:GetBounds() end