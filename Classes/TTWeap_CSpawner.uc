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

static function InitWeaponHudElements(CRZHud HUD)
{
	Super.InitWeaponHudElements(HUD);

    if ( HUD.HudMovie.WeaponName_TF != None )
        HUD.HudMovie.WeaponName_TF.SetString("text", "ReSpawner");
}

defaultproperties
{
	PlaceSpawnTime=1.0
	RemoveSpawnTime=1.5

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
