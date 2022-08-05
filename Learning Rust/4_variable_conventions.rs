
/* 
The data type is optional while declaring a variable in Rust. The data type is inferred from the value assigned to the variable.

The syntax for declaring a variable is given below.

1. let variable_name = value;            // no type specified
2. let variable_name:dataType = value;   //type specified

*/
fn main (){
    let salary = 40_000;
    let experience = "8 months";

    println!("My salary is: {} and my experience is: {}", salary,experience);
}
    