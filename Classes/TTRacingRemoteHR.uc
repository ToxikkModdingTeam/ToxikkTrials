//================================================================
// Trials.TTRacingRemoteHR
// ----------------
// Override to remove damage
// ----------------
// by Chatouille
//================================================================
class TTRacingRemoteHR extends CRZRemoteHellraiser;

simulated state Dying
{
Begin:
	Instigator = self;
	if ( Role == ROLE_Authority && !WorldInfo.Game.IsInState('MatchOver') )
	{
		DriverLeave(true);
	}
	PlaySound(HellraiserProjClass.default.ExplosionSound, true);
	//HellraiserProjClass.static.HellraiserHurtRadius(0.125, self, InstigatorController);
	Sleep(0.5);
	//HellraiserProjClass.static.HellraiserHurtRadius(0.300, self, InstigatorController);
	Sleep(0.2);
	//HellraiserProjClass.static.HellraiserHurtRadius(0.475, self, InstigatorController);
	Sleep(0.2);
	if (Role == ROLE_Authority && !WorldInfo.Game.IsInState('MatchOver'))
	{
		//HellraiserProjClass.static.DoKnockdown(Location, WorldInfo, InstigatorController);
	}
	//HellraiserProjClass.static.HellraiserHurtRadius(0.650, self, InstigatorController);
	Sleep(0.2);
	//HellraiserProjClass.static.HellraiserHurtRadius(0.825, self, InstigatorController);
	Sleep(0.2);
	//HellraiserProjClass.static.HellraiserHurtRadius(1.0, self, InstigatorController);
	if ( Role == ROLE_Authority && !WorldInfo.Game.IsInState('MatchOver') )
	{
		Destroy();
	}
}

defaultproperties
{
}