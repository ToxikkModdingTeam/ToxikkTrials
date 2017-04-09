//================================================================
// ToxikkTrials.TTPawn
// ----------------
// - Wallglitches fix experiment
// - Landing bug fix
// - Fadeout close players
// - Inhibit annoying sounds (landing)
// ----------------
// by Chatouille
//================================================================
class TTPawn extends CRZPawn;

var TTConfigMenu Conf;


simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	SetTimer(0.1, true, 'LooseTick');
}


simulated event TickSpecial(float dt)
{
	local PlayerController PC;
	local float Dist, StealthFactor;
	local int i;

	Super.TickSpecial(dt);

	// Landing bug FIX :
	// when PHYS_Walking and multijump NOT available, then the bug occured => call Landed manually
	// (client-side only)
	if ( Physics == PHYS_Walking && MultiJumpRemaining < MaxMultiJump )
		Landed(Vect(0,0,1), Base);

	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		PC = GetALocalPlayerController();
		if ( PC == None || PC.Pawn == None )
			return;
		if ( Conf == None )
			Conf = TTConfigMenu(class'ClientConfigMenuManager'.static.FindCCM(PC).AddMenuInteraction(class'TTConfigMenu'));

		// Fadeout close players
		if ( Conf != None && Conf.FadeoutDist > 0 && Self != PC.Pawn )
		{
			Dist = VSize(Self.Location - PC.Pawn.Location);
			StealthFactor = GetMappedRangeValue(vect2d(64,Conf.FadeoutDist), vect2d(1,0), Dist);
			StealthFactor = Sqrt(StealthFactor);

			for ( i=0; i<BodyMaterialInstances.length; i++ )
				BodyMaterialInstances[i].SetScalarParameterValue(StealthMaterialParameterName, StealthFactor);
			for ( i=0; i<BodyOverlayMaterialInstances.Length; i++ )
				BodyOverlayMaterialInstances[i].SetScalarParameterValue(StealthMaterialParameterName, StealthFactor);

			if ( StealthFactor > 0 )
			{
				if ( !OverlayMesh.bAttached )
				{
					SetHiddenOnMeshComponents(Mesh.HiddenGame,OverlayMeshComponents);
					AttachMeshComponentsOnActor(self,OverlayMeshComponents);
					OverlayMeshArms.SetHidden(ArmsMesh[0].HiddenGame);
					AttachComponent(OverlayMeshArms);
				}
			}
			else
			{
				if ( OverlayMesh.bAttached )
				{
					DetachMeshComponentsOnActor(self,OverlayMeshComponents);
					SetHiddenOnMeshComponents(true,OverlayMeshComponents);
					DetachComponent(OverlayMeshArms);
					OverlayMeshArms.SetHidden(true);
				}
			}

			CurrentStealthFactor = StealthFactor;
			if ( CRZWeaponAttachment(CurrentWeaponAttachment) != None )
				CRZWeaponAttachment(CurrentWeaponAttachment).UpdateStealth(Self);
			if ( CurrentJetPack != None )
				CurrentJetPack.UpdateStealth(Self);
		}
	}
}


simulated event LooseTick()
{
	local UTProjectile Proj;
	local UTWeapon Weap;
	local int i;
	//local SoundCue Cue;

	// Client
	// Remove others projectiles sounds
	if ( Conf != None && Conf.PC == Controller && Conf.bQuietPlayers )
	{
		foreach WorldInfo.AllActors(class'UTProjectile', Proj)
		{
			if ( Proj.Instigator != Self )
				Proj.bSuppressSounds = true;
		}
	}

	// Server
	// Change class of sound cues for weaponfires on server-side
	// Since weaponfiring is simulated, this shouldn't affect our own sounds
	// But every weaponfiring by others will be replicated with this class
	if ( WorldInfo.NetMode == NM_DedicatedServer || (WorldInfo.NetMode == NM_Standalone && PlayerController(Controller) == None) )
	{
		Weap = UTWeapon(Weapon);
		if ( Weap != None && Weap.WeaponFireSnd[0].SoundClass != 'WeaponEnemy' )
		{
			//`Log("[D] Reclassing cues" @ PlayerReplicationInfo.PlayerName @ Weap.ItemName);
			for ( i=0; i<Weap.WeaponFireSnd.Length; i++ )
			{
				/*
				Cue = new(Weap) class'SoundCue'(Weap.WeaponFireSnd[i]);
				Cue.SoundClass = 'WeaponEnemy';
				Weap.WeaponFireSnd[i] = Cue;
				*/
				Weap.WeaponFireSnd[i] = TTGRI(WorldInfo.GRI).GetCustomFiringCue(Weap, Weap.WeaponFireSnd[i]);
			}
		}
	}
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


// Disable stealth
simulated function EnableStealth(bool bTurnOn, optional bool ForceOFF=false) {}


// Landing sounds
simulated function PlayLandingSound()
{
	if ( Conf != None && Conf.bQuietPlayers && Conf.PC.Pawn != None && Self != Conf.PC.Pawn )
		return;

	Super.PlayLandingSound();
}


// Forward dodges to Keytracker
function bool Dodge(EDoubleClickDir DoubleClickMove)
{
	if ( Super.Dodge(DoubleClickMove) )
	{
		if ( Controller != None && Controller.IsLocalPlayerController() )
			TTHud(PlayerController(Controller).myHUD).Keytracker.Dodge(DoubleClickMove);

		return true;
	}
	return false;
}


defaultproperties
{
	bDirectHitWall=true
}
