//================================================================
// Trials.TTScoreboard
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTScoreboard extends GFxCRZUIScoreBoard;


function UpdateField(out array <sb_Row> Rows, byte RowIdx, byte ColIdx, optional string ColName, optional string OverrideText, optional object Content)
{	
	local TTPRI PRI;

	PRI = TTPRI(Content);
	if ( PRI != None )
	{
		Switch (ColName)
		{
			case "GRANK":
				UpdateFieldValue(Rows, RowIdx, ColIdx, PRI.LeaderboardPos != -1 ? ("<font color='#FF0000'>" $ (PRI.LeaderboardPos+1) $ "</font>") : "N/A");
				return;
			case "TOTAL":
				UpdateFieldValue(Rows, RowIdx, ColIdx, PRI.TotalPoints != -1 ? ("<font color='#FF0000'>" $ PRI.TotalPoints $ "</font>") : "N/A");
				return;
			case "MAPPOINTS":
				UpdateFieldValue(Rows, RowIdx, ColIdx, PRI.MapPoints != -1 ? ("<font color='#FFFF00'>" $ PRI.MapPoints $ "</font>") : "N/A");
				return;
		}
	}
	Super.UpdateField(Rows, RowIdx, ColIdx, ColName, OverrideText, Content);
}


defaultproperties
{
	Columns = ()
	Columns.Add(( Name="POS",        Align=ALIGN_Left,   MinSize=2, bFieldsHTML=true ))
	Columns.Add(( Name="PLAYERNAME", Align=ALIGN_Left,   MinSize=9, Color=0xFFFFFF ))
	Columns.Add(( Name="FROM",       Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="CLAN",       Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="SKILLCLASS", Align=ALIGN_Center, MinSize=2, bFieldsHTML=true ))

	Columns.Add(( Name="GRANK",      Align=ALIGN_Center, MinSize=3, bFieldsHTML=true, bHeadHTML=true, Title="<font color='#FF0000'>GPOS</font>" ))
	Columns.Add(( Name="TOTAL",      Align=ALIGN_Center, MinSize=5, bFieldsHTML=true, bHeadHTML=true, Title="<font color='#FF0000'>TOTAL</font>" ))
	Columns.Add(( Name="MAPPOINTS",  Align=ALIGN_Center, MinSize=4, bFieldsHTML=true, bHeadHTML=true, Title="<font color='#FFFF00'>MAP</font>" ))

	Columns.Add(( Name="TIME",       Align=ALIGN_Right,  MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="PING",       Align=ALIGN_Right,  MinSize=3, bFieldsHTML=true ))
}
