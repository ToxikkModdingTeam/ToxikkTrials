//================================================================
// ToxikkTrials.TTConfigMenu
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTConfigMenu extends BaseConfigInteraction
	Config(Trials);

CONST CONFIG_VERSION = 1;
var config int ConfigVersion;

var config String Keytracker_pos;
var config float Keytracker_alpha;

var config String Timers_pos;
var config float Timers_alpha;

var config String Boards_pos;
var config float Boards_alpha;

var config String Leaderboard_pos;
var config float Leaderboard_alpha;

var config bool bAutoBoards;
var config float AutoBoardsDelay;

var config int FadeoutDist;
var config bool bQuietPlayers;

var config String Speedometer_pos;
var config float Speedometer_alpha;
var config float Speedovectors_alpha;

var GUIPosWidget pw_Keytracker, pw_Timers, pw_Boards, pw_Leaderboard, pw_Speedometer;
var GUISlider s_KeytrackerAlpha, s_TimersAlpha, s_BoardsAlpha, s_LeaderboardAlpha;
var GUISlider s_AutoBoardsDelay, s_FadeoutDist, s_SpeedometerAlpha, s_SpeedovectorsAlpha;
var GUICheckBox cb_AutoBoards, cb_QuietPlayers;


function InitConfig()
{
	Keytracker_pos = "right:100%-32; center-y:50%";
	Keytracker_alpha = 1.0;

	Timers_pos = "right:100%-32; top:32";
	Timers_alpha = 1.0;

	Boards_pos = "right:100%-32; top:112";
	Boards_alpha = 1.0;

	Leaderboard_pos = "left:32; center-y:50%";
	Leaderboard_alpha = 1.0;

	bAutoBoards = true;
	AutoBoardsDelay = 2.0;

	FadeoutDist = 512;
	bQuietPlayers = true;

	Speedometer_pos = "right:100%-32; top:50%+100"; // below keytracker
	Speedometer_alpha = 0.8;
	Speedovectors_alpha = 0.0;

	ConfigVersion = CONFIG_VERSION;
	SaveConfig();
}


function CreateMenuElements(GUIRoot Root)
{
	local GUIPanel panel;
	local GUIGroup cont;
	local GUIButton btn;
	local int h;

	if ( ConfigVersion != CONFIG_VERSION )
		InitConfig();

	panel = class'GUIPanel'.static.CreatePanel(Root, "Trials", Root);
	panel.SetPosAuto("center-x:50%; center-y:50%; width:400");
	panel.SetColors(MakeColor(0,0,0,128), MakeColor(255,255,255,200));

	cont = class'GUIGroup'.static.CreateGroup(panel.Content);
	cont.SetPosAuto("left:16; top:16; width:100%-32; height:100%-32");

	h = 0;

	s_KeytrackerAlpha = MakeSlider(cont, h, "Keytracker alpha", Keytracker_alpha, 0.0, 1.0);
	s_TimersAlpha = MakeSlider(cont, h, "Timers alpha", Timers_alpha, 0.0, 1.0);
	s_BoardsAlpha = MakeSlider(cont, h, "Records alpha", Boards_alpha, 0.0, 1.0);
	s_LeaderboardAlpha = MakeSlider(cont, h, "Leaderboard alpha", Leaderboard_alpha, 0.0, 1.0);
	h += 8;
	cb_AutoBoards = MakeCheckbox(cont, h, "Auto show boards", bAutoBoards);
	s_AutoBoardsDelay = MakeSlider(cont, h, "Auto boards delay", AutoBoardsDelay, 0.5, 5.0);
	h += 8;
	s_FadeoutDist = MakeSlider(cont, h, "Fadeout players", FadeoutDist, 0, 8000);
	cb_QuietPlayers = MakeCheckbox(cont, h, "Quiet players", bQuietPlayers);
	cb_QuietPlayers.OnChanged = ChangeQuietPlayers;
	h += 8;
	s_SpeedometerAlpha = MakeSlider(cont, h, "Speedometer alpha", Speedometer_alpha, 0.0, 1.0);
	s_SpeedovectorsAlpha = MakeSlider(cont, h, "Speed vectors alpha", Speedovectors_alpha, 0.0, 1.0);

	h += 120;

	btn = class'GUIButton'.static.CreateButton(cont, "Save", OnClickSave);
	btn.SetAutoColor(MakeColor(32,200,32,255));
	btn.SetPosAuto("bottom:100%; width:40%; height:32");

	btn = class'GUIButton'.static.CreateButton(cont, "Close", OnClickClose);
	btn.SetAutoColor(MakeColor(255,64,64,255));
	btn.SetPosAuto("right:100%; bottom:100%; width:40%; height:32");

	panel.SetPosAuto("height:" $ h);

	pw_Keytracker = class'GUIPosWidget'.static.CreatePosWidget(Root, "Keytracker");
	pw_Timers = class'GUIPosWidget'.static.CreatePosWidget(Root, "Timers");
	pw_Boards = class'GUIPosWidget'.static.CreatePosWidget(Root, "Records");
	pw_Leaderboard = class'GUIPosWidget'.static.CreatePosWidget(Root, "Leaderboard");
	pw_Speedometer = class'GUIPosWidget'.static.CreatePosWidget(Root, "Speedometer");

	RefreshWidgets();
}

function GUISlider MakeSlider(GUIGroup cont, out int top, String label, float val, float vmin, float vmax)
{
	local GUISlider slider;

	slider = class'GUISlider'.static.CreateSlider(cont, val, vmin, vmax);
	slider.SetPosAuto("right:100%; top:"$top$"; width:200");

	MakeLabel(cont, top, slider.offH.Val, label);

	top += slider.offH.Val;

	return slider;
}

function GUICheckBox MakeCheckbox(GUIGroup cont, out int top, String label, bool val)
{
	local GUICheckBox cb;

	cb = class'GUICheckBox'.static.CreateCheckBox(cont, val);
	cb.SetPosAuto("right:100%; top:"$top);

	MakeLabel(cont, top, cb.offH.Val, label);

	top += cb.offH.Val;

	return cb;
}

function GUILabel MakeLabel(GUIGroup cont, int top, int height, String text)
{
	local GUILabel lbl;
	lbl = class'GUILabel'.static.CreateLabel(cont, text);
	lbl.SetPosAuto("left:0; top:"$top$"; width:100%; height:"$height);
	lbl.SetTextAlign(ALIGN_LEFT, ALIGN_MIDDLE);
	lbl.TextFont = class'HUD'.static.GetFontSizeIndex(1);
	lbl.SetTextColor(MakeColor(255,255,255,255));
	return lbl;
}


function ChangeQuietPlayers(GUICheckBox elem)
{
	// Remove weaponfire sounds
	PC.SetAudioGroupVolume('WeaponEnemy', elem.bChecked ? 0.0 : class'CRZAudioConfig'.default.SFXVolume);
}


function RefreshWidgets()
{
	pw_Keytracker.SetPosAuto(Keytracker_pos);
	pw_Keytracker.OnMoved(pw_Keytracker);
	pw_Timers.SetPosAuto(Timers_pos);
	pw_Timers.OnMoved(pw_Timers);
	pw_Boards.SetPosAuto(Boards_pos);
	pw_Boards.OnMoved(pw_Boards);
	pw_Leaderboard.SetPosAuto(Leaderboard_pos);
	pw_Leaderboard.OnMoved(pw_Leaderboard);
	pw_Speedometer.SetPosAuto(Speedometer_pos);
	pw_Speedometer.OnMoved(pw_Speedometer);

	s_KeytrackerAlpha.SetValue(Keytracker_alpha);
	s_KeytrackerAlpha.OnChanging(s_KeytrackerAlpha);

	s_TimersAlpha.SetValue(Timers_alpha);
	s_TimersAlpha.OnChanging(s_TimersAlpha);

	s_BoardsAlpha.SetValue(Boards_alpha);
	s_BoardsAlpha.OnChanging(s_BoardsAlpha);

	s_LeaderboardAlpha.SetValue(Leaderboard_alpha);
	s_LeaderboardAlpha.OnChanging(s_LeaderboardAlpha);

	cb_AutoBoards.SetChecked(bAutoBoards);
	cb_AutoBoards.OnChanged(cb_AutoBoards);
	s_AutoBoardsDelay.SetValue(AutoBoardsDelay);
	s_AutoBoardsDelay.OnChanging(s_AutoBoardsDelay);

	s_FadeoutDist.SetValue(FadeoutDist);
	s_FadeoutDist.OnChanging(s_FadeoutDist);
	cb_QuietPlayers.SetChecked(bQuietPlayers);
	cb_QuietPlayers.OnChanged(cb_QuietPlayers);

	s_SpeedometerAlpha.SetValue(Speedometer_alpha);
	s_SpeedometerAlpha.OnChanging(s_SpeedometerAlpha);
	s_SpeedovectorsAlpha.SetValue(Speedovectors_alpha);
	s_SpeedovectorsAlpha.OnChanging(s_SpeedovectorsAlpha);
}


function SaveOptions()
{
	Keytracker_pos = pw_Keytracker.GetBestAutoPos();
	Keytracker_alpha = s_KeytrackerAlpha.Value;

	Timers_pos = pw_Timers.GetBestAutoPos();
	Timers_alpha = s_TimersAlpha.Value;

	Boards_pos = pw_Boards.GetBestAutoPos();
	Boards_alpha = s_BoardsAlpha.Value;

	Leaderboard_pos = pw_Leaderboard.GetBestAutoPos();
	Leaderboard_alpha = s_LeaderboardAlpha.Value;

	bAutoBoards = cb_AutoBoards.bChecked;
	AutoBoardsDelay = s_AutoBoardsDelay.Value;

	FadeoutDist = Round(s_FadeoutDist.Value);
	bQuietPlayers = cb_QuietPlayers.bChecked;

	Speedometer_pos = pw_Speedometer.GetBestAutoPos();
	Speedometer_alpha = s_SpeedometerAlpha.Value;
	Speedovectors_alpha = s_SpeedovectorsAlpha.Value;

	SaveConfig();
}

function CloseMenu()
{
	RefreshWidgets();
	Super.CloseMenu();
}


exec function TTConfig()
{
	OpenMenu();
}

exec function ToggleAutoBoards()
{
	bAutoBoards = !bAutoBoards;
	SaveConfig();
}

exec function ToggleQuietPlayers()
{
	bQuietPlayers = !bQuietPlayers;
	cb_QuietPlayers.SetChecked(bQuietPlayers);
	cb_QuietPlayers.OnChanged(cb_QuietPlayers);
	SaveConfig();
}

exec function ToggleSpeedometer()
{
	Speedometer_alpha = Speedometer_alpha > 0 ? 0.0 : 0.8;
	SaveConfig();
	s_SpeedometerAlpha.SetValue(Speedometer_alpha);
	s_SpeedometerAlpha.OnChanging(s_SpeedometerAlpha);
}

exec function ToggleSpeedovectors()
{
	Speedovectors_alpha = Speedovectors_alpha > 0 ? 0.0 : 0.8;
	SaveConfig();
	s_SpeedovectorsAlpha.SetValue(Speedovectors_alpha);
	s_SpeedovectorsAlpha.OnChanging(s_SpeedovectorsAlpha);
}

exec function TTConfigReset(bool bConfirm)
{
	if ( !bConfirm )
		return;

	InitConfig();
	RefreshWidgets();
}


defaultproperties
{
	ConfigName="Trials"
}