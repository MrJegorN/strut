strut.utils = strut.utils or {}

function strut.utils.ToVertexLit(material)
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