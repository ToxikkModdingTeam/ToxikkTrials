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

/** Client Replicated - Current spawn point. Initially should be PointZero */
var TTSavepoint SpawnPoint;

/** Server Replicated - Stores the current active level */
var RepNotify TTLevel CurrentLevel;

/** Client - Whether current spawn point is locked */
var bool bLockedSpawnPoint;

/** Both-sided - Current target waypoint(s) */
var array<TTWaypoint> TargetWp;

/** Both-sided (but different!) - start date for LEVEL timer */
var int LevelStartDate;

/** Both-sided (but different!) - start date for GLOBAL timer */
var int GlobalStartDate;

/** Both-sided - Stores all currently unlocked Savepoints for player, excluding bInitiallyAvailable ones */
var array<TTSavepoint> UnlockedSavepoints;

/** Both-sided - Stores all currently validated Objectives for player */
var array<TTObjective> ValidatedObjectives;

/** Server - index of player in Playerlist */
var int Idx;

/** Server Replicated - Global position of player (leaderboard) */
var int LeaderboardPos;
/** Server Replicated - Total points of player */
var int TotalPoints;
/** Server Replicated - Map points of player */
var int MapPoints;

/** Server - To detect fast-forwarding in a level (via Savepoints) */
var array<TTSavepoint> LevelReachedSavepoints;

/** Server Replicated - Whether GlobalTimer should be disabled (finished and waiting for RESET) */
var bool bStopGlobal;

/** Server - To detect fast-forwarding in global (because we don't re-lock them upon reset anymore) */
var array<TTSavepoint> GlobalReachedSavepoints;


Replication
{
	if ( bNetInitial && bNetDirty )
		bHasCS, bForbiddenObj, LeaderboardPos, TotalPoints, MapPoints;
	if ( bNetOwner && (bNetInitial || bNetDirty) )
		CurrentLevel, bStopGlobal;
}


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( Role == ROLE_Authority )
		WaitForPlayerData();
}

function WaitForPlayerData()
{
	local UniqueNetId ZeroId;
	local TTGame Game;

	if ( PlayerName != "" && UniqueId != ZeroId )
	{
		Game = TTGame(WorldInfo.Game);
		Game.Playerlist.SyncPlayer(Self);
		MapPoints = Game.MapData.MapPointsForPlayer(Idx);
	}
	else
		SetTimer(0.1, false, GetFuncName());
}

//TODO: See if it makes sense to make this SIMULATED
function UpdateCurrentLevel(TTSavepoint Sp)
{
	if ( Sp.IsA('TTLevel') )
		SetCurrentLevel(TTLevel(Sp));
	else if ( CurrentLevel != None && LevelReachedSavepoints.Find(Sp) == INDEX_NONE )
	{
		// Either we switched to a Savepoint in the middle of another level
		// Or we tried to fast-forward the current level by dying and respawning at a further Savepoint already unlocked (but not re-reached since level-restart)
		// Timer is not valid
		SetCurrentLevel(None);
	}

	// Same shit for global now, because we don't re-lock points upon RESET anymore!
	if ( !bStopGlobal && !Sp.bInitiallyAvailable && GlobalReachedSavepoints.Find(Sp) == INDEX_NONE )
		SetGlobalTimerEnabled(false);
}

function SetGlobalTimerEnabled(bool bEnabled)
{
	bStopGlobal = !bEnabled;
	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		ReplicatedEvent('bStopGlobal');
}

function SetCurrentLevel(TTLevel Level)
{
	CurrentLevel = Level;
	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		ReplicatedEvent('CurrentLevel');
}

reliable server function ServerPickSpawnPoint(TTSavepoint Sp)
{
	if ( !Sp.bInitiallyAvailable && UnlockedSavepoints.Find(Sp) == INDEX_NONE )
	{
		`Log("[Trials] WARNING: SetSpawnPoint with unavailable Sp" @ PlayerName @ Sp.Name);
		return;
	}
	SpawnPoint = Sp;
	UpdateCurrentLevel(Sp);
	WorldInfo.Game.RestartPlayer(Controller(Owner));
}

reliable client function ClientReachedWaypoint(TTWaypoint Wp)
{
	if ( WorldInfo.NetMode == NM_Client )
		Wp.ReachedBy(Self);
}

reliable client function ClientSpawnedAtPoint(TTSavepoint Sp)
{
	if ( WorldInfo.NetMode == NM_Client )
		Sp.RespawnPlayer(Self);
}

reliable server function ServerPlaceCustomSpawn()
{
	local CRZPawn P;

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

simulated function int CurrentTimeMillis()
{
	// GetSystemTime ???
	return FFloor(WorldInfo.TimeSeconds*1000.f);
}

/** Timer function - send client timersync update every second */
function SendTimerSync()
{
	local int Now;
	Now = CurrentTimeMillis();
	ClientSyncTimers(Now-LevelStartDate, Now-GlobalStartDate);
}

// unreliable gives better results
// reliable will resend lost packets, but those will have a bigger delay => estimation mistake
unreliable client function ClientSyncTimers(int LevelMillis, int GlobalMillis)
{
	local int Now, EstimatedLevelStart, EstimatedGlobalStart;

	Now = CurrentTimeMillis() - FFloor(ExactPing*1000.f);

	EstimatedLevelStart = Now - LevelMillis;
	if ( Abs(EstimatedLevelStart - LevelStartDate) > 200 )
	{
		`Log("[Trials] Correcting LEVEL timer" @ LevelStartDate @ "=>" @ EstimatedLevelStart @ "(" $ (EstimatedLevelStart - LevelStartDate) $ ")");
		// pick middleground
		LevelStartDate = (LevelStartDate + EstimatedLevelStart) / 2;
	}

	EstimatedGlobalStart = Now - GlobalMillis;
	if ( Abs(EstimatedGlobalStart - GlobalStartDate) > 200 )
	{
		`Log("[Trials] Correcting GLOBAL timer" @ GlobalStartDate @ "=>" @ EstimatedGlobalStart @ "(" $ (EstimatedGlobalStart - GlobalStartDate) $ ")");
		// pick middleground
		GlobalStartDate = (GlobalStartDate + EstimatedGlobalStart) / 2;
	}
}

simulated event ReplicatedEvent(Name VarName)
{
	if ( VarName == 'bStopGlobal' )
		TTHud(GetALocalPlayerController().myHUD).GlobalTimerChanged(Self);
	else if ( VarName == 'CurrentLevel' )
		TTHud(GetALocalPlayerController().myHUD).LevelChanged(Self);
	else
		Super.ReplicatedEvent(VarName);
}


defaultproperties
{
	Idx=-1
	LeaderboardPos=-1
	TotalPoints=-1
	MapPoints=-1
}
