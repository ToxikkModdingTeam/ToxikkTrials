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
class TTLevel extends TTSavepoint
	placeable;

/** Shows up in the level-timer hud box */
var(Level) String LevelDisplayName;

/** Idx of level for records - set by GRI, deterministically */
var int LevelIdx;


/** Called by the gamemode */
simulated function ReachedBy(TTPRI PRI)
{
	NotifyPlayer(PRI);
	CheckLevelTime(PRI);
	SetRespawnPointFor(PRI);
	UpdatePlayerTargets(PRI);
	ModifyPlayer(PRI);
	ResetLevelTimerFor(PRI);
}

simulated function NotifyPlayer(TTPRI PRI)
{
	if ( PRI.CurrentLevel == None ) // If we are not in a valid level, just send the Savepoint message
		Super.NotifyPlayer(PRI);
	else if ( Role == ROLE_Authority && PlayerController(PRI.Owner) != None )
		PlayerController(PRI.Owner).ReceiveLocalizedMessage(class'TTLevelTimeMessage', PRI.CurrentTimeMillis()-PRI.LevelStartDate,,, Self);
}

function CheckLevelTime(TTPRI PRI)
{
	if ( PRI.CurrentLevel != None )
	{
		TTGame(WorldInfo.Game).CheckLevelTime(PRI);
		PRI.SetCurrentLevel(None);
	}
}

/** Called by the gamemode */
simulated function RespawnPlayer(TTPRI PRI)
{
	ClearPlayerTargets(PRI);
	UpdatePlayerTargets(PRI);
	ModifyPlayer(PRI);
	SetRespawnPointFor(PRI);
	ResetLevelTimerFor(PRI);
}

simulated function ResetLevelTimerFor(TTPRI PRI)
{
	PRI.LevelReachedSavepoints.Length = 0;
	PRI.LevelStartDate = PRI.CurrentTimeMillis();
	if ( Role == ROLE_Authority && WorldInfo.NetMode != NM_Standalone )
		PRI.SetTimer(1.0, true, 'SendTimerSync');
}


defaultproperties
{
	LevelDisplayName="- Level -"

	SpawnTreeLabel="LVL"

	ReachString="Level finished in %t"
	HudText="LVL"
	HudColor=(R=128,G=200,B=255,A=255)
}
