ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = true
ENT.PrintName = "Base Brush"

function ENT:PhysicsUpdate(phys)
    phys:EnableMotion(false)
end

function ENT:ResetMeshes()
    self.PhysicsMesh = {}
    self.Meshes = {}

    if CLIENT then self.IMesh = {} end
end

function ENT:AddMesh(mesh)
    if !self.Meshes then
        self:ResetMeshes()
    end

    if(!self.SurfaceProp) then // If we don't have a surface prop yet, try to extract it from one of the materials from our meshdata polygons
		local poly = mesh:GetPolys()[1]
		local mat = Material(poly:GetTexture())
		if !mat:IsError() then
			local surface = mat:GetString("$surfaceprop")
			if surface != "" then
				self.SurfaceProp = surface
			end
		end
	end

    self:CalculateBounds(mesh)

    table.insert(self.PhysicsMesh, mesh:GetVertices())
    table.insert(self.Meshes, mesh)
end

function ENT:GetSurfaceProp() return self.SurfaceProp || "concrete" end

function ENT:GetPhysicsMesh() return self.PhysicsMesh end

function ENT:CalculateBounds(mesh)
    local min, max = self.Min || Vector(math.huge, math.huge, math.huge), self.Max || Vector(-math.huge, -math.huge, -math.huge)
    local meshMin, meshMax = mesh.Min, mesh.Max
    
    min.x = math.min(meshMin.x, min.x)
    min.y = math.min(meshMin.y, min.y)
    min.z = math.min(meshMin.z, min.z)
    
    max.x = math.max(meshMax.x, max.x)
    max.y = math.max(meshMax.y, max.y)
    max.z = math.max(meshMax.z, max.z)
    
    self.Min, self.Max = min, max
end

function ENT:GetBounds() return self.Min || Vector(0, 0, 0), self.Max || Vector(0, 0, 0) end

function ENT:GetMeshes() return self.Meshes end

function ENT:CreatePhysics()
    self:SetModel("models/props_junk/MetalBucket01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)

    self:PhysicsInitMultiConvex(self:GetPhysicsMesh())
	self:EnableCustomCollisions(true)
    
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
    
    self:SetCollisionBounds(self:GetBounds())

    local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:AddGameFlag(bit.bor(FVPHYSICS_CONSTRAINT_STATIC, FVPHYSICS_NO_PLAYER_PICKUP, FVPHYSICS_NO_NPC_IMPACT_DMG, FVPHYSICS_NO_IMPACT_DMG))
		phys:SetMass(5000)
		phys:EnableMotion(false)
		phys:SetMaterial(self:GetSurfaceProp())
	end
end