//================================================================
// package.TTCustomSpawnMessage
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTCustomSpawnMessage extends CRZSubCenterMessage;

static simulated function ClientReceive(PlayerController PC, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    Super.ClientReceive(PC, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

	PC.PlayBeepSound();
}

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
    return None;
}

static function string GetCRZString(optional int Switch, optional PlayerController P, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	Switch (Switch)
	{
		case 0: return "Custom  spawn  placed !";
		case 1: return "Cannot  place  custom  spawn  while  in  movement !";
		case 2: return "Custom  spawn  removed !";
		case 3: return "Not  allowed  on  this  server !";
		case 4: return "Not  allowed  with  active  custom  respawn !";
	}
}

defaultproperties
{
	bIsUnique=false
	bIsConsoleMessage=false
	AnnouncementPriority=100
	bLongOpen=true
}
