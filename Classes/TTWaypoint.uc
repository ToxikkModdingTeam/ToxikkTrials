//================================================================
// Trials.TTWaypoint
// ----------------
// Just a base class for all waypoints
// - Forces path
// ----------------
// by Chatouille
//================================================================
class TTWaypoint extends Trigger
	placeable
	ClassGroup(Trials);

var(Waypoint) String ReachString;
var(Waypoint) array<TTWaypoint> NextPoints;

/** internal - list of waypoints pointing to me */
var array<TTWaypoint> PreviousPoints;

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
	for ( i=0; i<GRI.AllPoints.Length; i++ )
		for ( j=0; j<GRI.AllPoints[i].NextPoints.Length; j++ )
			if ( GRI.AllPoints[i].NextPoints[j] == Self )
				PreviousPoints.AddItem(GRI.AllPoints[i]);

	if ( WorldInfo.NetMode != NM_DedicatedServer )
		SetTimer(0.1, false, 'WaitForLocalPC');
}

simulated function WaitForLocalPC()
{
	local PlayerController PC;

	foreach WorldInfo.LocalPlayerControllers(class'PlayerController', PC)
	{
		FoundLocalPC(PC);
		return;
	}
	SetTimer(0.1, false, 'WaitForLocalPC');
}

simulated function FoundLocalPC(PlayerController PC)
{
	PC.myHUD.AddPostRenderedActor(Self);
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);

	if ( CRZPawn(Other) != None && TTGame(WorldInfo.Game) != None )
		TTGame(WorldInfo.Game).PawnTouchedWaypoint(CRZPawn(Other), Self);
}

/** Called by the gamemode (simulated only for the reacher!) */
simulated function ReachedBy(CRZPawn P)
{
	NotifyPlayer(P);
	UpdatePlayerTargets(P);
}

simulated function NotifyPlayer(CRZPawn P)
{
	if ( PlayerController(P.Controller) != None && CRZHud(PlayerController(P.Controller).myHUD) != None )
		CRZHud(PlayerController(P.Controller).myHUD).LocalizedCRZMessage(class'TTWaypointMessage', P.PlayerReplicationInfo, None, ReachString, 0, Self);
}

simulated function UpdatePlayerTargets(CRZPawn P)
{
	local TTPRI PRI;
	local int i,j,k;

	PRI = TTPRI(P.PlayerReplicationInfo);
	if ( PRI != None )
	{
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
}


// How to handle display ??
//  - show current target waypoint, always
//  - show next waypoint IIF it's a same-or-higher level waypoint
// display of parallel paths ??
//  - ???
//  - profit

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

/*
	if ( CamDir Dot Normal(Location - CamPos) < 0 )
		return;
*/

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

	bProjTarget=false
	bBlockActors=false
}
