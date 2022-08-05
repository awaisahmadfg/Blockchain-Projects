/*
A scalar type represents a single value. For example, 10,3.14,'c'. Rust has four primary scalar types.

    Integer
    Floating-point
    Booleans
    Characters

*/

// Integer
/*
Integers can be further classified as Signed and Unsigned.
Signed integers can store both negative and positive values. Unsigned integers can only store positive values*/

fn main() {
    let result = 10;    // i32 by default
    let age:u32 = 20;
    let sum:i32 = 5-15;
    let mark:isize = 10;
    let count:usize = 30;

    println!("result value is {}",result);
    println!("sum is {} and age is {}",sum,age);
    println!("mark is {} and count is {}",mark,count);
 }