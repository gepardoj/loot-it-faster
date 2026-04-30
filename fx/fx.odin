package fx

import rl "vendor:raylib"

music_footsteps: rl.Music

chest_open: rl.Sound
lock_correct: rl.Sound
lock_incorrect: rl.Sound
lock_opened: rl.Sound
lockpick_cracked: rl.Sound

init :: proc() {
	rl.InitAudioDevice()
	music_footsteps = rl.LoadMusicStream("assets/sounds/footsteps.mp3")
	rl.PlayMusicStream(music_footsteps)

	chest_open = rl.LoadSound("assets/sounds/chest_open.mp3")
	lock_correct = rl.LoadSound("assets/sounds/lock_correct.mp3")
	lock_incorrect = rl.LoadSound("assets/sounds/lock_incorrect.mp3")
	lock_opened = rl.LoadSound("assets/sounds/lock_opened.mp3")
	lockpick_cracked = rl.LoadSound("assets/sounds/lockpick_cracked.mp3")
}

cleanup :: proc() {
	rl.UnloadSound(chest_open)
	rl.UnloadSound(lock_correct)
	rl.UnloadSound(lock_incorrect)
	rl.UnloadSound(lock_opened)
	rl.UnloadSound(lockpick_cracked)
	rl.UnloadMusicStream(music_footsteps)
	rl.CloseAudioDevice()
}
