//================================================================
// Trials.TTMapData
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTMapData extends Object
	Config(TrialsData)
	PerObjectConfig;

struct sRecord
{
	/** Index of player in PlayersList */
	var int PlayerIdx;
	/** Time (ms) of the record */
	var int Time;
	/** Cached rank (time-range) this record belongs in (-1 if not calculated yet) */
	var int Rank;

	structdefaultproperties
	{
		Rank=-1
	}
};
var config array<sRecord> GlobalRecord;

var config int NumLevels;

var array<TTLevelData> Levels;


static function TTMapData Load(String MapName, optional int CalculatedNumLevels=0)
{
	local TTMapData MapData;
	local int i;

	MapData = new(None, "TTMap-"$MapName) default.class(None);

	if ( CalculatedNumLevels > 0 && MapData.NumLevels > 0 && CalculatedNumLevels != MapData.NumLevels )
		`Log("[Trials] WARNING - Map has different amount of levels but MapName hasn't changed !! Please fix records manually");

	MapData.NumLevels = Max(MapData.NumLevels, CalculatedNumLevels);

	MapData.Levels.Length = MapData.NumLevels;
	for ( i=0; i<MapData.Levels.Length; i++ )
		MapData.Levels[i] = class'TTLevelData'.static.Load(MapName, i);

	return MapData;
}


defaultproperties
{
}
