package main

import "core:fmt"
import "helpers"
import "inventory"
import "level"
import "listener"
import rl "vendor:raylib"

STEP :: 3.0
HALF_STEP :: STEP / 2
PLAYER_SPEED :: 7.5
CAMERA_SIZE :: 0.3
MOUSE_SENSITIVITY :: 0.1


LOCK_MATERIAL_I :: 3


ListenerCtx :: struct {
	chest_model: ^rl.Model,
}

main :: proc() {
	rl.InitWindow(1000, 800, "Loot it faster")

	rl.InitAudioDevice()
	music_footsteps := rl.LoadMusicStream("assets/footsteps.mp3")
	rl.PlayMusicStream(music_footsteps)


	wall_tex := rl.LoadTexture("assets/textures/wall.jpg")
	chest_braces_tex := rl.LoadTexture("assets/textures/chest_braces.jpg")
	chest_wood_tex := rl.LoadTexture("assets/textures/chest_wood.jpg")
	chest_lock_tex := rl.LoadTexture("assets/textures/chest_lock.jpg")

	cube_mesh := rl.GenMeshCube(STEP, STEP, STEP)

	wall_model := rl.LoadModelFromMesh(cube_mesh)

	lock_pick_model := rl.LoadModel("assets/lock_pick.glb")
	lock_pick_model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
	lock_pick_model.materials[1].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
	lock_pick_img := rl.LoadTexture("assets/img/lock_pick.png")


	chest_model := rl.LoadModel("assets/chest.gltf")
	chest_model.materials[2].maps[rl.MaterialMapIndex.ALBEDO].texture = chest_braces_tex
	chest_model.materials[2].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
	chest_model.materials[1].maps[rl.MaterialMapIndex.ALBEDO].texture = chest_wood_tex
	chest_model.materials[1].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
	chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].texture =
		chest_lock_tex
	chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE

	defer rl.UnloadModel(wall_model)
	defer rl.UnloadModel(chest_model)
	defer rl.UnloadModel(lock_pick_model)

	defer rl.UnloadTexture(wall_tex)
	defer rl.UnloadTexture(chest_braces_tex)
	defer rl.UnloadTexture(chest_wood_tex)
	defer rl.UnloadTexture(chest_lock_tex)
	defer rl.UnloadTexture(lock_pick_img)


	defer rl.UnloadMusicStream(music_footsteps)
	defer rl.CloseAudioDevice()

	defer rl.CloseWindow()

	listener.init()
	defer listener.cleanup()

	listener_ctx: ListenerCtx = {&chest_model}
	listener.subscribe(.DRAGGING_STARTED, &listener_ctx, on_dragging_started)
	listener.subscribe(.DRAGGING_ENDED, &listener_ctx, on_dragging_ended)

	rl.GenTextureMipmaps(&wall_tex)
	rl.SetTextureFilter(wall_tex, .POINT)

	wall_model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = wall_tex

	player_start_x, player_start_z, maze := level.generate()


	camera := rl.Camera {
		position   = {f32(player_start_x * STEP), 0, f32(player_start_z * STEP)},
		target     = {10, 0, 0},
		up         = {0, 1, 0},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}
	rl.DisableCursor()
	rl.SetTargetFPS(60)

	helpers.print_array(&maze)

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

		if rl.Vector3Length(move_direction) >= 0.5 do rl.UpdateMusicStream(music_footsteps)

		move_step := move_direction * PLAYER_SPEED * dt

		camera.position.x += move_step.x
		if is_wall_collide(&maze, &camera, dt) {
			camera.position.x = last_camera_pos.x
		}

		camera.position.z += move_step.z
		if is_wall_collide(&maze, &camera, dt) {
			camera.position.z = last_camera_pos.z
		}

		camera.target += (camera.position - last_camera_pos)

		mouse_delta := rl.GetMouseDelta()
		rotation :=
			rl.Vector3{mouse_delta.x, mouse_delta.y, 0} *
			MOUSE_SENSITIVITY *
			f32(int(!inventory.is_open()))
		rl.UpdateCameraPro(&camera, {}, rotation, 0)


		//// UPDATE GAME LOGIC
		inventory.update()


		//// DRAWING
		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode3D(camera)

		// rl.DrawModel(
		// 	lock_pick_model,
		// 	{f32(player_start_x * STEP), 0, f32(player_start_z * STEP)},
		// 	.1,
		// 	rl.WHITE,
		// )

		// render walls, floor, ceiling
		for w in 0 ..< level.LEVEL_W {
			for h in 0 ..< level.LEVEL_H {
				cell := maze[w][h]
				if cell == .W { 	// render wall
					center_pos := rl.Vector3{f32(w * STEP), 0, f32(h * STEP)}
					rl.DrawModel(wall_model, center_pos, 1, rl.WHITE)
				} else { 	// render floor, ceiling
					if cell == .C { 	// render chest
						center_pos := rl.Vector3 {
							f32(w * STEP),
							-HALF_STEP,
							f32(h * STEP) - HALF_STEP / 2,
						}
						rl.DrawModelEx(chest_model, center_pos, {0, 1, 0}, 90, 1, rl.WHITE)
					}
					floor_center_pos := rl.Vector3{f32(w * STEP), -STEP, f32(h * STEP)}
					rl.DrawModel(wall_model, floor_center_pos, 1, rl.WHITE)
					ceiling_center_pos := rl.Vector3{f32(w * STEP), STEP, f32(h * STEP)}
					rl.DrawModel(wall_model, ceiling_center_pos, 1, rl.WHITE)
				}
			}
		}

		rl.EndMode3D()

		//// UI ////
		inventory.render_ui(&lock_pick_img)

		rl.EndDrawing()
	}

	//// CLEANUP
	inventory.cleanup()
}

///// EVENTS //////

on_dragging_started :: proc(ctx: rawptr, data: rawptr) {
	ctx := (^ListenerCtx)(ctx)
	item := (^inventory.Item)(data)
	if item.type == .LOCK_PICK {
		ctx.chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color =
			rl.GREEN
	}
	fmt.println("main::draggin_started", item.type)
}

on_dragging_ended :: proc(ctx: rawptr, data: rawptr) {
	ctx := (^ListenerCtx)(ctx)
	item := (^inventory.Item)(data)
	if item.type == .LOCK_PICK {
		ctx.chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color =
			rl.WHITE
	}
	fmt.println("main::draggin_ended", item.type)
}


///// OTHER /////

is_wall_collide :: proc(
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
