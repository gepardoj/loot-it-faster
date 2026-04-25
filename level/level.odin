package level

import "core:math"
import "core:math/rand"

CellType :: enum u8 {
	P,
	O,
	W,
	C,
}

Direction :: enum {
	None,
	Left,
	Right,
	Up,
	Down,
}

LEVEL_W :: 20
LEVEL_H :: 20

CORRIDORS_NUM :: 80

CHEST_SPAWN_SECTOR_SIZE :: 6

generate :: proc() -> (int, int, [LEVEL_W][LEVEL_H]CellType) {
	level: [LEVEL_W][LEVEL_H]CellType

	for w in 0 ..< LEVEL_W {
		for h in 0 ..< LEVEL_H {
			level[w][h] = .W
		}
	}
	player_pos_x := rand.int_range(5, LEVEL_W - 5)
	player_pos_y := rand.int_range(5, LEVEL_H - 5)

	x := player_pos_x
	y := player_pos_y
	dir := Direction.None

	for i in 0 ..< CORRIDORS_NUM {
		available_dirs: []Direction
		if dir == .None {
			available_dirs = []Direction{.Left, .Right, .Up, .Down}
		} else if dir == .Left {
			available_dirs = []Direction{.Left, .Up, .Down}
		} else if dir == .Right {
			available_dirs = []Direction{.Right, .Up, .Down}
		} else if dir == .Up {
			available_dirs = []Direction{.Left, .Right, .Up}
		} else if dir == .Down {
			available_dirs = []Direction{.Left, .Right, .Down}
		}
		dir = rand.choice(available_dirs)
		for len in 1 ..= 2 {
			#partial switch dir {
			case .Left:
				x -= 1
			case .Right:
				x += 1
			case .Up:
				y += 1
			case .Down:
				y -= 1
			}
			if (x == -1 || y == -1 || x == LEVEL_W || y == LEVEL_H) {
				x = player_pos_x
				y = player_pos_y
				dir = .None
				break
			}
			if (level[x][y] == .P) {
				continue
			}
			level[x][y] = .O
		}
	}

	// spawn chests
	level[0][0] = .C
	make_corridors_to_player(&level, .None, 0, 0, player_pos_x, player_pos_y)
	for w in 0 ..< LEVEL_W / CHEST_SPAWN_SECTOR_SIZE {
		for h in 0 ..< LEVEL_H / CHEST_SPAWN_SECTOR_SIZE {
			x := rand.int_range(w * CHEST_SPAWN_SECTOR_SIZE, (w + 1) * CHEST_SPAWN_SECTOR_SIZE)
			y := rand.int_range(h * CHEST_SPAWN_SECTOR_SIZE, (h + 1) * CHEST_SPAWN_SECTOR_SIZE)
			level[x][y] = .C
			make_corridors_to_player(&level, .None, x, y, player_pos_x, player_pos_y)
		}
	}

	// fill with outer walls
	for w in 0 ..< LEVEL_W { 	// horizontal
		level[w][0] = .W
		level[w][LEVEL_H - 1] = .W
	}
	for h in 0 ..< LEVEL_H { 	// vertical
		level[0][h] = .W
		level[LEVEL_W - 1][h] = .W
	}

	level[player_pos_x][player_pos_y] = .P

	return player_pos_x, player_pos_y, level
}


make_corridors_to_player :: proc(
	level: ^[LEVEL_W][LEVEL_H]CellType,
	comes_from: Direction,
	start_x, start_y, player_x, player_y: int,
) {
	// TODO:check for array boundaries
	left := is_valid(start_x - 1, start_y) ? level[start_x - 1][start_y] : .W
	right := is_valid(start_x + 1, start_y) ? level[start_x + 1][start_y] : .W
	up := is_valid(start_x, start_y - 1) ? level[start_x][start_y - 1] : .W
	down := is_valid(start_x, start_y + 1) ? level[start_x][start_y + 1] : .W
	// if our chest is surrounded by walls then make corridor
	if (comes_from == .Left || left == .W || left == .C) &&
	   (comes_from == .Right || right == .W || right == .C) &&
	   (comes_from == .Up || up == .W || up == .C) &&
	   (comes_from == .Down || down == .W || down == .C) {
		// choose direction to the player spawn
		dx := player_x - start_x
		dy := player_y - start_y
		if dx != 0 {
			// move by x
			sign := math.sign(dx)
			from: Direction = sign == 1 ? .Left : .Right
			new_x := start_x + sign
			level[new_x][start_y] = .O
			make_corridors_to_player(level, from, new_x, start_y, player_x, player_y)
		} else if dy != 0 {
			// move by y
			sign := math.sign(dy)
			from: Direction = sign == 1 ? .Up : .Down
			new_y := start_y + sign
			level[start_x][new_y] = .O
			make_corridors_to_player(level, from, start_x, new_y, player_x, player_y)
		}
	}
}

is_valid :: proc(x, y: int) -> bool {
	return x >= 0 && x < LEVEL_W && y >= 0 && y < LEVEL_H
}
