//================================================================
// Trials.TTSubObjective
// ----------------
// - Forces path
// - Can modify player
// - Respawn point
// - Level delimiter for records
// ----------------
// by Chatouille
//================================================================
class TTSubObjective extends TTSavepoint;


/** Called by the gamemode */
simulated function ReachedBy(CRZPawn P)
{
	NotifyPlayer(P);
	UpdatePlayerTargets(P);
	ModifyPlayer(P);
	SetRespawnPointFor(P);
	CheckLevelTime(P);
}

function CheckLevelTime(CRZPawn P)
{
	//TODO
}

/** Called by the gamemode */
simulated function RespawnPlayer(CRZPawn P)
{
	ClearPlayerTargets(P);
	UpdatePlayerTargets(P);
	ModifyPlayer(P);
	SetRespawnPointFor(P);
	ResetLevelTimerFor(P);
}

function ResetLevelTimerFor(CRZPawn P)
{
	//TODO
}


defaultproperties
{
	SpawnTreeLabel="Level"
	UnlockString=""

	ReachString="Level finished"
	HudText="Objective"
	HudColor=(R=128,G=200,B=255,A=255)
}
