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

CONST COL_TOTAL_WIDTH = 64;
CONST COL_NAME_WIDTH = 160;
var int LB_WIDTH;


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
	var array<GUILabel> col;
};
struct sBoard
{
	var GUIGroup grp;
	var GUILabel title;
	var sBoardLine head;
	var array<sBoardLine> line;
};
var sBoard Globalboard;
var bool bUpdateGlobalboard;

var sBoard Levelboard;
var bool bUpdateLevelboard;

var sBoard Leaderboard;
var bool bUpdateLeaderboard;


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	RB_WIDTH = COL_POS_WIDTH + COL_TIME_WIDTH + COL_POINTS_WIDTH + COL_PLAYERS_WIDTH + 2*BOARD_PAD_X;
	LB_WIDTH = COL_POS_WIDTH + COL_TOTAL_WIDTH + COL_NAME_WIDTH + 2*BOARD_PAD_X;

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

	CreateTimerGroup(C, GlobalTimer, "- GLOBAL MAP TIME -", "top:32; right:100%-32; width:200; height:64");

	CreateTimerGroup(C, LevelTimer, "- CURRENT LEVEL -", "top:112; right:100%-32; width:200; height:64");

	CreateBoard(Globalboard, "- MAP TIME RANKS -", "top:192; right:100%-32; width:"$RB_WIDTH);
	CreateRankLine(Globalboard.head, Globalboard.grp, -1, "RNK", "TIME", "PTS", "PLAYERS");
	bUpdateGlobalboard = true;

	CreateBoard(Levelboard, "- CURRENT LEVEL RANKS -", "top:192; left:32; width:"$RB_WIDTH);
	CreateRankLine(Levelboard.head, Levelboard.grp, -1, "RNK", "TIME", "PTS", "PLAYERS");
	bUpdateLevelboard = true;

	CreateBoard(Leaderboard, "- GLOBAL LEADERBOARD -", "bottom:80%; right:100%-32; width:"$LB_WIDTH);
	CreatePlayerLine(Leaderboard.head, Leaderboard.grp, -1, "POS", "POINTS", "PLAYER");
	bUpdateLeaderboard = true;
}

function CreateTimerGroup(Canvas C, out sTimerGroup Group, String Title, String PosAuto)
{
	Group.grp = class'GUIGroup'.static.CreateGroup(Root);
	Group.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	Group.grp.SetPosAuto(PosAuto);

	Group.title = class'GUILabel'.static.CreateLabel(Group.grp, Title);
	Group.title.SetPosAuto("top:8; center-x:50%; width:100%");
	Group.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

	Group.timer = class'GUIlabel'.static.CreateLabel(Group.grp, FormatTrialTime(0));
	Group.timer.SizeToFit(C);
	Group.timer.SetPosAuto("bottom:100%-8; center-x:50%; width:100%");
	Group.timer.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);
}

function CreateBoard(out sBoard Board, String Title, String PosAuto)
{
	Board.grp = class'GUIGroup'.static.CreateGroup(Root);
	Board.grp.SetColors(MakeColor(0,0,0,128), Root.TRANSPARENT);
	Board.grp.SetPosAuto(PosAuto);

	Board.title = class'GUILabel'.static.CreateLabel(Board.grp, Title);
	Board.title.SetPosAuto("center-x:50%; width:100%; top:"$BOARD_PAD_Y);
	Board.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);
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
		if ( Globalboard.line[i].col[1].Text != time || Globalboard.line[i].col[3].Text != GRI.Globalboard[i].Players )
		{
			Globalboard.line[i].col[1].Text = time;
			Globalboard.line[i].col[3].Text = GRI.Globalboard[i].Players;

			FlashBoardLine(Globalboard.line[i].grp);
		}
	}

	// create new lines
	for ( i=i; i<GRI.GLOBALBOARD_SIZE; i++ )
	{
		if ( GRI.Globalboard[i].TimeRangeLimit <= 0 )
			break;

		CreateRankLine(line, Globalboard.grp, i,
			Right("0"$(i+1)$".",3),
			"<"@FormatTrialTime(GRI.Globalboard[i].TimeRangeLimit),
			class'TTGame'.static.PointsForGlobalRank(i),
			GRI.Globalboard[i].Players
		);

		Globalboard.line.Length = i+1;
		Globalboard.line[i] = line;
		FlashBoardLine(line.grp);
	}

	RecalcBoardHeight(Globalboard);

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
		if ( Levelboard.line[i].col[1].Text != time || Levelboard.line[i].col[3].Text != GRI.Levelboard[Idx].Board[i].Players )
		{
			Levelboard.line[i].col[1].Text = time;
			Levelboard.line[i].col[3].Text = GRI.Levelboard[Idx].Board[i].Players;
			FlashBoardLine(Levelboard.line[i].grp);
		}
	}

	// create new lines
	for ( i=i; i<GRI.LEVELBOARD_SIZE; i++ )
	{
		if ( GRI.Levelboard[Idx].Board[i].TimeRangeLimit <= 0 )
			break;

		CreateRankLine(line, Levelboard.grp, i,
			Right("0"$(i+1)$".",3),
			"<"@FormatTrialTime(GRI.Levelboard[Idx].Board[i].TimeRangeLimit),
			class'TTGame'.static.PointsForLevelRank(i),
			GRI.Levelboard[Idx].Board[i].Players
		);

		Levelboard.line.Length = i+1;
		Levelboard.line[i] = line;
		FlashBoardLine(line.grp);
	}

	RecalcBoardHeight(Levelboard);
}

function UpdateLeaderboard(Canvas C)
{
	local int i;
	local String pts;
	local sBoardLine line;

	// update existing lines
	for ( i=0; i<Leaderboard.line.Length; i++ )
	{
		pts = String(GRI.Leaderboard[i].Points);
		if ( Leaderboard.line[i].col[1].Text != pts || Leaderboard.line[i].col[2].Text != GRI.Leaderboard[i].Name )
		{
			Leaderboard.line[i].col[1].Text = pts;
			Leaderboard.line[i].col[2].Text = GRI.Leaderboard[i].Name;
			FlashBoardLine(Leaderboard.line[i].grp);
		}
	}

	// create new lines
	for ( i=i; i<GRI.LEADERBOARD_SIZE; i++ )
	{
		if ( GRI.Leaderboard[i].Points <= 0 )
			break;

		CreatePlayerLine(line, Leaderboard.grp, i,
			Right("0"$(i+1)$".", 3),
			GRI.Leaderboard[i].Points,
			GRI.Leaderboard[i].Name
		);

		Leaderboard.line.Length = i+1;
		Leaderboard.line[i] = line;
		FlashBoardLine(Leaderboard.line[i].grp);
	}

	RecalcBoardHeight(Leaderboard);

	bUpdateLeaderboard = false;
}

static function CreateRankLine(out sBoardLine line, GUIGroup Parent, int Pos, String Rank, String Time, coerce String Points, String Players)
{
	local int x;

	Pos = Pos+1;    //shift because of head
	line.grp = class'GUIGroup'.static.CreateGroup(Parent);
	line.grp.SetPosAuto("center-x:50%; width:100%-"$(2*BOARD_PAD_X)$"; top:"$(BOARD_PAD_Y+BOARD_TITLEHEIGHT+Pos*BOARD_LINEHEIGHT)$"; height:"$BOARD_LINEHEIGHT);
	line.grp.SetColors(line.grp.TRANSPARENT, MakeColor(255,255,255,32));

	line.col.Length = 0;
	x = 0;
	AddColumn(line, x, Rank, COL_POS_WIDTH, ALIGN_CENTER);
	AddColumn(line, x, Time, COL_TIME_WIDTH, ALIGN_CENTER);
	AddColumn(line, x, Points, COL_POINTS_WIDTH, ALIGN_CENTER);
	AddColumn(line, x, Players, COL_PLAYERS_WIDTH, ALIGN_LEFT);
}

static function CreatePlayerLine(out sBoardLine line, GUIGroup Parent, int Pos, String Rank, coerce String Total, String PlayerName)
{
	local int x;

	Pos = Pos+1;
	line.grp = class'GUIGroup'.static.CreateGroup(Parent);
	line.grp.SetPosAuto("center-x:50%; width:100%-"$(2*BOARD_PAD_X)$"; top:"$(BOARD_PAD_Y+BOARD_TITLEHEIGHT+Pos*BOARD_LINEHEIGHT)$"; height:"$BOARD_LINEHEIGHT);
	line.grp.SetColors(line.grp.TRANSPARENT, MakeColor(255,255,255,32));

	line.col.Length = 0;
	x = 0;
	AddColumn(line, x, Rank, COL_POS_WIDTH, ALIGN_CENTER);
	AddColumn(line, x, Total, COL_TOTAL_WIDTH, ALIGN_CENTER);
	AddColumn(line, x, PlayerName, COL_NAME_WIDTH, ALIGN_LEFT);
}

static function AddColumn(out sBoardLine line, out int x, String Text, int Width, eHorAlignment hAlign)
{
	local GUILabel lbl;

	lbl = class'GUILabel'.static.CreateLabel(line.grp, Text);
	lbl.SetPosAuto("center-y:50%; left:"$x$"; width:"$Width);
	lbl.SetTextAlign(hAlign, ALIGN_MIDDLE);
	line.col.AddItem(lbl);
	x += Width;
}

static function FlashBoardLine(GUIGroup line)
{
	line.ColorsTo(MakeColor(255,200,128,220), line.BoxColor.Val, 0.2, ANIM_LINEAR);
	line.QueueColors(line.TRANSPARENT, line.BoxColor.Val, 1.0, ANIM_LINEAR);
}

static function RecalcBoardHeight(out sBoard Board)
{
	if ( Board.line.Length > 0 )
		Board.grp.SetPosAuto("height:" $ (Board.line[Board.line.Length-1].grp.offY.Val+BOARD_LINEHEIGHT+BOARD_PAD_Y));
	else
		Board.grp.SetPosAuto("height:" $ (Board.head.grp.offY.Val+BOARD_LINEHEIGHT+BOARD_PAD_Y));
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
