strut.utils = strut.utils or {}

function strut.utils.GetMinMaxBounds(vec1, vec2)
    local vecMin, vecMax = Vector(), Vector()

    if vec1 and vec2 then 
        if(vec1.x < vec2.x) then vecMin.x = vec1.x; vecMax.x = vec2.x else vecMin.x = vec2.x; vecMax.x = vec1.x end
        if(vec1.y < vec2.y) then vecMin.y = vec1.y; vecMax.y = vec2.y else vecMin.y = vec2.y; vecMax.y = vec1.y end
        if(vec1.z < vec2.z) then vecMin.z = vec1.z; vecMax.z = vec2.z else vecMin.z = vec2.z; vecMax.z = vec1.z end
    end

    return vecMin, vecMax
end

function strut.utils.CreateEffect(...)
	local tbEnts = ents.GetAll()
	util.Effect(...)
	return ents.GetAll()[#tbEnts + 1] || NULL
end