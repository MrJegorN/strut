AddCSLuaFile()

SWEP.PrintName = "Strut Editor"

SWEP.Slot = 0
SWEP.SlotPos = 4

SWEP.Spawnable = true

SWEP.ViewModel = Model( "models/weapons/c_arms.mdl" )
SWEP.WorldModel = ""
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false

local GridSize = 50
local GridArea = 2500

local function snap(num)
    return math.Round(num / GridSize) * GridSize
end

local function toGrid(vec, offset)
    local height = -12799.9
    vec.x = snap(vec.x)
    vec.y = snap(vec.y)
    vec.z = height + (offset and offset or 0)

    return vec
end

AccessorFunc(SWEP, "trace1", "Trace1")
AccessorFunc(SWEP, "trace2", "Trace2")

function SWEP:SetupDataTables()
    self:NetworkVar("Vector", 3, "Vec1")
	self:NetworkVar("Vector", 4, "Vec2")

    self:NetworkVar("Int", 3, "Stage")
end

function SWEP:Initialize()
	self:SetHoldType("fist")

    if CLIENT then self:CreateMeshRenderer() end
end

function SWEP:IsOnStage(stage)
    return self:GetStage() == stage
end

function SWEP:GetTrace()
    local trace = self.Owner:GetEyeTrace()

    return trace
end

local material = strut.utils.ToVertexLit(Material("brick/brickwall003a_construct"))
function SWEP:GetCurrentMesh()
    local startPos, endPos = self:GetVec1(), toGrid(self:GetTrace().HitPos)
    local mesh = strut.mesh.GenerateWall(startPos, endPos, 10, 120, material)
    
    return mesh, mesh:GetBounds()
end

function SWEP:CreateMeshRenderer()
    if self.Renderer then self.Renderer.m_bRemove = true end

    local renderer = strut.utils.CreateEffect("effect_strut_brush", EffectData())
    self.Renderer = renderer
end

function SWEP:UpdateMeshRenderer()
    if !self.Renderer then return end

    if self:IsOnStage(1) then
        self.Renderer:SetVisible(true)
    else
        self.Renderer:SetVisible(false)
        return
    end
    
    local mesh, mins, maxs = self:GetCurrentMesh()
    
    self.Renderer:SetMesh(mesh)
    self.Renderer:SetBounds(mins, maxs)
end

function SWEP:GetMeshRenderer()
    return self.Renderer
end

function SWEP:PrimaryAttack()
    if SERVER then
        if self:IsOnStage(0) then
            self:SetTrace1(self:GetTrace())
            self:SetVec1(toGrid(self:GetTrace().HitPos))

            self:SetStage(1)
        elseif self:IsOnStage(1) then
            self:SetTrace2(self:GetTrace())
            self:SetVec2(toGrid(self:GetTrace().HitPos))
            
            local mesh = self:GetCurrentMesh()

            local hitent1 = self:GetTrace1().Entity
            local hitent2 = self:GetTrace2().Entity
            
            if IsValid(hitent1) and hitent1:GetClass() == "strut_brush_base" then
                hitent1:AddMesh(mesh, true)
            elseif IsValid(hitent2) and hitent2:GetClass() == "strut_brush_base" then
                hitent2:AddMesh(mesh, true)
            else
                local brush = ents.Create("strut_brush_base")
                brush:AddMesh(mesh)
                brush:Spawn()
                brush:Activate()

                undo.Create("Brush")
                    undo.AddEntity(brush)
                    undo.SetPlayer(self.Owner)
                undo.Finish()
            end

            self:SetStage(0)
        end
    end

    self:SetNextPrimaryFire(CurTime() + 0.2)
    self:SetNextSecondaryFire(CurTime() + 0.2)
end

function SWEP:SecondaryAttack()
	self:PrimaryAttack()
end

function SWEP:DrawHUD()
    self:UpdateMeshRenderer()
end

if CLIENT then

    hook.Add("PostDrawOpaqueRenderables", "Strut_Grid", function()
        if IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() != "weapon_strut_editor" then return end
        
        for i = -GridArea/2, GridArea/2, GridSize do
            local startX = toGrid(LocalPlayer():GetPos() + Vector(i, -GridArea/2, 0))
            local endX = toGrid(LocalPlayer():GetPos() + Vector(i, GridArea/2, 0))
            local startY = toGrid(LocalPlayer():GetPos() + Vector(-GridArea/2, i, 0))
            local endY = toGrid(LocalPlayer():GetPos() + Vector(GridArea/2, i, 0))
            
            render.DrawLine(startX, endX, color_white, true)
            render.DrawLine(startY, endY, color_white, true)
        end
    end)

end