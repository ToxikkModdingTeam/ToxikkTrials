//================================================================
// Trials.TTDynamicPointZero
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTDynamicPointZero extends TTPointZero;

var TTWaypoint RepNextPoints[8];

Replication
{
	if ( bNetInitial )
		RepNextPoints;
}

// this one won't be called on client
simulated function Init(TTGRI GRI)
{
	local int i;

	for ( i=0; i<NextPoints.Length && i<8; i++ )
		RepNextPoints[i] = NextPoints[i];
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( WorldInfo.NetMode == NM_Client )
		SetTimer(0.1, false, 'PostNetBeginPlay');
}

simulated function PostNetBeginPlay()
{
	local int i;

	for ( i=0; i<8; i++ )
		if ( RepNextPoints[i] != None )
			NextPoints.AddItem(RepNextPoints[i]);
}

defaultproperties
{
	bNoDelete=false
	RemoteRole=ROLE_SimulatedProxy
	bNetTemporary=true
}
