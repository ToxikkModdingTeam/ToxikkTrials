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
	/** Cached rank (time-range) this record belongs in */
	var int Rank;
	/** LevelRecord only - Reference to TTLevel.LevelIdx */
	var int LevelIdx;
};
var config array<sRecord> GlobalRecord;
var config array<sRecord> LevelRecord;

defaultproperties
{
}
