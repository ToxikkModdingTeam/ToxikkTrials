//================================================================
// Trials.TTProj_Cam
// ----------------
// Camera projectile fired by CamLauncher
// ----------------
// by Chatouille
//================================================================
class TTProj_Cam extends CRZProj_RocketLauncher;

//TODO NETCODE:
// instead of destroying/hiding the replicated Server projectile,
// we should destroy/hide our own simulated projectile and replace CamLauncher.ActiveCam with the Server projectile.
// => This should help getting rid of the occasional desyncs,
// where player starts firing client proj and server proj alternatively instead of simultaneously.
// Also, decreasing fire rate should help.

var TTWeap_CamLauncher Weap;
var float LandedLifeSpan;

/** Prevent the native engine shrinkcollision feature */
var CylinderComponent NewCylinder;

/** Server must tell client if projectile stopped VERY early ie. at initial replication */
var bool bStopped;

Replication
{
	if ( bNetInitial )
		bStopped;
}

// Stop sound when simulated projectile stopped too early and didn't call Explode...
simulated function Tick(float dt)
{
	Super.Tick(dt);

	if ( AmbientSoundComponent != None && Physics == PHYS_None )
	{
		AmbientSoundComponent.FadeOut(0.3, 0.0);
		AmbientSoundComponent = None;
	}
}

state WaitingForVelocity
{
	simulated function Tick(float dt)
	{
		local PlayerController LocalPC;

		Super.Tick(dt);

		// If player fires point-blank, the server actually replicates a stopped projectile, thus with zero velocity
		// ==> Super does not hide server projectile and owner sees two projectiles...

		foreach LocalPlayerControllers(class'PlayerController', LocalPC)
		{
			if ( bStopped && class'CRZWeapon'.default.bUseSimulatedProjectiles && Instigator != None && Instigator.Controller == LocalPC )
			{
				SetHidden(true);
				bSuppressExplosionFX = true;

				// fuck that sound.................
				if ( AmbientSoundComponent != None )
				{
					AmbientSoundComponent.FadeOut(0.3, 0.0);
					AmbientSoundComponent = None;
				}

				Destroy();
				break;
			}
		}
	}
}

//Override
simulated singular event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	Super(Actor).HitWall(HitNormal, Wall, WallComp);

	Explode(Location, HitNormal);
	SetBase(Wall);
}

//Override
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	Explode(HitLocation, HitNormal);
	SetBase(Other);
}

//Override
simulated function Explode(Vector HitLocation, Vector HitNormal)
{
	SetPhysics(PHYS_None);
	SetCollision(false);

	LifeSpan = LandedLifeSpan;

	if ( AmbientSoundComponent != None )
	{
		AmbientSoundComponent.FadeOut(0.3, 0.0);
		AmbientSoundComponent = None;
	}

	bStopped = true;
}

simulated event Destroyed()
{
	DisableCam();

	Super.Destroyed();
}

simulated event TornOff()
{
	DisableCam();

	Super.TornOff();
}

simulated function DisableCam()
{
	if ( Weap != None )
	{
		Weap.SetCameraView(false);
		Weap.ActiveCam = None;
	}
}

defaultproperties
{
	LandedLifeSpan=60.0

	bHardAttach=true

	bNetTemporary=false
	//bUpdateSimulatedPosition=true
	//bOnlyDirtyReplication=true
	//NetUpdateFrequency=8
	NetUpdateFrequency=1
	NetPriority=1.0

	//ProjFlightTemplate=ParticleSystem'TJResources.PS_CameraProj'

	ProjFlightTemplate=ParticleSystem'Laser_Beams.Effects.P_Laser_Beam'
	ProjWaterFlightTemplate=None

	ProjectileLightClass=class'Cruzade.CRZScionLaserProjectileLight'
	ExplosionLightClass=class'Cruzade.CRZScionRifleMuzzleFlashLight'

	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	ProjWaterExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_UnderWaterImpact'

	ExplosionDecal=None

	AmbientSound=None
	ExplosionSound=SoundCue'Snd_ScionRifle.SoundCues.A_Weapon_ScionRifle_ImpactCue'
	WaterSplashSound=SoundCue'Snd_ScionRifle.SoundCues.A_Weapon_ScionRifle_Impact_WaterCue'

	DecalWidth=64
	DecalHeight=64
	DurationOfDecal=10
	RotationRate=(Pitch=0,Yaw=0,Roll=0)
	bCanBeDamaged=false

    Speed=1500
    MaxSpeed=1500
    Damage=0
    DamageRadius=0.0
    MomentumTransfer=0
	LifeSpan=8

	// Engine shrinks projectile collision when it comes closer to walls
	// We don't want that - must not use the declared "CollisionCylinder"
	bCollideComplex=false
	Begin Object Class=CylinderComponent Name=NewCylinder
		CollisionHeight=24
		CollisionRadius=24
		CollideActors=true
	End Object
	NewCylinder=NewCylinder
	Components.Add(NewCylinder)
	CollisionComponent=NewCylinder
}
