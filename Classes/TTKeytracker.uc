//================================================================
// Trials.TTKeytracker
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTKeytracker extends Interaction
	Config(Trials);

var GameViewportClient Viewport;
var PlayerController PC;
var GUIRoot Root;

struct StrictConfig sKeyWidget
{
	var config String Label;
	var config String Command;
	var config String pos;
	var GUILabel elem;
};

var config array<sKeyWidget> KeyWidgets;
var config String pos;
var config float Alpha;

var GUIGroup Container;

// hardcoded dodge handling
var GUIGroup Dodges[4];
var Actor.EDoubleClickDir LastDClick;
var bool bJustDodged;


function Initialized()
{
	local int i, j;
	local Vector2D ContainerSize;

	if ( pos == "" )
		InitConfig();

    Viewport = GameViewportClient(Outer);
    PC = Viewport.GetPlayerOwner(0).Actor;

    Root = class'GUIRoot'.static.Create(Self, Viewport);

	Container = class'GUIGroup'.static.CreateGroup(Root);
	Container.SetPosAuto("left:0; top:0; width:0; height:0");

	for ( i=0; i<KeyWidgets.Length; i++ )
	{
		KeyWidgets[i].elem = class'GUILabel'.static.CreateLabel(Container, KeyWidgets[i].Label);
		KeyWidgets[i].elem.SetPosAuto(KeyWidgets[i].pos);
		KeyWidgets[i].elem.SetColors(MakeColor(0,0,0,128), MakeColor(255,255,255,220));
		KeyWidgets[i].elem.SetTextAlign(ALIGN_CENTER, ALIGN_MIDDLE);

		KeyWidgets[i].elem.CalcSizes(0);
		KeyWidgets[i].elem.CalcPos(0);
		ContainerSize.X = Max(KeyWidgets[i].elem.absX + KeyWidgets[i].elem.absW, ContainerSize.X);
		ContainerSize.Y = Max(KeyWidgets[i].elem.absY + KeyWidgets[i].elem.absH, ContainerSize.Y);

		j = -1;
		if ( KeyWidgets[i].Command ~= "GBA_MoveForward" ) j = 0;
		else if ( KeyWidgets[i].Command ~= "GBA_MoveBackward" ) j = 1;
		else if ( KeyWidgets[i].Command ~= "GBA_StrafeLeft" ) j = 2;
		else if ( KeyWidgets[i].Command ~= "GBA_StrafeRight" ) j = 3;
		if ( j != -1 )
		{
			Dodges[j] = class'GUIGroup'.static.CreateGroup(KeyWidgets[i].elem);
			Dodges[j].SetPosAuto("left:0; top:0; width:100%; height:100%");
			Dodges[j].SetColors(MakeColor(255,255,0,255), Dodges[i].TRANSPARENT);
			Dodges[j].SetAlpha(0.0);
		}
	}

	Container.SetPosAuto(pos);
	Container.SetPosAuto("width:" $ ContainerSize.X $ "; height:" $ ContainerSize.Y);
}


event Tick(float dt)
{
	local int i;

	if ( PC != None && PC.Pawn != None )
	{
		if ( PC.DoubleClickDir == DCLICK_ACTIVE )
		{
			if ( !bJustDodged )
			{
				Switch (LastDClick)
				{
					case DCLICK_Forward:	i = 0; break;
					case DCLICK_Back:		i = 1; break;
					case DCLICK_Left:		i = 2; break;
					case DCLICK_Right:		i = 3; break;
					default: i = -1;
				}
				if ( i != -1 )
				{
					Dodges[i].SetAlpha(1.0);
					Dodges[i].AlphaTo(0.0, 0.8, ANIM_EASE_OUT);
				}
				bJustDodged = true;
			}
		}
		else
		{
			bJustDodged = false;
			LastDClick = PC.DoubleClickDir;
		}

		Root.Tick(dt);
	}
}

event PostRender(Canvas C)
{
	if ( PC != None && PC.Pawn != None )
		Root.PostRender(C);
}

function bool OnKey(int ControllerId, name Key, Object.EInputEvent EventType, optional float AmountDepressed=1.0, optional bool bGamepad)
{
	local int i;
	local String Cmd;

	if ( EventType == IE_Pressed || EventType == IE_Released )
	{
		Cmd = PC.PlayerInput.GetBind(Key);
		for ( i=0; i<KeyWidgets.Length; i++ )
		{
			if ( Cmd ~= KeyWidgets[i].Command )
			{
				if ( EventType == IE_Pressed )
				{
					KeyWidgets[i].elem.SetColors(MakeColor(96,150,184,128), MakeColor(200,230,255,255));
					KeyWidgets[i].elem.SetTextColor(MakeColor(200,230,255,255));
				}
				else
				{
					KeyWidgets[i].elem.ColorsTo(MakeColor(0,0,0,128), MakeColor(255,255,255,220), 0.4, ANIM_EASE_OUT);
					KeyWidgets[i].elem.TextColorTo(KeyWidgets[i].elem.default.TextColor.Val, 0.4, ANIM_EASE_OUT);
				}
				break;
			}
		}
	}
    return false;
}


function InitConfig()
{
	KeyWidgets.Length = 9;

	KeyWidgets[0].Label = "W";
	KeyWidgets[0].Command = "GBA_MoveForward";
	KeyWidgets[0].pos = "left:96; top:0; width:36; height:36";

	KeyWidgets[1].Label = "S";
	KeyWidgets[1].Command = "GBA_Backward";
	KeyWidgets[1].pos = "left:96; top:40; width:36; height:36";

	KeyWidgets[2].Label = "A";
	KeyWidgets[2].Command = "GBA_StrafeLeft";
	KeyWidgets[2].pos = "left:56; top:40; width:36; height:36";

	KeyWidgets[3].Label = "D";
	KeyWidgets[3].Command = "GBA_StrafeRight";
	KeyWidgets[3].pos = "left:136; top:40; width:36; height:36";

	KeyWidgets[4].Label = "JUMP";
	KeyWidgets[4].Command = "GBA_Jump";
	KeyWidgets[4].pos = "left:56; top:86; width:116; height:24";

	KeyWidgets[5].Label = "dash";
	KeyWidgets[5].Command = "GBA_Dodge";
	KeyWidgets[5].pos = "left:0; top:52; width:40; height:24";

	KeyWidgets[6].Label = "duck";
	KeyWidgets[6].Command = "GBA_Duck";
	KeyWidgets[6].pos = "left:0; top:86; width:40; height:24";

	KeyWidgets[7].Label = "1";
	KeyWidgets[7].Command = "GBA_Fire";
	KeyWidgets[7].pos = "left:188; top:58; width:20; height:40";

	KeyWidgets[8].Label = "2";
	KeyWidgets[8].Command = "GBA_AltFire";
	KeyWidgets[8].pos = "left:218; top:58; width:20; height:40";

	pos = "right:100%-32; center-y:50%";

	Alpha = 1.0;

	//SaveConfig();
}



defaultproperties
{
	OnReceivedNativeInputKey=OnKey
}
