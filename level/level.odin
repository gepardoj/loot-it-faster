package level

import "core:math/rand"

CellType :: enum u8 {
	P = 0,
	E = 1,
	W = 2,
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

generate :: proc() -> [LEVEL_W][LEVEL_H]CellType {
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
	for i in 0 ..< 40 {

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
			level[x][y] = .E
		}
	}

	level[player_pos_x][player_pos_y] = .P

	return level
}
