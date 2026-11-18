## One named sound. Create .tres files from this (FileSystem > New Resource > SoundEntry),
## then add them to the "entries" list on the SoundManager scene.
## No code needed: set the id, drag audio files into "streams", done.
class_name SoundEntry
extends Resource

## The name the game asks for, e.g. &"footstep_walk". Must match the list at the top of sound_manager.gd.
@export var id: StringName
## Add several files for variation. One is picked at random each time, never the same one twice in a row.
@export var streams: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.5) var volume_db: float = 0.0
## Random pitch change. 0.1 means up to 10% higher or lower, so repeated footsteps don't sound identical.
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.05
## Which volume slider controls it. Use Music for chase_music, Ambience for ambience, SFX for the rest.
@export_enum("SFX", "Music", "Ambience") var bus: String = "SFX"
## Only for sounds that come from a spot in the world (doors, footsteps, the entity).
## Past this distance (meters) the sound is silent.
@export var max_distance: float = 30.0
