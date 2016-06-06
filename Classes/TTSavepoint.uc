//================================================================
// Trials.TTSavepoint
// ----------------
// - Forces path
// - Can modify player
// - Respawn point
// ----------------
// by Chatouille
//================================================================
class TTSavepoint extends TTCheckpoint;

var(Savepoint) array<PlayerStart> Respawns;
var(Savepoint) String SpawnTreeLabel;   //TBD: should the SpawnTree have Savepoints (=midlevel) or only SubObjectives (=levelstart) ???

/** Client - Whether the spawn point has been unlocked by player - map can unlock a point globally */
var(Savepoint) bool bAvailable;
var(Savepoint) String UnlockString;


/** Called by the gamemode */
simulated function ReachedBy(CRZPawn P)
{
	NotifyPlayer(P);
	UpdatePlayerTargets(P);
	ModifyPlayer(P);
	SetRespawnPointFor(P);
}

simulated function NotifyPlayer(CRZPawn P)
{
	if ( GetALocalPlayerController() == P.Controller && CRZHud(PlayerController(P.Controller).myHUD) != None )
	{
		if ( !bAvailable && UnlockString != "" )
			CRZHud(PlayerController(P.Controller).myHUD).LocalizedCRZMessage(class'TTWaypointMessage', P.PlayerReplicationInfo, None, UnlockString, 0, Self);

		CRZHud(PlayerController(P.Controller).myHUD).LocalizedCRZMessage(class'TTWaypointMessage', P.PlayerReplicationInfo, None, ReachString, 0, Self);
	}
}

simulated function SetRespawnPointFor(CRZPawn P)
{
	TTPRI(P.PlayerReplicationInfo).SetSpawnPoint(Self);

	if ( GetALocalPlayerController() == P.Controller )
	{
		bAvailable = true;
		if ( TTHud(PlayerController(P.Controller).myHUD) != None )
			TTHud(PlayerController(P.Controller).myHUD).SpawnTree.UpdateButtons();
	}
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
	SpawnTreeLabel="Sp"
	bAvailable=false
	UnlockString="Respawn point unlocked"

	bModifyHealth=true
	ForcedHealth=100
	ForcedArmor=0

	HudText="Savepoint"
	HudColor=(R=64,G=200,B=64,A=255)
}
