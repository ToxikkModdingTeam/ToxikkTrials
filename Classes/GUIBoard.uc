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

/** Separator char for columns is \n */
static function GUIBoard CreateBoard(optional GUIGroup _Parent=None, optional String Title="Board")
{
	local GUIBoard Board;

	Board = new(None) class'GUIBoard';
	if ( _Parent != None )
		_Parent.AddChild(Board);

	Board.l_title = class'GUILabel'.static.CreateLabel(Board, Title);
	Board.l_title.SetPosAuto("center-x:50%; width:100%; top:"$PAD_Y);
	Board.l_title.SetTextAlign(ALIGN_CENTER, ALIGN_TOP);

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

	if ( i > 0 )
		ColPosX.AddItem(ColPosX[i-1] + ColSize[i-1]);
	ColSize.AddItem(Size);
	ColAlign.AddItem(hAlign);

	head.cols[i] = class'GUILabel'.static.CreateLabel(head.grp, Title);
	head.cols[i].SetPosAuto("center-y:50%; left:"$ColPosX[i]$"; width:"$Size);
	head.cols[i].SetTextAlign(hAlign, ALIGN_MIDDLE);
}

function AddLine(String Columns)
{
	local int i,c;
	local array<String> Cols;

	i = lines.Length;
	lines.Length = i+1;

	lines[i].grp = class'GUIGroup'.static.CreateGroup(Self);
	lines[i].grp.SetPosAuto("center-x:50%; width:100%-"$(2*PAD_X)$"; top:"$(PAD_Y+TITLE_HEIGHT+(i+1)*LINE_HEIGHT)$"; height:"$LINE_HEIGHT);
	lines[i].grp.SetColors(TRANSPARENT, MakeColor(255,255,255,32));

	Cols = SplitString(Columns, "\n", true);

	lines[i].cols.Length = Cols.Length;
	for ( c=0; c<Cols.Length; c++ )
		lines[i].cols[c] = CreateElem(lines[i].grp, c, Cols[c]);

	RecalcHeight();
}

function UpdateLine(int i, String Columns)
{
	local array<String> Cols;
	local int c;
	local bool bModified;

	Cols = SplitString(Columns, "\n", false);

	for ( c=0; c<Cols.Length; c++ )
	{
		if ( Cols[c] != "_" && lines[i].cols[c].Text != Cols[c] )
		{
			lines[i].cols[c].Text = Cols[c];
			bModified = true;
		}
	}

	if ( bModified )
		FlashLine(i);
}

function FlashLine(int i)
{
	lines[i].grp.ColorsTo(MakeColor(255,200,128,220), lines[i].grp.BoxColor.Val, 0.2, ANIM_LINEAR);
	lines[i].grp.QueueColors(TRANSPARENT, lines[i].grp.BoxColor.Val, 1.0, ANIM_LINEAR);
}

function Empty()
{
	local int i;
	for ( i=0; i<lines.Length; i++ )
		lines[i].grp.RemoveFromParent();
	lines.Length = 0;
	RecalcHeight();
}

private function RecalcHeight()
{
	if ( lines.Length > 0 )
		MoveTo("_","_","_", lines[lines.Length-1].grp.offY.Val + LINE_HEIGHT + PAD_Y, 0.25, ANIM_LINEAR);
		//SetPosAuto("height:" $ (lines[lines.Length-1].grp.offY.Val + LINE_HEIGHT + PAD_Y));
	else
		MoveTo("_","_","_", head.grp.offY.Val + LINE_HEIGHT + PAD_Y, 0.25, ANIM_LINEAR);
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
}
