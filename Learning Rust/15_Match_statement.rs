/*

The match statement checks if a current value is matching from a list of values, 
this is very much similar to the switch statement in C language.

*/

 fn main(){
    let variable = "Awais";

    let check = match variable{
        "Awais" => {println!("Found match for variable"); "AWAIS"},
        "KL" => "Kerala",
        "KA" => "Karnadaka",
        "GA" => "Goa",
        _ => "Unknown"  
    };

    println!("State name is {}",variable);

}