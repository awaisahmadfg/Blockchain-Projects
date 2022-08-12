/*
If the Boolean expression evaluates to true, then the block of code inside the if statement will be executed. 
If the Boolean expression evaluates to false, then the first set of code after the end of the if statement 
(after the closing curly brace) will be executed.
 */

fn main(){
    let num:i32 = 5;
    if num > 0 {
        println!("number is positive");
    }
    println!("Code outside and below if statement");
}