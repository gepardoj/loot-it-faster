package helpers

import "core:fmt"

print_array :: proc(arr: ^[$W][$H]$T) {
	for w in 0 ..< W {
		for h in 0 ..< H {
			fmt.print(arr[w][h], " ")
		}
		fmt.println()
	}
}
