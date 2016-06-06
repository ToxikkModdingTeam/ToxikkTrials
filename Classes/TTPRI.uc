//================================================================
// Trials.TTPRI
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTPRI extends CRZPlayerReplicationInfo;


/** Server - holds custom respawn data */
var TTCustomSpawn MyCS;

/** Replicated for client - Whether we have an active CS (don't show SpawnTree) */
var bool bHasCS;

/** Server Replicated - tells whether we are not allowed to validate objective */
var bool bForbiddenObj;

/** Server - whether the player should be killed before restoring obj clearance */
var bool bMustDieToClean;

/** Server Replicated - Current spawn point. Initially should be PointZero */
var TTSavepoint SpawnPoint;

/** Server - Stores the last SubObj-type spawnpoint */
var TTSubObjective LastSubObjSpawnPoint;

/** Client Replicated - Whether current spawn point is locked */
var bool bLockedSpawnPoint;

/** Both-sided - Current target waypoint(s) */
var array<TTWaypoint> TargetWp;


Replication
{
	if ( bNetInitial || bNetDirty )
		bHasCS, bForbiddenObj, SpawnPoint;
}


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( Role == ROLE_Authority )
	{
		SetSpawnPoint(TTGRI(WorldInfo.GRI).PointZero);
	}
}

function SetSpawnPoint(TTSavepoint Sp)
{
	if ( bLockedSpawnPoint || Sp == None )
		return;

	SpawnPoint = Sp;
	if ( Sp.IsA('TTSubObjective') )
		LastSubObjSpawnPoint = TTSubObjective(Sp);
}

reliable server function ServerPickSpawnPoint(TTSavepoint Sp, bool bLock=false)
{
	bLockedSpawnPoint = false;
	SetSpawnPoint(Sp);
	bLockedSpawnPoint = bLock;
	WorldInfo.Game.RestartPlayer(Controller(Owner));
}

reliable client function ClientReachedWaypoint(CRZPawn P, TTWaypoint Wp)
{
	if ( WorldInfo.NetMode == NM_Client )
		Wp.ReachedBy(P);
}

reliable client function ClientSpawnedAtPoint(CRZPawn P, TTSavepoint Sp)
{
	if ( WorldInfo.NetMode == NM_Client )
		Sp.RespawnPlayer(P);
}

reliable server function ServerPlaceCustomSpawn()
{
	local CRZPawn P;

	/*
	if ( ! TRGame(WorldInfo.Game).bAllowCustomSpawns )
	{
		PlayerController(Owner).ReceiveLocalizedMessage(class'TRCustomSpawnMessage', 3);
		return;
	}
	*/

	if ( UTPlayerController(Owner) != None )
	{
		P = CRZPawn(Controller(Owner).Pawn);
		if ( P != None && P.Health > 0 )
		{
			if ( P.Physics == PHYS_Walking && VSize(P.Velocity) == 0 )
			{
				if ( MyCS == None )
					MyCS = Spawn(class'TTCustomSpawn', Self);

				MyCS.Init(P);
				PlayerController(Owner).ReceiveLocalizedMessage(class'TTCustomSpawnMessage', 0);
				bHasCS = true;
			}
			else
			{
				PlayerController(Owner).ReceiveLocalizedMessage(class'TTCustomSpawnMessage', 1);
			}
		}
	}
}

reliable server function ServerRemoveCustomSpawn()
{
	if ( MyCS != None )
	{
		if ( MyCS.bActive )
			bMustDieToClean = true;

		MyCS.Destroy();
		MyCS = None;
		PlayerController(Owner).ReceiveLocalizedMessage(class'TTCustomSpawnMessage', 2);
	}
	bHasCS = false;
	// it's up to the GameInfo/rules to decide if we are cleared after we just removed this "cheat"
	//ie. support multiple cheats (even though we have only this for now)
	TTGame(WorldInfo.Game).CheckPlayerObjClearance(Self);
}


defaultproperties
{
}
