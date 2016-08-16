//================================================================
// ToxikkTrials.TTPawn
// ----------------
// - Wallglitches fix experiment
// - Landing bug fix experiment
// ----------------
// by Chatouille
//================================================================
class TTPawn extends CRZPawn;


// Landing bug FIX :
// when PHYS_Walking and multijump NOT available, then the bug occured => call Landed manually
// (client-side only)
simulated event TickSpecial(float dt)
{
	Super.TickSpecial(dt);

	if ( Physics == PHYS_Walking && MultiJumpRemaining < MaxMultiJump )
		Landed(Vect(0,0,1), Base);
}


// Wallglitch FIX :
// when hitting BSP that is (almost) aligned to world-axis, push the pawn back a fraction of unit
// NOTE: we don't fix ramp glitches atm because of HitNormal.Z check. TODO: handle them on separate case
simulated event HitWall(Vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
   if (  ( Wall == WorldInfo || WallComp == None )
      && ( Abs(HitNormal.Z) < 0.1 )
      && ( Physics != PHYS_RigidBody )
      && ( !bIsCrouched )
      && ( PlayerController(Controller) != None )
      && ( PlayerController(Controller).bRun == 0 )
      && ( Abs(HitNormal.X) > 0.85 || Abs(HitNormal.Y) > 0.85 )
   )
   {
      SetLocation(Location + 0.2*HitNormal);

      // gotta manage the velocity ourselves otherwise it's not handled
      Velocity -= (Velocity Dot HitNormal) * HitNormal;
   }

   Super.HitWall(HitNormal, Wall, WallComp);
}


defaultproperties
{
	bDirectHitWall=true
}
