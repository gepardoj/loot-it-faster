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

array_contains :: proc(arr: ^[dynamic]$T, value: $T2) -> bool {
	for i in arr {
		if arr[i] == value do return true
	}
	return false
}
