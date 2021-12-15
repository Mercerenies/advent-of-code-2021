
package main

import (
	"fmt"
	"os"
	"bufio"
)

func main() {
	inputFile, _ := os.Open("input.txt")
	defer inputFile.Close()
	grid := [100]int32{0}

	scanner := bufio.NewScanner(inputFile)
	y := 0
	for scanner.Scan() {
		for x, char := range scanner.Text() {
			grid[y * 10 + x] = (char - '0')
		}
		y += 1
	}

	flashes := 0
	step := 0
	for {

		// Increment everybody's energy count
		for i := 0; i < 100; i++ {
			grid[i] += 1
		}

		// Everybody greater than 9 flashes
		flashed := [100]bool{false}
		for {
			done := true
			for y := 0; y < 10; y++ {
				for x := 0; x < 10; x++ {
					if grid[y * 10 + x] > 9 && !flashed[y * 10 + x] {
						flashes += 1
						flashed[y * 10 + x] = true
						done = false
						// Raise energy on nearby
						increment(grid[:], y - 1, x - 1)
						increment(grid[:], y - 1, x    )
						increment(grid[:], y - 1, x + 1)
						increment(grid[:], y    , x - 1)
						increment(grid[:], y    , x + 1)
						increment(grid[:], y + 1, x - 1)
						increment(grid[:], y + 1, x    )
						increment(grid[:], y + 1, x + 1)
					}
				}
			}
			if done {
				break
			}
		}

		// Reduce those who flashed
		allFlashed := true
		for i := 0; i < 100; i++ {
			if flashed[i] {
				grid[i] = 0
			} else {
				allFlashed = false
			}
		}

		step += 1
		if (allFlashed) {
			break
		}
	}

	fmt.Println(step)

}

func increment(arr []int32, y int, x int) {
	if y >= 0 && x >= 0 && y < 10 && x < 10 {
		arr[y * 10 + x] += 1
	}
}
