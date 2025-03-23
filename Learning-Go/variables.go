package main

import "fmt"

func main() {

	var a = "initial"
	fmt.Println(a)

	var b, c int = 1, 2
	fmt.Println(b, c)

	var d = true
	fmt.Println(d)

	var e int
	fmt.Println(e)

	// var f string = "apple" OR f := "apple"
	// Both are same As it's a shorter and more concise way to do the same thing.
	f := "apple"
	fmt.Println(f)
}
