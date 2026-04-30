package physics

import "../game"
import "../level"
import rl "vendor:raylib"

is_collide_level_walls :: proc(
	maze: ^[level.LEVEL_W][level.LEVEL_H]level.CellType,
	camera: ^rl.Camera,
	dt: f32,
) -> bool {
	player_box := rl.BoundingBox {
		camera.position - game.CAMERA_SIZE,
		camera.position + game.CAMERA_SIZE,
	}
	for w in 0 ..< level.LEVEL_W {
		for h in 0 ..< level.LEVEL_H {
			cell := maze[w][h]
			if (cell == .W) {
				wall_box := rl.BoundingBox {
					{
						f32(w) * level.STEP - level.HALF_STEP,
						-level.HALF_STEP,
						f32(h) * level.STEP - level.HALF_STEP,
					},
					{
						f32((w + 1)) * level.STEP - level.HALF_STEP,
						level.HALF_STEP,
						f32((h + 1)) * level.STEP - level.HALF_STEP,
					},
				}
				// rl.DrawBoundingBox(wall_box, rl.MAROON)
				if rl.CheckCollisionBoxes(wall_box, player_box) {
					// fmt.println("HIT", dt)
					return true
				}
			}
		}
	}
	return false
}
