//================================================================
// Trials.TTWeap_CamLauncher
// ----------------
// Weapon firing cameras to visualize round-the-corner spots
// Primary : fires a camera projectile, or destroys it.
// Secondary : switches in and out of camera view.
// ----------------
// by Chatouille
//================================================================
class TTWeap_CamLauncher extends CRZWeap_SniperRifle;

var TTProj_Cam ActiveCam;

// Sound is called right before firing - the ActiveCam var has not changed yet
simulated function PlayFiringSound()
{
	MakeNoise(1.0);
	if ( CurrentFireMode == 0 )
	{
		if ( ActiveCam == None )
			WeaponPlaySound( WeaponFireSnd[0] );
		else
			WeaponPlaySound( WeaponFireSnd[2] );
	}
	else if ( ActiveCam != None )
	{
		if ( ! IsInCam() )
			WeaponPlaySound( WeaponFireSnd[1] );
		else
			WeaponPlaySound( WeaponFireSnd[3] );
	}
	else
		WeaponPlaySound( WeaponEmptySnd );
}

// Primary : fire a camera projectile, or destroy it
simulated function Projectile ProjectileFire()
{
	if ( /*Role == ROLE_Authority &&*/ PlayerController(Instigator.Controller) != None )
	{
		if ( ActiveCam != None )
		{
			ActiveCam.Destroy();
		}
		else
		{
			ActiveCam = TTProj_Cam(Super.ProjectileFire());
			ActiveCam.Weap = Self;
			return ActiveCam;
		}
	}
	return None;
}

// Secondary : switch to camera view.
simulated function CustomFire()
{
	if ( /*Role == ROLE_Authority &&*/ ActiveCam != None )
	{
		SetCameraView( !IsInCam() );
	}
}

// Avoid constantly spamming fire while holding
simulated function bool ShouldRefire()
{
	ClearPendingFire(0);
	ClearPendingFire(1);
	return false;
}

// Hook player owner death to exit camera view
function HolderDied()
{
	if ( ActiveCam != None )
		ActiveCam.Destroy();

	Super.HolderDied();
}

// Hook weapon-switch to exit camera view
auto state Inactive
{
	simulated function BeginState(Name PrevStateName)
	{
		if ( ActiveCam != None )
			ActiveCam.Destroy();

		Super.BeginState(PrevStateName);
	}
}

simulated function bool IsInCam()
{
	return ( ActiveCam != None && PlayerController(Instigator.Controller) != None && PlayerController(Instigator.Controller).ViewTarget == ActiveCam );
}

function SetCameraView(bool bCamView)
{
	if ( bCamView ) 
	{
		if ( !IsInCam() )
		{
			PlayerController(Instigator.Controller).SetViewTarget(ActiveCam);
			PlayerController(Instigator.Controller).ClientSetViewTarget(ActiveCam);
		}
	}
	else
	{
		if ( IsInCam() )
		{
			PlayerController(Instigator.Controller).ClientSetViewTarget(Instigator);
			PlayerController(Instigator.Controller).SetViewTarget(Instigator);
		}
	}
}

function byte BestMode()
{
    return 1;	// prevent bots from being naughty...
}

simulated function InitWeaponHudElements(CRZHudMovie HUD)
{
	Super.InitWeaponHudElements(HUD);

    if ( HUD.WeaponName_TF != None )
        HUD.WeaponName_TF.SetString("text", "CamLauncher");
}

defaultproperties
{
	WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(1)=EWFT_Custom
	FireInterval(0)=0.5
	FireInterval(1)=0.33
	ShotCost(0)=0
	ShotCost(1)=0
	WeaponProjectiles(0)=class'TTProj_Cam'
	bCanThrow=false
	AmmoCount=1
	EquipTime=0.33
	PutDownTime=0.1
	AttachmentClass=class'TTAttachment_CamLauncher'
	// 0 = firing camera sound
	// 1 = enter camera view sound
	WeaponFireSnd(1)=SoundCue'Snd_Pickups.Steroids.A_Powerup_Steroids_WarningCue'
	// 2 = destroying camera sound
	WeaponFireSnd(2)=SoundCue'Snd_GUI.Cue_UI_Apply'
	// 3 = leaving camera view sound
	WeaponFireSnd(3)=SoundCue'Snd_Pickups.Steroids.A_Powerup_Steroids_WarningCue'

	Begin Object name=FPMesh
		FOV=55.0
        scale=1.0
	End Object

	//Override sniper stuff we don't want
	bZoomedFireMode(1)=0
}
