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

function int MapPointsForPlayer(int Idx)
{
	local int i,j;
	local int Total;

	Total = 0;

	i = GlobalRecord.Find('PlayerIdx', Idx);
	if ( i != INDEX_NONE )
		Total += class'TTGame'.static.PointsForGlobalRank(GlobalRecord[i].Rank);

	for ( i=0; i<Levels.Length; i++ )
	{
		j = Levels[i].Record.Find('PlayerIdx', Idx);
		if ( j != INDEX_NONE )
			Total += class'TTGame'.static.PointsForLevelRank(Levels[i].Record[j].Rank);
	}

	return Total;
}


defaultproperties
{
}
