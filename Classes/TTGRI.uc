//================================================================
// Trials.TTGRI
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTGRI extends CRZGameReplicationInfo;

/** List of all points */
var array<TTWaypoint> AllPoints;

/** Server Replicated - Reference to Point Zero */
var TTPointZero PointZero;

Replication
{
	if ( bNetInitial )
		PointZero;
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

	foreach WorldInfo.AllActors(class'TTWaypoint', Wp)
		AllPoints.AddItem(Wp);
	for ( i=0; i<AllPoints.Length; i++ )
		AllPoints[i].Init(Self);
}

function FindPointZero()
{
	local int i;
	local PlayerStart PS;

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

		PointZero.bModifyHealth = false;

		// find some playerstarts
		foreach WorldInfo.AllNavigationPoints(class'PlayerStart', PS)
		{
			if ( PS.bEnabled && PS.bPrimaryStart )
				PointZero.Respawns.AddItem(PS);
		}
		if ( PointZero.Respawns.Length == 0 )
		{
			if ( PS != None )
			{
				`Log("[Trials] WARNING - No enabled primary PlayerStart found for PointZero. Adding all playerstarts...");
				foreach WorldInfo.AllNavigationPoints(class'PlayerStart', PS)
					PointZero.Respawns.AddItem(PS);
			}
			else
				`Log("[Trials] ERROR - No PlayerStart found. Map is not playable !");
		}

		// find some Waypoints that have no predecessors...
		for ( i=0; i<AllPoints.Length; i++ )
		{
			if ( AllPoints[i].PreviousPoints.Length == 0 )
			{
				PointZero.NextPoints.AddItem(AllPoints[i]);
				AllPoints[i].PreviousPoints.AddItem(PointZero);
			}
		}
		if ( PointZero.NextPoints.Length == 0 )
			`Log("[Trials] ERROR - No successors found for PointZero. Map is not playable !");

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
		else if ( AllPoints[i].NextPoints.Length == 0 && !AllPoints[i].IsA('TTMainObjective') )
			`Log("[Trials] WARNING - Waypoint has no successors : " $ AllPoints[i].Name);
	}
}

defaultproperties
{
}
