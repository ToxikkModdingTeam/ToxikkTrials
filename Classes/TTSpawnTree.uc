//================================================================
// Trials.TTSpawnTree
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTSpawnTree extends Interaction;

var GameViewportClient Viewport;
var PlayerController PC;
var TTPRI PRI;
var GUIRoot Root;
var bool bShow;
var bool bRebuild;

var GUIGroup Panel;

struct sTreeNode
{
	var TTSavepoint Savepoint;
	var int Depth, Row;
	var GUIButton btn;
	var array<int> LinkTo;
};
var array<sTreeNode> Nodes;
var array<GUIGroup> Columns;

//==== Style ====
CONST PAD_X = 16;
CONST PAD_Y = 12;
CONST NODE_SPACING = 44;
CONST ROW_HEIGHT = 64;
var const Color COLOR_SELECTED, COLOR_LOCKED;
var const Color COLOR_AVAILABLE, COLOR_UNAVAILABLE, COLOR_TO_UNAVAILABLE;
var int TREE_Y;

function Initialized()
{
	Viewport = GameViewportClient(Outer);
	PC = Viewport.GetPlayerOwner(0).Actor;

	Root = class'GUIRoot'.static.Create(Self, Viewport);
	Root.OnLeftMouse = OnClickRoot;
	Root.bCaptureMouse = true;
}

function bool BuildSpawnTree(Canvas C)
{
	local TTGRI GRI;
	local GUILabel lbl;
	local int Row, i, bottom, x;

	//`Log("[D] BUILD SPAWN TREE");

	GRI = TTGRI(PC.WorldInfo.GRI);
	PRI = TTPRI(PC.PlayerReplicationInfo);
	if ( GRI == None || GRI.PointZero == None || PRI == None )
		return false;

	Root.Clear();
	Nodes.Length = 0;
	Columns.Length = 0;

	Panel = class'GUIGroup'.static.CreateGroup(Root);
	Panel.SetPosAuto("center-x:50%; center-y:50%");
	Panel.SetColors(class'GUIBoard'.default.BgColor.Val, Panel.TRANSPARENT);
	Panel.OnDraw = OnDrawPanelBackground;

	TREE_Y = PAD_Y;

	lbl = class'GUILabel'.static.CreateLabel(Panel, "- SPAWN TREE -");
	lbl.SetPosAuto("center-x:50%; width:100%; top:" $ TREE_Y);
	lbl.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);
	lbl.SetTextColor(class'GUIBoard'.default.TitleColor);
	//`Log("[D] " $ lbl.GetIntrinsicSize(C).X); // 110

	TREE_Y += lbl.GetIntrinsicSize(C).Y + 8;

	lbl = class'GUILabel'.static.CreateLabel(Panel, "- Right click to pick spawn point");
	lbl.SetPosAuto("left:" $ PAD_X $ "; width:100%; top:" $ TREE_Y);
	lbl.SetTextAlign(ALIGN_LEFT, ALIGN_TOP);
	lbl.SetTextColor(MakeColor(255,255,255,160));
	//`Log("[D] " $ lbl.GetIntrinsicSize(C).X); // 214

	TREE_Y += lbl.GetIntrinsicSize(C).Y + 4;

	lbl = class'GUILabel'.static.CreateLabel(Panel, "- Select twice to lock (red)");
	lbl.SetPosAuto("left:" $ PAD_X $ "; width:100%; top:" $ TREE_Y);
	lbl.SetTextAlign(ALIGN_LEFT, ALIGN_TOP);
	lbl.SetTextColor(MakeColor(255,255,255,160));
	//`Log("[D] " $ lbl.GetIntrinsicSize(C).X); // 183

	TREE_Y += lbl.GetIntrinsicSize(C).Y + 16;

	Row = 0;
	BuildTreeNodes(C, INDEX_NONE, GRI.PointZero, 0, Row);

	bottom = TREE_Y;
	for ( i=0; i<Nodes.Length; i++ )
	{
		Columns[Nodes[i].Depth].offW.Val = Max(Nodes[i].btn.offW.Val, Columns[Nodes[i].Depth].offW.Val);
		bottom = Max(Nodes[i].btn.offY.Val + Nodes[i].btn.offH.Val, bottom);
	}

	x = PAD_X;
	for ( i=0; i<Columns.Length; i++ )
	{
		if ( i > 0 )
			x += NODE_SPACING;
		Columns[i].SetPosAuto("left:" $ x);
		x += Columns[i].offW.Val;
	}

	Panel.SetPosAuto("width:" $ Max(x+PAD_X, 214+2*PAD_X) $ "; height:" $ (bottom + PAD_Y));

	bRebuild = false;
	UpdateButtons();
	return true;
}

function BuildTreeNodes(Canvas C, int ParentIdx, TTWaypoint Cur, int Depth, out int Row)
{
	local TTSavepoint Sp;
	local TTPointZero PZ;
	local int i, j;

	//`Log("[D] At point " $ Cur.Name);

	Sp = TTSavepoint(Cur);
	if ( Sp != None && !Sp.IsA('TTObjective') )
	{
		i = Nodes.Find('Savepoint', Sp);
		if ( i != INDEX_NONE )
		{
			if ( Depth < Nodes[i].Depth )
			{
				Nodes[i].Row = Row;
				Nodes[i].btn.SetPosAuto("top:" $ (TREE_Y + Row*ROW_HEIGHT));

				Columns[Depth].AddChild(Nodes[i].btn);
				if ( Columns[Nodes[i].Depth].Children.Length == 0 )
					Columns.Remove(Nodes[i].Depth,1);

				Nodes[i].Depth = Depth;
			}
		}
		else
		{
			if ( Depth == Columns.Length )
			{
				Columns.Length = Depth+1;
				Columns[Depth] = class'GUIGroup'.static.CreateGroup(Panel);
				Columns[Depth].SetPosAuto("left:0; top:0; width:0; height:100%");
			}

			i = Nodes.Length;
			Nodes.Length = i+1;
			Nodes[i].Savepoint = Sp;
			Nodes[i].Depth = Depth;
			Nodes[i].Row = Row;
			Nodes[i].btn = class'GUIButton'.static.CreateButton(Columns[Depth], Sp.SpawnTreeLabel, OnSelectNode);
			Nodes[i].btn.iData.AddItem(i);
			Nodes[i].btn.SetPosAuto("center-x:50%; top:" $ (TREE_Y + Row*ROW_HEIGHT));
			Nodes[i].btn.OnDraw = OnDrawNode;
			Nodes[i].btn.SizeToFit(C);
			//make buttons work on right-click, left-click is caught by Root to respawn
			Nodes[i].btn.OnRightMouse = Nodes[i].btn.OnLeftMouse;
			Nodes[i].btn.OnLeftMouse = Nodes[i].btn.LeftMousePropagate;
		}

		if ( ParentIdx == INDEX_NONE && Sp.IsA('TTPointZero') )
		{
			// Special case: if the initial point has only one successor, skip initial (PointZero ==> Point2)
			PZ = TTPointZero(Sp);
			if ( PZ.InitialPoint.NextPoints.Length == 1 )
			{
				Nodes[i].btn.Text = PZ.SingleSpawnTreeLabel;
				Nodes[i].btn.SizeToFit(C);
				BuildTreeNodes(C, i, PZ.InitialPoint.NextPoints[0], Depth+1, Row);
			}
			else
				BuildTreeNodes(C, i, PZ.InitialPoint, Depth+1, Row);
		}
		else
		{
			if ( ParentIdx != INDEX_NONE )
				Nodes[ParentIdx].LinkTo.AddItem(i);

			for ( j=0; j<Cur.NextPoints.Length; j++ )
				BuildTreeNodes(C, i, Cur.NextPoints[j], Depth+1, Row);
		}
	}
	else
	{
		for ( j=0; j<Cur.NextPoints.Length; j++ )
			BuildTreeNodes(C, ParentIdx, Cur.NextPoints[j], Depth, Row);
	}

	if ( Cur.NextPoints.Length == 0 )
		Row++;
}

function Rebuild()
{
	bRebuild = true;
}

function UpdateButtons()
{
	local int i;

	if ( Nodes.Length == 0 || bRebuild )	// filter out first call in Show() before SpawnTree is created
		return;

	// uglyfix: When PointZero.InitialPoint is skipped in the SpawnTree but selected automatically, we need to reselect PZ!
	if ( Nodes.Find('Savepoint', PRI.SpawnPoint) == INDEX_NONE )
		PRI.SpawnPoint = Nodes[0].Savepoint;

	for ( i=0; i<Nodes.Length; i++ )
	{
		Nodes[i].btn.SetEnabled(IsSavepointAvailable(Nodes[i].Savepoint));
		if ( Nodes[i].Savepoint == PRI.SpawnPoint )
			Nodes[i].btn.SetAutoColor(PRI.bLockedSpawnPoint ? COLOR_LOCKED : COLOR_SELECTED);
		else
			Nodes[i].btn.SetAutoColor(Nodes[i].btn.bEnabled ? COLOR_AVAILABLE : COLOR_UNAVAILABLE);
	}
}

function bool IsSavepointAvailable(TTSavepoint Sp)
{
	return (Sp.bInitiallyAvailable || PRI.UnlockedSavepoints.Find(Sp) != INDEX_NONE);
}

function OnClickRoot(GUIGroup elem, bool bDown)
{
	if ( bDown )
	{
		Show(false);
		TTPRI(PC.PlayerReplicationInfo).ServerPickSpawnPoint(PRI.SpawnPoint);
	}
}

function OnSelectNode(GUIButton elem)
{
	local int i;

	i = elem.iData[0];
	if ( Nodes[i].Savepoint == PRI.SpawnPoint )
		PRI.bLockedSpawnPoint = !PRI.bLockedSpawnPoint;
	else
	{
		PRI.bLockedSpawnPoint = false;
		PRI.SpawnPoint = Nodes[i].Savepoint;

		// Show corresponding level board
		if ( TTLevel(PRI.SpawnPoint) != None )
			PRI.CurrentLevel = TTLevel(PRI.SpawnPoint);
		else if ( TTPointZero(PRI.SpawnPoint) != None && PRI.SpawnPoint.NextPoints.Length > 0 && TTLevel(PRI.SpawnPoint.NextPoints[0]) != None )
			PRI.CurrentLevel = TTLevel(PRI.SpawnPoint.NextPoints[0]);
		else
			PRI.CurrentLevel = None;
		TTHud(PC.myHUD).UpdateLevelboard();
	}
	UpdateButtons();
}

// draw lines between nodes (center to center, buttons will be drawn over)
function OnDrawPanelBackground(GUIGroup elem, Canvas C)
{
	local int i, j, k;

	elem.InternalOnDraw(elem, C);

	for ( i=0; i<Nodes.Length; i++ )
	{
		for ( j=0; j<Nodes[i].LinkTo.Length; j++ )
		{
			k = Nodes[i].LinkTo[j];
			C.Draw2DLine(
				Nodes[i].btn.absX + Nodes[i].btn.absW/2,
				Nodes[i].btn.absY + Nodes[i].btn.absH/2,
				Nodes[k].btn.absX + Nodes[k].btn.absW/2,
				Nodes[k].btn.absY + Nodes[k].btn.absH/2,
				IsSavepointAvailable(Nodes[i].Savepoint)  ? (IsSavepointAvailable(Nodes[k].Savepoint) ? COLOR_AVAILABLE : COLOR_TO_UNAVAILABLE) : COLOR_UNAVAILABLE
			);
		}
	}
}

// draw buttons - don't use default because it has alpha - we need full alpha to cover the lines behind buttons
function OnDrawNode(GUIGroup elem, Canvas C)
{
	local GUIButton btn;
	btn = GUIButton(elem);
	if ( btn.bHover && btn.bActive )
    {
        btn.BgColor.Val = btn.MultColor(btn.AutoColor.Val, 0.5, 1.0);
        btn.BoxColor.Val = btn.MultColor(btn.AutoColor.Val, 0.8, 1.0);
        btn.TextColor.Val = btn.MultColor(btn.AutoColor.Val, 0.9, 1.0);
    }
    else if ( btn.bHover )
    {
        btn.BgColor.Val = btn.MultColor(btn.AutoColor.Val, 0.7, 1.0);
        btn.BoxColor.Val = btn.AutoColor.Val;
        btn.TextColor.Val = btn.AutoColor.Val;
    }
    else
    {
        btn.BgColor.Val = btn.MultColor(btn.AutoColor.Val, 0.3, 1.0);
        btn.BoxColor.Val = btn.MultColor(btn.AutoColor.Val, 0.8, 1.0);
        btn.TextColor.Val = btn.AutoColor.Val;
    }
	btn.bAutoColor = false;
	btn.InternalOnDraw(elem, C);
}

event Tick(float dt)
{
	if ( Root != None )
		Root.Tick(dt);
}

function Show(bool newShow)
{
	bShow = newShow;
	//Viewport.SetHardwareMouseCursorVisibility(bShow);
	if ( bShow )
	{
		UpdateButtons();
		Root.AlphaTo(1, 0.5, ANIM_EASE_IN);
	}
	else
		Root.AlphaTo(0, 0.3, ANIM_EASE_OUT);
}

event PostRender(Canvas C)
{
	if ( bShow )
	{
		if ( Viewport.Outer.TransitionType != TT_None )
			Free();
		else
		{
			if ( bRebuild && !BuildSpawnTree(C) )
				return;

			Root.PostRender(C);
		}
	}
}

function bool OnKey(int ControllerId, name Key, EInputEvent EventType, optional float AmountDepressed=1.0, optional bool bGamepad)
{
    if ( bShow )
    {
        if ( Key == 'Escape' && EventType == IE_Pressed )
        {
			OnClickRoot(None, true);
            return true;
        }
		if ( Root.KeyEvent(Key, EventType) )
		{
			//`Log("[D] " $ String(Key));

			// SPECIAL PRED-CODE
			if ( Key == 'RightMouseButton' && InStr(PC.PlayerInput.GetBind(Key), "Fire",, true) == INDEX_NONE )
				return false;

			return true;
		}
    }
    return false;
}

function NotifyGameSessionEnded()
{
	Super.NotifyGameSessionEnded();

	Free();
}

function Free()
{
	Nodes.Length = 0;
	if ( bShow ) 
		Show(false);
	if ( Root != None )
		Root.Free();
	Root = None;
	Panel = None;
	Columns.Length = 0;
	PRI = None;
}

defaultproperties
{
	COLOR_SELECTED=(R=255,G=255,B=255,A=255)
	COLOR_LOCKED=(R=255,G=32,B=32,A=255)
	COLOR_AVAILABLE=(R=32,G=220,B=32,A=255)
	COLOR_UNAVAILABLE=(R=128,G=128,B=128,A=255)
	COLOR_TO_UNAVAILABLE=(R=255,G=255,B=255,A=255)

	bRebuild=true
	OnReceivedNativeInputKey=OnKey
}
