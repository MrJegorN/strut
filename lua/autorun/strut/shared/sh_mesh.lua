local meta = {}
local methods = {}

strut.mesh = meta
meta.__index = methods

methods.MetaName = "Mesh"

function methods:GetPolys()
    return self.Polys
end

function methods:GetVertices()
    return self.Vertices
end

function methods:HasVertex(vpos)
	local e = 0.05

	local verts = self:GetVertices()
	for k, v in pairs(verts) do
		if(v == vpos) then return true
		else
			local diff = v - vpos
			if(diff.x <= e && diff.x >= -e && diff.y <= e && diff.y >= -e && diff.z <= e && diff.z >= -e) then return true, v end
		end
	end
	return false
end

function methods:AddPoly(poly)
    table.insert(self.Polys, poly)
end

function methods:AddPolyData(polydata)
	for _, data in pairs(polydata) do
		if data.MetaName != "Poly" and istable(data) then
			for _, p in pairs(data) do
				self:AddPolyData(p)
			end
		elseif data.MetaName == "Poly" then self:AddPoly(data) end
	end
end

function methods:SetTexture(texture)
	for _, poly in ipairs(self:GetPolys()) do
		poly:SetTexture(texture)
	end
end

function methods:GetSorted()
	local sorted = {}

	for _, poly in pairs(self:GetPolys()) do
		local texture = poly:GetTexture()
		
		if !sorted[texture] then sorted[texture] = {} end
		
		table.insert(sorted[texture], poly)
	end

	return sorted
end

function methods:CalculateBounds(vertpos)
	local min, max = self.Min || Vector(math.huge, math.huge, math.huge), self.Max || Vector(-math.huge, -math.huge, -math.huge)

	min.x = math.min(vertpos.x, min.x)
	min.y = math.min(vertpos.y, min.y)
	min.z = math.min(vertpos.z, min.z)
	
	max.x = math.max(vertpos.x, max.x)
	max.y = math.max(vertpos.y, max.y)
	max.z = math.max(vertpos.z, max.z)

	self.Min, self.Max = min, max
end

function methods:GetBounds()
	return self.Min || Vector(0, 0, 0), self.Max || Vector(0, 0, 0)
end

function methods:Calculate()
    local polys = self:GetPolys()
	
	for k, poly in pairs(polys) do
		if !IsValid(poly) then
			ErrorNoHalt("Warning: Invalid polygon (" .. k .. ")")
			table.remove(polys, k)
		else
			for _, vert in pairs(poly:GetVertices()) do
				local hasVertex, dupePos = self:HasVertex(vert.pos)
				
				if hasVertex then
					if dupePos then 
						vert.pos = dupePos
					end
				else
					table.insert(self.Vertices, vert.pos)

					self:CalculateBounds(vert.pos)
				end
			end
		end
	end
end

function methods:ToIMesh(material)
	local IMesh = Mesh(material)

	local triangles = {}

	for _, poly in pairs(self:GetPolys()) do
		local poly_triangles = poly:Triangulate()

		table.Add(triangles, poly_triangles)
	end
	
	mesh.Begin(IMesh, MATERIAL_TRIANGLES, #triangles / 3)
		for _, vert in pairs(triangles) do
			mesh.Position(vert.pos)

			mesh.TexCoord(0, vert.u, vert.v) 
			mesh.TexCoord(1, vert.u*2, vert.v*2)

			mesh.Normal(vert.normal)

			mesh.UserData(vert.userdata[1], vert.userdata[2], vert.userdata[3], vert.userdata[4])

			mesh.AdvanceVertex() 
		end
	mesh.End()

	return IMesh
end

function strut.mesh.Create(...)
    local t = {}
    setmetatable(t, meta)
	t.Min = Vector(0, 0, 0)
	t.Max = Vector(0, 0, 0)
    t.Polys = {}
    t.Vertices = {}

    t:AddPolyData({...})
	
	t:Calculate()
	return t
end

function strut.mesh.Copy(mesh)
    local t = {}
    setmetatable(t, meta)
	t.Min = mesh.Min
	t.Max = mesh.Max

	t.Polys = {}
	for k, poly in pairs(mesh.Polys) do
		t.Polys[k] = strut.poly.Copy(poly)
	end
	
    t.Vertices = mesh.Vertices

	return t
end

function strut.mesh.GenerateCubicMesh(min, max, material)
    local bounds = (max - min) * 0.5
	min = -bounds
	max = bounds
	local scale = 0.25
	local u,v = {1,0,0,0,scale},{0,-1,0,0,scale}
	local t = {u[1], u[2], u[3], 1}
	local n = Vector(0,0,1)
	local a = strut.poly.Create()
	a:SetTextureData(material,u,v)
	a:AddVertex(Vector(min.x,max.y,max.z))
	a:AddVertex(max)
	a:AddVertex(Vector(max.x,min.y,max.z))
	a:AddVertex(Vector(min.x,min.y,max.z))
	a:ApplyNormal(n)
	a:ApplyTangent(t)
	a:Calculate()

	u,v = {-1,0,0,0,scale},{0,-1,0,0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(0,0,-1)
	local b = strut.poly.Create()
	b:SetTextureData(material,u,v)
	b:AddVertex(min)
	b:AddVertex(Vector(max.x,min.y,min.z))
	b:AddVertex(Vector(max.x,max.y,min.z))
	b:AddVertex(Vector(min.x,max.y,min.z))
	b:ApplyNormal(n)
	b:ApplyTangent(t)
	b:Calculate()
	
	u,v = {0,1,0,0,scale},{0,0,-1,0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(-1,0,0)
	local c = strut.poly.Create()
	c:SetTextureData(material,u,v)
	c:AddVertex(Vector(min.x,min.y,max.z))
	c:AddVertex(min)
	c:AddVertex(Vector(min.x,max.y,min.z))
	c:AddVertex(Vector(min.x,max.y,max.z))
	c:ApplyNormal(n)
	c:ApplyTangent(t)
	c:Calculate()
	
	u,v = {0,-1,0,0,scale},{0,0,-1,0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(1,0,0)
	local d = strut.poly.Create()
	d:SetTextureData(material,u,v)
	d:AddVertex(max)
	d:AddVertex(Vector(max.x,max.y,min.z))
	d:AddVertex(Vector(max.x,min.y,min.z))
	d:AddVertex(Vector(max.x,min.y,max.z))
	d:ApplyNormal(n)
	d:ApplyTangent(t)
	d:Calculate()
	
	u,v = {1,0,0,0,scale},{0,0,-1,0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(0,1,0)
	local e = strut.poly.Create()
	e:SetTextureData(material,u,v)
	e:AddVertex(Vector(min.x,max.y,max.z))
	e:AddVertex(Vector(min.x,max.y,min.z))
	e:AddVertex(Vector(max.x,max.y,min.z))
	e:AddVertex(max)
	e:ApplyNormal(n)
	e:ApplyTangent(t)
	e:Calculate()
	
	u,v = {-1,0,0,0,scale},{0,0,-1,0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(0,-1,0)
	local f = strut.poly.Create()
	f:SetTextureData(material,u,v)
	f:AddVertex(Vector(max.x,min.y,max.z))
	f:AddVertex(Vector(max.x,min.y,min.z))
	f:AddVertex(min)
	f:AddVertex(Vector(min.x,min.y,max.z))
	f:ApplyNormal(n)
	f:ApplyTangent(t)
	f:Calculate()
	
	return strut.mesh.Create(a,b,c,d,e,f)
end