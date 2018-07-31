strut.utils = strut.utils or {}

strut.utils.nodraw = Material("nodraw")

function strut.utils.SortBounds(vec1, vec2)
    local vecMin, vecMax = Vector(), Vector()

    if vec1 and vec2 then 
        if(vec1.x < vec2.x) then vecMin.x = vec1.x; vecMax.x = vec2.x else vecMin.x = vec2.x; vecMax.x = vec1.x end
        if(vec1.y < vec2.y) then vecMin.y = vec1.y; vecMax.y = vec2.y else vecMin.y = vec2.y; vecMax.y = vec1.y end
        if(vec1.z < vec2.z) then vecMin.z = vec1.z; vecMax.z = vec2.z else vecMin.z = vec2.z; vecMax.z = vec1.z end
    end

    return vecMin, vecMax
end

function strut.utils.GetWallBounds(mins, maxs, width, height)
    local dir = (maxs - mins):GetNormalized()
    local right = dir:Cross(vector_up)

    mins = mins - right * width / 2
    maxs = maxs + right * width / 2 + vector_up * height

    //mins, maxs = strut.utils.SortBounds(mins, maxs)

    return mins, maxs
end

function strut.utils.ToVertexLit(material)
    if SERVER then return material end

	local str = material:GetName()
	
	local shader = material:GetShader()
	if !string.find(shader, "VertexLitGeneric") then
		local t = material:GetString("$basetexture")
		if t then
			local params = {}
			params["$basetexture"] = t

			material = CreateMaterial(str.."_strut_vlit", "VertexLitGeneric", params)
		end
	end
	return material
end

function strut.utils.ToUnlit(material)
    if SERVER then return material end

	local str = material:GetName()
	
	local shader = material:GetShader()
	if !string.find(shader, "UnlitGeneric") then
		local t = material:GetString("$basetexture")
		if t then
			local params = {}
			params["$basetexture"] = t

			material = CreateMaterial(str.."_strut_unlit", "UnlitGeneric", params)
		end
	end
	return material
end

function strut.utils.ToLitMapped(material)
    if SERVER then return material end
    
	local str = material:GetName()

	local shader = material:GetShader()
	if !string.find(shader, "LightmappedGeneric") then
		local t = material:GetString("$basetexture")
		if t then
			local params = {}
			params["$basetexture"] = t

			material = CreateMaterial(str.."_strut_litmapped", "LightmappedGeneric", params)
		end
	end
	return material
end

function strut.utils.CreateEffect(...)
	local tbEnts = ents.GetAll()
	util.Effect(...)
	return ents.GetAll()[#tbEnts + 1] || NULL
end