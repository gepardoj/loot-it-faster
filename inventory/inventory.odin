package inventory

import rl "vendor:raylib"


INV_W :: 8
INV_H :: 12
CELL_SIZE :: 50
CELL_SPACING :: 3

INV_START_X :: 550
INV_START_Y :: 100

BORDER_THICKNESS :: 4

BG_COLOR :: rl.Color{120, 100, 70, 255}
BORDER_COLOR :: rl.Color{110, 90, 60, 255}


@(private)
_inventory: [INV_W][INV_H]int // ID's of items, -1 for empty

@(private)
_is_open := false
is_open :: proc() -> bool {
	return _is_open
}

@(private)
_items: [dynamic]Item


init :: proc() {
	for w in 0 ..< INV_W {
		for h in 0 ..< INV_H {
			_inventory[w][h] = -1
		}
	}

	_items = make([dynamic]Item)

	for i in 0 ..< 5 {
		lock_pick: Item = {new_id(), .LOCK_PICK, lock_pick_shape}
		put_item(i, 0, &lock_pick)
		append(&_items, lock_pick)
	}
}

put_item :: proc(x, y: int, item: ^Item) {
	for offset in item.shape {
		_inventory[x + offset.x][y + offset.y] = item.id
	}
}

update :: proc() {
	if rl.IsKeyReleased(.I) {
		_is_open = !_is_open
		if _is_open {
			rl.EnableCursor()

		} else {
			rl.DisableCursor()
		}
	}
}

RenderingTriplet :: struct {
	x, y, id: int,
}

render_ui :: proc(lock_pick_img: ^rl.Texture) {
	if _is_open {
		rendered_ids := make([dynamic]RenderingTriplet)
		defer delete(rendered_ids)

		rl.DrawRectangle(INV_START_X, INV_START_Y, INV_W * CELL_SIZE, INV_H * CELL_SIZE, BG_COLOR)
		rl.DrawRectangleLinesEx(
			{INV_START_X, INV_START_Y, INV_W * CELL_SIZE, INV_H * CELL_SIZE},
			BORDER_THICKNESS,
			BORDER_COLOR,
		)
		// render cells
		for w in 0 ..< INV_W {
			for h in 0 ..< INV_H {
				pos_x := INV_START_X + w * CELL_SIZE
				pos_y := INV_START_Y + h * CELL_SIZE
				rl.DrawRectangleLinesEx(
					{f32(pos_x), f32(pos_y), CELL_SIZE, CELL_SIZE},
					BORDER_THICKNESS / 2,
					BORDER_COLOR,
				)
				// render item
				id := _inventory[w][h]
				for item in _items {
					if (id == item.id && !has_rendered_id(&rendered_ids, id)) {
						append(&rendered_ids, RenderingTriplet{pos_x, pos_y, id})
					}
				}
			}
		}
		for data in rendered_ids {
			rl.DrawTexture(lock_pick_img^, i32(data.x), i32(data.y), rl.WHITE)
		}
	}
}

cleanup :: proc() {
	delete(_items)
}

has_rendered_id :: proc(rendered_ids: ^[dynamic]RenderingTriplet, id: int) -> bool {
	for data in rendered_ids {
		if data.id == id do return true
	}
	return false
}
