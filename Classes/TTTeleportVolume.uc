//================================================================
// Trials.TTTeleportVolume
// ----------------
// Volume-based teleporter
// ----------------
// by Chatouille
//================================================================
class TTTeleportVolume extends PhysicsVolume;

var(Teleporter) String URL;
var(Teleporter) bool bResetVelocity;

var Teleporter Target;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local Teleporter T;

	Super(Actor).Touch(Other, OtherComp, HitLocation, HitNormal);

	if ( Role == ROLE_Authority && Pawn(Other) != None )
	{
		if ( Target == None )
		{
			foreach WorldInfo.AllNavigationPoints(class'Teleporter', T)
			{
				if ( String(T.Tag) ~= URL )
				{
					Target = T;
					break;
				}
			}
			if ( Target == None )
				return;
		}
		Pawn(Other).PlayTeleportEffect(true, true);
		Target.Accept(Other, None);
		if ( bResetVelocity )
		{
			Other.Velocity = Vect(0,0,0);
			if ( Other.Physics == PHYS_Walking )
				Other.SetPhysics(PHYS_Falling);
		}
	}
}

defaultproperties
{
}
