/*
Automatic Type Casting is not alllowed in Rust if you type just 23 it will give you mismatch error.
*/ 

fn main(){
    
    let interest:f64 = 23.4; // by defualt  let interest= 23 is also equals to the f64
    println!("interest is {}", interest);

}