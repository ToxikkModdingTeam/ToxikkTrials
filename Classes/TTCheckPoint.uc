//================================================================
// Trials.TTCheckpoint
// ----------------
// - Forces path
// - Can modify player
// ----------------
// by Chatouille
//================================================================
class TTCheckpoint extends TTWaypoint
	placeable;

var(Checkpoint) bool bModifyHealth;
var(Checkpoint) int ForcedHealth;
var(Checkpoint) int ForcedArmor;

struct sForcedWeapon
{
	var() class<UTWeapon> WeaponClass;
	var() int AmmoCount;
};
var(Checkpoint) bool bModifyWeapons;
var(Checkpoint) array<sForcedWeapon> ForcedWeapons;

struct sForcedInv
{
	var() class<UTInventory> InvClass;
	var() int JetpackJumps;
	var() int PowerupDuration;
};
var(Checkpoint) bool bModifyOtherInv;
var(Checkpoint) array<sForcedInv> ForcedInventory;


/** Called by the gamemode */
simulated function ReachedBy(TTPRI PRI)
{
	NotifyPlayer(PRI);
	UpdatePlayerTargets(PRI);
	ModifyPlayer(PRI);
}

function ModifyPlayer(TTPRI PRI)
{
	local CRZPawn P;
	local UTWeapon W;
	local UTInventory Inv;
	local int i;

	P = CRZPawn(Controller(PRI.Owner).Pawn);
	if ( P == None )
		return;

	if ( bModifyHealth )
	{
		if ( ForcedHealth > P.HealthMax )
			P.HealthMax = ForcedHealth;
		P.Health = ForcedHealth;
		P.VestArmor = ForcedArmor;
	}

	if ( bModifyWeapons )
	{
		foreach P.InvManager.InventoryActors(class'UTWeapon', W)
		{
			if ( ! TTGame(WorldInfo.Game).IsDefaultWeapon(W.Class) )
				P.InvManager.RemoveFromInventory(W);
		}

		for ( i=0; i<ForcedWeapons.Length; i++ )
		{
			W = Spawn(ForcedWeapons[i].WeaponClass, P);
			if ( W != None )
			{
				if ( ForcedWeapons[i].AmmoCount > 0 )
				{
					if ( W.MaxAmmoCount < ForcedWeapons[i].AmmoCount )
						W.MaxAmmoCount = ForcedWeapons[i].AmmoCount;
					W.AmmoCount = ForcedWeapons[i].AmmoCount;
				}

				W.GiveTo(P);
			}
		}
	}

	if ( bModifyOtherInv )
	{
		foreach P.InvManager.InventoryActors(class'UTInventory', Inv)
		{
			if ( !Inv.IsA('UTWeapon') )
				P.InvManager.RemoveFromInventory(Inv);
		}

		for ( i=0; i<ForcedInventory.Length; i++ )
		{
			Inv = Spawn(ForcedInventory[i].InvClass, P);
			if ( Inv != None )
			{
				if ( ForcedInventory[i].PowerupDuration > 0 && Inv.IsA('UTTimedPowerup') )
					UTTimedPowerup(Inv).TimeRemaining = ForcedInventory[i].PowerupDuration;
				else if ( ForcedInventory[i].JetpackJumps > 0 && Inv.IsA('CRZJetPack') )
					CRZJetPack(Inv).Charges = ForcedInventory[i].JetpackJumps;

				Inv.GiveTo(P);
			}
		}
	}
}

defaultproperties
{
	HudText="Checkpoint"
	HudColor=(R=200,G=220,B=255,A=255)
}
