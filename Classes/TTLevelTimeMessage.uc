//================================================================
// Trials.TTLevelTimeMessage
// ----------------
// 
// ----------------
// by Chatouille
//================================================================
class TTLevelTimeMessage extends CRZRewardMessage;

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
    return None;
}

static function string GetCRZString(optional int Switch, optional PlayerController PC, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	local String Str;

	if ( TTLevel(OptionalObject) != None )
		Str = Repl(TTLevel(OptionalObject).TimeMessage, "%lvl", TTLevel(OptionalObject).LevelDisplayName);
	else
		Str = Repl(class'TTLevel'.default.TimeMessage, "%lvl", class'TTLevel'.default.LevelDisplayName);

	return Repl(Str, "%time", class'TTHud'.static.FormatTrialTime(Switch));
}

defaultproperties
{
	bIsUnique=false
	bIsConsoleMessage=false
	AnnouncementPriority=100
	bIgnoreMessageBlock=true
}
