//================================================================
// Trials.TTHud
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTHud extends CRZHud;

var TTSpawnTree SpawnTree;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	SpawnTree = TTSpawnTree(CreateInteraction(class'TTSpawnTree'));
}

function Interaction CreateInteraction(class<Interaction> IntClass)
{
	local GameViewportClient Viewport;
	local Interaction newInt;

	Viewport = LocalPlayer(PlayerOwner.Player).ViewportClient;
	newInt = new(Viewport) IntClass;
	Viewport.InsertInteraction(newInt, 0);
	PlayerOwner.Interactions.InsertItem(0, newInt);
	return newInt;
}

simulated event Tick(float dt)
{
	local UTPawn P;

 	Super.Tick(dt);

	// fix-workaround for pawn landing issue (it's a clientside-only fix)
	P = UTPawn(PlayerOwner.Pawn);
	if ( P != None && P.Physics == PHYS_Walking && P.MultiJumpRemaining < P.MaxMultiJump )
		P.Landed(Vect(0,0,1), P.Base);
}

exec function PlaceCustomSpawn()
{
	if ( TTPRI(PlayerOwner.PlayerReplicationInfo) != None )
		TTPRI(PlayerOwner.PlayerReplicationInfo).ServerPlaceCustomSpawn();
}

exec function RemoveCustomSpawn()
{
	if ( TTPRI(PlayerOwner.PlayerReplicationInfo) != None )
		TTPRI(PlayerOwner.PlayerReplicationInfo).ServerRemoveCustomSpawn();
}


defaultproperties
{
	ScoreBoardClass=class'TTScoreboard'
}
