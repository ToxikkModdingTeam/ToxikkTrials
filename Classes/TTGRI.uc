//================================================================
// Trials.TTGRI
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTGRI extends CRZGameReplicationInfo;

CONST LEADERBOARD_SIZE = 10;

/** List of all points */
var array<TTWaypoint> AllPoints;

/** Total number of objectives (all must be validated for global record) */
var int TotalObjectives;

/** Server Replicated - Reference to Point Zero */
var TTPointZero PointZero;

/** List of all level points */
var array<TTLevel> LevelPoints;

/** Server Replicated - Leaderboard */
struct sPlayerInfo
{
	var String Name;
	var int Points;
};
var sPlayerInfo Leaderboard[LEADERBOARD_SIZE];

Replication
{
	if ( bNetInitial )
		PointZero;
	if ( bNetInitial || bNetDirty )
		Leaderboard;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	BuildPointsList();

	if ( Role == ROLE_Authority )
	{
		FindPointZero();
		CheckReachability();
	}
}

simulated function BuildPointsList()
{
	local TTWaypoint Wp;
	local int i;

	TotalObjectives = 0;
	foreach WorldInfo.AllActors(class'TTWaypoint', Wp)
	{
		AllPoints.AddItem(Wp);

		if ( Wp.IsA('TTLevel') && !Wp.IsA('TTObjective') )
			LevelPoints.AddItem(TTLevel(Wp));

		if ( Wp.IsA('TTObjective') )
			TotalObjectives += 1;
	}

	LevelPoints.Sort(CompareLevelPoints);
	for ( i=0; i<LevelPoints.Length; i++ )
		LevelPoints[i].LevelIdx = i;

	for ( i=0; i<AllPoints.Length; i++ )
		AllPoints[i].Init(Self);
}

function int CompareLevelPoints(TTLevel P1, TTLevel P2)
{
	if ( int(P1.Location.X) == int(P2.Location.X) )
	{
		if ( int(P1.Location.Y) == int(P2.Location.Y) )
		{
			if ( int(P1.Location.Z) == int(P2.Location.Z) )
				return (String(P2.Name) < String(P1.Name) ? 1 : -1);

			return (P1.Location.Z < P2.Location.Z ? 1 : -1);
		}
		return (P1.Location.Y < P2.Location.Y ? 1 : -1);
	}
	return (P1.Location.X < P2.Location.Y ? 1 : -1);
}

function FindPointZero()
{
	local int i;

	for ( i=0; i<AllPoints.Length; i++ )
	{
		if ( AllPoints[i].IsA('TTPointZero') )
		{
			if ( PointZero != None )
				`Log("[Trials] WARNING - Found multiple PointZero in map. Using '" $ PointZero.Name $ "'");
			else
				PointZero = TTPointZero(AllPoints[i]);
		}
	}

	if ( PointZero == None )
	{
		`Log("[Trials] WARNING - Found no PointZero in map. Creating one...");

		PointZero = Spawn(class'TTDynamicPointZero');

		// find a Savepoint with no precedessors
		for ( i=0; i<AllPoints.Length; i++ )
		{
			if ( AllPoints[i].IsA('TTSavepoint') && !AllPoints[i].IsA('TTObjective') && AllPoints[i].PreviousPoints.Length == 0 )
			{
				PointZero.InitialPoint = TTSavepoint(AllPoints[i]);
				AllPoints[i].PreviousPoints.AddItem(PointZero);
				break;
			}
		}
		if ( PointZero.NextPoints.Length == 0 )
			`Log("[Trials] ERROR - No successor found for PointZero. Map is not playable !");

		AllPoints.AddItem(PointZero);
		PointZero.Init(Self);
	}
}

function CheckReachability()
{
	local int i;

	for ( i=0; i<AllPoints.Length; i++ )
	{
		if ( AllPoints[i].PreviousPoints.Length == 0 && !AllPoints[i].IsA('TTPointZero') )
			`Log("[Trials] WARNING - Waypoint has no predecessors : " $ AllPoints[i].Name);
		else if ( AllPoints[i].NextPoints.Length == 0 && !AllPoints[i].IsA('TTObjective') )
			`Log("[Trials] WARNING - Waypoint has no successors : " $ AllPoints[i].Name);
	}
}


defaultproperties
{
}
