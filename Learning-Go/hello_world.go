package main
import "fmt"

func main() {
    fmt.Println("hello world")
}

/*
1. package main

    - In Go, the package keyword is used to define which package the current file belongs to.
    The main package is a special package in Go. 
    - It defines an executable program. When you run the Go program, the execution starts from the main() function.
    - If your program is intended to run (not be a library), you must define it inside the main package.
    - In this case, main doesn't take any parameters and doesn't return anything (its return type is implicitly void in Go).
*/