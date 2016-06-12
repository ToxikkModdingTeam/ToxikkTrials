//================================================================
// Trials.TTPlayersList
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTPlayersList extends Object
	Config(TrialsData)
	PerObjectConfig;

struct sPlayerData
{
	var String Name;
	var int TotalPoints;
};
var config array<sPlayerData> Player;

defaultproperties
{
}
