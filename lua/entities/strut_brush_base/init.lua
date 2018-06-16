AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

function ENT:Initialize()
    self:CreatePhysics()
end

function ENT:CreateRenderers()
    if !self.Meshes then return end

    local textures = {}

    for _, mesh in pairs(self.Meshes) do
        local sorted = mesh:GetSorted()

        for k, v in pairs(sorted) do
            if !textures[k] then textures[k] = {} end

            table.insert(textures[k], v)
        end
    end

    if !self.Renderers then self.Renderers = {} end

    for texture, polys in pairs(textures) do
        local poly_mesh = strut.mesh.Create(polys)

        if !IsValid(self.Renderers[texture]) then
            local renderer = ents.Create("strut_brush_render")
            renderer:SetTexture(texture)
            renderer:SetMesh(poly_mesh)
            renderer:SetPos(self:GetPos())
            renderer:SetParent(self)
            renderer:Spawn()
            renderer:Activate()
            
            self.Renderers[texture] = renderer
        else
            local renderer = self.Renderers[texture]
            renderer:SetTexture(texture)
            renderer:SetMesh(poly_mesh)
            renderer:SendUpdate()
        end
    end
end

function ENT:InvalidateRenderers() //TODO: only remove renderers without valid material
    if !self.Renderers then return end
    for _, renderer in pairs(self.Renderers) do 
        SafeRemoveEntity(renderer) 
    end 
end

function ENT:GetRenderers() return self.Renderers end

function ENT:OnRemove() 
    self:InvalidateRenderers()
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