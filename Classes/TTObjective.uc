//================================================================
// Trials.TTObjective
// ----------------
// - End of path
// - Sublevel delimiter for records
// - Contributes to global record
// ----------------
// by Chatouille
//================================================================
class TTObjective extends TTLevel
	placeable
	hidecategories(Checkpoint,Savepoint,Level);


/** Called by the gamemode */
simulated function ReachedBy(TTPRI PRI)
{
	NotifyPlayer(PRI);
	CheckLevelTime(PRI);
	ValidateObjectiveFor(PRI);
	UpdatePlayerTargets(PRI);
}

simulated function ValidateObjectiveFor(TTPRI PRI)
{
	if ( !PRI.bStopGlobal && PRI.ValidatedObjectives.Find(Self) == INDEX_NONE )
	{
		PRI.ValidatedObjectives.AddItem(Self);

		if ( Role == ROLE_Authority && PRI.ValidatedObjectives.Length == TTGRI(WorldInfo.GRI).TotalObjectives )
		{
			if ( PlayerController(PRI.Owner) != None )
				PlayerController(PRI.Owner).ReceiveLocalizedMessage(class'TTGlobalTimeMessage', PRI.CurrentTimeMillis()-PRI.GlobalStartDate, PRI,, Self);

			PRI.SetGlobalTimerEnabled(false);
			PRI.ClearTimer('SendTimerSync');

			TTGame(WorldInfo.Game).CheckGlobalTime(PRI);
		}
	}
}


defaultproperties
{
	ReachString="Objective done"

	HudText="OBJ"
	HudColor=(R=255,G=0,B=255,A=255)
}
