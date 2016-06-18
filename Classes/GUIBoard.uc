//================================================================
// Trials.GUIBoard
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class GUIBoard extends GUIGroup;

CONST TITLE_HEIGHT = 28;
CONST LINE_HEIGHT = 24;
CONST PAD_Y = 12;
CONST PAD_X = 12;

struct sBoardLine
{
	var GUIGroup grp;
	var array<GUILabel> cols;
};

var GUILabel l_title;
var sBoardLine head;
var array<sBoardLine> lines;

var array<int> ColPosX;
var array<int> ColSize;
var array<eHorAlignment> ColAlign;

var Color HeadTextColor;


static function GUIBoard CreateBoard(optional GUIGroup _Parent=None, optional String Title="Board")
{
	local GUIBoard Board;

	Board = new(None) class'GUIBoard';
	if ( _Parent != None )
		_Parent.AddChild(Board);

	Board.l_title = class'GUILabel'.static.CreateLabel(Board, Title);
	Board.l_title.SetPosAuto("center-x:50%; width:100%; top:"$PAD_Y);
	Board.l_title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);
	Board.l_title.SetTextColor(MakeColor(32,180,255,255));

	Board.head.grp = class'GUIGroup'.static.CreateGroup(Board);
	Board.head.grp.SetPosAuto("center-x:50%; width:100%-"$(2*PAD_X)$"; top:"$(PAD_Y+TITLE_HEIGHT)$"; height:"$LINE_HEIGHT);
	Board.head.cols.Length = 0;

	Board.RecalcHeight();

	return Board;
}

function SetTitle(String Title)
{
	l_title.Text = Title;
}

function AddColumn(String Title, int Size, eHorAlignment hAlign)
{
	local int i;

	i = head.cols.Length;
	head.cols.Length = i+1;

	ColPosX.AddItem(i > 0 ? (ColPosX[i-1]+ColSize[i-1]) : 0);
	ColSize.AddItem(Size);
	ColAlign.AddItem(hAlign);

	head.cols[i] = class'GUILabel'.static.CreateLabel(head.grp, Title);
	head.cols[i].SetPosAuto("center-y:50%; left:"$ColPosX[i]$"; width:"$Size);
	head.cols[i].SetTextAlign(hAlign, ALIGN_MIDDLE);
	head.cols[i].SetTextColor(HeadTextColor);

	RecalcWidth();
}

function AddLine(out array<String> Values)
{
	local int i,c;

	i = lines.Length;
	lines.Length = i+1;

	lines[i].grp = class'GUIGroup'.static.CreateGroup(Self);
	lines[i].grp.SetPosAuto("center-x:50%; width:100%-"$(2*PAD_X)$"; top:"$(PAD_Y+TITLE_HEIGHT+(i+1)*LINE_HEIGHT)$"; height:"$LINE_HEIGHT);
	lines[i].grp.SetColors(TRANSPARENT, MakeColor(255,255,255,32));

	lines[i].cols.Length = head.cols.Length;
	for ( c=0; c<head.cols.Length; c++ )
		lines[i].cols[c] = CreateElem(lines[i].grp, c, Values[c]);

	RecalcHeight();
}

function UpdateLine(int i, out array<String> Values)
{
	local int c;
	local bool bModified;

	for ( c=0; c<Min(lines[i].cols.Length,Values.Length); c++ )
	{
		if ( Values[c] != "_" && lines[i].cols[c].Text != Values[c] )
		{
			lines[i].cols[c].Text = Values[c];
			bModified = true;
		}
	}

	if ( bModified )
		lines[i].grp.FlashColors(MakeColor(255,200,128,220), MakeColor(255,255,255,255), 0.2, 1.0);
}

function Empty()
{
	local int i;
	for ( i=0; i<lines.Length; i++ )
		lines[i].grp.RemoveFromParent();
	lines.Length = 0;
	RecalcHeight();
}

private function RecalcWidth()
{
	SetPosAuto("width:" $ (ColPosX[ColPosX.Length-1] + ColSize[ColSize.Length-1] + 2*PAD_X));
}

private function RecalcHeight()
{
	if ( lines.Length > 0 )
		MoveTo("_","_","_", lines[lines.Length-1].grp.offY.Val + LINE_HEIGHT + PAD_Y, 0.25, ANIM_EASE_IN);
		//SetPosAuto("height:" $ (lines[lines.Length-1].grp.offY.Val + LINE_HEIGHT + PAD_Y));
	else
		MoveTo("_","_","_", head.grp.offY.Val + LINE_HEIGHT + PAD_Y, 0.25, ANIM_EASE_IN);
		//SetPosAuto("height:" $ (head.grp.offY.Val + LINE_HEIGHT + PAD_Y));
}

private function GUILabel CreateElem(GUIGroup _Parent, int c, String Text)
{
	local GUILabel lbl;

	lbl = class'GUILabel'.static.CreateLabel(_Parent, Text);
	lbl.SetPosAuto("center-y:50%; left:"$ColPosX[c]$"; width:"$ColSize[c]);
	lbl.SetTextAlign(ColAlign[c], ALIGN_MIDDLE);
	return lbl;
}

defaultproperties
{
	BgColor=(Val=(R=0,G=0,B=0,A=160))
	HeadTextColor=(R=255,G=160,B=0,A=255)
}
