//================================================================
// Trials.TTHud
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTHud extends CRZHud;

CONST BOARD_TITLEHEIGHT = 28;
CONST BOARD_LINEHEIGHT = 24;
CONST BOARD_PAD_Y = 12;
CONST BOARD_PAD_X = 12;

CONST COL_POS_WIDTH = 36;
CONST COL_TIME_WIDTH = 120;
CONST COL_POINTS_WIDTH = 40;
CONST COL_PLAYERS_WIDTH = 200;
var int RB_WIDTH;


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
	var sBoardLine head;
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

	RB_WIDTH = COL_POS_WIDTH + COL_TIME_WIDTH + COL_POINTS_WIDTH + COL_PLAYERS_WIDTH + 2*BOARD_PAD_X;

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
	Globalboard.grp.SetPosAuto("top:192; right:100%-32; width:"$RB_WIDTH);

	Globalboard.title = class'GUILabel'.static.CreateLabel(Globalboard.grp, "- MAP GLOBAL BOARD -");
	Globalboard.title.SetPosAuto("center-x:50%; width:100%; top:"$BOARD_PAD_Y);
	Globalboard.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	CreateLine(Globalboard.head, Globalboard.grp, -1, "RNK", "TIME", "PTS", "PLAYERS");
	UpdateGlobalboard(C);

	Levelboard.grp = class'GUIGroup'.static.CreateGroup(Root);
	Levelboard.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	Levelboard.grp.SetPosAuto("top:192; left:32; width:"$RB_WIDTH);

	Levelboard.title = class'GUILabel'.static.CreateLabel(Levelboard.grp, "- CURRENT LEVEL BOARD -");
	Levelboard.title.SetPosAuto("center-x:50%; width:100%; top:"$BOARD_PAD_Y);
	Levelboard.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	CreateLine(Levelboard.head, Levelboard.grp, -1, "RNK", "TIME", "PTS", "PLAYERS");
	UpdateLevelboard(C);
}

function UpdateGlobalboard(Canvas C)
{
	local int i;
	local String time;
	local sBoardLine line;

	// update existing lines
	for ( i=0; i<Globalboard.line.Length; i++ )
	{
		time = "<"@FormatTrialTime(GRI.Globalboard[i].TimeRangeLimit);
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

		CreateLine(line, Globalboard.grp, i,
			Right("0"$(i+1)$".",3),
			"<"@FormatTrialTime(GRI.Globalboard[i].TimeRangeLimit),
			class'TTGame'.static.PointsForGlobalRank(i),
			GRI.Globalboard[i].Players
		);

		Globalboard.line.Length = i+1;
		Globalboard.line[i] = line;

		FlashBoardLine(line.grp);
	}

	if ( Globalboard.line.Length > 0 )
		Globalboard.grp.SetPosAuto("height:" $ (Globalboard.line[Globalboard.line.Length-1].grp.offY.Val+BOARD_LINEHEIGHT+BOARD_PAD_Y));
	else
		Globalboard.grp.SetPosAuto("height:" $ (Globalboard.head.grp.offY.Val+BOARD_LINEHEIGHT+BOARD_PAD_Y));

	bUpdateGlobalboard = false;
}

function UpdateLevelboard(Canvas C)
{
	local TTPRI PRI;
	local int i;

	PRI = TTPRI(PlayerOwner.PlayerReplicationInfo);
	if ( PRI != None && PRI.CurrentLevel != None && GRI != None && PRI.CurrentLevel.LevelIdx < GRI.MAX_LEVELBOARDS )
	{
		// Just changed level - clear lines and rebuild the board
		if ( Levelboard.title.Text != PRI.CurrentLevel.LevelDisplayName )
		{
			Levelboard.title.Text = PRI.CurrentLevel.LevelDisplayName;
			for ( i=0; i<Levelboard.line.Length; i++ )
				Levelboard.line[i].grp.RemoveFromParent();
			Levelboard.line.Length = 0;
		}

		// update board
		Levelboard.grp.AlphaTo(1, 0.5, ANIM_LINEAR);
		__UpdateLevelboard(C, PRI.CurrentLevel.LevelIdx);
	}

	// Not in a level - hide the board
	else
		Levelboard.grp.AlphaTo(0, 0.5, ANIM_LINEAR);

	bUpdateLevelboard = false;
}

function __UpdateLevelboard(Canvas C, int Idx)
{
	local int i;
	local String time;
	local sBoardLine line;

	// update existing lines
	for ( i=0; i<Levelboard.line.Length; i++ )
	{
		time = "<"@FormatTrialTime(GRI.Levelboard[Idx].Board[i].TimeRangeLimit);
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

		CreateLine(line, Levelboard.grp, i,
			Right("0"$(i+1)$".",3),
			"<"@FormatTrialTime(GRI.Levelboard[Idx].Board[i].TimeRangeLimit),
			class'TTGame'.static.PointsForLevelRank(i),
			GRI.Levelboard[Idx].Board[i].Players
		);

		Levelboard.line.Length = i+1;
		Levelboard.line[i] = line;

		FlashBoardLine(line.grp);
	}

	if ( Levelboard.line.Length > 0 )
		Levelboard.grp.SetPosAuto("height:" $ (Levelboard.line[Levelboard.line.Length-1].grp.offY.Val+BOARD_LINEHEIGHT+BOARD_PAD_Y));
	else
		Levelboard.grp.SetPosAuto("height:" $ (Levelboard.head.grp.offY.Val+BOARD_LINEHEIGHT+BOARD_PAD_Y));
}

static function CreateLine(out sBoardLine line, GUIGroup Parent, int Pos, coerce String Rank, String Time, coerce String Points, String Players)
{
	local int x;

	Pos = Pos+1;    //shift because of head

	line.grp = class'GUIGroup'.static.CreateGroup(Parent);
	line.grp.SetPosAuto("center-x:50%; width:100%-"$(2*BOARD_PAD_X)$"; top:"$(BOARD_PAD_Y+BOARD_TITLEHEIGHT+Pos*BOARD_LINEHEIGHT)$"; height:"$BOARD_LINEHEIGHT);
	line.grp.SetColors(line.grp.TRANSPARENT, MakeColor(255,255,255,32));
	x = 0;

	line.pos = class'GUILabel'.static.CreateLabel(line.grp, Rank);
	line.pos.SetPosAuto("center-y:50%; left:"$x$"; width:"$COL_POS_WIDTH);
	line.pos.SetTextAlign(ALIGN_CENTER, ALIGN_MIDDLE);
	x += COL_POS_WIDTH;

	line.time = class'GUILabel'.static.CreateLabel(line.grp, Time);
	line.time.SetPosAuto("center-y:50%; left:"$x$"; width:"$COL_TIME_WIDTH);
	line.time.SetTextAlign(ALIGN_CENTER, ALIGN_MIDDLE);
	x += COL_TIME_WIDTH;

	line.points = class'GUILabel'.static.CreateLabel(line.grp, Points);
	line.points.SetPosAuto("center-y:50%; left:"$x$"; width:"$COL_POINTS_WIDTH);
	line.points.SetTextAlign(ALIGN_CENTER, ALIGN_MIDDLE);
	x += COL_POINTS_WIDTH;

	line.players = class'GUILabel'.static.CreateLabel(line.grp, Players);
	line.players.SetPosAuto("center-y:50%; left:"$x$"; width:"$COL_PLAYERS_WIDTH);
	line.players.SetTextAlign(ALIGN_LEFT, ALIGN_MIDDLE);
}

static function FlashBoardLine(GUIGroup line)
{
	line.ColorsTo(MakeColor(255,200,128,220), line.BoxColor.Val, 0.2, ANIM_LINEAR);
	line.QueueColors(line.TRANSPARENT, line.BoxColor.Val, 1.0, ANIM_LINEAR);
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
				LevelTimer.grp.AlphaTo(1, 0.5, ANIM_LINEAR);
			}
			else
				LevelTimer.grp.AlphaTo(0, 0.5, ANIM_LINEAR);
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
