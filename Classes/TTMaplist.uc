//================================================================
// Trials.TTMaplist
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTMaplist extends Object
	Config(TrialsData)
	PerObjectConfig;

var config array<String> Map;


static function TTMaplist Load()
{
	return new(None, "TTMaplist") default.class(None);
}

defaultproperties
{
}
