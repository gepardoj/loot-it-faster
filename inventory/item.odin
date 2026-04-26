package inventory


Point :: struct {
	x, y: int,
}


ItemType :: enum u8 {
	LOCK_PICK,
}

Item :: struct {
	id:     int,
	type:   ItemType,
	origin: Point, // top left beginning of shape
	shape:  []Point,
}

lock_pick_shape := []Point{{0, 0}, {0, 1}}

@(private)
_id_counter := -1

new_id :: proc() -> int {
	_id_counter += 1
	return _id_counter
}
