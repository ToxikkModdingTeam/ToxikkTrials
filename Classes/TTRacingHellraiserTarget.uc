//================================================================
// Trials.TTRacingHellraiserTarget
// ----------------
// Teleports hellraiser driver when reached
// Only visible by hellraiser drivers
// ----------------
// by Chatouille
//================================================================
class TTRacingHellraiserTarget extends Trigger
	placeable
	ClassGroup(Trials)
	hidecategories(Mobile);


/** Text to write on HUD icon when visible */
var(HUD) String HudText;
/** Color to use for HUD icon when visible */
var(HUD) Color HudColor;
/** Maximum distance to display the HUD icon at */
var(HUD) int MaxHudDistance;
/** Whether this target should be only be displayed when in direct line of sight */
var(HUD) bool bOccluded;
var(HUD) bool bOnlyHellraiserCanSee;

/** Const - HUD Icon box padding */
var Vector2D BoxPadding;


event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local CRZRemoteHellraiser HR;
	local Controller C;

	Super.Touch(Other, OtherComp, HitLocation, HitNormal);

	HR = CRZRemoteHellraiser(Other);
	if ( HR != None )
	{
		C = HR.Controller;
		if ( C != None )
		{
			HR.DriverLeave(true);
			HR.SetCollision(false, false);
			if ( C.Pawn != None )
			{
				C.Pawn.SetLocation(HR.Location);
				C.Pawn.SetRotation(HR.Rotation);
				C.Pawn.Velocity = Vect(0,0,0);
				C.Pawn.SetPhysics(PHYS_Falling);
				C.Pawn.PlayTeleportEffect(true, true);
			}
			HR.Destroy();
		}
	}
}

simulated function PostRenderFor(PlayerController PC, Canvas C, Vector CamPos, Vector CamDir)
{
	local float Dist;
	local Vector ScreenLoc;
	local float Scale;
	local Vector2D TextSize;

	if ( (bOnlyHellraiserCanSee && CRZRemoteHellraiser(PC.Pawn) == None) || (bOccluded && !FastTrace(Location, CamPos)) )
		return;

	Dist = VSize(CamPos - Location);
	if ( Dist > MaxHudDistance )
		return;

	ScreenLoc = C.Project(Location);
	if ( ScreenLoc.X < 0 || ScreenLoc.X >= C.ClipX || ScreenLoc.Y < 0 || ScreenLoc.Y >= C.ClipY )
		return;

	Scale = (Dist > 0 ? FClamp(1024 / Dist, 0.40, 8.0) : 5.0);

	C.Font = class'CRZHud'.default.GlowFonts[0];
	C.TextSize(HudText, TextSize.X, TextSize.Y, Scale, Scale);

	// no draw if wrap!
	if ( ScreenLoc.X + TextSize.X / 2 + 1 >= C.ClipX )
		return;

	C.SetDrawColor(0,0,0,100);
	C.SetPos(ScreenLoc.X - TextSize.X / 2 - BoxPadding.X*Scale + 1, ScreenLoc.Y - TextSize.Y / 2 - BoxPadding.Y*Scale + 1);
	C.DrawRect(TextSize.X + 2*BoxPadding.X*Scale - 2, TextSize.Y + 2*BoxPadding.Y*Scale - 2);

	class'TTWaypoint'.static.DrawObjBoxBounds(C,
			ScreenLoc.X - TextSize.X / 2 - BoxPadding.X*Scale, ScreenLoc.Y - TextSize.Y / 2 - BoxPadding.Y*Scale,
			TextSize.X + 2*BoxPadding.X*Scale, TextSize.Y + 2*BoxPadding.Y*Scale,
			HudColor);

	C.DrawColor = HudColor;
	C.SetPos(ScreenLoc.X - TextSize.X / 2, ScreenLoc.Y - TextSize.Y / 2);
	C.DrawText(HudText, false, Scale, Scale);
}


defaultproperties
{
	HudText="TARGET"
	HudColor=(R=255,G=180,B=0,A=255)
	MaxHudDistance=10000
	bOccluded=false
	bOnlyHellraiserCanSee=true

	BoxPadding=(X=16,Y=16)

	bAlwaysRelevant=true

	Begin Object Name=Sprite
		//TODO: custom icons
		Sprite=Texture2D'EditorResources.S_Trigger'
	End Object

	bProjTarget=false
	bBlockActors=false
}
