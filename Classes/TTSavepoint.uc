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
var(Savepoint) String SpawnTreeLabel;   //TBD: should the SpawnTree have Savepoints (=midlevel) or only SubObjectives (=levelstart) ???

/** Whether this point is already unlocked initially */
var(Savepoint) bool bInitiallyAvailable;
var(Savepoint) String UnlockString;


/** Called by the gamemode */
simulated function ReachedBy(CRZPawn P)
{
	SetRespawnPointFor(P);
	NotifyPlayer(P);
	UpdatePlayerTargets(P);
	ModifyPlayer(P);
}

simulated function SetRespawnPointFor(CRZPawn P)
{
	local TTPRI PRI;

	PRI = TTPRI(P.PlayerReplicationInfo);

	// unlock spawnpoint if necessary
	if ( !bInitiallyAvailable && PRI.UnlockedSavepoints.Find(Self) == INDEX_NONE )
	{
		PRI.UnlockedSavepoints.AddItem(Self);

		if ( GetALocalPlayerController() == P.Controller && TTHud(PlayerController(P.Controller).myHUD) != None )
		{
			if ( UnlockString != "" )
				CRZHud(PlayerController(P.Controller).myHUD).LocalizedCRZMessage(class'TTWaypointMessage', P.PlayerReplicationInfo, None, UnlockString, 0, Self);

			TTHud(PlayerController(P.Controller).myHUD).SpawnTree.UpdateButtons();
		}
	}
	if ( PRI.LevelReachedSavepoints.Find(Self) == INDEX_NONE )
		PRI.LevelReachedSavepoints.AddItem(Self);

	PRI.SetSpawnPoint(Self);
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
simulated function RespawnPlayer(CRZPawn P)
{
	ClearPlayerTargets(P);
	UpdatePlayerTargets(P);
	ModifyPlayer(P);
	SetRespawnPointFor(P);
}

simulated function ClearPlayerTargets(CRZPawn P)
{
	TTPRI(P.PlayerReplicationInfo).TargetWp.Length = 0;
}


defaultproperties
{
	SpawnTreeLabel="S"
	bInitiallyAvailable=false
	UnlockString="Respawn point unlocked"

	bModifyHealth=true
	ForcedHealth=100
	ForcedArmor=0

	HudText="Savepoint"
	HudColor=(R=64,G=200,B=64,A=255)
}
