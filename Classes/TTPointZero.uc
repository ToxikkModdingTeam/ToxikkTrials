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

/** Either a TTLevel TTSavepoint, depending on whether map starts in a sublevel or not */
var(PointZero) TTSavepoint InitialPoint;


simulated function Init(TTGRI GRI)
{
	if ( InitialPoint != None )
		InitialPoint.bInitiallyAvailable = true;
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
}


defaultproperties
{
	SpawnTreeLabel="RESET"
	bInitiallyAvailable=true

	CollisionType=COLLIDE_NoCollision
}
