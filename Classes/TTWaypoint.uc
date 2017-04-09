//================================================================
// Trials.TTWaypoint
// ----------------
// Just a base class for all waypoints
// - Forces path
// ----------------
// by Chatouille
//================================================================
class TTWaypoint extends Trigger
	notplaceable
	ClassGroup(Trials)
	hidecategories(Mobile);

var(Waypoint) String ReachString;
var(Waypoint) array<TTWaypoint> NextPoints;

var(Teleport) bool bEnableTeleporter;
var(Teleport) String URL;
var(Teleport) bool bResetVelocity;
var(Teleport) bool bTeleportOnlyWhenTarget;

/** internal - list of waypoints pointing to me */
var array<TTWaypoint> PreviousPoints;

/** internal - target teleporter */
var Teleporter TargetTP;

/** Text to write on HUD icon when this waypoint is target */
var(HUD) String HudText;
/** Color to use for HUD icon when this waypoint is target */
var(HUD) Color HudColor;
/** Alpha multiplier for when this waypoint is previewed in advance */
var(HUD) float PreviewAlpha;
/** Color to use for HUD icon when this waypoint is target but forbidden (because of cheaty helpers) */
var(HUD) Color ForbiddenHudColor;
/** Maximum distance to display the HUD icon at */
var(HUD) int MaxHudDistance;

/** Const - HUD Icon box padding */
var Vector2D BoxPadding;


/** called by GRI */
simulated function Init(TTGRI GRI)
{
	local int i,j;

	//anti-bullshit
	for ( i=0; i<NextPoints.Length; i++ )
	{
		if ( NextPoints[i] == Self )
		{
			`Log("[Trials] WARNING - Found self in NextPoints list for " $ Name);
			NextPoints.Remove(i,1);
			i--;
		}
		else if ( NextPoints[i] == None )
			`Log("[Trials] WARNING - Found none in NextPoints list for " $ Name);
	}
	for ( i=0; i<NextPoints.Length-1; i++ )
	{
		for ( j=i+1; j<NextPoints.Length; j++ )
		{
			if ( NextPoints[j] == NextPoints[i] )
			{
				`Log("[Trials] WARNING - Found duplicate in NextPoints list for " $ Name);
				NextPoints.Remove(j,1);
				j--;
			}
		}
	}

	// build list of referencing points
	PreviousPoints.Length = 0;
	for ( i=0; i<GRI.AllPoints.Length; i++ )
		for ( j=0; j<GRI.AllPoints[i].NextPoints.Length; j++ )
			if ( GRI.AllPoints[i].NextPoints[j] == Self )
				PreviousPoints.AddItem(GRI.AllPoints[i]);

	if ( WorldInfo.NetMode != NM_DedicatedServer )
		WaitForLocalPC();
}

simulated function bool FindInPredecessors(TTWaypoint ToFind)
{
	local int i;

	for ( i=0; i<PreviousPoints.Length; i++ )
	{
		if ( PreviousPoints[i] == ToFind || PreviousPoints[i].FindInPredecessors(ToFind) )
			return true;
	}
	return false;
}

simulated function WaitForLocalPC()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if ( PC != None )
		FoundLocalPC(PC);
	else
		SetTimer(0.1, false, GetFuncName());
}

simulated function FoundLocalPC(PlayerController PC)
{
	if ( PC.myHUD.PostRenderedActors.Find(Self) == INDEX_NONE )
		PC.myHUD.AddPostRenderedActor(Self);
}

simulated event Destroyed()
{
	local PlayerController PC;
	local int i;

	foreach WorldInfo.AllControllers(class'PlayerController', PC)
	{
		if ( TTPRI(PC.PlayerReplicationInfo) != None )
			TTPRI(PC.PlayerReplicationInfo).TargetWp.RemoveItem(Self);
	}

	PC = GetALocalPlayerController();
	if ( PC != None )
	{
		if ( TTPRI(PC.PlayerReplicationInfo) != None )
			TTPRI(PC.PlayerReplicationInfo).TargetWp.RemoveItem(Self);
		if ( PC.myHUD != None )
			PC.myHUD.RemovePostRenderedActor(Self);
		if ( TTHud(PC.myHUD) != None )
			TTHud(PC.myHUD).SpawnTree.Rebuild();
	}

	if ( TTGRI(WorldInfo.GRI) != None )
		TTGRI(WorldInfo.GRI).AllPoints.RemoveItem(Self);

	for ( i=0; i<PreviousPoints.Length; i++ )
	{
		if ( PreviousPoints[i] != None )
			PreviousPoints[i].NextPoints.RemoveItem(Self);
	}

	Super.Destroyed();
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);

	if ( CRZPawn(Other) != None && TTGame(WorldInfo.Game) != None )
		TTGame(WorldInfo.Game).PawnTouchedWaypoint(CRZPawn(Other), Self);
}

function TeleportPlayer(Pawn P)
{
	local Teleporter T;

	if ( TargetTP == None )
	{
		foreach WorldInfo.AllNavigationPoints(class'Teleporter', T)
		{
			if ( String(T.Tag) ~= URL )
			{
				TargetTP = T;
				break;
			}
		}
		if ( TargetTP == None )
			return;
	}
	P.PlayTeleportEffect(true, true);
	TargetTP.Accept(P, Self);
	if ( bResetVelocity )
	{
		P.Velocity = Vect(0,0,0);
		if ( P.Physics == PHYS_Walking )
			P.SetPhysics(PHYS_Falling);
	}
}

/** Called by the gamemode (simulated only for the reacher!) */
simulated function ReachedBy(TTPRI PRI)
{
	NotifyPlayer(PRI);
	UpdatePlayerTargets(PRI);
}

simulated function NotifyPlayer(TTPRI PRI)
{
	if ( PRI.IsLocalPlayerPRI() && CRZHud(PlayerController(PRI.Owner).myHUD) != None )
		CRZHud(PlayerController(PRI.Owner).myHUD).LocalizedCRZMessage(class'TTWaypointMessage', PRI, None, ReachString, 0, Self);
}

simulated function UpdatePlayerTargets(TTPRI PRI)
{
	local int i,j,k;

	i = PRI.TargetWp.Find(Self);
	if ( i != INDEX_NONE )
		PRI.TargetWp.Remove(i,1);
	else
		i = PRI.TargetWp.Length;

	for ( j=NextPoints.Length-1; j>=0; j-- )
	{
		k = PRI.TargetWp.Find(NextPoints[j]);
		if ( k > i )    // it appears later in list - remove to re-insert at the place where Self was
			PRI.TargetWp.Remove(k,1);
		else if ( k != INDEX_NONE ) // it appears earlier in list - skip
			continue;
		PRI.TargetWp.InsertItem(i, NextPoints[j]);
	}
}

simulated event PostRenderFor(PlayerController PC, Canvas C, Vector CamPos, Vector CamDir)
{
	local TTPRI PRI;

	PRI = TTPRI(PC.PlayerReplicationInfo);
	if ( PRI != None )
	{
		if ( PRI.TargetWp.Find(Self) != INDEX_NONE )
			DrawFor(PC, C, CamPos, CamDir);
		else if ( PRI.TargetWp.Length == 1 && PRI.TargetWp[0].NextPoints.Length == 1 && PRI.TargetWp[0].NextPoints[0] == Self && ClassIsChildOf(Self.Class,PRI.TargetWp[0].Class) )
			DrawFor(PC, C, CamPos, CamDir, true);
	}
}

simulated function DrawFor(PlayerController PC, Canvas C, Vector CamPos, Vector CamDir, optional bool bPreview=false)
{
	local float Dist;
	local Vector ScreenLoc;
	local float Scale;
	local Vector2D TextSize;
	local Color Col;
	local float AlphaMult;

	Dist = VSize(CamPos - Location);
	if ( Dist > MaxHudDistance )
		return;

	ScreenLoc = C.Project(Location);
	if ( ScreenLoc.X < 0 || ScreenLoc.X >= C.ClipX || ScreenLoc.Y < 0 || ScreenLoc.Y >= C.ClipY )
		return;

	Scale = (Dist > 0 ? FClamp(768 / Dist, 0.40, 7.0) : 4.0);

	C.Font = class'CRZHud'.default.GlowFonts[0];
	C.TextSize(HudText, TextSize.X, TextSize.Y, Scale, Scale);

	// no draw if wrap!
	if ( ScreenLoc.X + TextSize.X / 2 + 1 >= C.ClipX )
		return;

	AlphaMult = (bPreview ? PreviewAlpha : 1.0);

	C.SetDrawColor(0,0,0,100*AlphaMult);
	C.SetPos(ScreenLoc.X - TextSize.X / 2 - BoxPadding.X*Scale + 1, ScreenLoc.Y - TextSize.Y / 2 - BoxPadding.Y*Scale + 1);
	C.DrawRect(TextSize.X + 2*BoxPadding.X*Scale - 2, TextSize.Y + 2*BoxPadding.Y*Scale - 2);

	Col = TTPRI(PC.PlayerReplicationInfo).bForbiddenObj ? ForbiddenHudColor : HudColor;
	Col.A *= AlphaMult;

	DrawObjBoxBounds(C,
			ScreenLoc.X - TextSize.X / 2 - BoxPadding.X*Scale, ScreenLoc.Y - TextSize.Y / 2 - BoxPadding.Y*Scale,
			TextSize.X + 2*BoxPadding.X*Scale, TextSize.Y + 2*BoxPadding.Y*Scale,
			Col);

	C.DrawColor = Col;
	C.SetPos(ScreenLoc.X - TextSize.X / 2, ScreenLoc.Y - TextSize.Y / 2);
	C.DrawText(HudText, false, Scale, Scale);
}

static simulated function DrawObjBoxBounds(Canvas C, int X, int Y, int W, int H, out Color Col)
{
	C.SetDrawColor(Col.R, Col.G, Col.B, Col.A / 2);
	C.SetPos(X+1, Y+1);
	C.DrawRect(1, H/4-1);
	C.SetPos(X+1, Y+1);
	C.DrawRect(W/4-1, 1);

	C.SetPos(X+W-W/4, Y+1);
	C.DrawRect(W/4-2, 1);
	C.SetPos(X+W-1, Y+1);
	C.DrawRect(1, H/4-1);

	C.SetPos(X+1, Y+H-H/4);
	C.DrawRect(1, H/4-1);
	C.SetPos(X+1, Y+H-1);
	C.DrawRect(W/4-1, 1);

	C.SetPos(X+W-W/4, Y+H-1);
	C.DrawRect(W/4-1, 1);
	C.SetPos(X+W-1, Y+H-H/4);
	C.DrawRect(1, H/4-1);


	C.DrawColor = Col;
	C.SetPos(X, Y);
	C.DrawRect(1, H/4);
	C.SetPos(X, Y);
	C.DrawRect(W/4, 1);

	C.SetPos(X+W-W/4, Y);
	C.DrawRect(W/4, 1);
	C.SetPos(X+W, Y);
	C.DrawRect(1, H/4);

	C.SetPos(X, Y+H-H/4);
	C.DrawRect(1, H/4);
	C.SetPos(X, Y+H);
	C.DrawRect(W/4, 1);

	C.SetPos(X+W-W/4,Y+H);
	C.DrawRect(W/4, 1);
	C.SetPos(X+W, Y+H-H/4);
	C.DrawRect(1, H/4);
}


defaultproperties
{
	ReachString="Continue to next waypoint"
	HudText="Waypoint"
	HudColor=(R=220,G=220,B=220,A=220)
	PreviewAlpha=0.4
	ForbiddenHudColor=(R=255,G=0,B=0,A=255)
	MaxHudDistance=12000
	BoxPadding=(X=8,Y=4)

	bAlwaysRelevant=true

	Begin Object Name=Sprite
		//TODO: custom icons
		Sprite=Texture2D'EditorResources.S_Trigger'
	End Object

	Begin Object Name=CollisionCylinder
		CollisionRadius=+0064.000000
		CollisionHeight=+0064.000000
	End Object

	bProjTarget=false
	bBlockActors=false
}
