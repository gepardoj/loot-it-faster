package inventory


Point :: struct {
	x, y: int,
}


ItemType :: enum u8 {
	LOCKPICK,
}

Item :: struct {
	id:     int,
	type:   ItemType,
	origin: Point, // top left beginning of shape
	shape:  []Point,
}

EventItemData :: struct {
	item:       ^Item,
	is_in_area: bool,
}

LOCKPICK_SHAPE := []Point{{0, 0}, {0, 1}}

@(private)
_id_counter := -1

new_id :: proc() -> int {
	_id_counter += 1
	return _id_counter
}

get_shape_by_type :: proc(type: ItemType) -> []Point {
	switch type {
	case .LOCKPICK:
		return LOCKPICK_SHAPE
	}
	return {}
}
