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

function Vertex(pos, u, v, normal, tangent, color)
	return {
		pos = pos,
		u = u,
		v = v,
		normal = normal,
        userdata = tangent,
        color = color,
	}
end

function methods:GetVertices()
    return self.Vertices
end

function methods:IsValid() return #self:GetVertices() >= 3 end

function methods:SetTextureData(texture, uaxis, vaxis, color)
    if istable(texture) then
        self.TextureData = texture
        self:SetTexture(texture.texture)

        return
    end

    self.TextureData = {
        u_normal = uaxis[1],
        v_normal = vaxis[1],
        u_offset = uaxis[2],
        v_offset = vaxis[2],
        u_size = uaxis[3],
        v_size = vaxis[3],
    }
    self:SetTexture(texture)

    self:SetColor(color or color_white)
end

function methods:GetTextureData()
    return self.TextureData
end

function methods:SetTexture(texture)
    if !texture then return end

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
    if !tdata or !tdata.texture then return end

    for _, vert in pairs(self:GetVertices()) do
        local tu = (vert.pos:DotProduct(tdata.u_normal) / tdata.u_size + tdata.u_offset) / tdata.w
        local tv = (vert.pos:DotProduct(tdata.v_normal) / tdata.v_size + tdata.v_offset) / tdata.h
        vert.u = tu
        vert.v = tv
    end
end

function methods:AddVertex(pos, u, v, normal, tangent)
    local vertex = Vertex(pos, u || 0, v || 0, normal || self:GetNormal(), tangent || {1, 0, 0, 1}, color || self:GetColor())
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

function methods:SetColor(color)
    self.Color = color
end

function methods:GetColor()
    return self.Color || color_white
end

function methods:CalculateTangent() //Eric Leyngel
    if !self.Normal then self:CalculateNormal() end
    
    local verts = self:GetVertices()
    local vert1, vert2, vert3 = verts[1], verts[2], verts[3]

    local p1, p2, p3 = vert1.pos, vert2.pos, vert3.pos
    local u1, u2, u3 = vert1.u, vert2.u, vert3.u
    local v1, v2, v3 = vert1.v, vert2.v, vert3.v

    local x1 = p2.x - p1.x
    local x2 = p3.x - p1.x
    local y1 = p2.y - p1.y
    local y2 = p3.y - p1.y
    local z1 = p2.z - p1.z
    local z2 = p3.z - p1.z

    local s1 = u2 - u1
    local s2 = u3 - u1
    local t1 = v2 - v1
    local t2 = v3 - v1

    local r = 1 / (s1 * t2 - s2 * t1)
    local sdir = Vector((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r)
    local tdir = Vector((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r)
    
    local tangent = {}
    for _, vert in pairs(self.Vertices) do
        local n = vert.normal
        local t = sdir

        local tan = (t - n * n:Dot(t))
        tan:Normalize()

        local w = (n:Cross(t)):Dot(tdir) < 0 and -1 or 1

        vert.userdata = {tan[1], tan[2], tan[3], w}
    end
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

function methods:Calculate()
    if !self.Normal then self:CalculateNormal() end

    if CLIENT then 
        self:CalculateTextureUV()
        self:CalculateTangent()
    end
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

    t:SetTextureData(poly.TextureData)

    t:Calculate()

	return t
end