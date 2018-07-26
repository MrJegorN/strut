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

function SWEP:GetTraceVec()
    return self.Owner:GetEyeTrace().HitPos
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
    
    local mins, maxs = strut.utils.GetMinMaxBounds(self:GetVec1(), self:GetTraceVec())
    self.Renderer:SetCube(mins, maxs)
end

function SWEP:GetMeshRenderer()
    return self.Renderer
end

function SWEP:PrimaryAttack()
    if SERVER then
        if self:IsOnStage(0) then
            self:SetVec1(self:GetTraceVec())

            self:SetStage(1)
        elseif self:IsOnStage(1) then
            self:SetVec2(self:GetTraceVec())

            local mins, maxs = strut.utils.GetMinMaxBounds(self:GetVec1(), self:GetVec2())

            local size = maxs - mins
            
            local brush = ents.Create("strut_brush_base")
            brush:AddMesh(strut.mesh.GenerateCubicMesh(mins, maxs, "brick/brickwall014a"))
            brush:Spawn()
            brush:Activate()
            brush:SetPos(mins + size / 2)

            undo.Create("Brush")
                undo.AddEntity(brush)
                undo.SetPlayer(self.Owner)
            undo.Finish()

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