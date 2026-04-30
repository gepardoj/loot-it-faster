package inventory

import "../listener"
import "../rs"
import "core:fmt"
import rl "vendor:raylib"


INV_W :: 8
INV_H :: 12
CELL_SIZE :: 50
CELL_SPACING :: 3
EMPTY :: -1

INV_START_X :: 550
INV_START_Y :: 100

BORDER_THICKNESS :: 4

BG_COLOR :: rl.Color{120, 100, 70, 255}
BORDER_COLOR :: rl.Color{110, 90, 60, 255}


@(private)
_inventory: [INV_W][INV_H]int // ID's of items, -1 for empty


@(private)
_dragging_item: ^Item = nil
dragged_item :: proc() -> ^Item {return _dragging_item}
set_dragged_item :: proc(item: ^Item) {_dragging_item = item}
is_dragging :: proc() -> bool {return dragged_item != nil}


@(private)
_is_open := false
is_open :: proc() -> bool {return _is_open}

@(private)
_items: map[int]Item


init :: proc() {
	for w in 0 ..< INV_W {
		for h in 0 ..< INV_H {
			_inventory[w][h] = EMPTY
		}
	}

	_items = make(map[int]Item)

	for i in 0 ..< 5 {
		lockpick: Item = {new_id(), .LOCKPICK, {i, 0}, LOCKPICK_SHAPE}
		put_item(i, 0, &lockpick)
		_items[lockpick.id] = lockpick
	}
}

cleanup :: proc() {
	delete(_items)
}


// create_item :: proc(type: ItemType, pos_x, pos_y: int) -> ^Item {
// 	item: Item = {new_id(), type, {pos_x, pos_y}, get_shape_by_type(type)}
// 	_items[item.id] = item
// 	return &_items[item.id]
// }

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
	if _is_open {
		pos := rl.GetMousePosition()
		pos.x -= INV_START_X
		pos.y -= INV_START_Y
		// mouse inside the inventory area
		if pos.x >= 0 && pos.x < INV_W * CELL_SIZE && pos.y >= 0 && pos.y < INV_H * CELL_SIZE {
			cell_x := int(pos.x) / CELL_SIZE
			cell_y := int(pos.y) / CELL_SIZE
			if rl.IsMouseButtonPressed(.LEFT) {
				// fmt.println("pressed :: ", cell_x, cell_y)
				item_id := _inventory[cell_x][cell_y]
				if (item_id != EMPTY) {
					_dragging_item = &_items[item_id]
					listener.emit(.DRAGGING_STARTED, _dragging_item)
				}
			}
			if _dragging_item != nil {
				// fmt.println("dragging :: ", cell_x, cell_y)
				// fmt.println(_dragging_item.type)
				listener.emit(.DRAGGING, _dragging_item)
			}
			if _dragging_item != nil && rl.IsMouseButtonReleased(.LEFT) {
				// fmt.println("released :: ", cell_x, cell_y, _dragging_item.type)
				new_x := cell_x
				new_y := cell_y
				if _can_move_to(_dragging_item, new_x, new_y) do _move_item_to(_dragging_item, new_x, new_y)
				data: EventItemData = {_dragging_item, true}
				listener.emit(.DRAGGING_ENDED, &data)
				_dragging_item = nil
			}
		} else { 	// outside the inventory area
			if _dragging_item != nil && rl.IsMouseButtonReleased(.LEFT) {
				data: EventItemData = {_dragging_item, false}
				listener.emit(.DRAGGING_ENDED, &data)
				_dragging_item = nil
			}
		}
	}
}

@(private)
_can_move_to :: proc(item: ^Item, new_x, new_y: int) -> bool {
	for offset in item.shape {
		x := new_x + offset.x
		y := new_y + offset.y
		if (x < 0 || x >= INV_W || y < 0 || y >= INV_H || (_inventory[x][y] != item.id && _inventory[x][y] != EMPTY)) do return false
	}
	return true
}

@(private)
_move_item_to :: proc(item: ^Item, new_x, new_y: int) {
	// this two actions of clearing and setting item, it has to be separated, otherwise it can clear each other, if we move the item bellow by 1 step
	if item.origin.x != -1 { 	//TODO:we need to use inventory origin pointer. if item came from other source
		for offset in item.shape {
			_inventory[item.origin.x + offset.x][item.origin.y + offset.y] = EMPTY
		}
	}
	for offset in item.shape {
		_inventory[new_x + offset.x][new_y + offset.y] = item.id
	}
	item.origin = {new_x, new_y}
	// fmt.println("moved")
}

RenderingTriplet :: struct {
	x, y, id: int,
}

render_ui :: proc() {
	if _is_open {
		rendered_items := make([dynamic]RenderingTriplet)
		defer delete(rendered_items)

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
				id := _inventory[w][h]
				for item_id in _items {
					// 1. we need to store ids of items to prevent rendering again the other parts of this item
					if (id == item_id && !has_rendered_id(&rendered_items, id)) {
						append(&rendered_items, RenderingTriplet{pos_x, pos_y, id})
					}
				}
			}
		}
		// 2. and we render items separately from inventory loop
		for data in rendered_items {
			// we do not render dragged item in its current position
			if _dragging_item != nil && _dragging_item.id == data.id do continue
			rl.DrawTexture(rs.lockpick_img, i32(data.x), i32(data.y), rl.WHITE)
		}
		// render dragged item
		if _dragging_item != nil {
			mouse_pos := rl.GetMousePosition()
			rl.DrawTexture(rs.lockpick_img, i32(mouse_pos.x), i32(mouse_pos.y), rl.WHITE)
		}
	}
}

has_rendered_id :: proc(rendered_ids: ^[dynamic]RenderingTriplet, id: int) -> bool {
	for data in rendered_ids {
		if data.id == id do return true
	}
	return false
}

remove_item :: proc(item: ^Item) {
	for offset in item.shape {
		_inventory[item.origin.x + offset.x][item.origin.y + offset.y] = EMPTY
	}
	delete_key(&_items, item.id)
}
