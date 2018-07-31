function EFFECT:Init(data)
	self.m_bVisible = true
end

function EFFECT:SetMesh(mesh) self.Mesh = mesh; self:CreateIMesh(); end

function EFFECT:GetMesh() return self.Mesh end
function EFFECT:SetMeshs(n) end
function EFFECT:SetVisible(visible) self.m_bVisible = visible end

function EFFECT:GetVisible() return self.m_bVisible end

local color = Color(194, 205, 198, 100)
local material = strut.utils.ToUnlit(Material("color"))

function EFFECT:SetBounds(mins, maxs)
	self:SetRenderBoundsWS(mins, maxs)
end

function EFFECT:CreateIMesh()
    self.IMesh = self:GetMesh():ToIMesh(material, color)
end

function EFFECT:GetIMesh() return self.IMesh end

function EFFECT:RenderMesh()
	if self.IMesh then
		local matrix = Matrix()
		matrix:SetTranslation(self:GetPos())

		render.SetMaterial(material)

		cam.PushModelMatrix(matrix)
			self.IMesh:Draw() 
		cam.PopModelMatrix()
	end
end

function EFFECT:Think()
	return !self.m_bRemove
end

function EFFECT:Render()
	if !self.m_bVisible then return end

	self:RenderMesh()
end