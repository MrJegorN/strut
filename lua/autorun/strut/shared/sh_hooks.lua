hook.Add("PhysgunPickup", "strut_disable_physgun", function(ply, entity)
    if entity:GetClass() == "strut_brush_base" then return false end
end)