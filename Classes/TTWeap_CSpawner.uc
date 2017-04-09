//================================================================
// Trials.TTWeap_CSpawner
// ----------------
// Weapon to place/replace/remove custom personnal spawn points
// ----------------
// by Chatouille
//================================================================
class TTWeap_CSpawner extends CRZWeap_PistolAW29;

var float PlaceSpawnTime;
var float RemoveSpawnTime;

var Vector2D ProgressSize;
var Color ProgressCol[2];
var GUIGroup ProgressBox;
var GUIGroup ProgressLoad;
var bool bProgressVisible;

simulated function CustomFire()
{
	// Start timer on both server and client
	StartTimer();

	// Check pawn is non moving when placing custom respawns
	// Only server should reset timer otherwise we'll have stupid desyncs
	if ( CurrentFireMode == 0 && Role == ROLE_Authority )
		Enable('Tick');
}

// Avoid constantly spamming fire while holding
simulated function bool ShouldRefire()
{
	ClearPendingFire(0);
	ClearPendingFire(1);
	return false;
}

// Constantly check pawn is non moving while placing custom respawn
event Tick(float dt)
{
	local Pawn P;

	if ( Role == ROLE_Authority && IsTimerActive('FireTimer') && CurrentFireMode == 0 )
	{
		P = Pawn(Owner);
		if ( P == None || P.Physics != PHYS_Walking || VSize(P.Velocity) > 0 || P.Base == None )
			ResetTimer();
	}
	else
		Disable('Tick');
}

simulated function StartTimer()
{
	if ( CurrentFireMode == 0 )
		SetTimer(PlaceSpawnTime, false, 'FireTimer');
	else
		SetTimer(RemoveSpawnTime, false, 'FireTimer');
}

simulated function ResetTimer()
{
	if ( IsTimerActive('FireTimer') )
		StartTimer();

	if ( WorldInfo.NetMode == NM_DedicatedServer )
		ClientResetTimer();
}

// unreliable because it can be called a lot (tick)
// will generate desyncs in extreme cases...
unreliable client simulated function ClientResetTimer()
{
	ResetTimer();
}

simulated function FireTimer()
{
	// Call directly from authority, no need to replicate from client
	// Client uses this timer only for chargebar display
	if ( Role == ROLE_Authority )
	{
		if ( CurrentFireMode == 0 )
			TTPRI(Instigator.PlayerReplicationInfo).ServerPlaceCustomSpawn();
		else
			TTPRI(Instigator.PlayerReplicationInfo).ServerRemoveCustomSpawn();
		if ( ProgressLoad != None )
			ProgressLoad.MoveToAuto("width:100%", 0.1, ANIM_EASE_IN);
	}
}

simulated function EndFire(byte FireModeNum)
{
	ClearTimer('FireTimer');

	Super.EndFire(FireModeNum);
}

simulated function WeaponPlaySound(SoundCue Sound, optional float NoiseLoudness)
{
	if ( Sound != None && Instigator != None && !bSuppressSounds )
		Instigator.PlaySound(Sound, true);
}

function byte BestMode()
{
    return 1;	// prevent bots from doing silly stuff
}

// HUD Progressbar
simulated function DrawWeaponCrosshair(Hud HUD)
{
	local TTHud H;
	local float pct;

	H = TTHud(HUD);
	if ( H == None )
		return;

	if ( ProgressBox == None )
	{
		ProgressBox = class'GUIGroup'.static.CreateGroup(H.Root);
		ProgressBox.SetPosAuto("center-x:50%; top:50%+64; width:"$ProgressSize.X$"; height:"$ProgressSize.Y);
		ProgressBox.SetColors(MakeColor(0,0,0,128), MakeColor(255,255,255,255));
		ProgressBox.SetAlpha(0.0);

		ProgressLoad = class'GUIGroup'.static.CreateGroup(ProgressBox);
		ProgressLoad.SetPosAuto("left:1; top:1; width:100%-2; height:100%-2");
	}

	if ( IsTimerActive('FireTimer') && !WorldInfo.GRI.bMatchIsOver )
	{
		if ( !bProgressVisible )
		{
			ProgressLoad.SetPosAuto("width:0");
			ProgressBox.AlphaTo(1.0, 0.3, ANIM_EASE_IN);
			bProgressVisible = true;
		}

		ProgressLoad.SetColors(ProgressCol[CurrentFireMode], ProgressLoad.TRANSPARENT);

		pct = 1.0 - GetRemainingTimeForTimer('FireTimer') / (CurrentFireMode == 0 ? PlaceSpawnTime : RemoveSpawnTime);

		ProgressLoad.MoveToAuto("width:" $ (100.0*pct) $ "%", 0.1, ANIM_EASE_IN);
	}
	else if ( bProgressVisible )
	{
		ProgressBox.AlphaTo(0.0, 0.3, ANIM_EASE_OUT);
		bProgressVisible = false;
	}
}

simulated event Destroyed()
{
	if ( ProgressBox != None )
	{
		ProgressBox.RemoveFromParent();
		ProgressBox = None;
	}
	Super.Destroyed();
}


// Weapon name
static function InitWeaponHudElements(CRZHud HUD)
{
	Super.InitWeaponHudElements(HUD);

    if ( HUD.HudMovie.WeaponName_TF != None )
        HUD.HudMovie.WeaponName_TF.SetString("text", "ReSpawner");
}

defaultproperties
{
	PlaceSpawnTime=0.8
	RemoveSpawnTime=1.4

	ProgressSize=(X=200,Y=34)
	ProgressCol(0)=(R=32,G=220,B=32,A=220)
	ProgressCol(1)=(R=255,G=0,B=0,A=220)

	bLoaded=true

	WeaponFireTypes(0)=EWFT_Custom
	WeaponFireTypes(1)=EWFT_Custom
	FireInterval(0)=0.1
	FireInterval(1)=0.1
	ShotCost(0)=0
	ShotCost(1)=0
	bCanThrow=false
	AmmoCount=1
	EquipTime=0.33
	PutDownTime=0.1
	WeaponFireSnd(0)=SoundCue'Snd_GUI.Cue_UI_Apply'
	WeaponFireSnd(1)=SoundCue'Snd_GUI.Cue_UI_Apply'

    Begin Object name=FPMesh
        FOV=50.0
        Scale=1.0
    End Object

	//Override pistol stuff we don't want
	FiringStatesArray(1)=WeaponFiring
}
