//================================================================
// Trials.TTLevel
// ----------------
// - Forces path
// - Can modify player
// - Respawn point
// - Level delimiter for records
// ----------------
// by Chatouille
//================================================================
class TTLevel extends TTSavepoint;

/** Shows up in the level-timer hud box */
var(Level) String LevelDisplayName;

/** Idx of level for records - set by GRI, deterministically */
var int LevelIdx;


/** Called by the gamemode */
simulated function ReachedBy(CRZPawn P)
{
	NotifyPlayer(P);
	CheckLevelTime(P);
	SetRespawnPointFor(P);
	UpdatePlayerTargets(P);
	ModifyPlayer(P);
	ResetLevelTimerFor(P);
}

simulated function NotifyPlayer(CRZPawn P)
{
	local TTPRI PRI;

	PRI = TTPRI(P.PlayerReplicationInfo);
	if ( PRI.CurrentLevel == None ) // If we are not in a valid level, just send the Savepoint message
		Super.NotifyPlayer(P);
	else if ( Role == ROLE_Authority && PlayerController(P.Controller) != None )
		PlayerController(P.Controller).ReceiveLocalizedMessage(class'TTLevelTimeMessage', PRI.CurrentTimeMillis()-PRI.LevelStartDate,,, Self);
}

function CheckLevelTime(CRZPawn P)
{
	local TTPRI PRI;

	PRI = TTPRI(P.PlayerReplicationInfo);
	if ( PRI.CurrentLevel == None ) // Ignore leveltime if we are not in a valid level
		return;

	TTGame(WorldInfo.Game).CheckLevelTime(PRI);
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

simulated function ResetLevelTimerFor(CRZPawn P)
{
	local TTPRI PRI;

	PRI = TTPRI(P.PlayerReplicationInfo);
	PRI.LevelStartDate = PRI.CurrentTimeMillis();
	if ( Role == ROLE_Authority && WorldInfo.NetMode != NM_Standalone )
		PRI.SetTimer(1.0, true, 'SendTimerSync');
}


defaultproperties
{
	LevelDisplayName="- Level -"

	SpawnTreeLabel="LVL"

	ReachString="Level finished in %t"
	HudText="Level"
	HudColor=(R=128,G=200,B=255,A=255)
}
