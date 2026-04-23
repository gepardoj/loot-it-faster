package main

import "core:fmt"
import "level"

main :: proc() {
	maze := level.generate()

	for w in 0 ..< level.LEVEL_W {
		fmt.println(maze[w])
	}
}
