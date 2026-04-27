package main

import "core:fmt"
import "helpers"
import "inventory"
import "level"
import "listener"
import rl "vendor:raylib"

PLAYER_SPEED :: 7.5
CAMERA_SIZE :: 0.3
MOUSE_SENSITIVITY :: 0.1


LOCK_MATERIAL_I :: 3
LOCK_MESH_I :: 0
CHEST_ROTATION_D :: 45
CHEST_ROTATION_R :: CHEST_ROTATION_D * rl.DEG2RAD

USE_DISTANCE :: 2.5


ListenerCtx :: struct {
	camera:           ^rl.Camera,
	chest_model:      ^rl.Model,
	chests_positions: ^[dynamic]rl.Vector3,
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

	cube_mesh := rl.GenMeshCube(level.STEP, level.STEP, level.STEP)

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

	listener_ctx: ListenerCtx = {&camera, &chest_model, &level.chests_positions}
	listener.subscribe(.DRAGGING_STARTED, &listener_ctx, on_dragging_started)
	listener.subscribe(.DRAGGING_ENDED, &listener_ctx, on_dragging_ended)

	rl.GenTextureMipmaps(&wall_tex)
	rl.SetTextureFilter(wall_tex, .POINT)

	wall_model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = wall_tex

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

		if rl.Vector3Length(move_direction) >= 0.5 do rl.UpdateMusicStream(music_footsteps)

		move_step := move_direction * PLAYER_SPEED * dt

		camera.position.x += move_step.x
		if is_wall_collide(&level.maze, &camera, dt) {
			camera.position.x = last_camera_pos.x
		}

		camera.position.z += move_step.z
		if is_wall_collide(&level.maze, &camera, dt) {
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
		chest_i := 0
		for w in 0 ..< level.LEVEL_W {
			for h in 0 ..< level.LEVEL_H {
				cell := level.maze[w][h]
				if cell == .W { 	// render wall
					center_pos := rl.Vector3{f32(w * level.STEP), 0, f32(h * level.STEP)}
					rl.DrawModel(wall_model, center_pos, 1, rl.WHITE)
				} else { 	// render floor, ceiling
					if cell == .C { 	// render chest
						center_pos := level.chests_positions[chest_i]
						rl.DrawModelEx(
							chest_model,
							center_pos,
							{0, 1, 0},
							CHEST_ROTATION_D,
							1,
							rl.WHITE,
						)
						chest_i += 1
					}
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
		inventory.render_ui(&lock_pick_img)

		rl.EndDrawing()
	}

	//// CLEANUP
	inventory.cleanup()
}

///// EVENT HANDLERS //////

on_dragging_started :: proc(ctx: rawptr, data: rawptr) {
	ctx := (^ListenerCtx)(ctx)
	item := (^inventory.Item)(data)
	if item.type == .LOCK_PICK {
		ctx.chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color =
			rl.GREEN
	}
	// fmt.println("main::draggin_started", item.type)
}

on_dragging_ended :: proc(ctx: rawptr, data: rawptr) {
	ctx := (^ListenerCtx)(ctx)
	data := (^inventory.EventItemData)(data)
	// use a lockpick on a chest
	if data.item.type == .LOCK_PICK {
		ctx.chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color =
			rl.WHITE
		if !data.is_in_area {
			is_raycasting_chest_lock(ctx)
		}
	}
	// fmt.println("main::draggin_ended", data.item.type)
}


///// OTHER /////

is_raycasting_chest_lock :: proc(ctx: ^ListenerCtx) {
	ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), ctx.camera^)
	for pos in ctx.chests_positions {
		rotation := rl.MatrixRotate({0, 1, 0}, CHEST_ROTATION_R)
		translation := rl.MatrixTranslate(pos.x, pos.y, pos.z)
		transform := translation * rotation
		hit_info := rl.GetRayCollisionMesh(ray, ctx.chest_model.meshes[LOCK_MESH_I], transform)
		if hit_info.hit == true && hit_info.distance <= USE_DISTANCE {
			fmt.println("use it")
		}
	}
}

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
