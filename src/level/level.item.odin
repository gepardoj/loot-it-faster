package level

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

LOCKPICK_ROTATION_Z :: 90
LOCK_DIFFICULTY :: 4
LOCKPICK_CRACK_RATE :: .20


Chest :: struct {
	pos:            rl.Vector3,
	opened:         bool,
	is_lockpick_in: bool,
	lock_size:      u8,
	lock_index:     u8, // it keeps index where we are lockpicking
	lock_code:      u16, // bit mask 0 - left, 1 - right
}

Lockpick :: struct {
	pos:        rl.Vector3,
	rotation_z: int,
	chest:      ^Chest,
	enabled:    bool,
}

create_chest :: proc(pos: rl.Vector3) -> Chest {
	size, code := generate_random_lock_code()
	return Chest{pos, false, false, size, 0, code}
}

create_lockpick :: proc(pos: rl.Vector3, chest: ^Chest) -> Lockpick {
	return Lockpick{pos, LOCKPICK_ROTATION_Z, chest, true}
}

// get size and code (bit mask)
generate_random_lock_code :: proc() -> (u8, u16) {
	size: u8 = LOCK_DIFFICULTY
	code: u16 = 0
	for i in 0 ..< size {
		bit := u16(rand.int_range(0, 2)) // 0 or 1
		code = (code << 1) | bit
	}
	// code := rand.choice([]u16{0b0101, 0b1010})
	// 1010 // R L R L
	fmt.printf("%b\n", code)
	return size, code
}
