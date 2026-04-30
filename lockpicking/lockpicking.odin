package lockpicking

import "../fx"
import "../game"
import "../inventory"
import "../level"
import "../rs"
import "core:fmt"
import "core:math/rand"
import "core:time"
import rl "vendor:raylib"

SCALE_M := rl.MatrixScale(.1, .1, .1)
ROT_X_M := rl.MatrixRotateX(-90 * rl.DEG2RAD)

grabbed_lockpick_obj: ^level.Lockpick


update :: proc(camera: ^rl.Camera) {
	lockpicking(camera)
	grab_lockpick_back(camera)
}

@(private)
grab_lockpick_back :: proc(camera: ^rl.Camera) {
	// if !inventory.is_open() do return
	// if grabbed_lockpick_obj != nil {
	// 	if rl.IsKeyReleased(.LEFT) {

	// 	}
	// 	return
	// }
	// for &lockpick in level.lockpicks {
	// 	if !lockpick.enabled do continue
	// 	if rl.IsMouseButtonPressed(.LEFT) {
	// 		ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), camera^)
	// 		rot_z_m := rl.MatrixRotateZ(f32(lockpick.rotation_z) * rl.DEG2RAD)
	// 		lockpick_transform :=
	// 			rl.MatrixTranslate(lockpick.pos.x, lockpick.pos.y, lockpick.pos.z) *
	// 			rot_z_m *
	// 			ROT_X_M *
	// 			SCALE_M
	// 		hit_info := rl.GetRayCollisionMesh(
	// 			ray,
	// 			rs.lockpick_model.meshes[0],
	// 			lockpick_transform,
	// 		)
	// 		if hit_info.hit && hit_info.distance <= game.USE_DISTANCE {
	// 			grabbed_lockpick_obj = &lockpick
	// 			lockpick.enabled = false
	// 			lockpick_item := inventory.create_item(.LOCKPICK, -1, -1)
	// 			inventory.set_dragged_item(lockpick_item)
	// 		}
	// 	}
	// }
}

@(private)
lockpicking :: proc(camera: ^rl.Camera) {
	for &lockpick in level.lockpicks {
		if !lockpick.enabled || lockpick.chest.opened do continue
		distance := rl.Vector3Distance(camera.position, lockpick.pos)
		if distance <= game.USE_DISTANCE {
			player_turn_dir: u16 = 13 // any value except 0, 1
			if rl.IsKeyPressed(.LEFT) do player_turn_dir = 0
			if rl.IsKeyPressed(.RIGHT) do player_turn_dir = 1
			if player_turn_dir == 0 || player_turn_dir == 1 {
				lock_turn_dir := (lockpick.chest.lock_code >> lockpick.chest.lock_index) & 1 // we get a bit 0 or 1 by the current index
				// correct turn
				if player_turn_dir == lock_turn_dir {
					fmt.println("correct turn")
					// left
					if player_turn_dir == 0 do lockpick.rotation_z += 15
					else do lockpick.rotation_z -= 15 // right
					lockpick.chest.lock_index += 1
					if lockpick.chest.lock_index == lockpick.chest.lock_size {
						lockpick.chest.opened = true
						fmt.println("a chest lock has opened")
						rl.PlaySound(fx.lock_opened)
					} else {
						rl.PlaySound(fx.lock_correct)
					}
				} else { 	// incorrect turn
					lockpick.rotation_z = level.LOCKPICK_ROTATION_Z
					fmt.println("incorrect turn")
					rl.PlaySound(fx.lock_incorrect)
					lockpick.chest.lock_index = 0
					if rand.float32_range(0, 1) <= level.LOCKPICK_CRACK_RATE {
						rl.PlaySound(fx.lockpick_cracked)
						lockpick.chest.is_lockpick_in = false
						lockpick.enabled = false
					}
				}
			}
		}
	}
}
