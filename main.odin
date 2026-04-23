package main

import "core:fmt"
import "level"
import rl "vendor:raylib"

STEP :: 3.0
HALF_STEP :: STEP / 2
PLAYER_SPEED :: 5
CAMERA_SIZE :: 0.3
MOUSE_SENSITIVITY :: 0.1

main :: proc() {
	rl.InitWindow(1000, 800, "Loot it faster")
	defer rl.CloseWindow()

	player_start_x, player_start_y, maze := level.generate()


	camera := rl.Camera {
		position   = {f32(player_start_x * STEP), 0, f32(player_start_y * STEP)},
		target     = {10, 0, 0},
		up         = {0, 1, 0},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}
	rl.DisableCursor()
	rl.SetTargetFPS(60)


	for w in 0 ..< level.LEVEL_W {
		fmt.println(maze[w])
	}

	last_camera_pos := camera.position
	last_camera_target := camera.target

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		last_camera_pos = camera.position
		last_camera_target = camera.target

		//// CONTROL
		move_dir: rl.Vector3
		if rl.IsKeyDown(.W) do move_dir.z += 1
		if rl.IsKeyDown(.S) do move_dir.z -= 1
		if rl.IsKeyDown(.D) do move_dir.x += 1
		if rl.IsKeyDown(.A) do move_dir.x -= 1
		move_dir = rl.Vector3Normalize(move_dir)

		dir_forward := rl.Vector3Normalize(camera.target - camera.position)
		dir_right := rl.Vector3Normalize(rl.Vector3CrossProduct(dir_forward, camera.up))
		move_step := dir_forward * move_dir.z + dir_right * move_dir.x
		move_step.y = 0
		move_step *= PLAYER_SPEED * dt

		camera.position.x += move_step.x
		if isWallCollide(&maze, &camera, dt) {
			camera.position.x = last_camera_pos.x
		}

		camera.position.z += move_step.z
		if isWallCollide(&maze, &camera, dt) {
			camera.position.z = last_camera_pos.z
		}

		camera.target += (camera.position - last_camera_pos)

		mouse_delta := rl.GetMouseDelta()
		rotation := rl.Vector3 {
			mouse_delta.x * MOUSE_SENSITIVITY,
			mouse_delta.y * MOUSE_SENSITIVITY,
			0,
		}
		rl.UpdateCameraPro(&camera, {}, rotation, 0)


		//// UPDATE GAME LOGIC


		//// DRAWING
		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode3D(camera)

		for w in 0 ..< level.LEVEL_W {
			for h in 0 ..< level.LEVEL_H {
				cell := maze[w][h]
				if (cell == .W) {
					center_pos := rl.Vector3{f32(w * STEP), 0, f32(h * STEP)}
					rl.DrawCube(center_pos, STEP, STEP, STEP, rl.GOLD)

				}
			}
		}

		rl.EndMode3D()

		rl.EndDrawing()
	}
}


isWallCollide :: proc(
	maze: ^[level.LEVEL_W][level.LEVEL_H]level.CellType,
	camera: ^rl.Camera,
	dt: f32,
) -> bool {
	player_box := rl.BoundingBox{camera.position - CAMERA_SIZE, camera.position + CAMERA_SIZE}
	for w in 0 ..< level.LEVEL_W {
		for h in 0 ..< level.LEVEL_H {
			cell := maze[w][h]
			if (cell == .W) {
				wall_box := rl.BoundingBox {
					{f32(w) * STEP - HALF_STEP, -HALF_STEP, f32(h) * STEP - HALF_STEP},
					{f32((w + 1)) * STEP - HALF_STEP, HALF_STEP, f32((h + 1)) * STEP - HALF_STEP},
				}
				// rl.DrawBoundingBox(wall_box, rl.MAROON)
				if rl.CheckCollisionBoxes(wall_box, player_box) {
					fmt.println("HIT", dt)
					return true
				}
			}
		}
	}
	return false
}
