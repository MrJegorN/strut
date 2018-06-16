strut.utils = strut.utils or {}

function strut.utils.ToVertexLit(material)
	local str = material:GetName()

	local shader = material:GetShader()
	if string.find(shader,"Water") || string.find(shader, "LightmappedGeneric") || string.find(shader, "Cable") || string.find(shader, "WorldVertexTransition") then
		local t = material:GetString("$basetexture")
		if t then
			local params = {}
			params["$basetexture"] = t

			material = CreateMaterial(str.."_strut_vlit", "VertexLitGeneric", params)
		end
	end
	return material
end

function strut.utils.ToLitMapped(material)
	local str = material:GetName()

	local shader = material:GetShader()
	if string.find(shader,"Water") || string.find(shader, "VertexLitGeneric") || string.find(shader, "Cable") || string.find(shader, "WorldVertexTransition") then
		local t = material:GetString("$basetexture")
		if t then
			local params = {}
			params["$basetexture"] = t

			material = CreateMaterial(str.."_strut_litmapped", "LightmappedGeneric", params)
		end
	end
	return material
end