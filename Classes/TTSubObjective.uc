//================================================================
// Trials.TTSubObjective
// ----------------
// - Forces path
// - Can modify player
// - Respawn point
// - Sublevel delimiter for records
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
	CheckPlayerTime(P);
}

function CheckPlayerTime(CRZPawn P)
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
	ResetSubTimerFor(P);
}

function ResetSubTimerFor(CRZPawn P)
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
