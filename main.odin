package main

import "core:fmt"
import "fx"
import "game"
import "helpers"
import "inventory"
import "level"
import "listener"
import "lockpicking"
import "physics"
import "rs"
import rl "vendor:raylib"


main :: proc() {
	rl.InitWindow(1000, 800, "Loot it faster")


	fx.init()
	rs.init()
	defer rs.cleanup()
	defer fx.cleanup()


	cube_mesh := rl.GenMeshCube(level.STEP, level.STEP, level.STEP)
	wall_model := rl.LoadModelFromMesh(cube_mesh)
	defer rl.UnloadModel(wall_model)


	defer rl.CloseWindow()

	level.init()
	level.generate()
	defer level.cleanup()

	camera := rl.Camera {
		position   = {
			f32(level.player_start_x * level.STEP),
			0,
			f32(level.player_start_z * level.STEP),
		},
		target     = {10, 0, 0},
		up         = {0, 1, 0},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}

	listener.init()
	defer listener.cleanup()

	listener_ctx: listener.ListenerCtx = {&camera, &rs.chest_model, &level.chests}
	listener.subscribe(.DRAGGING_STARTED, &listener_ctx, on_dragging_started)
	listener.subscribe(.DRAGGING_ENDED, &listener_ctx, on_dragging_ended)

	rl.GenTextureMipmaps(&rs.wall_tex)
	rl.SetTextureFilter(rs.wall_tex, .POINT)

	wall_model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = rs.wall_tex

	rl.DisableCursor()
	rl.SetTargetFPS(60)

	helpers.print_array(&level.maze)

	last_camera_pos := camera.position
	last_camera_target := camera.target

	inventory.init()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		last_camera_pos = camera.position
		last_camera_target = camera.target

		//// CONTROL
		raw_dir: rl.Vector3
		if rl.IsKeyDown(.W) do raw_dir.z += 1
		if rl.IsKeyDown(.S) do raw_dir.z -= 1
		if rl.IsKeyDown(.D) do raw_dir.x += 1
		if rl.IsKeyDown(.A) do raw_dir.x -= 1

		dir_forward := rl.Vector3Normalize(camera.target - camera.position)
		dir_forward.y = 0
		dir_right := rl.Vector3Normalize(rl.Vector3CrossProduct(dir_forward, camera.up))
		move_direction := dir_forward * raw_dir.z + dir_right * raw_dir.x
		move_direction = rl.Vector3Normalize(move_direction)

		if rl.Vector3Length(move_direction) >= 0.5 do rl.UpdateMusicStream(fx.music_footsteps)

		move_step := move_direction * game.PLAYER_SPEED * dt

		camera.position.x += move_step.x
		if physics.is_collide_level_walls(&level.maze, &camera, dt) {
			camera.position.x = last_camera_pos.x
		}

		camera.position.z += move_step.z
		if physics.is_collide_level_walls(&level.maze, &camera, dt) {
			camera.position.z = last_camera_pos.z
		}

		camera.target += (camera.position - last_camera_pos)

		mouse_delta := rl.GetMouseDelta()
		rotation :=
			rl.Vector3{mouse_delta.x, mouse_delta.y, 0} *
			game.MOUSE_SENSITIVITY *
			f32(int(!inventory.is_open()))
		rl.UpdateCameraPro(&camera, {}, rotation, 0)


		//// UPDATE GAME LOGIC
		inventory.update()
		lockpicking.update(&camera)


		//// DRAWING
		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode3D(camera)

		for chest in level.chests {
			rl.DrawModelEx(
				rs.chest_model,
				chest.pos,
				{0, 1, 0},
				game.CHEST_ROTATION_D,
				1,
				rl.WHITE,
			)
		}

		for lockpick in level.lockpicks {
			if !lockpick.enabled do continue
			rot_z_m := rl.MatrixRotateZ(f32(lockpick.rotation_z) * rl.DEG2RAD)
			translate_m := rl.MatrixTranslate(lockpick.pos.x, lockpick.pos.y, lockpick.pos.z)
			rs.lockpick_model.transform =
				translate_m * rot_z_m * lockpicking.ROT_X_M * lockpicking.SCALE_M
			rl.DrawModel(rs.lockpick_model, {0, 0, 0}, 1, rl.WHITE)
		}

		// render walls, floor, ceiling
		for w in 0 ..< level.LEVEL_W {
			for h in 0 ..< level.LEVEL_H {
				cell := level.maze[w][h]
				if cell == .W { 	// render wall
					center_pos := rl.Vector3{f32(w * level.STEP), 0, f32(h * level.STEP)}
					rl.DrawModel(wall_model, center_pos, 1, rl.WHITE)
				} else { 	// render floor, ceiling
					floor_center_pos := rl.Vector3 {
						f32(w * level.STEP),
						-level.STEP,
						f32(h * level.STEP),
					}
					rl.DrawModel(wall_model, floor_center_pos, 1, rl.WHITE)
					ceiling_center_pos := rl.Vector3 {
						f32(w * level.STEP),
						level.STEP,
						f32(h * level.STEP),
					}
					rl.DrawModel(wall_model, ceiling_center_pos, 1, rl.WHITE)
				}
			}
		}

		rl.EndMode3D()

		//// UI ////
		inventory.render_ui()

		rl.EndDrawing()
	}

	//// CLEANUP
	inventory.cleanup()
}

///// EVENT HANDLERS //////

on_dragging_started :: proc(ctx: rawptr, data: rawptr) {
	ctx := (^listener.ListenerCtx)(ctx)
	item := (^inventory.Item)(data)
	if item.type == .LOCKPICK {
		ctx.chest_model.materials[rs.LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color =
			rl.GREEN
	}
	// fmt.println("main::draggin_started", item.type)
}

on_dragging_ended :: proc(ctx: rawptr, data: rawptr) {
	ctx := (^listener.ListenerCtx)(ctx)
	data := (^inventory.EventItemData)(data)
	// use a lockpick on a chest
	if data.item.type == .LOCKPICK {
		ctx.chest_model.materials[rs.LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color =
			rl.WHITE
		if !data.is_in_area {
			lockpicking.create_lockpick_in_chest_lock(ctx, data.item)
		}
	}
	// fmt.println("main::draggin_ended", data.item.type)
}
