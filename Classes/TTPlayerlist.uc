//================================================================
// Trials.TTPlayerlist
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTPlayerlist extends Object
	Config(TrialsData)
	PerObjectConfig;

struct StrictConfig sPlayerData
{
	/** Unique Net ID of player */
	var config String UID;
	/** Last known name of player - updated every time he joins server */
	var config String Name;
	/** Total points this player has */
	var config int TotalPoints;

	/** (instance) Reference to ingame player */
	var TTPRI PRI;
};
var config array<sPlayerData> Player;


static function TTPlayerlist Load()
{
	return new(None, "TTPlayerlist") default.class(None);
}

/** Matches up PRI with stored player data (defines TTPRI.Idx) - creates new entry if not found */
function InitPlayer(TTPRI PRI)
{
	local String UID;
	local int i;

	UID = class'OnlineSubsystemSteamworks'.static.UniqueNetIdToString(PRI.UniqueId);

	i = Player.Find('UID', UID);
	if ( i == INDEX_NONE )
	{
		i = Player.Length;
		Player.Length = i+1;
		Player[i].UID = UID;
		Player[i].TotalPoints = 0;
	}
	Player[i].Name = PRI.PlayerName;
	SaveConfig();   //TODO: rework the SaveConfig - maybe do it every minute?

	Player[i].PRI = PRI;
	PRI.Idx = i;
}


defaultproperties
{
}
