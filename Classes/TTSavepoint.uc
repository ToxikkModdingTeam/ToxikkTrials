//================================================================
// Trials.TTSavepoint
// ----------------
// - Forces path
// - Can modify player
// - Respawn point
// ----------------
// by Chatouille
//================================================================
class TTSavepoint extends TTCheckpoint
	placeable;


var(Savepoint) array<PlayerStart> Respawns;
var(Savepoint) String SpawnTreeLabel;

/** Whether this point is already unlocked initially */
var(Savepoint) bool bInitiallyAvailable;
var(Savepoint) String UnlockString;


simulated function ReachedBy(TTPRI PRI)
{
	SetRespawnPointFor(PRI);
	NotifyPlayer(PRI);
	UpdatePlayerTargets(PRI);
	ModifyPlayer(PRI);
}

simulated function SetRespawnPointFor(TTPRI PRI)
{
	// unlock spawnpoint if necessary
	if ( !bInitiallyAvailable && PRI.UnlockedSavepoints.Find(Self) == INDEX_NONE )
	{
		PRI.UnlockedSavepoints.AddItem(Self);
		if ( UnlockString != "" && PRI.IsLocalPlayerPRI() && TTHud(PlayerController(PRI.Owner).myHUD) != None )
			CRZHud(PlayerController(PRI.Owner).myHUD).LocalizedCRZMessage(class'TTWaypointMessage', PRI, None, UnlockString, 0, Self);
	}
	if ( PRI.LevelReachedSavepoints.Find(Self) == INDEX_NONE )  // new security stuff for level
		PRI.LevelReachedSavepoints.AddItem(Self);
	if ( PRI.GlobalReachedSavepoints.Find(Self) == INDEX_NONE ) // new security stuff for global
		PRI.GlobalReachedSavepoints.AddItem(Self);

	PRI.UpdateCurrentLevel(Self);

	if ( !PRI.bLockedSpawnPoint )	// don't care about serverside, client sends SpawnPoint every before spawn
		PRI.SpawnPoint = Self;
}

/** Called by the gamemode */
function NavigationPoint FindStartSpot(Controller Player)
{
	if ( Respawns.Length == 0 )
	{
		`Warn("[Trials] WARNING - No respawn point for Savepoint " $ Name);
		return None;
	}
	return Respawns[Rand(Respawns.Length)];
}

/** Called by the gamemode */
simulated function RespawnPlayer(TTPRI PRI)
{
	ClearPlayerTargets(PRI);
	UpdatePlayerTargets(PRI);
	ModifyPlayer(PRI);
	SetRespawnPointFor(PRI);
}

simulated function ClearPlayerTargets(TTPRI PRI)
{
	PRI.TargetWp.Length = 0;
}


defaultproperties
{
	SpawnTreeLabel="S"
	bInitiallyAvailable=false
	UnlockString="Respawn point unlocked"

	bModifyHealth=true
	ForcedHealth=100
	ForcedArmor=0

	HudText="SAVE"
	HudColor=(R=64,G=200,B=64,A=255)
}
