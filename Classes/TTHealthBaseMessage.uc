//================================================================
// Trials.TTHealthBaseMessage
// ----------------
// Getting the right symbol icon
// ----------------
// by Chatouille
//================================================================
class TTHealthBaseMessage extends CRZPickupMessage;

static function string GetSymbolNameByInventoryClassOrSwitch(optional Object ItemClass, optional int MSwitch)
{
	return "HealthPack";
}

defaultproperties
{
}
