//================================================================
// Trials.TTDynamicPointZero
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTDynamicPointZero extends TTPointZero
	notplaceable;

var TTSavePoint RepInitialPoint;

Replication
{
	if ( bNetInitial )
		RepInitialPoint;
}

// this one won't be called on client
simulated function Init(TTGRI GRI)
{
	Super.Init(GRI);
	RepInitialPoint = InitialPoint;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( WorldInfo.NetMode == NM_Client )
		SetTimer(0.1, false, 'PostNetBeginPlay');
}

simulated function PostNetBeginPlay()
{
	InitialPoint = RepInitialPoint;
	if ( InitialPoint != None )
		InitialPoint.bInitiallyAvailable = true;
}

defaultproperties
{
	bNoDelete=false
	RemoteRole=ROLE_SimulatedProxy
	bNetTemporary=true
}
