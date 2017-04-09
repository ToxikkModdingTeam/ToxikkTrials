//================================================================
// Trials.TTPointZero
// ----------------
// - Resets main objectives validation and global timer
// - Delegates playerspawn to InitialPoint
// ----------------
// by Chatouille
//================================================================
class TTPointZero extends TTSavepoint
	placeable
	hidecategories(Savepoint,Checkpoint,Waypoint,HUD,Trigger,Collision);

/** Either a TTLevelInitial or a TTSpawnInitial, depending on whether map starts starts in a level or not */
var(PointZero) TTSavepoint InitialPoint;

var(Savepoint) String SingleSpawnTreeLabel;


simulated function Init(TTGRI GRI)
{
	if ( InitialPoint != None )
	{
		InitialPoint.bInitiallyAvailable = true;
		NextPoints.AddItem(InitialPoint);
		InitialPoint.PreviousPoints.AddItem(Self);
	}
	else
		`Log("[Trials] WARNING - PointZero.InitialPoint is None");
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal);

/** Called by the gamemode */
function NavigationPoint FindStartSpot(Controller Player)
{
	return InitialPoint.FindStartSpot(Player);
}

/** Called by the gamemode */
simulated function RespawnPlayer(TTPRI PRI)
{
	GlobalResetFor(PRI);
	InitialPoint.RespawnPlayer(PRI);
}

simulated function GlobalResetFor(TTPRI PRI)
{
	PRI.GlobalReachedSavepoints.Length = 0;
	PRI.ValidatedObjectives.Length = 0;
	PRI.GlobalStartDate = PRI.CurrentTimeMillis();
	PRI.SetGlobalTimerEnabled(true);
}


defaultproperties
{
	SpawnTreeLabel="RESET"
	SingleSpawnTreeLabel="START"
	bInitiallyAvailable=true

	CollisionType=COLLIDE_NoCollision
}
