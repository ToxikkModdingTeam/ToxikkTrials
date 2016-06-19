//================================================================
// Trials.TTObjective
// ----------------
// - End of path
// - Sublevel delimiter for records
// - Contributes to global record
// ----------------
// by Chatouille
//================================================================
class TTObjective extends TTLevel
	placeable
	hidecategories(/*Waypoint,*/Checkpoint,Savepoint,Level);


/** Called by the gamemode */
simulated function ReachedBy(CRZPawn P)
{
	NotifyPlayer(P);
	CheckLevelTime(P);
	ResetRespawnPointFor(P);
	ValidateObjectiveFor(P);
	UpdatePlayerTargets(P);
	//ResetLevelTimerFor(P);
}

// when we finish a Objective, we must set the Spawnpoint back to the last Level (not keep the last Savepoint) !
simulated function ResetRespawnPointFor(CRZPawn P)
{
	local TTPRI PRI;

	PRI = TTPRI(P.PlayerReplicationInfo);
	if ( PRI.CurrentLevel != None )
		PRI.SetSpawnPoint(PRI.CurrentLevel);
	else
		PRI.SetSpawnPoint(TTGRI(WorldInfo.GRI).PointZero);
}

simulated function ValidateObjectiveFor(CRZPawn P)
{
	local TTPRI PRI;

	PRI = TTPRI(P.PlayerReplicationInfo);
	if ( PRI.ValidatedObjectives.Find(Self) == INDEX_NONE )
	{
		PRI.ValidatedObjectives.AddItem(Self);

		if ( Role == ROLE_Authority && PRI.ValidatedObjectives.Length == TTGRI(WorldInfo.GRI).TotalObjectives )
		{
			if ( PlayerController(P.Controller) != None )
				PlayerController(P.Controller).ReceiveLocalizedMessage(class'TTGlobalTimeMessage', PRI.CurrentTimeMillis()-PRI.GlobalStartDate,,, Self);

			PRI.SetGlobalTimerEnabled(false);
			PRI.SetCurrentLevel(None);  // can't be in a level after finished global - until respawn at some TTLevel
			PRI.ClearTimer('SendTimerSync');

			TTGame(WorldInfo.Game).CheckGlobalTime(PRI);
		}
	}
}


defaultproperties
{
	ReachString="Level finished in %t"
	HudText="Objective"
	HudColor=(R=255,G=0,B=255,A=255)
}
