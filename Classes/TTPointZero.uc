//================================================================
// Trials.TTPointZero
// ----------------
// - Root of all paths
// - Can modify player
// - Respawn point
// - Sublevel delimited for records (only start)
// ----------------
// by Chatouille
//================================================================
class TTPointZero extends TTSubObjective;

simulated function Init(TTGRI GRI);

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal);

/** Called by the gamemode */
simulated function RespawnPlayer(CRZPawn P)
{
	ClearPlayerTargets(P);
	UpdatePlayerTargets(P);
	ModifyPlayer(P);
	SetRespawnPointFor(P);
	ResetSubTimerFor(P);
	ResetGlobalTimerFor(P);
}

function ResetSubTimerFor(CRZPawn P)
{
	//TODO
}

function ResetGlobalTimerFor(CRZPawn P)
{
	//TODO
}


defaultproperties
{
	SpawnTreeLabel="START"
	bAvailable=true
	UnlockString=""

	bModifyHealth=false
	ReachString=""
	HudText=""
	MaxHudDistance=0
}
