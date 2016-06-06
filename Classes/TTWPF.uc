//================================================================
// Trials.TTWPF
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTWPF extends CRZWeaponPickupFactory
	notplaceable;

var RepNotify class<CRZWeapon> MyWeaponPickupClass;
var bool bClientReady;

Replication
{
	if ( bNetInitial )
		MyWeaponPickupClass;
}

simulated event PreBeginPlay()
{
	if ( Role == ROLE_Authority && CRZWeaponPickupFactory(Owner) != None )
	{
		MyWeaponPickupClass = CRZWeaponPickupFactory(Owner).WeaponPickupClass;
		WeaponPickupClass = MyWeaponPickupClass;
		if ( WorldInfo.NetMode == NM_Standalone )
			ReplicatedEvent('MyWeaponPickupClass');
	}

	Super.PreBeginPlay();
}

simulated event InitializePickup()
{
	if ( Role == ROLE_Authority || bClientReady )
		Super.InitializePickup();
}

simulated event ReplicatedEvent(Name VarName)
{
	local PlayerController PC;

	if ( VarName == 'MyWeaponPickupClass' )
	{
		WeaponPickupClass = MyWeaponPickupClass;
		bClientReady = true;

		GotoState('Pickup');
		InitializePickup();
		SetInitialState();

		foreach WorldInfo.LocalPlayerControllers(class'PlayerController', PC)
			break;
		if ( PC != None && CRZHud(PC.myHUD) != None )
		{
			if ( CRZWeaponPickupFactory(Owner) != None )
				CRZHud(PC.myHUD).RemovePostRenderedActor(Owner);
			CRZHud(PC.myHUD).AddPostRenderedActor(Self);
		}
	}

	Super.ReplicatedEvent(VarName);
}

//Override
simulated event SetInitialState()
{
	if ( Role == ROLE_Authority || bClientReady )
		Super.SetInitialState();
}

//Override
simulated function UpdateSpawnEffect(float FadeFactor)
{
	if ( MIC_Visibility != None )
		Super.UpdateSpawnEffect(FadeFactor);  
}

//Override
function PickedUpBy(Pawn P)
{
	Super(UTPickupFactory).PickedUpBy(P);
}

//Ovveride
function SetRespawn() {}

//Override
function SpawnCopyFor(Pawn Recipient)
{
	local UTWeapon Weap;

	if ( UTInventoryManager(Recipient.InvManager) != None )
	{
		Weap = UTWeapon( UTInventoryManager(Recipient.InvManager).HasInventoryOfClass(WeaponPickupClass) );
		if ( Weap != None )
		{
			Weap.AmmoCount = Weap.MaxAmmoCount;
			Weap.AnnouncePickup(Recipient);
			return;
		}
	}
	Weap = Spawn(WeaponPickupClass);
	if ( Weap != None )
	{
		Weap.AmmoCount = Weap.MaxAmmoCount;
		Weap.GiveTo(Recipient);
		Weap.AnnouncePickup(Recipient);
	}
	Recipient.MakeNoise(0.20);
}

//Override
simulated function float GetRespawnTime()
{
	return 0.0;
}

auto state Pickup
{
	//Override
	function bool AllowPickup(UTBot Bot)
	{
		return true;
	}
	//Override
	simulated function NotifyLocalPlayerDead(PlayerController PC) {}
	//Override
	simulated event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
    {
		local Pawn Recipient;

		Recipient = Pawn(Other);
		if ( Recipient != None && ValidTouch(Recipient) )
		{
			if ( Role == ROLE_Authority )
				GiveTo(Recipient);
			else
				class'CRZItemPickupFactory'.static.PlayPickupSoundForSimulated(Recipient, InventoryType.default.PickupSound, LastPickupTime);
		}
	}
}

defaultproperties
{
	bVerifiedWeaponStay=true
}
