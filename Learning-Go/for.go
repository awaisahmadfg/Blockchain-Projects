package main

import "fmt"

func main() {

    i := 1
    for i <= 3 {
        fmt.Println(i)
        i = i + 1
    }

    for j := 0; j < 3; j++ {
        fmt.Println(j)
    }

    // for i := range 3 {
	for i := range [3]int{1, 2, 3} {  // Create an array of 3 elements
        fmt.Println("range", i)
    }

    for {
        fmt.Println("loop")
        break
    }

    // for n := range 6 {
	for n := range []int{1, 2, 3, 4, 5} {  // Create a slice of 5 elements
        if n%2 == 0 {
            continue
        }
        fmt.Println(n)
    }
}

/*
# ERRORS: command-line-arguments
	./for.go:17:20: cannot range over 3 (untyped int constant)
	./for.go:26:20: cannot range over 6 (untyped int constant)

SOLUTIONS: 
	In Go, range is used to iterate over data structures like slices, arrays, maps, or channels. 
	It cannot be directly used with integers like 3 or 6 because they are not iterables.
*/