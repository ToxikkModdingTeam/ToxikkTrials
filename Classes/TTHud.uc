//================================================================
// Trials.TTHud
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTHud extends CRZHud;

CONST COL_POS_WIDTH = 36;
CONST COL_TIME_WIDTH = 120;
CONST COL_POINTS_WIDTH = 48;
CONST COL_PLAYERS_WIDTH = 200;

CONST COL_TOTAL_WIDTH = 80;
CONST COL_NAME_WIDTH = 140;

CONST STANDING_TIME = 2.0;


var GameViewportClient Viewport;
var TTGRI GRI;

var TTSpawnTree SpawnTree;
var TTKeytracker Keytracker;

var GUIRoot Root;

struct sTimerGroup
{
	var GUIGroup grp;
	var GUILabel title;
	var GUILabel timer;
};
var sTimerGroup GlobalTimer;
var sTimerGroup LevelTimer;


var GUIBoard Globalboard;
var bool bUpdateGlobalboard;

var GUIBoard Levelboard;
var bool bUpdateLevelboard;

var GUIBoard Leaderboard;
var bool bUpdateLeaderboard;

var Vector PreviousPos;
var float TimeStanding;

var enum eTTDisplayMode
{
	TTDM_Timers,
	TTDM_Boards,
	TTDM_Dead,
} CurrentDisplayMode;


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	Viewport = LocalPlayer(PlayerOwner.Player).ViewportClient;
	SpawnTree = TTSpawnTree(CreateInteraction(class'TTSpawnTree'));
	Keytracker = TTKeytracker(CreateInteraction(class'TTKeytracker'));
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

	Globalboard = class'GUIBoard'.static.CreateBoard(Root, "- MAP TIME RANKS -");
	Globalboard.SetPosAuto("right:100%-32; top:112");
	Globalboard.AddColumn("RNK", COL_POS_WIDTH, ALIGN_CENTER);
	Globalboard.AddColumn("TIME", COL_TIME_WIDTH, ALIGN_CENTER);
	Globalboard.AddColumn("PTS", COL_POINTS_WIDTH, ALIGN_CENTER);
	Globalboard.AddColumn("PLAYERS", COL_PLAYERS_WIDTH, ALIGN_LEFT);
	bUpdateGlobalboard = true;

	Levelboard = class'GUIBoard'.static.CreateBoard(Root, "- CURRENT LEVEL RANKS -");
	Levelboard.SetPosAuto("right:100%-32; top:" $ (Root.CurTargetFloat(Globalboard.offY) + Root.CurTargetFloat(Globalboard.offH) + 16));
	Levelboard.AddColumn("RNK", COL_POS_WIDTH, ALIGN_CENTER);
	Levelboard.AddColumn("TIME", COL_TIME_WIDTH, ALIGN_CENTER);
	Levelboard.AddColumn("PTS", COL_POINTS_WIDTH, ALIGN_CENTER);
	Levelboard.AddColumn("PLAYERS", COL_PLAYERS_WIDTH, ALIGN_LEFT);
	Levelboard.iData.AddItem(-1);
	bUpdateLevelboard = true;

	Leaderboard = class'GUIBoard'.static.CreateBoard(Root, "- GLOBAL LEADERBOARD -");
	Leaderboard.SetPosAuto("left:32; center-y:50%");
	Leaderboard.AddColumn("POS", COL_POS_WIDTH, ALIGN_CENTER);
	Leaderboard.AddColumn("TOTAL", COL_TOTAL_WIDTH, ALIGN_CENTER);
	Leaderboard.AddColumn("PLAYER", COL_NAME_WIDTH, ALIGN_LEFT);
	bUpdateLeaderboard = true;

	SetDisplayMode(TTDM_Dead);
}

function CreateTimerGroup(Canvas C, out sTimerGroup Group, String Title, String PosAuto)
{
	Group.grp = class'GUIGroup'.static.CreateGroup(Root);
	Group.grp.SetColors(class'GUIBoard'.default.BgColor.Val, Root.TRANSPARENT);
	Group.grp.SetPosAuto(PosAuto);

	Group.title = class'GUILabel'.static.CreateLabel(Group.grp, Title);
	Group.title.SetPosAuto("top:8; center-x:50%; width:100%");
	Group.title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);
	Group.title.SetTextColor(class'GUIBoard'.default.TitleColor);

	Group.timer = class'GUIlabel'.static.CreateLabel(Group.grp, FormatTrialTime(0));
	Group.timer.SizeToFit(C);
	Group.timer.SetPosAuto("bottom:100%-8; center-x:50%; width:100%");
	Group.timer.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);
}

function UpdateGlobalboard()
{
	local int i;
	local array<String> data;

	data.Length = 4;
	for ( i=0; i<GRI.GLOBALBOARD_SIZE; i++ )
	{
		if ( GRI.Globalboard[i].TimeRangeLimit <= 0 )
			break;

		data[0] = Right("0"$(i+1)$".",3);
		data[1] = /*"<"@*/FormatTrialTime(GRI.Globalboard[i].TimeRangeLimit);
		data[2] = ""$class'TTGame'.static.PointsForGlobalRank(i);
		data[3] = GRI.Globalboard[i].Players;

		if ( Globalboard.lines.Length > i )
			Globalboard.UpdateLine(i, data);
		else
		{
			Globalboard.AddLine(data);
			Levelboard.MoveToAuto("y:" $ (Root.CurTargetFloat(Globalboard.offY) + Root.CurTargetFloat(Globalboard.offH) + 16), 0.25, ANIM_EASE_IN);
		}
	}

	bUpdateGlobalboard = false;
}

function UpdateLevelboard()
{
	local TTPRI PRI;
	local int Idx, i;
	local array<String> data;

	PRI = TTPRI(PlayerOwner.PlayerReplicationInfo);
	if ( PRI != None && PRI.CurrentLevel != None && GRI != None && PRI.CurrentLevel.LevelIdx < GRI.MAX_LEVELBOARDS )
	{
		Idx = PRI.CurrentLevel.LevelIdx;

		// Just changed level - clear lines and rebuild the board
		if ( Levelboard.iData[0] != Idx )
		{
			Levelboard.SetTitle("-" @ PRI.CurrentLevel.LevelDisplayName @ "-");
			Levelboard.FlashColors(MakeColor(255,200,128,220), Levelboard.TRANSPARENT);
			Levelboard.Empty();
		}

		data.Length = 4;
		for ( i=0; i<GRI.LEVELBOARD_SIZE; i++ )
		{
			if ( GRI.Levelboard[Idx].Board[i].TimeRangeLimit <= 0 )
				break;

			data[0] = Right("0"$(i+1)$".",3);
			data[1] = /*"<"@*/FormatTrialTime(GRI.Levelboard[Idx].Board[i].TimeRangeLimit);
			data[2] = ""$class'TTGame'.static.PointsForLevelRank(i);
			data[3] = GRI.Levelboard[Idx].Board[i].Players;

			if ( Levelboard.lines.Length > i )
				Levelboard.UpdateLine(i, data);
			else
				Levelboard.AddLine(data);

			if ( CurrentDisplayMode != TTDM_Timers )
				Levelboard.AlphaTo(1, 0.5, ANIM_EASE_IN);
		}
	}

	// Not in a level - hide the board
	else
		Levelboard.AlphaTo(0, 0.5, ANIM_EASE_OUT);

	bUpdateLevelboard = false;
}

function UpdateLeaderboard()
{
	local int i;
	local array<String> data;

	data.Length = 3;
	for ( i=0; i<GRI.LEADERBOARD_SIZE; i++ )
	{
		if ( GRI.Leaderboard[i].Points <= 0 )
			break;

		data[0] = Right("0"$(i+1)$".", 3);
		data[1] = ""$GRI.Leaderboard[i].Points;
		data[2] = ""$GRI.Leaderboard[i].Name;

		if ( Leaderboard.lines.Length > i )
			Leaderboard.UpdateLine(i, data);
		else
			Leaderboard.AddLine(data);
	}

	bUpdateLeaderboard = false;
}

function GlobalTimerChanged(TTPRI PRI)
{
	if ( PRI.bStopGlobal && PRI.CurrentLevel == None && CurrentDisplayMode == TTDM_Timers )
		SetDisplayMode(TTDM_Boards);
	else if ( PRI.bStopGlobal )
		GlobalTimer.grp.AlphaTo(0, 0.5, ANIM_EASE_OUT);
	else if ( CurrentDisplayMode != TTDM_Boards )
		GlobalTimer.grp.AlphaTo(1, 0.5, ANIM_EASE_IN);
}

function LevelChanged(TTPRI PRI)
{
	if ( Root == None )
		return;

	if ( PRI.CurrentLevel != None )
	{
		LevelTimer.title.Text = "-" @ PRI.CurrentLevel.LevelDisplayName @ "-";
		LevelTimer.title.FlashColors(MakeColor(255,200,128,220), LevelTimer.title.TRANSPARENT);
		if ( CurrentDisplayMode == TTDM_Timers )
			LevelTimer.grp.AlphaTo(1, 0.5, ANIM_EASE_IN);
	}
	else
		LevelTimer.grp.AlphaTo(0, 0.5, ANIM_EASE_OUT);

	bUpdateLevelboard = true;
}

simulated event Tick(float dt)
{
	local UTPawn P;
	local TTPRI PRI;
	local int Now;

 	Super.Tick(dt);

	P = UTPawn(PlayerOwner.Pawn);

	//NOTE: fix-workaround for pawn landing issue (clientside-only)
	/* Experimenting in TTPawn now
	if ( P != None && P.Physics == PHYS_Walking && P.MultiJumpRemaining < P.MaxMultiJump )
		P.Landed(Vect(0,0,1), P.Base);
	*/

	if ( Root != None )
	{
		PRI = TTPRI(PlayerOwner.PlayerReplicationInfo);
		if ( PRI != None )
		{
			// Update timers time
			Now = PRI.CurrentTimeMillis();
			GlobalTimer.timer.Text = FormatTrialTime(Now - PRI.GlobalStartDate);
			LevelTimer.timer.Text = FormatTrialTime(Now - PRI.LevelStartDate);

			// Switch displaymodes
			if ( P == None || P.IsInState('Dead') )
				SetDisplayMode(TTDM_Dead);
			else if ( PRI.bStopGlobal && PRI.CurrentLevel == None )
				SetDisplayMode(TTDM_Boards);
			else if ( P.Location == PreviousPos )
			{
				TimeStanding += dt;
				if ( TimeStanding > STANDING_TIME )
					SetDisplayMode(TTDM_Boards);
			}
			else
			{
				SetDisplayMode(TTDM_Timers);
				TimeStanding = 0;
				PreviousPos = P.Location;
			}
		}
		Root.Tick(dt);
	}
}

function SetDisplayMode(eTTDisplayMode Mode)
{
	local TTPRI PRI;

	if ( CurrentDisplayMode == Mode )
		return;
	CurrentDisplayMode = Mode;

	PRI = TTPRI(PlayerOwner.PlayerReplicationInfo);
	Switch (Mode)
	{
		// normal state - show the two timers
		case TTDM_Timers:
			if ( PRI != None && !PRI.bStopGlobal ) GlobalTimer.grp.AlphaTo(1, 0.5, ANIM_EASE_IN);
			if ( PRI != None && PRI.CurrentLevel != None ) LevelTimer.grp.AlphaTo(1, 0.5, ANIM_EASE_IN);
			Globalboard.AlphaTo(0, 0.3, ANIM_EASE_OUT);
			Levelboard.AlphaTo(0, 0.3, ANIM_EASE_OUT);
			Leaderboard.AlphaTo(0, 0.3, ANIM_EASE_OUT);
			break;

		// standing still - hide timers and show boards
		case TTDM_Boards:
			GlobalTimer.grp.AlphaTo(0, 0.3, ANIM_EASE_OUT);
			LevelTimer.grp.AlphaTo(0, 0.3, ANIM_EASE_OUT);
			Globalboard.AlphaTo(1, 0.5, ANIM_EASE_IN);
			if ( PRI != None && PRI.CurrentLevel != None ) Levelboard.AlphaTo(1, 0.5, ANIM_EASE_IN);
			Leaderboard.AlphaTo(1, 0.5, ANIM_EASE_IN);
			break;

		// dead - hide level timer, show everything else
		//TODO: show levelboard in real time when we select level in SpawnTree
		case TTDM_Dead:
			if ( PRI != None && !PRI.bStopGlobal ) GlobalTimer.grp.AlphaTo(1, 0.5, ANIM_EASE_IN);
			LevelTimer.grp.AlphaTo(0, 0.3, ANIM_EASE_OUT);
			Globalboard.AlphaTo(1, 0.5, ANIM_EASE_IN);
			if ( PRI != None && PRI.CurrentLevel != None ) Levelboard.AlphaTo(1, 0.5, ANIM_EASE_IN);
			Leaderboard.AlphaTo(1, 0.5, ANIM_EASE_IN);
			break;
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
			UpdateGlobalboard();
		if ( bUpdateLevelboard )
			UpdateLevelboard();
		if ( bUpdateLeaderboard )
			UpdateLeaderboard();

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
