//================================================================
// Trials.TTHealthBase
// ----------------
// Custom HP/Shield setter "factory"
// ----------------
// by Chatouille
//================================================================
class TTHealthBase extends CRZHealthPickupFactory
	placeable
	ClassGroup(Trials);

var(HealthBase) int SetHealthAmount;
var(HealthBase) bool bReduceHealthIfOver;

var(HealthBase) int SetShieldAmount;
var(HealthBase) bool bReduceShieldIfOver;

var array<UTPawn> Touchers;
var ParticleSystemComponent ActiveEffect;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	//ActiveEffect.DeactivateSystem();
	ActiveEffect.SetStopSpawning(0, true);
}

//Override
simulated function SpawnCopyFor(Pawn Recipient)
{
	if ( Role == ROLE_Authority && UTPawn(Recipient) != None )
	{
		if ( Recipient.Health < SetHealthAmount || bReduceHealthIfOver )
			Recipient.Health = SetHealthAmount;

		if ( UTPawn(Recipient).VestArmor < SetShieldAmount || bReduceShieldIfOver )
			UTPawn(Recipient).VestArmor = SetShieldAmount;
	}

	// paste from CRZItemPickupFactory - need to override the localized message
	if ( Role < ROLE_Authority )
		class'CRZItemPickupFactory'.static.PlayPickupSoundForSimulated(Recipient, PickupSound, LastPickupTime);
	else
	{
		Recipient.PlaySound(PickupSound, true);
		Recipient.MakeNoise(0.20);
	}
	if ( WorldInfo.NetMode == NM_StandAlone || WorldInfo.NetMode == NM_Client )
		CRZHud(PlayerController(Recipient.Controller).myHUD).LocalizedCRZMessage(class'TTHealthBaseMessage', None, None, "HP+"$SetHealthAmount$"  ARMOR+"$SetShieldAmount, 0, None);
}

auto state Pickup
{
	//Override
    simulated event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
    {
		local UTPawn P;

		P = UTPawn(Other);
		if ( P != None && P.Health > 0 )
		{
			SpawnCopyFor(P);
			Touchers.AddItem(P);
			if ( Touchers.length == 1 )
			{
				//ActiveEffect.ActivateSystem();
				ActiveEffect.SetStopSpawning(0, false);
			}
		}
	}

	simulated event UnTouch(Actor Other)
	{
		if ( Other.IsA('UTPawn') )
		{
			Touchers.RemoveItem(Other);
			if ( Touchers.length == 0 )
			{
				//ActiveEffect.DeactivateSystem();
				ActiveEffect.SetStopSpawning(0, true);
			}
		}
	}
}

defaultproperties
{
	SetHealthAmount=200
	bReduceHealthIfOver=false
	SetShieldAmount=150
	bReduceShieldIfOver=false

    bRotatingPickup=true
	YawRotationRate=32768.0
	MessageClass=class'TTHealthBaseMessage'

	LightEnvironment=None
	Components(2)=None

	Begin Object name=BaseMeshComp
		StaticMesh=StaticMesh'Jumppad01.SM_jumppad01'
		CastShadow=false
		bForceDirectLightMap=true
		bCastDynamicShadow=false
		CollideActors=false
		Translation=(X=0,Y=0,Z=-45)
		Scale=0.5
	End Object
	Components(3)=BaseMeshComp

	Begin Object name=PickupEmitterComp class=UTParticleSystemComponent
		Template=ParticleSystem'TTResources.PS_HPPickup'
		Translation=(X=0,Y=0,Z=-4)
	End Object
	PickupMesh=PickupEmitterComp
	Components(4)=PickupEmitterComp

	Begin Object name=ActiveEffectComp class=UTParticleSystemComponent
		Template=ParticleSystem'TTResources.PS_HPPickupActive'
		Translation=(X=0,Y=0,Z=-4)
	End Object
	ActiveEffect=ActiveEffectComp
	Components(5)=ActiveEffectComp
}
