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

var GUIPanel Panel;

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
var const Color COLOR_SELECTED, COLOR_LOCKED;
var const Color COLOR_AVAILABLE, COLOR_UNAVAILABLE, COLOR_TO_UNAVAILABLE;
var const Vector PANEL_PADDING;
var const int NODE_SPACING;
var const int ROW_HEIGHT;

function Initialized()
{
	Viewport = GameViewportClient(Outer);
	PC = Viewport.GetPlayerOwner(0).Actor;
	PRI = TTPRI(PC.PlayerReplicationInfo);

	Root = class'GUIRoot'.static.Create(Self, Viewport);
	Root.OnLeftMouse = OnClickRoot;
	Root.bCaptureMouse = true;
}

function bool BuildSpawnTree(Canvas C)
{
	local TTGRI GRI;
	local int Row, i, w, h;
	local Vector2D s;

	`Log("[D] BUILD SPAWN TREE");

	GRI = TTGRI(PC.WorldInfo.GRI);
	if ( GRI == None || GRI.PointZero == None )
		return false;

	Root.Clear();
	Nodes.Length = 0;
	Columns.Length = 0;

	Panel = class'GUIPanel'.static.CreatePanel(Root, "Spawn Tree", Root);
	Panel.SetPosAuto("center-x:50%; center-y:50%");
	Panel.Content.OnDraw = OnDrawPanelContent;
	Panel.bCaptureMouse = false;

	Row = 0;
	BuildTreeNodes(C, INDEX_NONE, GRI.PointZero, 0, Row);
	UpdateButtons();

	h = 0;
	for ( i=0; i<Nodes.Length; i++ )
	{
		Columns[Nodes[i].Depth].offW.Val = Max(Nodes[i].btn.offW.Val, Columns[Nodes[i].Depth].offW.Val);
		h = Max(Nodes[i].btn.offY.Val + Nodes[i].btn.offH.Val, h);
	}

	w = PANEL_PADDING.X;
	for ( i=0; i<Columns.Length; i++ )
	{
		if ( i > 0 )
			w += NODE_SPACING;
		Columns[i].SetPosAuto("left:" $ w);
		w += Columns[i].offW.Val;
	}

	s = Panel.TitleBar.GetIntrinsicSize(C);
	Panel.SetPosAuto("width:" $ Max(w+PANEL_PADDING.X, s.X) $ "; height:" $ (s.Y + h + PANEL_PADDING.Z));

	bRebuild = false;
	return true;
}

function BuildTreeNodes(Canvas C, int ParentIdx, TTWaypoint Cur, int Depth, out int Row)
{
	local TTSavepoint Sp;
	local int i, j;

	`Log("[D] At point " $ Cur.Name);

	Sp = TTSavepoint(Cur);
	if ( Sp != None && !Sp.IsA('TTObjective') )
	{
		i = Nodes.Find('Savepoint', Sp);
		if ( i != INDEX_NONE )
		{
			if ( Depth < Nodes[i].Depth )
			{
				Nodes[i].Row = Row;
				Nodes[i].btn.SetPosAuto("top:" $ (PANEL_PADDING.Y + Row*ROW_HEIGHT));

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
				Columns[Depth] = class'GUIGroup'.static.CreateGroup(Panel.Content);
				Columns[Depth].SetPosAuto("left:0; top:0; width:0; height:100%");
			}

			i = Nodes.Length;
			Nodes.Length = i+1;
			Nodes[i].Savepoint = Sp;
			Nodes[i].Depth = Depth;
			Nodes[i].Row = Row;
			Nodes[i].btn = class'GUIButton'.static.CreateButton(Columns[Depth], Sp.SpawnTreeLabel, OnSelectNode);
			Nodes[i].btn.Data.AddItem(String(i));
			Nodes[i].btn.SetPosAuto("center-x:40%; top:" $ (PANEL_PADDING.Y + Row*ROW_HEIGHT));
			Nodes[i].btn.OnDraw = OnDrawNode;
			Nodes[i].btn.SizeToFit(C);
			//make buttons work on right-click, left-click is caught by Root to respawn
			Nodes[i].btn.OnRightMouse = Nodes[i].btn.OnLeftMouse;
			Nodes[i].btn.OnLeftMouse = Nodes[i].btn.LeftMousePropagate;
		}

		if ( ParentIdx == INDEX_NONE && Sp.IsA('TTPointZero') )
			BuildTreeNodes(C, i, TTPointZero(Sp).InitialPoint, Depth+1, Row);
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
		TTPRI(PC.PlayerReplicationInfo).ServerPickSpawnPoint(PRI.SpawnPoint, PRI.bLockedSpawnPoint);
	}
}

function OnSelectNode(GUIButton elem)
{
	local int i;

	i = int(elem.Data[0]);
	if ( Nodes[i].Savepoint == PRI.SpawnPoint )
		PRI.bLockedSpawnPoint = !PRI.bLockedSpawnPoint;
	else
	{
		PRI.bLockedSpawnPoint = false;
		PRI.SpawnPoint = Nodes[i].Savepoint;
	}
	UpdateButtons();
}

// draw lines between nodes (center to center, buttons will be drawn over)
function OnDrawPanelContent(GUIGroup elem, Canvas C)
{
	local int i, j, k;

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
	if ( PC.IsInState('Dead') && !PRI.bHasCS )
	{
		if ( !bShow )
			Show(true);
		else if ( !Viewport.bDisplayHardwareMouseCursor )
			Viewport.SetHardwareMouseCursorVisibility(true);

		Root.Tick(dt);
	}
	else if ( bShow )
		Show(false);
}

function Show(bool newShow)
{
	bShow = newShow;
	Viewport.SetHardwareMouseCursorVisibility(bShow);
	if ( bShow )
	{
		UpdateButtons();
		Root.AlphaTo(1.0, 0.5, ANIM_EASE_IN);
	}
	else
		Root.SetAlpha(0.0);
}

event PostRender(Canvas C)
{
	if ( bShow )
	{
		if ( Viewport.Outer.TransitionType != TT_None )
			Show(false);
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
		return Root.KeyEvent(Key, EventType);
    }
    return false;
}

function NotifyGameSessionEnded()
{
	Super.NotifyGameSessionEnded();

	if ( bShow ) 
		Show(false);
}

defaultproperties
{
	COLOR_SELECTED=(R=255,G=255,B=255,A=255)
	COLOR_LOCKED=(R=255,G=32,B=32,A=255)
	COLOR_AVAILABLE=(R=32,G=220,B=32,A=255)
	COLOR_UNAVAILABLE=(R=128,G=128,B=128,A=255)
	COLOR_TO_UNAVAILABLE=(R=255,G=255,B=255,A=255)
	PANEL_PADDING=(X=16,Y=12,Z=12)
	NODE_SPACING=48
	ROW_HEIGHT=64

	bRebuild=true
	OnReceivedNativeInputKey=OnKey
}
