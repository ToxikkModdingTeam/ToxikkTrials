//================================================================
// Trials.TTHudMovie
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTHudMovie extends CRZHudMovie;

//function InitPlayerStats();
//function UpdatePlayerStats(CRZPlayerReplicationInfo myPRI);
function UpdatePlayerStats(CRZPlayerReplicationInfo myPRI)
{
	PlayerStatsMC.SetVisible(false);
}

// remove all the death screen stuff
function SetHudMode(EHudMode Mode)
{
	if ( !bMovieIsOpen )
		return;

	if ( Mode == HM_KillView )
	{
		Super.SetHudMode(Mode);

		if ( ! TTPRI(GetPC().PlayerReplicationInfo).bHasCS )
		{
			TTHud(GetPC().myHUD).SpawnTree.Show(true);
			EnableMouseCursor(true);
		}
	}
	else if ( Mode == HM_DroneView )
	{
		// don't change anything
	}
	else
	{
		TTHud(GetPC().myHUD).SpawnTree.Show(false);
		Super.SetHudMode(Mode);
	}
}

defaultproperties
{
}
