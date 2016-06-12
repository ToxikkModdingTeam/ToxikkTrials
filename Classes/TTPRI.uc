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

/** Client Replicated Server Replicated - Current spawn point. Initially should be PointZero */
var TTSavepoint SpawnPoint;

/** Server Replicated - Stores the last SubObj-type spawnpoint (= should be current level) */
var TTLevel CurrentLevel;

/** Client Replicated - Whether current spawn point is locked */
var bool bLockedSpawnPoint;

/** Both-sided - Current target waypoint(s) */
var array<TTWaypoint> TargetWp;

/** Both-sided (though different) - start date for LEVEL timer */
var int LevelStartDate;

/** Both-sided (though different) - start date for GLOBAL timer */
var int GlobalStartDate;

/** Both-sided - Stores all currently unlocked Savepoints for player, excluding bInitiallyAvailable ones */
var array<TTSavepoint> UnlockedSavepoints;

/** Both-sided - Stores all currently validated Objectives for player */
var array<TTObjective> ValidatedObjectives;


Replication
{
	if ( bNetInitial || bNetDirty )
		bHasCS, bForbiddenObj, SpawnPoint, CurrentLevel;
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

	if ( !Sp.bInitiallyAvailable && UnlockedSavepoints.Find(Sp) == INDEX_NONE )
	{
		`Log("[Trials] WARNING: SetSpawnPoint with unavailable Sp" @ PlayerName @ Sp.Name);
		return;
	}

	SpawnPoint = Sp;

	if ( Sp.IsA('TTLevel') )
		CurrentLevel = TTLevel(Sp);
	else if ( CurrentLevel != None && !Sp.FindInPredecessors(Currentlevel) )
		CurrentLevel = None;    // we switched level but picked a Savepoint (not a LevelStart) - timer is not valid
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

function int CurrentTimeMillis()
{
	// GetSystemTime ???
	return FFloor(WorldInfo.TimeSeconds*1000.f);
}

/** Timer function - send client timersync update every second */
function SendTimerSync()
{
	local int Now;
	//TODO: check timers still make sense - otherwise stop the timer
	Now = CurrentTimeMillis();
	ClientSyncTimers(Now-LevelStartDate, Now-GlobalStartDate);
}

reliable client function ClientSyncTimers(int LevelMillis, int GlobalMillis)
{
	local int Now, EstimatedLevelStart, EstimatedGlobalStart;

	Now = CurrentTimeMillis() - FFloor(ExactPing*1000.f);

	EstimatedLevelStart = Now - LevelMillis;
	if ( Abs(EstimatedLevelStart - LevelStartDate) > 100 )
	{
		`Log("[Trials] Correcting LEVEL timer" @ LevelStartDate @ "=>" @ EstimatedLevelStart @ "(" $ (EstimatedLevelStart - LevelStartDate) $ ")");
		// pick middleground
		LevelStartDate = (LevelStartDate + EstimatedLevelStart) / 2;
	}

	EstimatedGlobalStart = Now - GlobalMillis;
	if ( Abs(EstimatedGlobalStart - GlobalStartDate) > 100 )
	{
		`Log("[Trials] Correcting GLOBAL timer" @ GlobalStartDate @ "=>" @ EstimatedGlobalStart @ "(" $ (EstimatedGlobalStart - GlobalStartDate) $ ")");
		// pick middleground
		GlobalStartDate = (GlobalStartDate + EstimatedGlobalStart) / 2;
	}
}


defaultproperties
{
}
