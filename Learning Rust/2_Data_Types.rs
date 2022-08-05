fn main() {

/*
The println! macro takes two arguments −

    1. A special syntax { }, which is the placeholder
    2. The variable name or a constant
   
Note:  The placeholder will be replaced by the variable’s value

*/
    let string_var = "Awais Ahmad";
    let floating_var = 23.6;
    let boolean_var = true;
    let icon_char = '♥';

    println!("My name is: {}", string_var);
    println!("My age is: {}", floating_var);
    println!("My age written is: {}", boolean_var);
    println!("Special Character: {}", icon_char);


}
