package level

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

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
STEP :: 3.0
HALF_STEP :: STEP / 2

CORRIDORS_NUM :: 80

CHEST_SPAWN_SECTOR_SIZE :: 6

chests_positions: [dynamic]rl.Vector3
player_start_x: int
player_start_z: int
maze: [LEVEL_W][LEVEL_H]CellType

init :: proc() {
	chests_positions = make([dynamic]rl.Vector3)
}

cleanup :: proc() {
	delete(chests_positions)
}

generate :: proc() {
	for w in 0 ..< LEVEL_W {
		for h in 0 ..< LEVEL_H {
			maze[w][h] = .W
		}
	}
	player_start_x = rand.int_range(5, LEVEL_W - 5)
	player_start_z = rand.int_range(5, LEVEL_H - 5)

	x := player_start_x
	y := player_start_z
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
				x = player_start_x
				y = player_start_z
				dir = .None
				break
			}
			if (maze[x][y] == .P) {
				continue
			}
			maze[x][y] = .O
		}
	}

	// spawn chests
	maze[0][0] = .C
	make_corridors_to_player(&maze, .None, 0, 0, player_start_x, player_start_z)
	for w in 0 ..< LEVEL_W / CHEST_SPAWN_SECTOR_SIZE {
		for h in 0 ..< LEVEL_H / CHEST_SPAWN_SECTOR_SIZE {
			x := rand.int_range(w * CHEST_SPAWN_SECTOR_SIZE, (w + 1) * CHEST_SPAWN_SECTOR_SIZE)
			y := rand.int_range(h * CHEST_SPAWN_SECTOR_SIZE, (h + 1) * CHEST_SPAWN_SECTOR_SIZE)
			maze[x][y] = .C
			make_corridors_to_player(&maze, .None, x, y, player_start_x, player_start_z)
		}
	}

	// fill with outer walls
	for w in 0 ..< LEVEL_W { 	// horizontal
		maze[w][0] = .W
		maze[w][LEVEL_H - 1] = .W
	}
	for h in 0 ..< LEVEL_H { 	// vertical
		maze[0][h] = .W
		maze[LEVEL_W - 1][h] = .W
	}

	maze[player_start_x][player_start_z] = .P

	init_chests_positions()
}

@(private)
init_chests_positions :: proc() {
	for w in 0 ..< LEVEL_W {
		for h in 0 ..< LEVEL_H {
			cell := maze[w][h]
			if (cell == .C) {
				center_pos := rl.Vector3{f32(w * STEP), -HALF_STEP, f32(h * STEP) - HALF_STEP / 2}
				append(&chests_positions, center_pos)
			}
		}
	}
}

@(private)
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
