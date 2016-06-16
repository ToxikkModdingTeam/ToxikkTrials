//================================================================
// Trials.TTHud
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTHud extends CRZHud;

CONST BOARD_WIDTH = 256;
CONST BOARD_LINEHEIGHT = 24;

var GameViewportClient Viewport;
var TTSpawnTree SpawnTree;
var TTGRI GRI;
var GUIRoot Root;

struct sTimerGroup
{
	var GUIGroup grp;
	var GUILabel title;
	var GUILabel timer;
};
var sTimerGroup GlobalTimer;
var sTimerGroup LevelTimer;

struct sBoardLine
{
	var GUIGroup grp;
	var GUILabel pos;
	var GUILabel time;
	var GUILabel points;
	var GUILabel players;
};
struct sRankBoard
{
	var GUIGroup grp;
	var GUILabel title;
	var array<sBoardLine> line;
};
var sRankBoard Globalboard;
var bool bUpdateGlobalboard;

var sRankBoard Levelboard;
var bool bUpdateLevelboard;

struct sLeaderboard
{
	var GUIGroup grp;
	var array<GUIGroup> line;
};
var sLeaderboard Leaderboard;
var bool bUpdateLeaderboard;


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	Viewport = LocalPlayer(PlayerOwner.Player).ViewportClient;
	SpawnTree = TTSpawnTree(CreateInteraction(class'TTSpawnTree'));
}

function Interaction CreateInteraction(class<Interaction> IntClass)
{
	local int i;
	local Interaction newInt;

	for ( i=0; i<PlayerOwner.Interactions.Length; i++ )
	{
		if ( PlayerOwner.Interactions[i].Class == IntClass )
			return PlayerOwner.Interactions[i];
	}

	newInt = new(Viewport) IntClass;
	Viewport.InsertInteraction(newInt, 0);
	PlayerOwner.Interactions.InsertItem(0, newInt);
	return newInt;
}

function CreateElements(Canvas C)
{
	// don't build until GRI is ready
	GRI = TTGRI(PlayerOwner.WorldInfo.GRI);
	if ( GRI == None )
		return;

	Root = class'GUIRoot'.static.Create(Self, Viewport);

	GlobalTimer.grp = class'GUIGroup'.static.CreateGroup(Root);
	GlobalTimer.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	GlobalTimer.grp.SetPosAuto("top:32; right:100%-32; width:200; height:64");

	GlobalTimer.title = class'GUILabel'.static.CreateLabel(GlobalTimer.grp, "- GLOBAL MAP TIME -");
	GlobalTimer.title.SetPosAuto("top:8; center-x:50%; width:100%");
	GlobalTimer.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	GlobalTimer.timer = class'GUIlabel'.static.CreateLabel(GlobalTimer.grp, FormatTrialTime(0));
	GlobalTimer.timer.SizeToFit(C);
	GlobalTimer.timer.SetPosAuto("bottom:100%-8; center-x:50%; width:100%");
	GlobalTimer.timer.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	LevelTimer.grp = class'GUIGroup'.static.CreateGroup(Root);
	LevelTimer.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	LevelTimer.grp.SetPosAuto("top:112; right:100%-32; width:200; height:64");

	LevelTimer.title = class'GUILabel'.static.CreateLabel(LevelTimer.grp, "- CURRENT LEVEL -");
	LevelTimer.title.SetPosAuto("top:8; center-x:50%; width:100%");
	LevelTimer.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	LevelTimer.timer = class'GUIlabel'.static.CreateLabel(LevelTimer.grp, FormatTrialTime(0));
	LevelTimer.timer.SizeToFit(C);
	LevelTimer.timer.SetPosAuto("bottom:100%-8; center-x:50%; width:100%");
	LevelTimer.timer.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	Globalboard.grp = class'GUIGroup'.static.CreateGroup(Root);
	Globalboard.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	Globalboard.grp.SetPosAuto("top:192; right:100%-32");

	Globalboard.title = class'GUILabel'.static.CreateLabel(Globalboard.grp, "- MAP GLOBAL BOARD -");
	Globalboard.title.SetPosAuto("top:0; center-x:50%; width:100%");
	Globalboard.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	UpdateGlobalboard(C);

	Levelboard.grp = class'GUIGroup'.static.CreateGroup(Root);
	Levelboard.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	Levelboard.grp.SetPosAuto("top:192; left:32");

	Levelboard.title = class'GUILabel'.static.CreateLabel(Globalboard.grp, "- CURRENT LEVEL BOARD -");
	Levelboard.title.SetPosAuto("top:0; center-x:50%; width:100%");
	Levelboard.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	UpdateLevelboard(C);
}

function UpdateGlobalboard(Canvas C)
{
	local int i;
	local String time;
	local GUIGroup line;

	// update existing lines
	for ( i=0; i<Globalboard.line.Length; i++ )
	{
		time = FormatTrialTime(GRI.Globalboard[i].TimeRangeLimit);
		if ( Globalboard.line[i].time.Text != time || Globalboard.line[i].players.Text != GRI.Globalboard[i].Players )
		{
			Globalboard.line[i].time.Text = time;
			Globalboard.line[i].players.Text = GRI.Globalboard[i].Players;

			FlashBoardLine(Globalboard.line[i].grp);
		}
	}

	// create new lines
	for ( i=i; i<GRI.GLOBALBOARD_SIZE; i++ )
	{
		if ( GRI.Globalboard[i].TimeRangeLimit <= 0 )
			break;

		Globalboard.line.Length = i+1;

		line = class'GUIGroup'.static.CreateGroup(Globalboard.grp);
		Globalboard.line[i].grp = line;
		line.SetPosAuto("left:0; top:"$(i*BOARD_LINEHEIGHT)$"; width:100%; height:"$BOARD_LINEHEIGHT);

		Globalboard.line[i].pos = class'GUILabel'.static.CreateLabel(line, i$".");
		Globalboard.line[i].pos.SetPosAuto("left:0; width:32; center-y:50%");

		Globalboard.line[i].time = class'GUILabel'.static.CreateLabel(line, FormatTrialTime(GRI.Globalboard[i].TimeRangeLimit));
		Globalboard.line[i].time.SetPosAuto("left:32; width:64; center-y:50%");

		Globalboard.line[i].points = class'GUILabel'.static.CreateLabel(line, class'TTGame'.static.PointsForGlobalRank(i));
		Globalboard.line[i].points.SetPosAuto("left:96; width:48; center-y:50%");

		Globalboard.line[i].players = class'GUILabel'.static.CreateLabel(line, GRI.Globalboard[i].Players);
		Globalboard.line[i].players.SetPosAuto("left:144; right:100%; center-y:50%");

		FlashBoardLine(line);
	}

	if ( Globalboard.line.Length > 0 )
		Globalboard.grp.SetPosAuto("height:" $ (Globalboard.line[Globalboard.line.Length-1].grp.offY.Val+BOARD_LINEHEIGHT));

	bUpdateGlobalboard = false;
}

static function FlashBoardLine(GUIGroup line)
{
	line.ColorsTo(MakeColor(255,255,255,200), MakeColor(255,255,0,255), 0.2, ANIM_LINEAR);
	line.QueueColors(line.TRANSPARENT, MakeColor(255,255,255,64), 0.5, ANIM_LINEAR);
}

function UpdateLevelboard(Canvas C)
{
	local TTPRI PRI;

	PRI = TTPRI(PlayerOwner.PlayerReplicationInfo);
	if ( PRI != None && PRI.CurrentLevel != None && GRI != None && PRI.CurrentLevel.LevelIdx < GRI.MAX_LEVELBOARDS )
	{
		if ( Levelboard.title.Text != PRI.CurrentLevel.LevelDisplayName )
		{
			Levelboard.title.Text = PRI.CurrentLevel.LevelDisplayName;
			Levelboard.grp.Clear();
			Levelboard.line.Length = 0;
		}
		__UpdateLevelboard(C, PRI.CurrentLevel.LevelIdx);
	}
	else if ( Levelboard.line.Length > 0 )
	{
		Levelboard.grp.Clear();
		Levelboard.line.Length = 0;
		Levelboard.grp.SetPosAuto("height:0");
	}
	bUpdateLevelboard = false;
}

function __UpdateLevelboard(Canvas C, int Idx)
{
	local int i;
	local String time;
	local GUIGroup line;

	// update existing lines
	for ( i=0; i<Levelboard.line.Length; i++ )
	{
		time = FormatTrialTime(GRI.Levelboard[Idx].Board[i].TimeRangeLimit);
		if ( Levelboard.line[i].time.Text != time || Levelboard.line[i].players.Text != GRI.Levelboard[Idx].Board[i].Players )
		{
			Levelboard.line[i].time.Text = time;
			Levelboard.line[i].players.Text = GRI.Levelboard[Idx].Board[i].Players;

			FlashBoardLine(Levelboard.line[i].grp);
		}
	}

	// create new lines
	for ( i=i; i<GRI.LEVELBOARD_SIZE; i++ )
	{
		if ( GRI.Levelboard[Idx].Board[i].TimeRangeLimit <= 0 )
			break;

		Levelboard.line.Length = i+1;

		line = class'GUIGroup'.static.CreateGroup(Levelboard.grp);
		Levelboard.line[i].grp = line;
		line.SetPosAuto("left:0; top:"$(i*BOARD_LINEHEIGHT)$"; width:100%; height:"$BOARD_LINEHEIGHT);

		Levelboard.line[i].pos = class'GUILabel'.static.CreateLabel(line, i$".");
		Levelboard.line[i].pos.SetPosAuto("left:0; width:32; center-y:50%");

		Levelboard.line[i].time = class'GUILabel'.static.CreateLabel(line, FormatTrialTime(GRI.Levelboard[Idx].Board[i].TimeRangeLimit));
		Levelboard.line[i].time.SetPosAuto("left:32; width:64; center-y:50%");

		Levelboard.line[i].points = class'GUILabel'.static.CreateLabel(line, class'TTGame'.static.PointsForGlobalRank(i));
		Levelboard.line[i].points.SetPosAuto("left:96; width:48; center-y:50%");

		Levelboard.line[i].players = class'GUILabel'.static.CreateLabel(line, GRI.Levelboard[Idx].Board[i].Players);
		Levelboard.line[i].players.SetPosAuto("left:144; right:100%; center-y:50%");

		FlashBoardLine(line);
	}

	if ( Levelboard.line.Length > 0 )
		Levelboard.grp.SetPosAuto("height:" $ (Levelboard.line[Levelboard.line.Length-1].grp.offY.Val+BOARD_LINEHEIGHT));
}

function UpdateLeaderboard(Canvas C)
{
	//TODO:
	bUpdateLeaderboard = false;
}


simulated event Tick(float dt)
{
	local UTPawn P;
	local TTPRI PRI;
	local int Now;

 	Super.Tick(dt);

	//NOTE: fix-workaround for pawn landing issue (clientside-only)
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
	if ( Root != None )
	{
		if ( bUpdateGlobalboard )
			UpdateGlobalboard(Canvas);
		if ( bUpdateLevelboard )
			UpdateLevelboard(Canvas);
		if ( bUpdateLeaderboard )
			UpdateLeaderboard(Canvas);

		Root.PostRender(Canvas);
	}
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
