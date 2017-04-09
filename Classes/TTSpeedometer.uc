//================================================================
// ToxikkTrials.TTSpeedometer
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTSpeedometer extends Interaction
	Config(Trials);

var GameViewportClient Viewport;
var PlayerController PC;
var GUIRoot Root;

var TTConfigMenu Conf;

var GUIGroup grp_Vectors;

var GUIGroup grp_Graph;
var GUILabel lbl_Speed;
var GUILabel lbl_zSpeed;
var GUIGroup Graph;

CONST CONFIG_VERSION = 1;
var config int ConfigVersion;
var config Color GraphBg, GraphBorder, GraphLine, GraphFill;
var config Color ForwardColor, VelocityColor, AccelColor;

var config float GRAPH_TIME_SPAN;
var config int GRAPH_FREQ_MS;
var int GRAPH_POINTS;
const GRAPH_MAX_SPEED = 1000.0;

var array<int> GraphPoints;
var int GraphLast;

function InitConfig()
{
	GRAPH_TIME_SPAN = 8.0;
	GRAPH_FREQ_MS = 20;

	GraphBg = MakeColor(0,0,0,80);
	GraphBorder = MakeColor(255,255,255,160);
	GraphLine = MakeColor(255,220,0,100);
	GraphFill = MakeColor(255,220,0,80);

	ForwardColor = MakeColor(255,255,255,80);
	VelocityColor = MakeColor(0,220,0,255);
	AccelColor = MakeColor(255,0,0,160);

	ConfigVersion = CONFIG_VERSION;
	SaveConfig();
}

function Initialized()
{
	if ( ConfigVersion != CONFIG_VERSION )
		InitConfig();

	GRAPH_POINTS = FCeil((1000.0*GRAPH_TIME_SPAN) / GRAPH_FREQ_MS);

    Viewport = GameViewportClient(Outer);
    PC = Viewport.GetPlayerOwner(0).Actor;

	Conf = TTConfigMenu(class'ClientConfigMenuManager'.static.FindCCM(PC).AddMenuInteraction(class'TTConfigMenu'));

    Root = class'GUIRoot'.static.Create(Self, Viewport);

	grp_Graph = class'GUIGroup'.static.CreateGroup(Root);
	grp_Graph.SetPosAuto(Conf.Speedometer_pos);
	grp_Graph.SetPosAuto("width:256; height:128");
	grp_Graph.SetAlpha(Conf.Speedometer_alpha);

	lbl_Speed = class'GUILabel'.static.CreateLabel(grp_Graph, "0 u/s");
	lbl_Speed.SetTextAlign(ALIGN_RIGHT, ALIGN_TOP);
	lbl_Speed.SetPosAuto("right:100%; top:0; height:18");

	lbl_zSpeed = class'GUILabel'.static.CreateLabel(grp_Graph, "0 u/s");
	lbl_zSpeed.SetTextAlign(ALIGN_RIGHT, ALIGN_BOTTOM);
	lbl_zSpeed.SetPosAuto("right:100%; bottom:100%; height:18");

	Graph = class'GUIGroup'.static.CreateGroup(grp_Graph);
	Graph.SetPosAuto("width:100%; center-y:50%; height:" $ (grp_Graph.offH.Val - lbl_Speed.offH.Val - lbl_zSpeed.offH.Val));
	Graph.SetColors(GraphBg, GraphBorder);
	Graph.OnDraw = RenderGraph;

	grp_Vectors = class'GUIGroup'.static.CreateGroup(Root);
	grp_Vectors.SetPosAuto("center-x:50%; center-y:50%; width:15%; height:15%");
	grp_Vectors.OnDraw = RenderVectors;
	grp_Vectors.SetAlpha(Conf.Speedovectors_alpha);

	Conf.pw_Speedometer.OnMoved = ChangeSpeedometerPos;
	Conf.s_SpeedometerAlpha.OnChanging = ChangeSpeedometerAlpha;
	Conf.s_SpeedovectorsAlpha.OnChanging = ChangeSpeedovectorsAlpha;
}

function ChangeSpeedometerPos(GUIDraggable elem)
{
	grp_Graph.SetPosAuto(GUIPosWidget(elem).GetBestAutoPos());
}

function ChangeSpeedometerAlpha(GUISlider elem)
{
	grp_Graph.SetAlpha(elem.Value);
}

function ChangeSpeedovectorsAlpha(GUISlider elem)
{
	grp_Vectors.SetAlpha(elem.Value);
}


event Tick(float dt)
{
	if ( PC != None && PC.Pawn != None && !PC.WorldInfo.GRI.bMatchIsOver )
		Root.Tick(dt);
}

event PostRender(Canvas C)
{
	if ( PC != None && PC.Pawn != None && !PC.WorldInfo.GRI.bMatchIsOver )
	{
		// Update labels
		lbl_Speed.Text = Round(VSize2D(PC.Pawn.Velocity)) $ " u/s";
		lbl_Speed.SizeToFit(C);
		lbl_zSpeed.Text = Round(PC.Pawn.Velocity.Z) $ " u/s";
		lbl_zSpeed.SizeToFit(C);

		Root.PostRender(C);
	}
}

function RenderVectors(GUIGroup elem, Canvas C)
{
	local float x1, x2, y1, y2;
	local float angle;

	if ( !elem.ShouldDraw() )
		return;

	x1 = elem.absX + elem.absW/2;
	y1 = elem.absY + elem.absH/2;

	x2 = x1;
	y2 = y1 - elem.absH;
	C.Draw2DLine(x1, y1, x2, y2, elem.ApplyAlpha(ForwardColor));

	angle = Rotator(PC.Pawn.Velocity).Yaw;
	if ( angle != 0 )
	{
		angle = (angle - PC.Rotation.Yaw) * UnrRotToRad;
		x2 = x1 + elem.absW * Sin(angle);
		y2 = y1 - elem.absH * Cos(angle);

		C.Draw2DLine(x1, y1, x2, y2, elem.ApplyAlpha(VelocityColor));
	}

	angle = Rotator(PC.Pawn.Acceleration).Yaw;
	if ( angle != 0 )
	{
		angle = (angle - PC.Rotation.Yaw) * UnrRotToRad;
		x2 = x1 + elem.absW * Sin(angle);
		y2 = y1 - elem.absH * Cos(angle);

		C.Draw2DLine(x1, y1, x2, y2, elem.ApplyAlpha(AccelColor));
	}
}

function RenderGraph(GUIGroup elem, Canvas C)
{
	local int now, i, j, t, last, size;
	local array<Vector> segs;
	local Color Col;

	if ( !elem.ShouldDraw() )
		return;

	// Potentially dynamically configurable now
	if ( GraphPoints.Length != GRAPH_POINTS )
	{
		GraphPoints.Remove(0, GraphPoints.Length);
		GraphPoints.Add(GRAPH_POINTS);
	}

	// Draw bg and box
	elem.InternalOnDraw(elem, C);

	// index for current time
	now = FFloor( (PC.WorldInfo.TimeSeconds % GRAPH_TIME_SPAN) * (1000 / GRAPH_FREQ_MS) );

	// set value for current time
	GraphPoints[now] = Round(VSize2D(PC.Pawn.Velocity));

	// fill all points between last tick and now
	size = (GRAPH_POINTS+now-GraphLast) % GRAPH_POINTS;
	i = 0;
	for ( t=GraphLast; t!=now; t=(t+1)%GRAPH_POINTS )
	{
		GraphPoints[t] = Round(Lerp(float(GraphPoints[GraphLast]), float(GraphPoints[now]), float(i)/float(size)));
		i++;
	}

	GraphLast = now;

	// iterate in reverse order
	// start from now
	// go in reverse order
	// wrap around 0->1000
	// draw the graph from right to left
	last = now;
	j = 0;
	for ( i=1; i<GRAPH_POINTS; i++ )
	{
		t = (GRAPH_POINTS+now-i) % GRAPH_POINTS;
		if ( GraphPoints[t] != GraphPoints[last] || i == GRAPH_POINTS-1 )
		{
			size = (GRAPH_POINTS+last-t) % GRAPH_POINTS;

			j = segs.Length;
			segs.Length = j+1;
			// x = (i-size) .. i
			segs[j].X = elem.absX + elem.absW - (i / float(GRAPH_POINTS)) * elem.absW;
			segs[j].Z = segs[j].X + (size / float(GRAPH_POINTS)) * elem.absW;
			// y = GraphPoints[last]
			segs[j].Y = elem.absY + elem.absH - (GraphPoints[last] / GRAPH_MAX_SPEED) * elem.absH;

			/*
			// fill
			elem.SetDrawColor(C, GraphFill);
			C.SetPos(x1, y1);
			//C.DrawRect(x2-x1, elem.absY+elem.absH-y1);
			C.DrawTile(C.DefaultTexture, x2-x1, elem.absY+elem.absH-y, 0, 0, 32, 32);
			// segment
			C.Draw2DLine(x1, y, x2, y, elem.ApplyAlpha(GraphLine));
			*/

			last = t;
		}
	}

	// Optimize drawing - we loop twice, but it's worth it (DrawTile is the most expensive by far)
	C.SetDrawColorStruct(elem.ApplyAlpha(GraphFill));
	C.PreOptimizeDrawTiles(segs.Length, C.DefaultTexture);
	for ( j=0; j<segs.Length; j++ )
	{
		C.SetPos(segs[j].X, segs[j].Y);
		//C.DrawRect(segs[j].Z-segs[j].X, elem.absY+elem.absH-segs[j].Y);
		C.DrawTile(C.DefaultTexture, segs[j].Z-segs[j].X, elem.absY+elem.absH-segs[j].Y, 0, 0, 32, 32);
	}
	Col = elem.ApplyAlpha(GraphLine);
	for ( j=0; j<segs.Length; j++ )
		C.Draw2DLine(segs[j].X, segs[j].Y, segs[j].Z, segs[j].Y, Col);
}


defaultproperties
{
}