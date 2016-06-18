//================================================================
// Trials.TTPointZero
// ----------------
// - Resets main objectives validation and global timer
// - Delegates playerspawn to InitialPoint
// ----------------
// by Chatouille
//================================================================
class TTPointZero extends TTSavepoint
	hidecategories(Savepoint,Checkpoint,Waypoint,HUD,Trigger,Collision);

/** Either a TTLevel or a TTSavepoint, depending on whether map starts starts in a level */
var(PointZero) TTSavepoint InitialPoint;


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
simulated function RespawnPlayer(CRZPawn P)
{
	GlobalResetFor(P);
	InitialPoint.RespawnPlayer(P);
}

simulated function GlobalResetFor(CRZPawn P)
{
	local TTPRI PRI;

	PRI = TTPRI(P.PlayerReplicationInfo);
	PRI.UnlockedSavepoints.Length = 0;  // relock all Savepoints
	PRI.ValidatedObjectives.Length = 0; // invalidate all objectives
	PRI.GlobalStartDate = PRI.CurrentTimeMillis();
	PRI.SetGlobalTimerEnabled(true);
}


defaultproperties
{
	SpawnTreeLabel="RESET"
	bInitiallyAvailable=true

	CollisionType=COLLIDE_NoCollision
}
