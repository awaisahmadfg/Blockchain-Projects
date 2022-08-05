/* 

By default, variables are immutable − read only in Rust. 
In other words, the variable's value cannot be changed once a value is bound to a variable name.

*/

fn main (){
    let count = 7;
    println!("count value is {}",count);
    
    // Assigning new value
    count = 8;
    println!("count value is {}", count);
    
    
}