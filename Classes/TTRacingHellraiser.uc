//================================================================
// Trials.TTRacingHellraiser
// ----------------
// CRZ Hellraiser doesn't go through GameInfo.ReduceDamage
// So we have to extend it to remove damage
// ----------------
// by Chatouille
//================================================================
class TTRacingHellraiser extends CRZWeap_Hellraiser;

// Both fire and altfire send to driving
simulated function Projectile ProjectileFire()
{
	local CRZRemoteHellraiser Warhead;

	if ( Role < ROLE_Authority )
		return None;

	WarHead = Spawn(TeamWarHeadClass[0],,, GetPhysicalFireStartLoc(), Instigator.GetViewRotation());
	if ( WarHead != None )
	{
		Warhead.TryToDrive(Instigator);
	}

	IncrementFlashCount();

	return None;
}

defaultproperties
{
	TeamWarHeadClass[0]=class'TTRacingRemoteHR'
	ShotCost[0]=0
	ShotCost[1]=0
}
