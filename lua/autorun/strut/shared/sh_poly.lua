local meta = {}
local methods = {}

strut.poly = meta
meta.__index = methods

methods.MetaName = "Poly"

function meta:__tostring()
	return "Poly["..#self:GetVertices().." vertices]["..tostring(self:GetNormal()).."]"
end

function methods:IsValid()
    return #self:GetVertices() >= 3
end

function Vertex(pos, u, v, normal, tangent)
	return {
		pos = pos,
		u = u,
		v = v,
		normal = normal,
        userdata = tangent,
	}
end

function methods:GetVertices()
    return self.Vertices
end

function methods:IsValid() return #self:GetVertices() >= 3 end

function methods:SetTextureData(texture, uaxis, vaxis)
    if istable(texture) then
        self.TextureData = texture
        self:SetTexture(texture.texture)

        return
    end

    self.TextureData = {
        u_normal = Vector(uaxis[1], uaxis[2], uaxis[3]),
        v_normal = Vector(vaxis[1], vaxis[2], vaxis[3]),
        u_offset = uaxis[4],
        v_offset = vaxis[4],
        u_size = uaxis[5],
        v_size = vaxis[5],
    }
    self:SetTexture(texture)
end

function methods:GetTextureData()
    return self.TextureData
end

function methods:SetTexture(texture)
    self.TextureData.texture = texture

    if SERVER then return end

    local id = surface.GetTextureID(texture)
    local w, h = surface.GetTextureSize(id)

    self.TextureData.w = w
    self.TextureData.h = h
end

function methods:GetTexture()
    return self:GetTextureData() and self:GetTextureData().texture or nil
end

function methods:CalculateTextureUV()
    local tdata = self:GetTextureData()
    if !tdata then return end

    for _, vert in pairs(self:GetVertices()) do
        local tu = (vert.pos:DotProduct(tdata.u_normal) / tdata.u_size + tdata.u_offset) / tdata.w
        local tv = (vert.pos:DotProduct(tdata.v_normal) / tdata.v_size + tdata.v_offset) / tdata.h
        vert.u = tu
        vert.v = tv
    end
end

function methods:AddVertex(pos, u, v, normal, tangent)
    local vertex = Vertex(pos, u || 0, v || 0, normal || self:GetNormal(), tangent || self:GetTangent())
    table.insert(self.Vertices, vertex)

    self:CalculateBounds(pos)
end

function methods:GetUVVector(vert)
    return Vector(vert.u, vert.v, 0)
end

function methods:Triangulate()
    local triangles = {}
    
    local verts = self:GetVertices()
    local axis = verts[1]
    
    local helper = verts[2]
    for i = 3, #verts do
        temp = verts[i]
        
        table.insert(triangles, axis)
        table.insert(triangles, helper)
        table.insert(triangles, temp)

        helper = temp
    end

    return triangles
end

function methods:CalculateBounds(vertpos)
	local min, max = self:GetBounds()

	min.x = math.min(vertpos.x, min.x)
	min.y = math.min(vertpos.y, min.y)
	min.z = math.min(vertpos.z, min.z)
	
	max.x = math.max(vertpos.x, max.x)
	max.y = math.max(vertpos.y, max.y)
	max.z = math.max(vertpos.z, max.z)

	self.Min, self.Max = min, max
end

function methods:GetBounds()
    return self.Min || Vector(math.huge, math.huge, math.huge), self.Max || Vector(-math.huge, -math.huge, -math.huge)
end

function methods:SetTangent(tangent)
    self.Tangent = tangent
end

function methods:GetTangent()
    return self.Tangent || {1, 0, 0, 1}
end

function methods:ApplyTangent(tangent)
    for _, vert in pairs(self:GetVertices()) do
        vert.userdata = tangent
    end

    self:SetTangent(tangent)
end

function methods:CalculateTangent() //Eric Leyngel
    if !self.Normal then self:CalculateNormal() end
    
    local verts = self:GetVertices()

    local v1, v2, v3 = verts[1].pos, verts[2].pos, verts[#verts].pos
    local w1, w2, w3 = self:GetUVVector(verts[1]), self:GetUVVector(verts[2]), self:GetUVVector(verts[#verts])

    local vec1, vec2 = v2 - v1, v3 - v1
    local stv1, stv2 = w2 - w1, w3 - w1

    local r = 1 / (stv1.x * stv2.y - stv2.x * stv1.y)
    local sdir = (stv2.y * vec1 - stv1.y * vec2) * r
    local tdir = (stv1.x * vec2 - stv2.x * vec1) * r
    
    local normal = self:GetNormal()

    local tangent = (sdir - normal * normal:Dot(sdir)):GetNormal()
    local handedness = (tdir:Dot(normal:Cross(sdir)) < 0) && -1 || 1

    local userdata = {
        tangent.x,
        tangent.y,
        tangent.z,
        handedness,
    }

    self:ApplyTangent(userdata)
end

function methods:SetNormal(normal)
    self.Normal = normal
end

function methods:GetNormal()
    return self.Normal || vector_up
end

function methods:ApplyNormal(normal)
    for _, vert in pairs(self:GetVertices()) do
        vert.normal = normal
    end

    self:SetNormal(normal)
end

function methods:CalculateNormal()
    local verts = self:GetVertices()

    local vec1, vec2 = verts[2].pos - verts[1].pos, verts[1].pos - verts[#verts].pos

    local normal = vec1:Cross(vec2):GetNormal()

    self:ApplyNormal(normal)
end

function methods:Calculate(force)
    if !self.Normal or force then self:CalculateNormal() end
    if !self.Tangent or force then self:CalculateTangent() end

    if CLIENT then self:CalculateTextureUV() end
end

function strut.poly.Create()
	local t = {}
	setmetatable(t, meta)
	t.Vertices = {}
	t.Min = Vector(0,0,0)
	t.Max = Vector(0,0,0)

	return t
end

function strut.poly.Copy(poly) //Because metatables are not copied with net.WriteTable()
    local t = {}
    setmetatable(t, meta)

    t.Vertices = poly.Vertices
	t.Min = poly.Min
    t.Max = poly.Max
    t.Normal = poly.Normal
    t.Tangent = poly.Tangent

    t:SetTextureData(poly.TextureData)

    t:Calculate()

	return t
end