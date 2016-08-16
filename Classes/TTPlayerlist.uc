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
	var config String Uid;
	/** Last known name of player - updated every time he joins server */
	var config String Name;
	/** Total points this player has */
	var config int TotalPoints;

	/** (instance) Reference to ingame player */
	var TTPRI PRI;
};
var config array<sPlayerData> Player;

/** Index map for sorted players list */
var array<int> Sortmap;


static function TTPlayerlist Load()
{
	return new(None, "TTPlayerlist") default.class(None);
}

/** Matches up PRI with stored player data (defines TTPRI.Idx) - creates new entry if not found */
function SyncPlayer(TTPRI PRI)
{
	local String Uid;
	local int i;

	Uid = class'OnlineSubsystemSteamworks'.static.UniqueNetIdToString(PRI.UniqueId);

	i = Player.Find('Uid', Uid);
	if ( i == INDEX_NONE )
	{
		i = Player.Length;
		Player.Length = i+1;
		Player[i].Uid = Uid;
		Player[i].TotalPoints = 0;
	}
	Player[i].Name = PRI.PlayerName;
	SaveConfig();   //TODO: rework the SaveConfig - maybe do it every minute?

	Player[i].PRI = PRI;

	PRI.Idx = i;
	PRI.LeaderboardPos = Sortmap.Find(i);
	PRI.TotalPoints = Player[i].TotalPoints;
	PRI.MapPoints = 0;
}

function SortPlayers()
{
	local int i,k;

	Sortmap.Length = Player.Length;
	// Only sort players that have points
	for ( i=0; i<Player.Length; i++ )
	{
		if ( Player[i].TotalPoints > 0 )
		{
			Sortmap[k] = i;
			k++;
		}
	}
	Sortmap.Length = k;

	Sortmap.Sort(ComparePlayers);
}

function int ComparePlayers(int p1, int p2)
{
	return (Player[p1].TotalPoints - Player[p2].TotalPoints);
}


defaultproperties
{
}
