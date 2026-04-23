package main

import "core:fmt"
import "level"
import rl "vendor:raylib"

STEP :: 3

main :: proc() {
	rl.InitWindow(1000, 800, "Loot it faster")
	defer rl.CloseWindow()

	player_x, player_y, maze := level.generate()


	camera := rl.Camera {
		position   = {f32(player_x * STEP), 0, f32(player_y * STEP)},
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

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		rl.UpdateCamera(&camera, .FREE)

		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode3D(camera)

		for w in 0 ..< level.LEVEL_W {
			for h in 0 ..< level.LEVEL_H {
				cell := maze[w][h]
				if (cell == .W) {
					pos := rl.Vector3{f32(w * STEP), 0, f32(h * STEP)}
					rl.DrawCube(pos, STEP, STEP, STEP, rl.GOLD)
				}
			}
		}

		rl.EndMode3D()

		rl.EndDrawing()
	}
}
