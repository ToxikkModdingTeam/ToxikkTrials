//================================================================
// Trials.TTInfoPod
// ----------------
// Wooooo info pods!
// ----------------
// by Chatouille
//================================================================
class TTInfoPod extends Actor
	placeable
	ClassGroup(Trials);

// dynamic
var(InfoPod) bool bEnabled;
var(InfoPod) String Text;
var(InfoPod) Color TextColor;
var(InfoPod) float Scale;

// static
var(InfoPod) Font TextFont;
var(InfoPod) int MaxViewDistance;

// internals
var Vector PlayerCamPos;
var bool bPlayerCanSee;

Replication
{
	if ( bNetInitial || bNetDirty )
		bEnabled, Text, TextColor, Scale;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( WorldInfo.NetMode != NM_DedicatedServer )
		SetTimer(0.5, false, 'AddToHUD');
}

simulated function AddToHUD()
{
	local PlayerController PC;

	foreach LocalPlayerControllers(class'PlayerController', PC)
	{
		if ( CRZHud(PC.myHud) != None )
		{
			CRZHud(PC.myHud).AddPostRenderedActor(Self);
			SetTimer(0.5, true, 'CheckPlayerCanSee');
			return;
		}
	}
	SetTimer(0.5, false, GetFuncName());
}

simulated function SetEnabled(bool newEnabled)
{
	bEnabled = newEnabled;
}

simulated function OnToggle(SeqAct_Toggle Action)
{
	if ( Action.InputLinks[0].bHasImpulse ) //turn on
		SetEnabled(true);
	else if ( Action.InputLinks[1].bHasImpulse )    //turn off
		SetEnabled(false);
	else if ( Action.InputLinks[2].bHasImpulse )    //toggle
		SetEnabled(!bEnabled);
}

simulated function CheckPlayerCanSee()
{
	bPlayerCanSee = FastTrace(Location, PlayerCamPos);
}

simulated event PostRenderFor(PlayerController PC, Canvas C, Vector CamPos, Vector CamDir)
{
	local float Dist;
	local Vector ScreenLoc;
	local Vector2D TextSize;

	PlayerCamPos = CamPos;

	if ( !bEnabled || !bPlayerCanSee )
		return;

	Dist = VSize(CamPos - Location);
	if ( Dist > MaxViewDistance )
		return;

	ScreenLoc = C.Project(Location);
	if ( ScreenLoc.X < 0 || ScreenLoc.X >= C.ClipX || ScreenLoc.Y < 0 || ScreenLoc.Y >= C.ClipY )
		return;

	C.Font = TextFont;
	C.TextSize(Text, TextSize.X, TextSize.Y, Scale, Scale);

	// no draw if wrap!
	if ( ScreenLoc.X + TextSize.X / 2 + 1 >= C.ClipX )
		return;

	if ( Dist > 0.9*MaxViewDistance )
		C.SetDrawColor(TextColor.R, TextColor.G, TextColor.B, TextColor.A * (MaxViewDistance - Dist) / (0.1*MaxViewDistance));
	else
		C.DrawColor = TextColor;

	C.SetPos(ScreenLoc.X - TextSize.X / 2, ScreenLoc.Y - TextSize.Y / 2);
	C.DrawText(Text, false, Scale, Scale);
}

defaultproperties
{
	bEnabled=true
	Text="- Info Pod -"
	TextColor=(R=255,G=255,B=255,A=255)
	Scale=0.8
	TextFont=Font'crzgfx.Font_Jupiter_DF'
	MaxViewDistance=1000

	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true

	bHidden=true
	bNoDelete=true

	Begin Object name=Sprite class=SpriteComponent
		Sprite=Texture2D'EditorResources.S_Keypoint'
        AlwaysLoadOnClient=false
        AlwaysLoadOnServer=false
	End Object
	Components(0)=Sprite
}
