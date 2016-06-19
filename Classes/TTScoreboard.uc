//================================================================
// Trials.TTScoreboard
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTScoreboard extends ModularScoreboard;

/** Initialize row for player */
function InitializeRow(out sb_Row PRow)
{
	UpdateField(PRow, "FROM", "---");
	UpdateField(PRow, "LVL", "--");
	PRow.Background.SetVisible(true);
}

/** Update row for player */
function UpdateRow(out sb_Row PRow, CRZPlayerReplicationInfo CRZPRI)
{
	local TTPRI PRI;

	PRI = TTPRI(CRZPRI);
	if ( PRI == None )
	{
		Super.UpdateRow(PRow, CRZPRI);
		return;
	}

	// Highlight myself
	if ( PRI.IsLocalPlayerPRI() )
		PRow.Background.SetVisible(true);
	else
		PRow.Background.SetVisible(false);

	UpdateField(PRow, "POS", PRI.bOnlySpectator ? "SPC" : class'CRZHud'.static.FormatInteger(PRI.ScoreboardRank,2) );

	UpdateField(PRow, "ID", Left(PRI.PlayerName,9));

	UpdateField(PRow, "FROM", PRI.bBot ? "---" : Caps(Left(PRI.CountryCode,3)) );

	UpdateField(PRow, "CLAN", PRI.ClanTag == "" ? "---" : Caps(Left(PRI.ClanTag,3)) );

	UpdateField(PRow, "LVL", class'CRZHud'.static.FormatInteger(int(PRI.SkillClass), 2));

	UpdateField(PRow, "GRANK", PRI.LeaderboardPos != -1 ? ("<font color='#FF0000'>" $ (PRI.LeaderboardPos+1) $ "</font>") : "N/A");

	UpdateField(PRow, "TOTAL", PRI.TotalPoints != -1 ? ("<font color='#FF0000'>" $ PRI.TotalPoints $ "</font>") : "N/A");

	UpdateField(PRow, "MAPPOINTS", PRI.MapPoints != -1 ? ("<font color='#FFFF00'>" $ PRI.MapPoints $ "</font>") : "N/A");

	UpdateField(PRow, "TIME", class'CRZHud'.static.FormatTime(FMax(0,CRZGameReplicationInfo(PRI.WorldInfo.GRI).GetElapsedTime() - PRI.StartTime)) );

	UpdateField(PRow, "PING", class'CRZHud'.static.FormatPingHexColor(PRI.GetPing()*1000, true));
}

defaultproperties
{
	Columns = ()
	Columns.Add(( Name="POS",   Align=ALIGN_Left,   MinSize=2, bFieldsHTML=true ))
	Columns.Add(( Name="ID",    Align=ALIGN_Left,   MinSize=9, Color=0xFFFFFF ))
	Columns.Add(( Name="FROM",  Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="CLAN",  Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="LVL",   Align=ALIGN_Center, MinSize=2, bFieldsHTML=true ))

	Columns.Add(( Name="GRANK", Align=ALIGN_Center, MinSize=3, bFieldsHTML=true, bHeadHTML=true, Title="<font color='#FF0000'>GPOS</font>" ))
	Columns.Add(( Name="TOTAL", Align=ALIGN_Center, MinSize=5, bFieldsHTML=true, bHeadHTML=true, Title="<font color='#FF0000'>TOTAL</font>" ))
	Columns.Add(( Name="MAPPOINTS", Align=ALIGN_Center, MinSize=4, bFieldsHTML=true, bHeadHTML=true, Title="<font color='#FFFF00'>MAP</font>" ))

	Columns.Add(( Name="TIME",  Align=ALIGN_Right,  MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="PING",  Align=ALIGN_Right,  MinSize=3, bFieldsHTML=true ))
}
