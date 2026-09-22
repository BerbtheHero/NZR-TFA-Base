-- evill ass inbred baby
-- All bob styles from ARC9's cl_sway.lua, selected via cl_tfa_gunbob_style
-- 0 = Bread & Darsu, 1 = Fesiug, 2 = Arctic, 3 = Darsu, 4 = Bread exaggerated, 5 = CoD Black Ops, -1 = Half-Life 2
-- thanks charlotte

local vector_origin = Vector()

SWEP.BobCT = 0
SWEP.ViewModelBobVelocity = 0
SWEP.ViewModelNotOnGround = 0

local gunbob_intensity_cvar = GetConVar("cl_tfa_gunbob_intensity")
local gunbob_style_cvar = GetConVar("cl_tfa_gunbob_style")
local gunbob_intensity = 1

local gunbob_style_intensity = {
	[0] = 0.5, -- ArcticBreadDarsu
	[1] = 3,   -- Fesiug
	[2] = 0.5, -- Arctic
	[3] = 0.4, -- Darsu
	[4] = 0.3, -- ArcticBread
	[5] = 0.8,   -- BlackOps
}
local gunbob_ads_multiplier = {
	[0] = 6, -- ArcticBreadDarsu
	[1] = 0.03, -- Fesiug
	[2] = 0.6, -- Arctic
	[3] = 3, -- Darsu
	[4] = 4, -- ArcticBread
	[5] = 0.8, -- BlackOps
}

local gunbob_anim_mode_cvar = GetConVar("cl_tfa_gunbob_anim_mode")

local function l_Lerp(t, a, b)
	if t <= 0 then return a end
	if t >= 1 then return b end
	return a + (b - a) * t
end

local function WeaponHasLocomotionAnims(self, self2)
	return self2.GetStatL(self, "WalkAnimation") ~= nil
		and self2.GetStatL(self, "SprintAnimation") ~= nil
end

local function WeaponHasSprintAnim(self, self2)
	return self2.GetStatL(self,"Sprint_Mode") ~= TFA.Enum.LOCOMOTION_LUA
end

local function ShouldSuppressGunbob(self, self2)
	if self2.GetStatL(self, "ForceGunbob") then
		return false
	end

local mode = gunbob_anim_mode_cvar:GetInt()	

	if mode == 1 then
		return false -- Force both on: keep gunbob
	elseif mode == 2 then
		return false -- Gunbob only: keep gunbob, disable animations elsewhere
	end

if self2.GetStatL(self,"Walk_Mode") ~= TFA.Enum.LOCOMOTION_LUA then
	return true
end

if WeaponHasSprintAnim(self, self2) then
	return self:GetSprinting()
end


return false 
end

local function easeInExpo(x)
	if x <= 0 then return 0 end
	if x >= 1 then return 1 end
	return math.pow(2, 10 * (x - 1))
end

local function easeInQuart(x)
	return x * x * x * x
end

local function easeInQuad(x)
	return x * x
end

-- pawprint 8/21/26: thread changes for the sake of subbase compatibility, persistent state below moved to ctx
local offset = Vector()
local affset = Angle()


local defbobsettingstable  = {0.5, 0.25, 1,    0.75, 2, 0.875} -- x y z   p y r
local defbobsettingstable2 = {1, 0.75, 1,      1, 1, 0.75}       -- x y z   p y r


local function GetSightAmount(self, self2)
	return self2.IronSightsProgressUnpredicted or self:GetIronSightsProgress() or 0
end

local function GetSharedMult(self, self2, stylemult)

	local mult
	if self:GetSprinting() then
		mult = self2.GetStatL(self, "BobSprintMult", 1) or 1
	else
		mult = self2.GetStatL(self, "BobWalkMult", 1) or 1
	end
	return mult * stylemult
end

local function FesiugBob(self, self2, pos, ang, stylemult, ctx)
	if self:GetCustomizing() then return pos, ang end
	local owner = self:GetOwner()
	if not IsValid(owner) then return pos, ang end

	local sharedmult = GetSharedMult(self, self2, stylemult)
	local sightamount = GetSightAmount(self, self2)
	local sightdelta = 1 - sightamount

	local cv = owner:GetVelocity():Length()
	ctx.v = math.Approach(ctx.v, cv, FrameTime()*400/0.4)
	ctx.v = math.Clamp(ctx.v, 0, 400)
	local tv = ctx.v / 400
	tv = tv * 1.1
	local mulp = Lerp(sightdelta, 1, 0.15)
	local mulk = Lerp(sightdelta, 1, 0.3)
	local tk = tv * mulk
	tv = tv * mulp
	ctx.BobScale = 0
	local p = math.pi
	local spe = self:GetSprinting()

	local grounded = (owner:IsOnGround() or owner:GetMoveType() == MOVETYPE_NOCLIP)
	ctx.airtime = math.Approach(ctx.airtime, (grounded and 0 or 1), FrameTime()*5*(grounded and 10 or 1))

	offset:Set(vector_origin)
	affset:Set(angle_zero)

	local ct = CurTime() * 1.1

	offset.x = offset.x + math.sin( ct * p * 2 ) * 0.2 * ( spe and -2 or 1 )
	offset.y = offset.y + math.pow(math.sin( ct * p * 2 ), 2) * -0.5 * ( spe and -2 or 1 )
	offset.z = offset.z + math.abs(math.sin( ct * p * -1 )) * -0.15

	offset.z = offset.z + math.pow(math.abs( math.sin(ct * p * 2) ), 6) * -0.395 * ( spe and -4 or 0 )

	offset.z = offset.z + ( (-0.395/2)*3 * tv )

	offset.z = offset.z + ( math.pow(math.sin((ct+0)*p*2.5), 2) * -0.3 )
	offset.z = offset.z + ( math.pow(math.sin((ct+0.3)*p*2.5), 2) * -0.3 )

	affset.x = affset.x - ( math.pow( math.sin( ct * p ) * 2.2, 2 ) - ( (2.2/2) * tv ) ) * ( spe and 2 or 1 )
	affset.y = affset.y + math.sin( ct * p * -(3) ) * 0.5 * 1.5

	affset.z = affset.z + ( -1 * math.sin( ct * p * 2 ) * 2 * 1.5 ) * ( spe and 2 or 1 )
	affset.z = affset.z + ( 2 * math.sin( ct * p * 2 ) * 2 * 1.5 ) * ( spe and 2 or 1 )

	affset.x = affset.x + ( (-2) * tv )

	pos:Add( ang:Right()     *   offset.x * tv * sharedmult )
	pos:Add( ang:Forward()   *   offset.y * tv * sharedmult )
	pos:Add( ang:Up()        *   offset.z * tv * sharedmult )

	local stammertime_pos = Vector()
	local stammertime_ang = Angle()

	local pep = owner:KeyDown(IN_FORWARD) or owner:KeyDown(IN_BACK) or owner:KeyDown(IN_MOVELEFT) or owner:KeyDown(IN_MOVERIGHT)
	if tk > 0.1 then
		ctx.stammer = 1
		ctx.stammer_moving = true
	else
		ctx.stammer_moving = false
		ctx.stammer = math.Approach(ctx.stammer, 0, FrameTime()*3)
	end

	ctx.elistam = math.Approach(ctx.elistam, (!pep and ctx.stammer or 0)*Lerp(sightdelta, 1, 0.3)*0.5, FrameTime()*3)

	stammertime_pos.x = stammertime_pos.x + math.sin( ct * p * 5*1.334 ) * -0.05
	stammertime_pos.y = stammertime_pos.y + ctx.elistam*-0.5
	stammertime_pos.z = stammertime_pos.z + ctx.elistam*-0.25
	stammertime_ang.y = stammertime_ang.y + math.sin( ct * p * 2*1.334 ) * 0.8
	stammertime_ang.z = stammertime_ang.z + math.sin( ct * p * 5*1.334 ) * 0.5

	pos:Add( ang:Right()     *   stammertime_pos.x * ctx.elistam * sharedmult )
	pos:Add( ang:Forward()   *   stammertime_pos.y * ctx.elistam * sharedmult )
	pos:Add( ang:Up()        *   stammertime_pos.z * ctx.elistam * sharedmult )

	ang:RotateAroundAxis( ang:Forward(),        affset.x * tv * sharedmult )
	ang:RotateAroundAxis( ang:Right(),          affset.y * tv * sharedmult )
	ang:RotateAroundAxis( ang:Up(),             affset.z * tv * sharedmult )

	ang:RotateAroundAxis( ang:Forward(),        stammertime_ang.x * ctx.elistam * sharedmult )
	ang:RotateAroundAxis( ang:Right(),          stammertime_ang.y * ctx.elistam * sharedmult )
	ang:RotateAroundAxis( ang:Up(),             stammertime_ang.z * ctx.elistam * sharedmult )
	ctx.smoothstrafeturn = math.Approach(ctx.smoothstrafeturn, (owner:KeyDown(IN_MOVELEFT) and 2 or owner:KeyDown(IN_MOVERIGHT) and -2 or 0), FrameTime()*10)
	ang:RotateAroundAxis( ang:Up(),             ctx.smoothstrafeturn * tv )

	ang:RotateAroundAxis( ang:Forward(),          math.sin( ct * p * 1 ) * ctx.airtime*-5 * mulp * 2)
	ang:RotateAroundAxis( ang:Right(),          ( math.sin( ct * p * 1 ) * ctx.airtime*3 * mulp ) + ( (3/2) * ctx.airtime * mulp ) )
	ang:RotateAroundAxis( ang:Up(),          math.sin( ct * p * 2 ) * ctx.airtime*2 * mulp )

	return pos, ang
end

local function ArcticBob(self, self2, pos, ang, stylemult, ctx)
	local step = 10
	local mag = 1
	local ts = 0 
	if self:GetCustomizing() then return pos, ang end

	local owner = self:GetOwner()
	if not IsValid(owner) then return pos, ang end
	local ft = FrameTime()

	local sharedmult = GetSharedMult(self, self2, stylemult)

	local v = owner:GetVelocity():Length()
	v = math.Clamp(v, 0, 350)
	ctx.ViewModelBobVelocity = math.Approach(ctx.ViewModelBobVelocity, v, ft * 10000)
	local d = math.Clamp(ctx.ViewModelBobVelocity / 350, 0, 1)

	if owner:OnGround() and owner:GetMoveType() != MOVETYPE_NOCLIP then
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 0, ft / 0.1)
	else
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 1, ft / 0.1)
	end

	d = d * Lerp(GetSightAmount(self, self2), 1, 0.5) * Lerp(ts, 1, 1.5)
	mag = d * 2
	mag = mag * Lerp(ts, 1, 1.5)
	step = 10
	ang:RotateAroundAxis(ang:Forward(), math.sin(ctx.BobCT * step * 0.5) * ((math.sin(ctx.BobCT * 6.151) * 0.2) + 1) * 4.5 * d * sharedmult)
	ang:RotateAroundAxis(ang:Right(), math.sin(ctx.BobCT * step * 0.12) * ((math.sin(ctx.BobCT * 1.521) * 0.2) + 1) * 2.11 * d * sharedmult)
	pos = pos - (ang:Up() * math.sin(ctx.BobCT * step) * 0.075 * ((math.sin(ctx.BobCT * 3.515) * 0.2) + 1) * mag * sharedmult)
	pos = pos + (ang:Forward() * math.sin(ctx.BobCT * step * 0.3) * 0.11 * ((math.sin(ctx.BobCT * 2) * ts * 1.25) + 1) * ((math.sin(ctx.BobCT * 1.615) * 0.2) + 1) * mag * sharedmult)
	pos = pos + (ang:Right() * (math.sin(ctx.BobCT * step * 0.15) + (math.cos(ctx.BobCT * step * 0.3332))) * 0.16 * mag * sharedmult)

	local steprate = Lerp(d, 1, 2.5)
	steprate = Lerp(ctx.ViewModelNotOnGround, steprate, 0.25)

	ctx.BobCT = ctx.BobCT + (ft * steprate)

	return pos, ang
end

local function ArcticBreadBob(self, self2, pos, ang, stylemult, ctx)
	local step = 10
	local mag = 1
	local ts = 0 -- self:GetTraversalSprintAmount()
	if self:GetCustomizing() then return pos, ang end

	local owner = self:GetOwner()
	if not IsValid(owner) then return pos, ang end
	local ft = FrameTime()

	local sharedmult = GetSharedMult(self, self2, stylemult)

	local velocityangle = owner:GetVelocity()
	local v = velocityangle:Length()
	v = math.Clamp(v, 0, 350)
	ctx.ViewModelBobVelocity = math.Approach(ctx.ViewModelBobVelocity, v, ft * 10000)
	local d = math.Clamp(ctx.ViewModelBobVelocity / 350, 0, 1)

	if owner:OnGround() and owner:GetMoveType() != MOVETYPE_NOCLIP then
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 0, ft / 0.1)
	else
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 1, ft / 0.1)
	end

	local sightamount = GetSightAmount(self, self2)

	d = d * Lerp(sightamount, 1,0.03) * Lerp(ts, 1, 1.5)
	mag = d * 2
	mag = mag * Lerp(ts, 1, 2)
	step = 10

	local sidemove = (owner:GetVelocity():Dot(owner:EyeAngles():Right()) / owner:GetMaxSpeed()) * 4 * (1.5-sightamount)
	ctx.smoothsidemove = Lerp(math.Clamp(ft*8, 0, 1), ctx.smoothsidemove, sidemove)

	local crouchmult = 1
	if owner:Crouching() then
		crouchmult = 3.5 + sightamount* 10
		step = 6
	end

	local jumpmove = math.Clamp(easeInExpo(math.Clamp(velocityangle.z, -150, 0)/-150)*0.5 + easeInExpo(math.Clamp(velocityangle.z, 0, 350)/350)*-50, -4, 2.5) * 0.5   -- crazy math for jump movement
	ctx.smoothjumpmove = Lerp(math.Clamp(ft*8, 0, 1), ctx.smoothjumpmove, jumpmove)
	local smoothjumpmove2 = math.Clamp(ctx.smoothjumpmove, -0.3, 0.01) * (1.5-sightamount)


	if owner.GetSliding then if owner:GetSliding() then mag = 0 step = 5 ctx.smoothsidemove = 0 end end

	if self:GetSprinting() then
		pos = pos - (ang:Up() * math.sin(ctx.BobCT * step) * 0.45 * ((math.sin(ctx.BobCT * 3.515) * 0.2) + 1) * mag * sharedmult)
		pos = pos + (ang:Forward() * math.sin(ctx.BobCT * step * 0.3) * 0.11 * ((math.sin(ctx.BobCT * 2) * ts * 1.25) + 1) * ((math.sin(ctx.BobCT * 0.615) * 0.2) + 2) * mag * sharedmult)
		pos = pos + (ang:Right() * (math.sin(ctx.BobCT * step * 0.5) + (math.cos(ctx.BobCT * step * 0.5))) * 0.55 * mag * sharedmult)
		ang:RotateAroundAxis(ang:Forward(), math.sin(ctx.BobCT * step * 0.5) * ((math.sin(ctx.BobCT * 6.151) * 0.2) + 1) * 9 * d * sharedmult + ctx.smoothsidemove * 1.5)
		ang:RotateAroundAxis(ang:Right(), math.sin(ctx.BobCT * step * 0.12) * ((math.sin(ctx.BobCT * 1.521) * 0.2) + 1) * 1 * d * sharedmult)
		ang:RotateAroundAxis(ang:Up(), math.sin(ctx.BobCT * step * 0.5) * ((math.sin(ctx.BobCT * 1.521) * 0.2) + 1) * 6 * d * sharedmult)
		ang:RotateAroundAxis(ang:Right(), smoothjumpmove2 * 5)
	else
		pos = pos - (ang:Up() * math.sin(ctx.BobCT * step) * 0.1 * ((math.sin(ctx.BobCT * 3.515) * 0.2) + 2) * mag * crouchmult * sharedmult) - (ang:Up() * ctx.smoothsidemove * -0.05) - (ang:Up() * smoothjumpmove2 * 0.2)
		pos = pos + (ang:Forward() * math.sin(ctx.BobCT * step * 0.3) * 0.11 * ((math.sin(ctx.BobCT * 2) * ts * 1.25) + 1) * ((math.sin(ctx.BobCT * 0.615) * 0.2) + 1) * mag * sharedmult)
		pos = pos + (ang:Right() * (math.sin(ctx.BobCT * step * 0.5) + (math.cos(ctx.BobCT * step * 0.5))) * 0.55 * mag * sharedmult)
		ang:RotateAroundAxis(ang:Forward(), math.sin(ctx.BobCT * step * 0.5) * ((math.sin(ctx.BobCT * 6.151) * 0.2) + 1) * 5 * d * sharedmult + ctx.smoothsidemove)
		ang:RotateAroundAxis(ang:Right(), math.sin(ctx.BobCT * step * 0.12) * ((math.sin(ctx.BobCT * 1.521) * 0.2) + 1) * 0.1 * d * sharedmult)
		ang:RotateAroundAxis(ang:Right(), smoothjumpmove2 * 5)
	end

	local steprate = Lerp(d, 1, 2.75)
	steprate = Lerp(ctx.ViewModelNotOnGround, steprate, 0.75)

	ctx.BobCT = ctx.BobCT + (ft * steprate)

	return pos, ang
end

local function ArcticBreadDarsuBob(self, self2, pos, ang, stylemult, ctx)
	local step = 10
	local mag = 1
	local ts = 0 -- self:GetTraversalSprintAmount()
	if self:GetCustomizing() then return pos, ang end

	local owner = self:GetOwner()
	if not IsValid(owner) then return pos, ang end
	local ft = FrameTime()

	local sharedmult = GetSharedMult(self, self2, stylemult)
	local velocityangle = owner:GetVelocity()
	local v = velocityangle:Length()
	v = math.Clamp(v, 0, 350)
	ctx.ViewModelBobVelocity = math.Approach(ctx.ViewModelBobVelocity, v, ft * 10000)
	local d = math.Clamp(ctx.ViewModelBobVelocity / 350, 0, 1)
	if owner:OnGround() and owner:GetMoveType() != MOVETYPE_NOCLIP then
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 0, ft / 0.1)
	else
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 1, ft / 0.1)
	end

	local sightamount = GetSightAmount(self, self2)

	d = d * Lerp(sightamount, 1,0.03) * Lerp(ts, 1, 1.5)
	mag = d * 2
	mag = mag * Lerp(ts, 1, 2)
	step = 9.25

	local sidemove = (owner:GetVelocity():Dot(owner:EyeAngles():Right()) / owner:GetMaxSpeed()) * 4 * (1.5-sightamount)
	ctx.smoothsidemove = Lerp(math.Clamp(ft*8, 0, 1), ctx.smoothsidemove, sidemove)

	local crouchmult = 1
	if owner:Crouching() then
		crouchmult = 3.5 + sightamount * 3
		step = 6
	end

	local jumpmove = math.Clamp(easeInExpo(math.Clamp(velocityangle.z, -150, 0)/-150)*0.5 + easeInExpo(math.Clamp(velocityangle.z, 0, 350)/350)*-50, -4, 2.5) * 0.5   -- crazy math for jump movement
	ctx.smoothjumpmove = Lerp(math.Clamp(ft*8, 0, 1), ctx.smoothjumpmove, jumpmove)
	local smoothjumpmove2 = math.Clamp(ctx.smoothjumpmove, -0.3, 0.01) * (1.5-sightamount) * 2


	if owner.GetSliding then if owner:GetSliding() then mag = 0 step = 5 ctx.smoothsidemove = 0 end end


	if self:GetSprinting() then
		pos = pos - (ang:Up() * math.sin(ctx.BobCT * step) * 0.45 * ((math.sin(ctx.BobCT * 3.515) * 0.2) + 1) * mag * sharedmult)
		pos = pos + (ang:Forward() * math.sin(ctx.BobCT * step * 0.3) * 0.13 * ((math.sin(ctx.BobCT * 2) * ts * 1.25) + 2) * ((math.sin(ctx.BobCT * 0.615) * 0.2) + 2) * mag * sharedmult)
		pos = pos + (ang:Right() * (math.sin(ctx.BobCT * step * 0.5) + (math.cos(ctx.BobCT * step * 0.5))) * 0.55 * mag * sharedmult)
		ang:RotateAroundAxis(ang:Forward(), math.sin(ctx.BobCT * step * 0.5) * ((math.sin(ctx.BobCT * 6.151) * 0.2) + 1) * 6 * d * sharedmult + ctx.smoothsidemove * 1.5)
		ang:RotateAroundAxis(ang:Right(), math.sin(ctx.BobCT * step * 0.12) * ((math.sin(ctx.BobCT * 1.521) * 0.2) + 1) * 1 * d * sharedmult)
		ang:RotateAroundAxis(ang:Up(), math.sin(ctx.BobCT * step * 0.5) * ((math.sin(ctx.BobCT * 1.521) * 0.2) + 1) * 3 * d * sharedmult)
		ang:RotateAroundAxis(ang:Right(), smoothjumpmove2 * 2.5)
	else
		pos = pos - (ang:Up() * math.sin(ctx.BobCT * step) * 0.1 * ((math.sin(ctx.BobCT * 3.515) * 0.2) + 1.5) * mag * crouchmult * sharedmult) - (ang:Up() * ctx.smoothsidemove * -0.05) - (ang:Up() * smoothjumpmove2 * 0.1)
		pos = pos + (ang:Forward() * math.sin(ctx.BobCT * step * 0.3) * 0.11 * ((math.sin(ctx.BobCT * 2) * ts * 1.25) + 1) * ((math.sin(ctx.BobCT * 0.615) * 0.2) + 1) * mag * sharedmult)
		pos = pos + (ang:Right() * (math.sin(ctx.BobCT * step * 0.5) + (math.cos(ctx.BobCT * step * 0.5))) * 0.2 * mag * sharedmult)
		ang:RotateAroundAxis(ang:Forward(), math.sin(ctx.BobCT * step * 0.5) * ((math.sin(ctx.BobCT * 6.151) * 0.2) + 1) * 5 * d * sharedmult + ctx.smoothsidemove)
		ang:RotateAroundAxis(ang:Right(), math.sin(ctx.BobCT * step * 0.12) * ((math.sin(ctx.BobCT * 1.521) * 0.2) + 1) * 0.1 * d * sharedmult)
		ang:RotateAroundAxis(ang:Right(), smoothjumpmove2 * 2.5)
	end

	local steprate = Lerp(d, 1, 2.75)
	steprate = Lerp(ctx.ViewModelNotOnGround, steprate, 0.75)

	ctx.BobCT = ctx.BobCT + (ft * steprate)

	return pos, ang
end

local function DarsuBob(self, self2, pos, ang, stylemult, ctx)
	ctx.BobScale = 0 -- hl2 bob removal
	if self:GetCustomizing() then return pos, ang end

	local owner = self:GetOwner()
	if not IsValid(owner) then return pos, ang end
	local ft = FrameTime()
	local velocityangle = owner:GetVelocity()
	local sightamount = GetSightAmount(self, self2)
	local sprintamount = self:GetSprintProgress()

	local sharedmult = GetSharedMult(self, self2, stylemult)

	local velocity = math.Clamp(velocityangle:Length(), 0, 350)

	ctx.ViewModelBobVelocity = math.Approach(ctx.ViewModelBobVelocity, velocity, ft * 10000)

	local d = math.Clamp(ctx.ViewModelBobVelocity / 350, 0, 0.75)

	ctx.notonground = math.Approach(ctx.notonground, (owner:OnGround() and owner:GetMoveType() != MOVETYPE_NOCLIP) and 0 or 1, ft / 0.1)
	local steprate = Lerp(d, 1, 2.5)
	steprate = Lerp(ctx.notonground, steprate, 0.5)


	local jumpmove = math.Clamp(easeInExpo(math.Clamp(velocityangle.z, -350, 0)/-350)*25 + easeInExpo(math.Clamp(velocityangle.z, 0, 350)/350)*-60, -5, 3.5) * (1.5-sightamount) -- crazy math for jump movement
	ctx.smoothjumpmove = Lerp(math.Clamp(ft*8, 0, 1), ctx.smoothjumpmove, jumpmove)


	ctx.BobCT = ctx.BobCT + (ft * steprate)

	d = d * Lerp(sightamount, 1.4, 0.8) -- If we in sights make less moves

	local d2 = easeInQuart(d)
	local d3 = easeInQuad(d) * 0.6
	local speedmult = 1.4
	local speedmultang = 1.45

	local settings = self.BobSettingsMove or defbobsettingstable -- custom bob per gun
	local settings2 = self.BobSettingsSpeed or defbobsettingstable2
	local xm, ym, zm, pm, yym, rm = settings[1], settings[2], settings[3], settings[4], settings[5], settings[6]
	local xms, yms, zms, pms, yyms, rms = settings2[1], settings2[2], settings2[3], settings2[4], settings2[5], settings2[6]

	local sidemove = (owner:GetVelocity():Dot(owner:EyeAngles():Right()) / owner:GetMaxSpeed()) * 4 * (1.5-sightamount)
	ctx.smoothsidemove = Lerp(math.Clamp(ft*8, 0, 1), ctx.smoothsidemove, sidemove)

	local crouchmult = (owner:Crouching() and not self:GetSprinting()) and 2.5*(1.3-sightamount)  or 1

	if owner.GetSliding then if owner:GetSliding() then speedmult = 0.01 d3 = 0 ctx.smoothsidemove = -10 end end

	pos:Sub(ang:Right() *          math.sin(speedmult * ctx.BobCT * 5 * xms)  * d2 * 0.5 * Lerp(sprintamount, 1, 0.05) * xm * sharedmult)                                   -- X
	pos:Sub(ang:Up() *             math.cos(speedmult * ctx.BobCT * 7 * yms)    * d * 0.05 * (crouchmult*crouchmult*crouchmult) * Lerp(sprintamount, 1, 0.3) * ym * sharedmult)                     -- Y
	pos:Sub(ang:Forward() *        math.sin(speedmult * ctx.BobCT * 4 * zms)  * d2 * 0.75 * crouchmult * zm * sharedmult)                   -- Z

	ang:RotateAroundAxis(ang:Right(),   math.sin(speedmultang * ctx.BobCT * 5.5 * pms + 0.3)    * d3 * 2.25 * pm * sharedmult + ctx.smoothjumpmove)                  -- P
	ang:RotateAroundAxis(ang:Up(),      math.cos(speedmultang * ctx.BobCT * 3.3 * yyms)  * d3 * 1 * Lerp(sprintamount, 1, 0.1) * yym * sharedmult)                                   -- Y
	ang:RotateAroundAxis(ang:Forward(), math.sin(speedmultang * ctx.BobCT * 6 * rms)    * d3 * 4.5 * crouchmult * rm * sharedmult + ctx.smoothsidemove)   -- R

	return pos, ang
end

-- CoD Black Ops style gunbob, Thanks Project Aether Devs & KisakBlack source code
-- movement speed based bob
local function BlackOpsBob(self, self2, pos, ang, stylemult, ctx)
	if self:GetCustomizing() then return pos, ang end

	local owner = self:GetOwner()
	if not IsValid(owner) then return pos, ang end
	local ft = FrameTime()

	local sharedmult = GetSharedMult(self, self2, stylemult)
	local sightamount = GetSightAmount(self, self2)


	local velocity = owner:GetVelocity()
	local xyspeed = math.Clamp(velocity:Length(), 0, 350)
	ctx.ViewModelBobVelocity = math.Approach(ctx.ViewModelBobVelocity, xyspeed, ft * 10000)
	local d = math.Clamp(ctx.ViewModelBobVelocity / 350, 0, 1)

	if owner:OnGround() and owner:GetMoveType() != MOVETYPE_NOCLIP then
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 0, ft / 0.1)
	else
		ctx.ViewModelNotOnGround = math.Approach(ctx.ViewModelNotOnGround, 1, ft / 0.1)
	end

	local steprate = Lerp(d, 1, 2.5)
	steprate = Lerp(ctx.ViewModelNotOnGround, steprate, 0.5)

	ctx.BobCT = ctx.BobCT + (ft * steprate)


	-- BOB SPEED: lower = slower. Reduce this multiplier to slow the bob,
	-- raise it to speed it up (intensity is unaffected).
	local cycle = ctx.BobCT * 4 + math.pi * 0.25 + math.pi * 2

	-- CoD Black Ops: speed = xyspeed * bg_weaponBobAmplitudeBase (0.16)
	local speed = ctx.ViewModelBobVelocity * 0.16

	local vBob = (math.sin(cycle * 2) + math.sin(cycle * 4 + math.pi / 2) * 0.2) * 0.75 * speed * 0.03


	local hBob = math.sin(cycle) * speed * 0.08


	local rollBob = math.sin(cycle - 0.47123894) * speed * 1.5 * 0.055
	rollBob = math.min(rollBob, 0)

	local adsBobFactor = Lerp(sightamount, 1, 0.3)
	vBob = vBob * adsBobFactor
	hBob = hBob * adsBobFactor
	rollBob = rollBob * adsBobFactor


	ang:RotateAroundAxis(ang:Right(), -vBob * sharedmult)
	ang:RotateAroundAxis(ang:Up(), -hBob * sharedmult)
	ang:RotateAroundAxis(ang:Forward(), rollBob * sharedmult)

	return pos, ang
end

-- pawprint 8/21/26: fresh ctx table for a new caller, we need life before it can be roblox
function SWEP:NewWalkBobCtx()
	return {v = 0, airtime = 0, stammer = 0, stammer_moving = false, elistam = 0, smoothstrafeturn = 0, smoothsidemove = 0, smoothjumpmove = 0, notonground = 0, ViewModelBobVelocity = 0, ViewModelNotOnGround = 0, BobCT = 0, BobScale = 0, SwayScale = 0}
end

-- pawprint 8/21/26: ctx is optional and defaults to self2.WalkBobCtx, a caller passing its own ctx gets isolated state and never touches self.BobScale/self.SwayScale
function SWEP:WalkBob(pos, ang, breathIntensity, walkIntensity, rate, ftv, ctx)
	local self2 = self:GetTable()
	if not self2.OwnerIsValid(self) then return pos, ang end
	if ShouldSuppressGunbob(self, self2) then
		return pos, ang
	end

	local isDefaultCtx = ctx == nil

	if isDefaultCtx then
		self2.WalkBobCtx = self2.WalkBobCtx or self:NewWalkBobCtx()
		ctx = self2.WalkBobCtx
	end

	gunbob_intensity = gunbob_intensity_cvar:GetFloat()
	local style = gunbob_style_cvar:GetInt()
	local stylemult = gunbob_intensity * (gunbob_style_intensity[style] or 1)

	local sightamount = GetSightAmount(self, self2)
	local adsmult = Lerp(sightamount, 1, gunbob_ads_multiplier[style] or 0.3)
	stylemult = stylemult * adsmult

	ctx.BobScale = 0
	ctx.SwayScale = 0

	local outPos, outAng

	if style == 1 then
		outPos, outAng = FesiugBob(self, self2, pos, ang, stylemult, ctx)
	elseif style == 2 then
		outPos, outAng = ArcticBob(self, self2, pos, ang, stylemult, ctx)
	elseif style == 3 then
		outPos, outAng = DarsuBob(self, self2, pos, ang, stylemult, ctx)
	elseif style == 4 then
		outPos, outAng = ArcticBreadBob(self, self2, pos, ang, stylemult, ctx)
	elseif style == 5 then
		outPos, outAng = BlackOpsBob(self, self2, pos, ang, stylemult, ctx)
	elseif style == 0 then
		outPos, outAng = ArcticBreadDarsuBob(self, self2, pos, ang, stylemult, ctx)
	else
		-- Half-Life 2 style, let the engine handle it
		local sightdelta = 1 - GetSightAmount(self, self2)
		ctx.SwayScale = Lerp(sightdelta, 1, 0.01)
		ctx.BobScale = Lerp(sightdelta, 1, 0.01)
		outPos, outAng = pos, ang
	end

	if isDefaultCtx then
		self.BobScale = ctx.BobScale
		self.SwayScale = ctx.SwayScale
	end

	return outPos, outAng
end

function SWEP:SprintBob(pos, ang, intensity, origPos, origAng)
	return pos, ang
end

local cv_customgunbob = GetConVar("cl_tfa_gunbob_custom")
local fac, bscale

function SWEP:UpdateEngineBob()
	local self2 = self:GetTable()

	if cv_customgunbob:GetBool() then
		self2.BobScale = 0
		self2.SwayScale = 0

		return
	end

	local isp = self2.IronSightsProgressUnpredicted or self:GetIronSightsProgress()
	local wpr = self2.WalkProgressUnpredicted or self:GetWalkProgress()
	local spr = self:GetSprintProgress()

	fac = gunbob_intensity_cvar:GetFloat() * ((1 - isp) * 0.85 + 0.15)
	bscale = fac

	if spr > 0.005 then
		bscale = bscale * l_Lerp(spr, 1, self2.SprintBobMult)
	elseif wpr > 0.005 then
		bscale = bscale * l_Lerp(wpr, 1, l_Lerp(isp, self2.WalkBobMult, self2.WalkBobMult_Iron or self2.WalkBobMult))
	end

	self2.BobScale = bscale
	self2.SwayScale = fac
end
