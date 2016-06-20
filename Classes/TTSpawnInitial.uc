//================================================================
// package.TTSpawnInitial
// ----------------
// Simple TTSavepoint wrapper for PointZero.InitialPoint
// For mappers
// ----------------
// by Chatouille
//================================================================
class TTSpawnInitial extends TTSavepoint
	placeable
	hidecategories(HUD,Trigger,Collision);

defaultproperties
{
	SpawnTreeLabel="START"
	bInitiallyAvailable=true
	UnlockString=""

	ReachString=""

	CollisionType=COLLIDE_NoCollision
}
