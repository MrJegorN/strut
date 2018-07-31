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
	return self.Min, self.Max
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

function methods:ToIMesh(material, color)
	if !material then
		material = Material(self:GetPolys()[1]:GetTexture())
	end

	if !color then
		color = self:GetPolys()[1]:GetColor()
	end
	
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

			mesh.Color(color.r, color.g, color.b, color.a)

			mesh.AdvanceVertex() 
		end
	mesh.End()

	return IMesh
end

function strut.mesh.Create(...)
    local t = {}
    setmetatable(t, meta)
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

function strut.mesh.GenerateCubicMesh(min, max, material, color)
	if material and !isstring(material) then
		material = material:GetName()
	end

	local scale = 0.25
	local u,v = {Vector(1, 0, 0),0,scale},{Vector(0, -1, 0),0,scale}
	local t = {u[1], u[2], u[3], 1}
	local n = Vector(0,0,1)
	local a = strut.poly.Create()
	a:SetTextureData(material,u,v,color)
	a:AddVertex(Vector(min.x,max.y,max.z))
	a:AddVertex(max)
	a:AddVertex(Vector(max.x,min.y,max.z))
	a:AddVertex(Vector(min.x,min.y,max.z))
	a:ApplyNormal(n)
	a:Calculate()

	u,v = {Vector(-1, 0, 0),0,scale},{Vector(0, -1, 0),0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(0,0,-1)
	local b = strut.poly.Create()
	b:SetTextureData(material,u,v,color)
	b:AddVertex(min)
	b:AddVertex(Vector(max.x,min.y,min.z))
	b:AddVertex(Vector(max.x,max.y,min.z))
	b:AddVertex(Vector(min.x,max.y,min.z))
	b:ApplyNormal(n)
	b:Calculate()
	
	u,v = {Vector(0, 1, 0),0,scale},{Vector(0, 0, -1),0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(-1,0,0)
	local c = strut.poly.Create()
	c:SetTextureData(material,u,v,color)
	c:AddVertex(Vector(min.x,min.y,max.z))
	c:AddVertex(min)
	c:AddVertex(Vector(min.x,max.y,min.z))
	c:AddVertex(Vector(min.x,max.y,max.z))
	c:ApplyNormal(n)
	c:Calculate()
	
	u,v = {Vector(0, -1, 0),0,scale},{Vector(0, 0, -1),0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(1,0,0)
	local d = strut.poly.Create()
	d:SetTextureData(material,u,v,color)
	d:AddVertex(max)
	d:AddVertex(Vector(max.x,max.y,min.z))
	d:AddVertex(Vector(max.x,min.y,min.z))
	d:AddVertex(Vector(max.x,min.y,max.z))
	d:ApplyNormal(n)
	d:Calculate()
	
	u,v = {Vector(1, 0, 0),0,scale},{Vector(0, 0, -1),0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(0,1,0)
	local e = strut.poly.Create()
	e:SetTextureData(material,u,v,color)
	e:AddVertex(Vector(min.x,max.y,max.z))
	e:AddVertex(Vector(min.x,max.y,min.z))
	e:AddVertex(Vector(max.x,max.y,min.z))
	e:AddVertex(max)
	e:ApplyNormal(n)
	e:Calculate()
	
	u,v = {Vector(-1, 0, 0),0,scale},{Vector(0, 0, -1),0,scale}
	t = {u[1], u[2], u[3], 1}
	n = Vector(0,-1,0)
	local f = strut.poly.Create()
	f:SetTextureData(material,u,v,color)
	f:AddVertex(Vector(max.x,min.y,max.z))
	f:AddVertex(Vector(max.x,min.y,min.z))
	f:AddVertex(min)
	f:AddVertex(Vector(min.x,min.y,max.z))
	f:ApplyNormal(n)
	f:Calculate()
	
	return strut.mesh.Create(a,b,c,d,e,f)
end

function strut.mesh.GenerateWall(startPos, endPos, thickness, height, material, color)
	if material and !isstring(material) then
		material = material:GetName()
	end
	
	local forwardDir = (endPos - startPos):GetNormalized()
    local rightDir = forwardDir:Cross(vector_up)

	local widthOffset = rightDir * thickness / 2
	local heightOffset = vector_up * height

	local vertices = {
		startPos - widthOffset,
		startPos + widthOffset,
		endPos - widthOffset,
		endPos + widthOffset,
		startPos - widthOffset + heightOffset,
		startPos + widthOffset + heightOffset,
		endPos - widthOffset + heightOffset,
		endPos + widthOffset + heightOffset,
	}

	local texScale = 0.25

	local front = strut.poly.Create()
	front:SetTextureData(material, {-rightDir, 0, texScale}, {-vector_up, 0, texScale}, color)
	front:AddVertex(vertices[3])
	front:AddVertex(vertices[4])
	front:AddVertex(vertices[8])
	front:AddVertex(vertices[7])
	front:ApplyNormal(forwardDir)
	front:Calculate()

	local back = strut.poly.Create()
	back:SetTextureData(material, {rightDir, 0, texScale}, {-vector_up, 0, texScale}, color)
	back:ApplyNormal(-forwardDir)
	back:AddVertex(vertices[2])
	back:AddVertex(vertices[1])
	back:AddVertex(vertices[5])
	back:AddVertex(vertices[6])
	back:Calculate()

	local right = strut.poly.Create()
	right:SetTextureData(material, {forwardDir, 0, texScale}, {-vector_up, 0, texScale}, color)
	right:AddVertex(vertices[4])
	right:AddVertex(vertices[2])
	right:AddVertex(vertices[6])
	right:AddVertex(vertices[8])
	right:ApplyNormal(rightDir)
	right:Calculate()

	local left = strut.poly.Create()
	left:SetTextureData(material, {-forwardDir, 0, texScale}, {-vector_up, 0, texScale}, color)
	left:AddVertex(vertices[1])
	left:AddVertex(vertices[3])
	left:AddVertex(vertices[7])
	left:AddVertex(vertices[5])
	left:ApplyNormal(-rightDir)
	left:Calculate()

	local top = strut.poly.Create()
	top:SetTextureData(material, {forwardDir, 0, texScale}, {-rightDir, 0, texScale}, color)
	top:AddVertex(vertices[6])
	top:AddVertex(vertices[5])
	top:AddVertex(vertices[7])
	top:AddVertex(vertices[8])
	top:ApplyNormal(vector_up)
	top:Calculate()

	local bottom = strut.poly.Create()
	bottom:SetTextureData(material, {-forwardDir, 0, texScale}, {-rightDir, 0, texScale}, color)
	bottom:AddVertex(vertices[1])
	bottom:AddVertex(vertices[2])
	bottom:AddVertex(vertices[4])
	bottom:AddVertex(vertices[3])
	bottom:ApplyNormal(-vector_up)
	bottom:Calculate()

	return strut.mesh.Create(front, back, right, left, top, bottom)
end