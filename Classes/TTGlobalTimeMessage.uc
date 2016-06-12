//================================================================
// Trials.TTGlobalTimeMessage
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTGlobalTimeMessage extends CRZRewardMessage;

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
    return None;
}

static function string GetCRZString(optional int Switch, optional PlayerController PC, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	return "Map finished in " $ class'TTHud'.static.FormatTrialTime(Switch);
}

defaultproperties
{
	bIsUnique=false
	bIsConsoleMessage=false
	AnnouncementPriority=100
	bIgnoreMessageBlock=true
}
