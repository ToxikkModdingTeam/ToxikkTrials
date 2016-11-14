//================================================================
// Trials.TTGame
// ----------------
// Version 3 of trials !
// ----------------
// by Chatouille
//================================================================
class TTGame extends CRZGame
	config(Trials);

/** Server - holds our TT GRI */
var TTGRI GRI;

/** Server - holds Playerlist instance */
var TTPlayerlist Playerlist;

/** Server - holds current map's MapData instance */
var TTMapData MapData;


//================================================
// Initialization
//================================================

function PostBeginPlay()
{
	local int NumLevelRecords, i;

	Super.PostBeginPlay();

	// force a few config values...
	SpawnProtectionTime = 0.0;
	GoalScore = 0;
	TimeLimit = 0;
	MinRespawnDelay = 0;
	//bForceRespawn = true;

	// init config - generate first time ini for server admins
	InitConfig();
	`Log("[Trials] Config available in UDKTrials.ini");

	Playerlist = class'TTPlayerlist'.static.Load();
	`Log("[Trials] Playerlist loaded - " $ Playerlist.Player.Length $ " players");

	GRI = TTGRI(GameReplicationInfo);

	CheckMaplist();

	MapData = class'TTMapData'.static.Load(WorldInfo.GetMapName(true), GRI.LevelPoints.Length);

	BuildGlobalboard();

	NumLevelRecords = 0;
	for ( i=0; i<MapData.Levels.Length; i++ )
	{
		BuildLevelboard(i);
		NumLevelRecords += MapData.Levels[i].Record.Length;
	}

	`Log("[Trials] MapData loaded -" @ MapData.GlobalRecord.Length @ "map records," @ MapData.Levels.Length @ "levels," @ NumLevelRecords @ "level records");

	UpdateLeaderboard();
}

function InitConfig()
{
	SaveConfig();
}

function CheckMaplist()
{
	local TTMaplist StoredMaplist;
	local array<UDKUIResourceDataProvider> Providers;
	local int i,j;
	local CRZUIDataProvider_MapInfo MapInfo;
	local array<bool> bFoundMap;
	local bool bModified;

	StoredMaplist = class'TTMaplist'.static.Load();
	bFoundMap.Length = StoredMaplist.Map.Length;


	class'CRZUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'CRZUIDataProvider_MapInfo', Providers);
	for ( i=0; i<Providers.Length; i++ )
	{
		MapInfo = CRZUIDataProvider_MapInfo(Providers[i]);
		if ( MapInfo != None )
		{
			j = StoredMaplist.Map.Find(MapInfo.MapName);
			if ( j == INDEX_NONE )
			{
				`Log("[Trials] New map detected: " $ MapInfo.MapName);
				ToggleRecordsForMap(MapInfo.MapName, +1);
				StoredMaplist.Map.AddItem(MapInfo.MapName);
				bModified = true;
			}
			else
				bFoundMap[j] = true;
		}
	}

	for ( i=0; i<bFoundMap.Length; i++ )
	{
		if ( !bFoundMap[i] )
		{
			`Log("[Trials] A map was removed: " $ StoredMaplist.Map[i]);
			ToggleRecordsForMap(StoredMaplist.Map[i], -1);
			StoredMaplist.Map.Remove(i,1);
			bFoundMap.Remove(i--,1);
			bModified = true;
		}
	}

	if ( bModified )
	{
		StoredMaplist.SaveConfig();
		Playerlist.SaveConfig();
	}
}

//TODO: This can lead to huge iterations count if several maps got removed.
// Build a queue of maps to process and process one per Tick.
function ToggleRecordsForMap(String MapName, int Sign)
{
	local TTMapData Data;
	local int i,j;

	Data = class'TTMapData'.static.Load(MapName);
	for ( i=0; i<Data.GlobalRecord.Length; i++ )
	{
		Playerlist.Player[Data.GlobalRecord[i].PlayerIdx].TotalPoints += Sign * PointsForGlobalRank(Data.GlobalRecord[i].Rank);
	}
	for ( i=0; i<Data.Levels.Length; i++ )
	{
		for ( j=0; j<Data.Levels[i].Record.Length; j++ )
		{
			Playerlist.Player[Data.Levels[i].Record[j].PlayerIdx].TotalPoints += Sign * PointsForLevelRank(Data.Levels[i].Record[j].Rank);
		}
	}
}


function BuildGlobalboard()
{
	local int i, CurrentRank, CurrentRangeLimit;

	CurrentRank = -1;
	CurrentRangeLimit = 0;
	for ( i=0; i<MapData.GlobalRecord.Length; i++ )
	{
		if ( MapData.GlobalRecord[i].Time > CurrentRangeLimit )
		{
			CurrentRank++;
			CurrentRangeLimit = TimeRangeLimitForTime(MapData.GlobalRecord[i].Time);
			if ( CurrentRank < GRI.GLOBALBOARD_SIZE )
			{
				GRI.Globalboard[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
				GRI.Globalboard[CurrentRank].Players = Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].Name;
			}
		}
	}
}

function BuildLevelboard(int Idx)
{
	local int i, CurrentRank, CurrentRangeLimit;

	CurrentRank = -1;
	CurrentRangeLimit = 0;
	for ( i=0; i<MapData.Levels[Idx].Record.Length; i++ )
	{
		if ( MapData.Levels[Idx].Record[i].Time > CurrentRangeLimit )
		{
			CurrentRank++;
			CurrentRangeLimit = TimeRangeLimitForTime(MapData.Levels[Idx].Record[i].Time);
			if ( CurrentRank < GRI.GLOBALBOARD_SIZE )
			{
				GRI.Levelboard[Idx].Board[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
				GRI.Levelboard[Idx].Board[CurrentRank].Players = Playerlist.Player[MapData.Levels[Idx].Record[i].PlayerIdx].Name;
			}
		}
	}
}


//================================================
// Spawning
//================================================

// Replace pickup & weapon bases with our all-instant ones
function bool CheckRelevance(Actor Other)
{
	local CRZWeaponPickupFactory wpf;

	if ( ! Super.CheckRelevance(Other) )
		return false;

	wpf = CRZWeaponPickupFactory(Other);
	if ( wpf != None )
	{
		// hide CRZ factories and replace them with ours
		if ( !wpf.IsA('TTWPF') )
		{
			Spawn(class'TTWPF', wpf, wpf.Tag, wpf.Location, wpf.Rotation);
			wpf.DisablePickup();
			wpf.SetHidden(true);
		}
	}
	return true;
}

// Custom spawning system
function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string incomingName)
{
	local TTPRI PRI;

	if ( Player != None )
	{
		PRI = TTPRI(Player.PlayerReplicationInfo);
		if ( PRI != None )
		{
			if ( PRI.MyCS != None )
				return PRI.MyCS;

			if ( PRI.SpawnPoint == None )   //failsafe
				PRI.SpawnPoint = GRI.PointZero;

			return PRI.SpawnPoint.FindStartSpot(Player);
		}
	}

	return Super.FindPlayerStart(Player, InTeam, incomingName);
}

function SetPlayerDefaults(Pawn PlayerPawn)
{
	local CRZPawn P;
	local TTPRI PRI;
	local TTSavepoint Sp;

	Super.SetPlayerDefaults(PlayerPawn);

	P = CRZPawn(PlayerPawn);
	if ( P == None )
		return;

	// no collision to each other
	P.SetCollision(true, false, false);

	// fast-suicide
	P.LastStartTime = WorldInfo.TimeSeconds - 10;

	// custom spawning system
	PRI = TTPRI(P.PlayerReplicationInfo);
	if ( PRI != None )
	{
		if ( PRI.MyCS != None )
			PRI.MyCS.RespawnPlayer(P);
		else
		{
			Sp = PRI.SpawnPoint;    //WARNING: PointZero.RespawnPlayer changes PRI.SpawnPoint
			Sp.RespawnPlayer(PRI);
			PRI.ClientSpawnedAtPoint(Sp);
		}
	}
}


//================================================
// Damage and kills
//================================================

function ReduceDamage(out int Damage, Pawn injured, Controller InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	// negate any player-to-player damage
	// allow self-damage, world-damage
	// no bot damage for now
	if ( injured != None && InstigatedBy != None && InstigatedBy.Pawn != None && InstigatedBy.Pawn != injured )
	{
		Damage = 0;
		Momentum = Vect(0,0,0);
	}
	Super.ReduceDamage(Damage, injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
}

// remove all default scoring stuff
function ScoreKill(Controller Killer, Controller Other) {}
function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType) {}


//================================================
// Trials stuff
//================================================

function CheckPlayerObjClearance(TTPRI PRI)
{
	// reasons to forbid objective
	if ( !PRI.bForbiddenObj && PRI.MyCS != None && PRI.MyCS.bActive )
	{
		PRI.bForbiddenObj = true;
		return;
	}

	// else, allow objective
	PRI.bForbiddenObj = false;

	// force-suicide to respawn in a clean state
	if ( PRI.bMustDieToClean && Controller(PRI.Owner).Pawn != None )
		Controller(PRI.Owner).Pawn.Suicide();
}

function PawnTouchedWaypoint(CRZPawn P, TTWaypoint Wp)
{
	local TTPRI PRI;

	if ( P.Health > 0 )
	{
		//MEH: this should be in TTWaypoint, but easier to handle here... because of the Point's subclassing methods
		if ( Wp.bEnableTeleporter && !Wp.bTeleportOnlyWhenTarget )
			Wp.TeleportPlayer(P);

		PRI = TTPRI(P.PlayerReplicationInfo);
		if ( PRI != None && PRI.TargetWp.Find(Wp) != INDEX_NONE )
		{
			if ( PRI.bForbiddenObj )
			{
				if ( PlayerController(P.Controller) != None )
					PlayerController(P.Controller).ReceiveLocalizedMessage(class'TTCustomSpawnMessage', 4);
			}
			else
			{
				PlayerReachedWaypoint(PRI, Wp);

				if ( Wp.bEnableTeleporter && Wp.bTeleportOnlyWhenTarget )
					Wp.TeleportPlayer(P);
			}
		}
	}
}

function PlayerReachedWaypoint(TTPRI PRI, TTWaypoint Wp)
{
	Wp.ReachedBy(PRI);
	PRI.ClientReachedWaypoint(Wp);
}

function CheckGlobalTime(TTPRI PRI)
{
	local int Time;
	local int i;
	local bool bInserted, bBeaten, bBest, bModified;
	local int CurrentRank, CurrentRangeLimit;
	local TTPRI OtherPRI;

	Time = PRI.CurrentTimeMillis() - PRI.GlobalStartDate;

	// records list must ALWAYS be sorted by Time !
	// in ONE single iteration, we can :
	// - check if time is better than previous' player time (if any)
	// - insert new record in the right place
	// - calculate new time-ranges and
	//    - update ranks for the records that were shifted up
	//    - update the replicated board
	// - remove previous record
	CurrentRangeLimit = 0;
	CurrentRank = -1;
	//WARNING: we go up to Length so we can factor the insert code, when rec is to be appended at end
	for ( i=0; i<=MapData.GlobalRecord.Length; i++ )
	{
		// Insert new player record
		if ( !bInserted && (i == MapData.GlobalRecord.Length || Time < MapData.GlobalRecord[i].Time) )
		{
			MapData.GlobalRecord.Insert(i, 1);
			MapData.GlobalRecord[i].PlayerIdx = PRI.Idx;
			MapData.GlobalRecord[i].Time = Time;

			if ( Time > CurrentRangeLimit )
			{
				CurrentRank ++;
				CurrentRangeLimit = TimeRangeLimitForTime(Time);
				if ( CurrentRank < GRI.GLOBALBOARD_SIZE )
				{
					GRI.Globalboard[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
					GRI.Globalboard[CurrentRank].Players = Playerlist.Player[PRI.Idx].Name;
				}
			}
			else
			{
				if ( Len(GRI.Globalboard[CurrentRank].Players) + Len(Playerlist.Player[PRI.Idx].Name) <= 28 )
					GRI.Globalboard[CurrentRank].Players $= ", " $ Playerlist.Player[PRI.Idx].Name;
				else
					GRI.Globalboard[CurrentRank].Players $= ", ...";
			}

			MapData.GlobalRecord[i].Rank = CurrentRank;
			Playerlist.Player[PRI.Idx].TotalPoints += PointsForGlobalRank(CurrentRank);
			PRI.TotalPoints = Playerlist.Player[PRI.Idx].TotalPoints;
			PRI.MapPoints += PointsForGlobalRank(CurrentRank);

			bModified = true;
			bInserted = true;
			bBest = (i == 0);
			continue;
		}
		else if ( i == MapData.GlobalRecord.Length )
			break;

		// Remove player's old record
		else if ( bInserted && MapData.GlobalRecord[i].PlayerIdx == PRI.Idx )
		{
			Playerlist.Player[PRI.Idx].TotalPoints -= PointsForGlobalRank(MapData.GlobalRecord[i].Rank);
			PRI.TotalPoints = Playerlist.Player[PRI.Idx].TotalPoints;
			PRI.MapPoints -= PointsForGlobalRank(MapData.GlobalRecord[i].Rank);

			MapData.GlobalRecord.Remove(i--,1);
			bBeaten = true;
			continue;
		}

		// Just passing by - moving on to new time-range
		else if ( MapData.GlobalRecord[i].Time > CurrentRangeLimit )
		{
			CurrentRank ++;
			CurrentRangeLimit = TimeRangeLimitForTime(MapData.GlobalRecord[i].Time);
			if ( CurrentRank < GRI.GLOBALBOARD_SIZE )
			{
				GRI.Globalboard[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
				GRI.Globalboard[CurrentRank].Players = Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].Name;
			}
		}
		// Just passing by
		else
		{
			if ( Len(GRI.Globalboard[CurrentRank].Players) + Len(Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].Name) <= 28 )
				GRI.Globalboard[CurrentRank].Players $= ", " $ Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].Name;
			else
				GRI.Globalboard[CurrentRank].Players $= ", ...";
		}

		// Update record Rank if it changed - should only occur for shifted-up ranks.
		if ( MapData.GlobalRecord[i].Rank != CurrentRank )
		{
			// this record was not shifted up and we calculated different Rank - NOT NORMAL
			if ( !bInserted )
				`Log("[Trials] WARNING - Correcting incorrect Rank for GLOBAL record" @ i @ MapData.GlobalRecord[i].Rank @ "=>" @ CurrentRank);

			Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].TotalPoints -= PointsForGlobalRank(MapData.GlobalRecord[i].Rank);
			MapData.GlobalRecord[i].Rank = CurrentRank;
			Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].TotalPoints += PointsForGlobalRank(MapData.GlobalRecord[i].Rank);
			bModified = true;

			OtherPRI = Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].PRI;
			if ( OtherPRI != None )
			{
				OtherPRI.MapPoints += (Playerlist.Player[OtherPRI.Idx].TotalPoints - OtherPRI.TotalPoints);
				OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
			}
		}

		// No new record
		if ( MapData.GlobalRecord[i].PlayerIdx == PRI.Idx )
			break;
	}

	if ( !bModified )
		return;

	// announce
	if ( bBest )
		BroadcastHandler.Broadcast(PRI, PRI.PlayerName @ "has set a new #1 MAP record with" @ class'TTHud'.static.FormatTrialTime(Time), 'Event');
	else if ( bBeaten )
		BroadcastHandler.Broadcast(PRI, PRI.PlayerName @ "beat his personnal MAP record with" @ class'TTHud'.static.FormatTrialTime(Time), 'Event');
	else if ( bInserted )
		BroadcastHandler.Broadcast(PRI, PRI.PlayerName @ "finished the MAP with" @ class'TTHud'.static.FormatTrialTime(Time), 'Event');

	// save
	Playerlist.SaveConfig();
	MapData.SaveConfig();

	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		GRI.ReplicatedEvent('Globalboard'); // not even ashamed

	UpdateLeaderboard();
}


static function int TimeRangeLimitForTime(int TimeMillis)
{
	//Disable ranks for now => show all records
	return TimeMillis;

	//? Math.pow(seconds, 1.01)
	//? seconds + seconds/20
	return TimeMillis + (TimeMillis / 20);
}

static function int PointsForGlobalRank(int Rank)
{
	return (Rank == -1 ? 0 : (150/(Rank+1)));
}

function CheckLevelTime(TTPRI PRI)
{
	local int Time;
	local int LevelIdx, i;
	local bool bInserted, bBeaten, bBest, bModified;
	local int CurrentRank, CurrentRangeLimit;
	local TTPRI OtherPRI;

	if ( PRI.CurrentLevel == None )
		return;

	Time = PRI.CurrentTimeMillis() - PRI.LevelStartDate;
	LevelIdx = PRI.CurrentLevel.LevelIdx;

	CurrentRangeLimit = 0;
	CurrentRank = -1;
	//WARNING: we go up to Length so we can factor the insert code, when rec is to be appended at end
	for ( i=0; i<=MapData.Levels[LevelIdx].Record.Length; i++ )
	{
		// Insert new player record
		if ( !bInserted && (i == MapData.Levels[LevelIdx].Record.Length || Time < MapData.Levels[LevelIdx].Record[i].Time) )
		{
			MapData.Levels[LevelIdx].Record.Insert(i, 1);
			MapData.Levels[LevelIdx].Record[i].PlayerIdx = PRI.Idx;
			MapData.Levels[LevelIdx].Record[i].Time = Time;

			if ( Time > CurrentRangeLimit )
			{
				CurrentRank ++;
				CurrentRangeLimit = TimeRangeLimitForTime(Time);
				if ( LevelIdx < GRI.MAX_LEVELBOARDS && CurrentRank < GRI.LEVELBOARD_SIZE )
				{
					GRI.Levelboard[LevelIdx].Board[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
					GRI.Levelboard[LevelIdx].Board[CurrentRank].Players = Playerlist.Player[PRI.Idx].Name;
				}
			}
			else
			{
				if ( Len(GRI.Levelboard[LevelIdx].Board[CurrentRank].Players) + Len(Playerlist.Player[PRI.Idx].Name) <= 28 )
					GRI.Levelboard[LevelIdx].Board[CurrentRank].Players $= ", " $ Playerlist.Player[PRI.Idx].Name;
				else
					GRI.Levelboard[LevelIdx].Board[CurrentRank].Players $= ", ...";
			}

			MapData.Levels[LevelIdx].Record[i].Rank = CurrentRank;
			Playerlist.Player[PRI.Idx].TotalPoints += PointsForLevelRank(CurrentRank);
			PRI.TotalPoints = Playerlist.Player[PRI.Idx].TotalPoints;
			PRI.MapPoints += PointsForLevelRank(CurrentRank);

			bModified = true;
			bInserted = true;
			bBest = (i == 0);
			continue;
		}
		else if ( i == MapData.Levels[LevelIdx].Record.Length )
			break;

		// Remove player's old record
		else if ( bInserted && MapData.Levels[LevelIdx].Record[i].PlayerIdx == PRI.Idx )
		{
			Playerlist.Player[PRI.Idx].TotalPoints -= PointsForLevelRank(MapData.Levels[LevelIdx].Record[i].Rank);
			PRI.TotalPoints = Playerlist.Player[PRI.Idx].TotalPoints;
			PRI.MapPoints -= PointsForLevelRank(MapData.Levels[LevelIdx].Record[i].Rank);

			MapData.Levels[LevelIdx].Record.Remove(i--,1);
			bBeaten = true;
			continue;
		}

		// Just passing by - keep calculating current time-range and rank
		else if ( MapData.Levels[LevelIdx].Record[i].Time > CurrentRangeLimit )
		{
			CurrentRank ++;
			CurrentRangeLimit = TimeRangeLimitForTime(MapData.Levels[LevelIdx].Record[i].Time);
			if ( LevelIdx < GRI.MAX_LEVELBOARDS && CurrentRank < GRI.LEVELBOARD_SIZE )
			{
				GRI.Levelboard[LevelIdx].Board[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
				GRI.Levelboard[LevelIdx].Board[CurrentRank].Players = Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].Name;
			}
		}
		else
		{
			if ( Len(GRI.Levelboard[LevelIdx].Board[CurrentRank].Players) + Len(Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].Name) <= 28 )
				GRI.Levelboard[LevelIdx].Board[CurrentRank].Players $= ", " $ Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].Name;
			else
				GRI.Levelboard[LevelIdx].Board[CurrentRank].Players $= ", ...";
		}

		// Update record Rank if it changed - should only occur for shifted-up ranks.
		if ( MapData.Levels[LevelIdx].Record[i].Rank != CurrentRank )
		{
			// this record was not shifted up and we calculated different Rank - NOT NORMAL
			if ( !bInserted )
				`Log("[Trials] WARNING - Correcting incorrect Rank for LEVEL record" @ LevelIdx @ i @ MapData.Levels[LevelIdx].Record[i].Rank @ "=>" @ CurrentRank);

			Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].TotalPoints -= PointsForLevelRank(MapData.Levels[LevelIdx].Record[i].Rank);
			MapData.Levels[LevelIdx].Record[i].Rank = CurrentRank;
			Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].TotalPoints += PointsForLevelRank(MapData.Levels[LevelIdx].Record[i].Rank);
			bModified = true;

			OtherPRI = Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].PRI;
			if ( OtherPRI != None )
			{
				OtherPRI.MapPoints += (Playerlist.Player[OtherPRI.Idx].TotalPoints - OtherPRI.TotalPoints);
				OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
			}
		}

		// No new record
		if ( MapData.Levels[LevelIdx].Record[i].PlayerIdx == PRI.Idx )
			break;
	}

	if ( !bModified )
		return;

	// announce
	if ( bBest )
		BroadcastHandler.Broadcast(PRI, PRI.PlayerName @ "has set a new #1" @ PRI.CurrentLevel.LevelDisplayName @ "record with" @ class'TTHud'.static.FormatTrialTime(Time), 'Event');
	else if ( bBeaten )
		BroadcastHandler.Broadcast(PRI, PRI.PlayerName @ "beat his personnal" @ PRI.CurrentLevel.LevelDisplayName @ "record with" @ class'TTHud'.static.FormatTrialTime(Time), 'Event');
	else if ( bInserted )
		BroadcastHandler.Broadcast(PRI, PRI.PlayerName @ "finished" @ PRI.CurrentLevel.LevelDisplayName @ "with" @ class'TTHud'.static.FormatTrialTime(Time), 'Event');

	// save
	Playerlist.SaveConfig();
	MapData.Levels[LevelIdx].SaveConfig();

	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		GRI.ReplicatedEvent('Levelboard');

	UpdateLeaderboard();
}

static function int PointsForLevelRank(int Rank)
{
	return (Rank == -1 ? 0 : (50/(Rank+1)));
}


function UpdateLeaderboard()
{
	local int i, k;

	Playerlist.SortPlayers();

	for ( i=0; i<Min(Playerlist.Sortmap.Length,GRI.LEADERBOARD_SIZE); i++ )
	{
		k = Playerlist.Sortmap[i];
		GRI.Leaderboard[i].Name = Playerlist.Player[k].Name;
		GRI.Leaderboard[i].Points = Playerlist.Player[k].TotalPoints;
		if ( Playerlist.Player[k].PRI != None )
			Playerlist.Player[k].PRI.LeaderboardPos = i;
	}
	for ( i=i; i<GRI.LEADERBOARD_SIZE; i++ )
		GRI.Leaderboard[i].Points = 0;
	for ( i=i; i<Playerlist.Sortmap.Length; i++ )
	{
		k = Playerlist.Sortmap[i];
		if ( Playerlist.Player[k].PRI != None )
			Playerlist.Player[k].PRI.LeaderboardPos = i;
	}

	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		GRI.ReplicatedEvent('Leaderboard');
}


//================================================
// End game - not much here
//================================================

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
	if ( Reason ~= "triggered" )
	{
		if ( Winner == None )
            Winner = GRI.GetCurrentBestPlayer();
		GRI.Winner = Winner;
		EndTime = WorldInfo.TimeSeconds + EndTimeDelay;
		SetEndGameFocus(Winner);
		return true;
	}
	return false;
}

function PlayEndOfMatchMessage()
{
	local UTPlayerController PC;

	// everyone wins because yes
	foreach WorldInfo.AllControllers(class'UTPlayerController', PC)
		PC.ClientPlayAnnouncement(VictoryMessageClass, 2);
}


//================================================
// Admin
//================================================

exec function DeleteGlobalBest()
{
	local int i;
	local int CurrentRank, CurrentRangeLimit;
	local TTPRI OtherPRI;

	if ( MapData.GlobalRecord.Length == 0 )
		return;

	// Remove #1 record and update owning player's points
	Playerlist.Player[MapData.GlobalRecord[0].PlayerIdx].TotalPoints -= PointsForGlobalRank(0);
	MapData.GlobalRecord.Remove(0,1);

	OtherPRI = Playerlist.Player[MapData.GlobalRecord[0].PlayerIdx].PRI;
	if ( OtherPRI != None )
	{
		OtherPRI.MapPoints -= PointsForGlobalRank(0);
		OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
	}

	// Update the rest of the board
	CurrentRangeLimit = 0;
	CurrentRank = -1;
	for ( i=0; i<MapData.GlobalRecord.Length; i++ )
	{
		// Moving on to new time-range
		if ( MapData.GlobalRecord[i].Time > CurrentRangeLimit )
		{
			CurrentRank ++;
			CurrentRangeLimit = TimeRangeLimitForTime(MapData.GlobalRecord[i].Time);
			if ( CurrentRank < GRI.GLOBALBOARD_SIZE )
			{
				GRI.Globalboard[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
				GRI.Globalboard[CurrentRank].Players = Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].Name;
			}
		}
		// Just passing by
		else
		{
			if ( Len(GRI.Globalboard[CurrentRank].Players) + Len(Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].Name) <= 28 )
				GRI.Globalboard[CurrentRank].Players $= ", " $ Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].Name;
			else
				GRI.Globalboard[CurrentRank].Players $= ", ...";
		}

		// Several records must have been shifted down
		if ( MapData.GlobalRecord[i].Rank != CurrentRank )
		{
			Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].TotalPoints -= PointsForGlobalRank(MapData.GlobalRecord[i].Rank);
			MapData.GlobalRecord[i].Rank = CurrentRank;
			Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].TotalPoints += PointsForGlobalRank(MapData.GlobalRecord[i].Rank);

			OtherPRI = Playerlist.Player[MapData.GlobalRecord[i].PlayerIdx].PRI;
			if ( OtherPRI != None )
			{
				OtherPRI.MapPoints += (Playerlist.Player[OtherPRI.Idx].TotalPoints - OtherPRI.TotalPoints);
				OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
			}
		}
	}

	// announce
	AdminEvent(None, "Global map record #1 has been deleted !");

	// save
	Playerlist.SaveConfig();
	MapData.SaveConfig();

	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		GRI.ReplicatedEvent('Globalboard');

	UpdateLeaderboard();
}

exec function GetLevel()
{
	local PlayerController PC;

	foreach WorldInfo.AllControllers(class'PlayerController', PC)
	{
		if ( WorldInfo.NetMode == NM_Standalone || AccessControl.IsAdmin(PC) )
			PC.ClientMessage("[A] Current Level idx : " $ TTPRI(PC.PlayerReplicationInfo).CurrentLevel);
	}
}

exec function DeleteLevelBest(int LevelIdx)
{
	local int i;
	local int CurrentRank, CurrentRangeLimit;
	local TTPRI OtherPRI;

	if ( LevelIdx < 0 || LevelIdx >= MapData.Levels.Length )
		AdminEvent(None, "Unrecognized level idx");

	if ( MapData.Levels[LevelIdx].Record.Length == 0 )
		return;

	// Remove #1 record and update owning player's points
	Playerlist.Player[MapData.Levels[LevelIdx].Record[0].PlayerIdx].TotalPoints -= PointsForLevelRank(0);
	MapData.Levels[LevelIdx].Record.Remove(0,1);

	OtherPRI = Playerlist.Player[MapData.Levels[LevelIdx].Record[0].PlayerIdx].PRI;
	if ( OtherPRI != None )
	{
		OtherPRI.MapPoints -= PointsForLevelRank(0);
		OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
	}

	// Update the rest of the board
	CurrentRangeLimit = 0;
	CurrentRank = -1;
	for ( i=0; i<=MapData.Levels[LevelIdx].Record.Length; i++ )
	{
		// Moving on to new time-range
		if ( MapData.Levels[LevelIdx].Record[i].Time > CurrentRangeLimit )
		{
			CurrentRank ++;
			CurrentRangeLimit = TimeRangeLimitForTime(MapData.Levels[LevelIdx].Record[i].Time);
			if ( LevelIdx < GRI.MAX_LEVELBOARDS && CurrentRank < GRI.LEVELBOARD_SIZE )
			{
				GRI.Levelboard[LevelIdx].Board[CurrentRank].TimeRangeLimit = CurrentRangeLimit;
				GRI.Levelboard[LevelIdx].Board[CurrentRank].Players = Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].Name;
			}
		}
		else
		{
			if ( Len(GRI.Levelboard[LevelIdx].Board[CurrentRank].Players) + Len(Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].Name) <= 28 )
				GRI.Levelboard[LevelIdx].Board[CurrentRank].Players $= ", " $ Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].Name;
			else
				GRI.Levelboard[LevelIdx].Board[CurrentRank].Players $= ", ...";
		}

		// Several records must have been shifted down
		if ( MapData.Levels[LevelIdx].Record[i].Rank != CurrentRank )
		{
			Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].TotalPoints -= PointsForLevelRank(MapData.Levels[LevelIdx].Record[i].Rank);
			MapData.Levels[LevelIdx].Record[i].Rank = CurrentRank;
			Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].TotalPoints += PointsForLevelRank(MapData.Levels[LevelIdx].Record[i].Rank);

			OtherPRI = Playerlist.Player[MapData.Levels[LevelIdx].Record[i].PlayerIdx].PRI;
			if ( OtherPRI != None )
			{
				OtherPRI.MapPoints += (Playerlist.Player[OtherPRI.Idx].TotalPoints - OtherPRI.TotalPoints);
				OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
			}
		}
	}

	// announce
	AdminEvent(None, GRI.LevelPoints[LevelIdx].LevelDisplayName @ "record #1 has been deleted !");

	// save
	Playerlist.SaveConfig();
	MapData.Levels[LevelIdx].SaveConfig();

	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		GRI.ReplicatedEvent('Levelboard');

	UpdateLeaderboard();
}

exec function WipeGlobalRecords()
{
	local int i;
	local TTPRI OtherPRI;

	if ( MapData.GlobalRecord.Length == 0 )
		return;

	while ( MapData.GlobalRecord.Length > 0 )
	{
		// Remove #1 record and update owning player's points
		Playerlist.Player[MapData.GlobalRecord[0].PlayerIdx].TotalPoints -= PointsForGlobalRank(0);
		MapData.GlobalRecord.Remove(0,1);

		OtherPRI = Playerlist.Player[MapData.GlobalRecord[0].PlayerIdx].PRI;
		if ( OtherPRI != None )
		{
			OtherPRI.MapPoints -= PointsForGlobalRank(0);
			OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
		}
	}

	// Clear board
	for ( i=0; i<GRI.GLOBALBOARD_SIZE; i++ )
	{
		GRI.Globalboard[i].TimeRangeLimit = 0;
		GRI.Globalboard[i].Players = "";
	}

	// announce
	AdminEvent(None, "Global map records have been wiped !");

	// save
	Playerlist.SaveConfig();
	MapData.SaveConfig();

	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		GRI.ReplicatedEvent('Globalboard');

	UpdateLeaderboard();
}

exec function WipeLevelRecords(int LevelIdx)
{
	local int i;
	local TTPRI OtherPRI;

	if ( LevelIdx < 0 || LevelIdx >= MapData.Levels.Length )
		AdminEvent(None, "Unrecognized level idx");

	if ( MapData.Levels[LevelIdx].Record.Length == 0 )
		return;

	while ( MapData.Levels[LevelIdx].Record.Length > 0 )
	{
		// Remove #1 record and update owning player's points
		Playerlist.Player[MapData.Levels[LevelIdx].Record[0].PlayerIdx].TotalPoints -= PointsForLevelRank(0);
		MapData.Levels[LevelIdx].Record.Remove(0,1);

		OtherPRI = Playerlist.Player[MapData.Levels[LevelIdx].Record[0].PlayerIdx].PRI;
		if ( OtherPRI != None )
		{
			OtherPRI.MapPoints -= PointsForLevelRank(0);
			OtherPRI.TotalPoints = Playerlist.Player[OtherPRI.Idx].TotalPoints;
		}
	}

	// Clear board
	if ( LevelIdx < GRI.MAX_LEVELBOARDS )
	{
		for ( i=0; i<GRI.LEVELBOARD_SIZE; i++ )
		{
			GRI.Levelboard[LevelIdx].Board[i].TimeRangeLimit = 0;
			GRI.Levelboard[LevelIdx].Board[i].Players = "";
		}
	}

	// announce
	AdminEvent(None, GRI.LevelPoints[LevelIdx].LevelDisplayName @ "records have been wiped !");

	// save
	Playerlist.SaveConfig();
	MapData.Levels[LevelIdx].SaveConfig();

	if ( WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_ListenServer )
		GRI.ReplicatedEvent('Levelboard');

	UpdateLeaderboard();
}

//TODO: This will have to be split over several Ticks
exec function RecalculateAllRecords()
{
	local TTMaplist StoredMaplist;
	local int i;

	AdminEvent(None, "Recalculating all map records...");

	StoredMaplist = class'TTMaplist'.static.Load();

	for ( i=0; i<StoredMaplist.Map.Length; i++ )
		RecalculateAll_Map( class'TTMapData'.static.Load(StoredMaplist.Map[i]) );

	// save
	Playerlist.SaveConfig();

	AdminEvent(None, "Recalculation finished - map restart required !");
}

function RecalculateAll_Map(TTMapData OtherMapData)
{
	local int i;
	local int CurrentRank, CurrentRangeLimit;

	CurrentRangeLimit = 0;
	CurrentRank = -1;
	for ( i=0; i<OtherMapData.GlobalRecord.Length; i++ )
	{
		// Moving on to new time-range
		if ( OtherMapData.GlobalRecord[i].Time > CurrentRangeLimit )
		{
			CurrentRank ++;
			CurrentRangeLimit = TimeRangeLimitForTime(OtherMapData.GlobalRecord[i].Time);
		}
		// Check if rank has moved
		if ( OtherMapData.GlobalRecord[i].Rank != CurrentRank )
		{
			AdminEvent(None, "Modified record ("$Mid(OtherMapData.Name,6)$") PID="$OtherMapData.GlobalRecord[i].PlayerIdx@"RANK:"@OtherMapData.GlobalRecord[i].Rank@"->"@CurrentRank);
			Playerlist.Player[OtherMapData.GlobalRecord[i].PlayerIdx].TotalPoints -= PointsForLevelRank(OtherMapData.GlobalRecord[i].Rank);
			OtherMapData.GlobalRecord[i].Rank = CurrentRank;
			Playerlist.Player[OtherMapData.GlobalRecord[i].PlayerIdx].TotalPoints += PointsForLevelRank(OtherMapData.GlobalRecord[i].Rank);
		}
	}
	// save
	OtherMapData.SaveConfig();

	for ( i=0; i<OtherMapData.Levels.Length; i++ )
		RecalculateAll_Level(OtherMapData.Levels[i]);
}

function RecalculateAll_Level(TTLevelData OtherLevelData)
{
	local int i;
	local int CurrentRank, CurrentRangeLimit;

	CurrentRangeLimit = 0;
	CurrentRank = -1;
	for ( i=0; i<OtherLevelData.Record.Length; i++ )
	{
		// Moving on to new time-range
		if ( OtherLevelData.Record[i].Time > CurrentRangeLimit )
		{
			CurrentRank ++;
			CurrentRangeLimit = TimeRangeLimitForTime(OtherLevelData.Record[i].Time);
		}
		// Check if rank has moved
		if ( OtherLevelData.Record[i].Rank != CurrentRank )
		{
			AdminEvent(None, "Modified record ("$Mid(OtherLevelData.Name,8)$") PID="$OtherLevelData.Record[i].PlayerIdx@"RANK:"@OtherLevelData.Record[i].Rank@"->"@CurrentRank);
			Playerlist.Player[OtherLevelData.Record[i].PlayerIdx].TotalPoints -= PointsForLevelRank(OtherLevelData.Record[i].Rank);
			OtherLevelData.Record[i].Rank = CurrentRank;
			Playerlist.Player[OtherLevelData.Record[i].PlayerIdx].TotalPoints += PointsForLevelRank(OtherLevelData.Record[i].Rank);
		}
	}
	// save
	OtherLevelData.SaveConfig();
}

function AdminEvent(PlayerReplicationInfo Sender, String Msg)
{
	`Log("[TR]" @ Msg);
	Broadcast(Sender, "[A]" @ Msg, 'Event');
}


//================================================
// Misc
//================================================

exec function DebugTree()
{
	DebugPrintWaypoint(GRI.PointZero, 0);
}
function DebugPrintWaypoint(TTWaypoint Wp, int Depth)
{
	local String indent;
	local int i;

	indent = "";
	for ( i=0; i<Depth; i++ )
		indent $= "-";

	`Log("[Tree] " $ indent $ String(Wp.Name));

	for ( i=0; i<Wp.NextPoints.Length; i++ )
		DebugPrintWaypoint(Wp.NextPoints[i], Depth+1);
}

function bool IsDefaultWeapon(class<Weapon> WC)
{
	return (DefaultInventory.Find(WC) != INDEX_NONE);
}


defaultproperties
{
	Acronym="TT"
	MapPrefixes(0)="TT"
	DefaultInventory=(class'TTWeap_CSpawner',class'TTWeap_CamLauncher')
	GameReplicationInfoClass=class'TTGRI'
	PlayerReplicationInfoClass=class'TTPRI'
	MinRespawnDelay=0
	bGivePhysicsGun=false
	HUDType=class'TTHud'
	DefaultPawnClass=class'TTPawn'

	OnlineStatsWriteClass=class'Cruzade.CRZStatsWriteXP'
	OnlineGameSettingsClass=class'Cruzade.CRZGameSettingsBL'
}
