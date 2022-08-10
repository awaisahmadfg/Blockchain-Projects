/*
The String data type in Rust can be classified into the following −

1.    String Literal(&str) or string slices : when the value of a string is known at compile time. String literals are static by default. 
This means that string literals are guaranteed to be valid for the duration of the entire program.

2.    String Object(String): The String object type can be used to represent string values that are provided at runtime.

/* CompileTime vs RunTime
1. Compile time is the period when the programming code (such as C#, Java, C, Python) is converted to the machine code (i.e. binary code).
2. Runtime is the period of time when a program is running and generally occurs after compile time.
*/ 



*/

fn main(){
    let companyname: &str = "Learning String slices in InvoZone";
    let mylocation: &str= "Lahore, Pakistan";

    println!("I'm {} and my location is {}", companyname,mylocation);
}