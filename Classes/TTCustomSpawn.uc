//================================================================
// Trials.TTCustomSpawn
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTCustomSpawn extends NavigationPoint;

var int SavedHealth;
var int SavedHealthMax;
var int SavedVestArmor;
var array< class<Inventory> > SavedInv;
var array<int> SavedAmmo;

/** whether it has been used at least once */
var bool bActive;

function Init(CRZPawn P)
{
	local Inventory Inv;
	local int i;

	SetLocation(P.Location);
	// Attach to base, in case we placed it on a mover
	SetBase(P.Base);
	SetRotation(P.Rotation);
	SavedHealth = P.Health;
	SavedHealthMax = P.HealthMax;
	SavedVestArmor = P.VestArmor;
	SavedInv.length = 0;
	SavedAmmo.length = 0;
	foreach P.InvManager.InventoryActors(class'Inventory', Inv)
	{
		i = SavedInv.length;
		SavedInv.length = i+1;
		SavedInv[i] = Inv.class;

		SavedAmmo.length = i+1;
		if ( Inv.IsA('UTWeapon') )
			SavedAmmo[i] = UTWeapon(Inv).GetAmmoCount();
	}
}

function RespawnPlayer(CRZPawn P)
{
	local Inventory Inv;
	local int i;

	// loc/rot should now be handled by base code as we are returned by FindPlayerStart()
	//P.SetLocation(Location);
	//P.SetRotation(Rotation);
	//P.Controller.SetRotation(Rotation);
	//P.SetPhysics(PHYS_Falling);

	P.HealthMax = SavedHealthMax;
	P.Health = SavedHealth;
	P.VestArmor = SavedVestArmor;
	foreach P.InvManager.InventoryActors(class'Inventory', Inv)
	{
		P.InvManager.RemoveFromInventory(Inv);
		Inv.Destroy();
	}
	for ( i=0; i<SavedInv.length; i++ )
	{
		Inv = P.Spawn(SavedInv[i], P);
		Inv.GiveTo(P);
		if ( Inv.IsA('UTWeapon') )
		{
			if ( UTWeapon(Inv).MaxAmmoCount < SavedAmmo[i] )
				UTWeapon(Inv).MaxAmmoCount = SavedAmmo[i];
			UTWeapon(Inv).AmmoCount = SavedAmmo[i];
		}
	}

	if ( !bActive )
	{
		bActive = true;
		TTGame(WorldInfo.Game).CheckPlayerObjClearance(TTPRI(P.PlayerReplicationInfo));
	}
}

defaultproperties
{
	bActive=false

	//not sure if it is a good idea to extend NavigationPoint...
	Components=()
	CollisionComponent=None
	CylinderComponent=None
	bCollideWhenPlacing=false
	bStatic=false
	bNoDelete=false
	bHidden=true
}
