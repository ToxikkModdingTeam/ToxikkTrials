//================================================================
// package.TTMusicManager
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class TTMusicManager extends CRZMusicManager;

var array<MusicSegment> AllMusics;
var AudioComponent Fadeout;
var float FadeFactor;

function StopIntroMusic()
{
	ChangeTrack(MST_Ambient);
}

function NotifyPlayerSpawn()
{
	if ( MusicStartTime <= 0 || WorldInfo.TimeSeconds - MusicStartTime >= 30 )
		ChangeTrack(MST_Ambient);
}

function ChangeTrack(EMusicState NewState)
{
	local int i;

	if ( Fadeout != None && Fadeout.IsPlaying() )
		Fadeout.Stop();

	Fadeout = CurrentTrack;

	//not sure if used
	LastBeat = 0;

	i = Rand(AllMusics.Length);
	while ( CurrentTrack != None && CurrentTrack.SoundCue == AllMusics[i].TheCue )
		i = Rand(AllMusics.Length);

	CurrentTrack = CreateNewTrack(AllMusics[i].TheCue);
	CurrentTrack.VolumeMultiplier = 0.01;
	CurrentTrack.Play();

	MusicStartTime = WorldInfo.TimeSeconds;
}

function Tick(float dt)
{
	local float Dur, Time;

	if ( CurrentTrack != None && CurrentTrack.VolumeMultiplier < MusicVolume )
		CurrentTrack.VolumeMultiplier = FMin(CurrentTrack.VolumeMultiplier + FadeFactor*dt, MusicVolume);

	if ( Fadeout != None && Fadeout.VolumeMultiplier > 0.f )
	{
		Fadeout.VolumeMultiplier = Fadeout.VolumeMultiplier - FadeFactor*dt;
		if ( Fadeout.VolumeMultiplier <= 0.f )
		{
			Fadeout.VolumeMultiplier = 0.f;
			Fadeout.Stop();
			Fadeout = None;
		}
	}

	if ( CurrentTrack != None )
	{
		Dur = CurrentTrack.SoundCue.GetCueDuration();
		Time = WorldInfo.TimeSeconds - MusicStartTime;
		if ( (Dur > 300 && Time >= 120) || (Time >= Dur-3) )
			ChangeTrack(MST_Ambient);
	}
}

defaultproperties
{
	FadeFactor=0.3

	AllMusics=()
	AllMusics.Add((TheCue=SoundCue'MUS_Action.Cue.MUS_Action_Chemical'))
	AllMusics.Add((TheCue=SoundCue'MUS_Action.Cue.MUS_Action_Hollywood'))
	AllMusics.Add((TheCue=SoundCue'MUS_Action.Cue.MUS_Action_Metal'))
	AllMusics.Add((TheCue=SoundCue'MUS_Action.Cue.MUS_Action_Mixed'))
	AllMusics.Add((TheCue=SoundCue'MUS_Action.Cue.MUS_Action_SkyCity'))
	AllMusics.Add((TheCue=SoundCue'MUS_Action.Cue.MUS_Action_Urban'))
	AllMusics.Add((TheCue=SoundCue'MUS_Ambient.Cue.MUS_Ambient_Chemical'))
	AllMusics.Add((TheCue=SoundCue'MUS_Ambient.Cue.MUS_Ambient_Dark_Urbban'))
	AllMusics.Add((TheCue=SoundCue'MUS_Ambient.Cue.MUS_Ambient_Hollywood'))
	AllMusics.Add((TheCue=SoundCue'MUS_Ambient.Cue.MUS_Ambient_Mixed'))
	AllMusics.Add((TheCue=SoundCue'MUS_Ambient.Cue.MUS_Ambient_SkyCity'))
	AllMusics.Add((TheCue=SoundCue'MUS_Ambient.Cue.MUS_Ambient_Trial'))
	AllMusics.Add((TheCue=SoundCue'MUS_Ambient.Cue.MUS_Ambient_Urban'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Artifact'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Caliber'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Castello'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Citadel'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Cube'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Dekk'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Ehrgeiz'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Foundation'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_Ganesha'))
	AllMusics.Add((TheCue=SoundCue'MUS_Intro.Cue.MUS_Intro_TwinPeaks'))
	AllMusics.Add((TheCue=SoundCue'MUS_Suspense.Cue.MUS_Suspense_TwinPeaks'))
	AllMusics.Add((TheCue=SoundCue'MUS_Tension.Cue.MUS_Tension_TwinPeaks'))
}