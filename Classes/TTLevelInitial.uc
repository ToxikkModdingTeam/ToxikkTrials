//================================================================
// Trials.TTLevelInitial
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTLevelInitial extends TTLevel
	placeable
	hidecategories(HUD,Trigger,Collision);

defaultproperties
{
	LevelDisplayName="- Level 1 -"

	SpawnTreeLabel="LVL 1"
	bInitiallyAvailable=true
	UnlockString=""

	ReachString=""

	CollisionType=COLLIDE_NoCollision
}
