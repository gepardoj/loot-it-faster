package rs

import rl "vendor:raylib"

LOCK_MATERIAL_I :: 3


wall_tex: rl.Texture
chest_braces_tex: rl.Texture
chest_wood_tex: rl.Texture
chest_lock_tex: rl.Texture
lockpick_tex: rl.Texture

chest_model: rl.Model
lockpick_model: rl.Model
lockpick_img: rl.Texture

init :: proc() {
	wall_tex = rl.LoadTexture("assets/textures/wall.jpg")
	chest_braces_tex = rl.LoadTexture("assets/textures/chest_braces.jpg")
	chest_wood_tex = rl.LoadTexture("assets/textures/chest_wood.jpg")
	chest_lock_tex = rl.LoadTexture("assets/textures/chest_lock.jpg")
	lockpick_tex = rl.LoadTexture("assets/textures/lockpick.jpg")

	lockpick_model = rl.LoadModel("assets/lockpick.gltf")
	lockpick_model.materials[1].maps[rl.MaterialMapIndex.ALBEDO].texture = lockpick_tex
	lockpick_model.materials[1].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
	lockpick_img = rl.LoadTexture("assets/img/lockpick.png")

	chest_model = rl.LoadModel("assets/chest.gltf")
	chest_model.materials[2].maps[rl.MaterialMapIndex.ALBEDO].texture = chest_braces_tex
	chest_model.materials[2].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
	chest_model.materials[1].maps[rl.MaterialMapIndex.ALBEDO].texture = chest_wood_tex
	chest_model.materials[1].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
	chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].texture =
		chest_lock_tex
	chest_model.materials[LOCK_MATERIAL_I].maps[rl.MaterialMapIndex.ALBEDO].color = rl.WHITE
}

cleanup :: proc() {
	rl.UnloadTexture(wall_tex)
	rl.UnloadTexture(chest_braces_tex)
	rl.UnloadTexture(chest_wood_tex)
	rl.UnloadTexture(chest_lock_tex)
	rl.UnloadTexture(lockpick_img)
	rl.UnloadTexture(lockpick_tex)

	rl.UnloadModel(chest_model)
	rl.UnloadModel(lockpick_model)
}
