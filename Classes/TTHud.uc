//================================================================
// Trials.TTHud
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTHud extends CRZHud;

var GameViewportClient Viewport;
var TTSpawnTree SpawnTree;

var GUIRoot Root;

struct sTimerGroup
{
	var GUIGroup grp;
	var GUILabel title;
	var GUILabel timer;
};
var sTimerGroup LevelTimer;
var sTimerGroup GlobalTimer;


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	Viewport = LocalPlayer(PlayerOwner.Player).ViewportClient;
	SpawnTree = TTSpawnTree(CreateInteraction(class'TTSpawnTree'));
}

function Interaction CreateInteraction(class<Interaction> IntClass)
{
	local Interaction newInt;

	newInt = new(Viewport) IntClass;
	Viewport.InsertInteraction(newInt, 0);
	PlayerOwner.Interactions.InsertItem(0, newInt);
	return newInt;
}

function CreateElements(Canvas C)
{
	Root = class'GUIRoot'.static.Create(Self, Viewport);

	GlobalTimer.grp = class'GUIGroup'.static.CreateGroup(Root);
	GlobalTimer.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	GlobalTimer.grp.SetPosAuto("top:32; right:100%-32; width:200; height:64");

	GlobalTimer.title = class'GUILabel'.static.CreateLabel(GlobalTimer.grp, "- GLOBAL MAP TIME -");
	GlobalTimer.title.SetPosAuto("top:8; center-x:50%; width:100%");
	GlobalTimer.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	GlobalTimer.timer = class'GUIlabel'.static.CreateLabel(GlobalTimer.grp, FormatTrialTime(0));
	GlobalTimer.timer.SizeToFit(C);
	GlobalTimer.timer.SetPosAuto("bottom:100%-8; center-x:50%");

	LevelTimer.grp = class'GUIGroup'.static.CreateGroup(Root);
	LevelTimer.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	LevelTimer.grp.SetPosAuto("top:112; right:100%-32; width:200; height:64");

	LevelTimer.title = class'GUILabel'.static.CreateLabel(LevelTimer.grp, "- CURRENT LEVEL -");
	LevelTimer.title.SetPosAuto("top:8; center-x:50%; width:100%");
	LevelTimer.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	LevelTimer.timer = class'GUIlabel'.static.CreateLabel(LevelTimer.grp, FormatTrialTime(0));
	LevelTimer.timer.SizeToFit(C);
	LevelTimer.timer.SetPosAuto("bottom:100%-8; center-x:50%");
}

simulated event Tick(float dt)
{
	local UTPawn P;
	local TTPRI PRI;
	local int Now;

 	Super.Tick(dt);

	// fix-workaround for pawn landing issue (it's a clientside-only fix)
	P = UTPawn(PlayerOwner.Pawn);
	if ( P != None && P.Physics == PHYS_Walking && P.MultiJumpRemaining < P.MaxMultiJump )
		P.Landed(Vect(0,0,1), P.Base);

	if ( Root != None )
	{
		PRI = TTPRI(PlayerOwner.PlayerReplicationInfo);
		if ( PRI != None )
		{
			Now = PRI.CurrentTimeMillis();
			GlobalTimer.timer.Text = FormatTrialTime(Now - PRI.GlobalStartDate);
			LevelTimer.timer.Text = FormatTrialTime(Now - PRI.LevelStartDate);
			if ( PRI.CurrentLevel != None )
			{
				LevelTimer.title.Text = PRI.CurrentLevel.LevelDisplayName;
				LevelTimer.grp.SetAlpha(1);
			}
			else
				LevelTimer.grp.SetAlpha(0);
		}
		Root.Tick(dt);
	}
}

event PostRender()
{
	Super.PostRender();

	if ( Root == None )
		CreateElements(Canvas);

	Root.PostRender(Canvas);
}


exec function PlaceCustomSpawn()
{
	if ( TTPRI(PlayerOwner.PlayerReplicationInfo) != None )
		TTPRI(PlayerOwner.PlayerReplicationInfo).ServerPlaceCustomSpawn();
}

exec function RemoveCustomSpawn()
{
	if ( TTPRI(PlayerOwner.PlayerReplicationInfo) != None )
		TTPRI(PlayerOwner.PlayerReplicationInfo).ServerRemoveCustomSpawn();
}


static function String FormatTrialTime(int Millis)
{
	local int h, m, s, ms;
	h = Millis / 3600000;
	Millis = Millis % 3600000;
	m = Millis / 60000;
	Millis = Millis % 60000;
	s = Millis / 1000;
	ms = Millis % 1000;
	return (h > 0 ? (Right("0"$h,2)$":") : "") $ Right("0"$m,2) $ ":" $ Right("0"$s,2) $ "." $ Left(Right("00"$ms,3),2);
}


defaultproperties
{
	HUDClass=class'TTHudMovie'
	ScoreBoardClass=class'TTScoreboard'
}
