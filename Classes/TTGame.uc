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

function PostBeginPlay()
{
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

	GRI = TTGRI(GameReplicationInfo);
}

function InitConfig()
{
	SaveConfig();
}

// Replace pickup & weapon bases with our all-instant ones
function bool CheckRelevance(Actor Other)
{
	local CRZWeaponPickupFactory wpf;
	wpf = CRZWeaponPickupFactory(Other);
	if ( wpf != None )
	{
		// hide CRZ factories and replace them with ours
		if ( !wpf.IsA('TTWPF') )
		{
			Spawn(class'TTWPF', wpf, wpf.Tag, wpf.Location, wpf.Rotation);
			return false;
		}
	}
	return Super.CheckRelevance(Other);
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
				PRI.SetSpawnPoint(GRI.PointZero);

			return PRI.SpawnPoint.FindStartSpot(Player);
		}
	}

	return Super.FindPlayerStart(Player, InTeam, incomingName);
}

function SetPlayerDefaults(Pawn PlayerPawn)
{
	local CRZPawn P;
	local TTPRI PRI;

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
			PRI.SpawnPoint.RespawnPlayer(P);
			PRI.ClientSpawnedAtPoint(P, PRI.SpawnPoint);
		}
	}
}

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
		PRI = TTPRI(P.PlayerReplicationInfo);
		if ( PRI != None && PRI.TargetWp.Find(Wp) != INDEX_NONE )
		{
			if ( PRI.bForbiddenObj )
			{
				if ( PlayerController(P.Controller) != None )
					PlayerController(P.Controller).ReceiveLocalizedMessage(class'TTCustomSpawnMessage', 4);
			}
			else
				PlayerReachedWaypoint(P, Wp);
		}
	}
}

function PlayerReachedWaypoint(CRZPawn P, TTWaypoint Wp)
{
	Wp.ReachedBy(P);
	TTPRI(P.PlayerReplicationInfo).ClientReachedWaypoint(P, Wp);
}

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

	OnlineStatsWriteClass=class'Cruzade.CRZStatsWriteXP'
	OnlineGameSettingsClass=class'Cruzade.CRZGameSettingsBL'
}
