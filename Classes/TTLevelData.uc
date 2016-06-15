//================================================================
// Trials.TTLevelData
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTLevelData extends Object DependsOn(TTMapData)
	Config(TrialsData)
	PerObjectConfig;


var config array<sRecord> Record;


static function TTLevelData Load(String MapName, int LevelIdx)
{
	return new(None, "TTLevel-"$LevelIdx$"-"$MapName) default.class(None);
}


defaultproperties
{
}
