//================================================================
// Trials.TTMainObjective
// ----------------
// - End of path
// - Sublevel delimiter for records
// - Contributes to global record
// ----------------
// by Chatouille
//================================================================
class TTMainObjective extends TTSubObjective
	hidecategories(Waypoint,Checkpoint,Savepoint);


/** Called by the gamemode */
simulated function ReachedBy(CRZPawn P)
{
	NotifyPlayer(P);
	UpdatePlayerTargets(P);
	SetRespawnPointFor(P);
	CheckPlayerTime(P);
	CheckPlayerFinishedGlobal(P);
}

// when we finish a MainObjective, we must set the Spawnpoint back to the last SubObjective (not keep the last Savepoint) !
simulated function SetRespawnPointFor(CRZPawn P)
{
	TTPRI(P.PlayerReplicationInfo).SetSpawnPoint(TTPRI(P.PlayerReplicationInfo).LastSubObjSpawnPoint);
}

function CheckPlayerFinishedGlobal(CRZPawn P)
{
	//TODO:
	// check MainObj isn't already validated for player
	// validate this MainObjective for the player
	// if player has validated all MainObjs => check global timer for record,
	//  remove/hide the globaltimer now useless until respawn at PointZero
}


defaultproperties
{
	ReachString="Main objective done"
	HudText="Objective"
	HudColor=(R=255,G=0,B=255,A=255)
}
